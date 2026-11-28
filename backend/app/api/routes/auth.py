import secrets

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from psycopg import Error as DatabaseError
from psycopg.rows import dict_row

from db import get_connection
from app.core.authorization import (
    get_current_user,
    require_admin,
    bearer_scheme,
    unauthorized,
)
from fastapi.security import HTTPAuthorizationCredentials
from app.core.rate_limit import enforce_login_rate_limit
from app.core.tokens import decode_access_token, TokenError
from datetime import datetime, timezone
import re

from app.core.security import (
    hash_password,
    verify_password,
)

from app.core.tokens import (
    ACCESS_TOKEN_MINUTES,
    ALLOWED_ROLES,
    create_access_token,
)


router = APIRouter(
    prefix="/api/auth",
    tags=["Authentication"],
)


# Dummy hash prevents immediately revealing
# whether an account exists.
_dummy_password_hash = hash_password(
    secrets.token_urlsafe(32)
)


class LoginRequest(BaseModel):
    email: str = Field(
        min_length=1,
        max_length=150,
    )

    password: str = Field(
        min_length=1,
        max_length=128,
    )


class AuthenticatedUser(BaseModel):
    user_id: int
    full_name: str
    email: str
    role: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: AuthenticatedUser


def invalid_credentials() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid email or password.",
        headers={
            "WWW-Authenticate": "Bearer"
        },
    )


@router.post(
    "/login",
    response_model=LoginResponse,
    dependencies=[Depends(enforce_login_rate_limit)],
)
def login(data: LoginRequest):
    email = data.email.strip().lower()
    password = data.password

    if not email:
        raise invalid_credentials()

    try:
        with get_connection() as conn:
            with conn.cursor(
                row_factory=dict_row
            ) as cursor:
                cursor.execute(
                    """
                    SELECT
                        user_id,
                        full_name,
                        email,
                        password_hash,
                        role
                    FROM passenger_counting.users_tbl
                    WHERE LOWER(email) = %s
                    LIMIT 2
                    """,
                    (email,),
                )

                users = cursor.fetchall()

    except DatabaseError:
        raise HTTPException(
            status_code=503,
            detail="Authentication service unavailable.",
        ) from None

    if len(users) != 1:
        verify_password(
            password,
            _dummy_password_hash,
        )

        raise invalid_credentials()

    user = users[0]

    if not verify_password(
        password,
        user["password_hash"],
    ):
        raise invalid_credentials()

    if user["role"] not in ALLOWED_ROLES:
        raise invalid_credentials()

    token = create_access_token(
        user_id=user["user_id"],
        role=user["role"],
    )

    return LoginResponse(
        access_token=token,
        token_type="bearer",
        expires_in=ACCESS_TOKEN_MINUTES * 60,
        user=AuthenticatedUser(
            user_id=user["user_id"],
            full_name=user["full_name"],
            email=user["email"],
            role=user["role"],
        ),
    )


@router.get(
    "/me",
    response_model=AuthenticatedUser,
)
def get_my_account(
    current_user: dict = Depends(get_current_user),
):
    return AuthenticatedUser(**current_user)


# ============================================================
# SECURE LOGOUT
# ============================================================

@router.post("/logout")
def logout(
    current_user: dict = Depends(get_current_user),
    credentials: HTTPAuthorizationCredentials = Depends(
        bearer_scheme
    ),
):
    try:
        claims = decode_access_token(
            credentials.credentials
        )
    except TokenError:
        raise unauthorized() from None

    try:
        with get_connection() as conn:
            with conn.cursor() as cursor:

                cursor.execute(
                    """
                    DELETE FROM
                    passenger_counting.revoked_tokens_tbl
                    WHERE expires_at <= CURRENT_TIMESTAMP
                    """
                )

                cursor.execute(
                    """
                    INSERT INTO
                    passenger_counting.revoked_tokens_tbl (
                        token_id,
                        user_id,
                        expires_at
                    )
                    VALUES (%s, %s, %s)
                    ON CONFLICT (token_id) DO NOTHING
                    """,
                    (
                        claims["token_id"],
                        current_user["user_id"],
                        datetime.fromtimestamp(
                            claims["expires_at"],
                            timezone.utc,
                        ),
                    ),
                )

            conn.commit()

    except DatabaseError:
        raise HTTPException(
            status_code=503,
            detail="Logout service unavailable.",
        ) from None

    return {"message": "Signed out successfully."}


# ============================================================
# ADMIN-ONLY OPERATOR ACCOUNT CREATION
# ============================================================

class OperatorAccount(AuthenticatedUser):
    created_at: datetime | None = None


class OperatorCreateRequest(BaseModel):
    full_name: str = Field(
        min_length=1,
        max_length=100,
    )
    email: str = Field(
        min_length=1,
        max_length=150,
    )
    password: str = Field(
        min_length=8,
        max_length=128,
    )


@router.post(
    "/operators",
    response_model=OperatorAccount,
    status_code=201,
)
def create_operator(
    data: OperatorCreateRequest,
    admin: dict = Depends(require_admin),
):
    name = data.full_name.strip()
    email = data.email.strip().lower()

    if not name:
        raise HTTPException(
            status_code=400,
            detail="Full name is required.",
        )

    if not re.fullmatch(
        r"[^@\s]+@[^@\s]+\.[^@\s]+",
        email,
    ):
        raise HTTPException(
            status_code=400,
            detail="Invalid email address.",
        )

    try:
        password_hash = hash_password(
            data.password
        )
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="Invalid password.",
        ) from None

    try:
        with get_connection() as conn:
            with conn.cursor(
                row_factory=dict_row
            ) as cursor:

                cursor.execute(
                    """
                    LOCK TABLE passenger_counting.users_tbl
                    IN SHARE ROW EXCLUSIVE MODE
                    """
                )

                cursor.execute(
                    """
                    SELECT user_id
                    FROM passenger_counting.users_tbl
                    WHERE LOWER(email) = %s
                    """,
                    (email,),
                )

                if cursor.fetchone() is not None:
                    raise HTTPException(
                        status_code=409,
                        detail="Email is already registered.",
                    )

                cursor.execute(
                    """
                    INSERT INTO
                    passenger_counting.users_tbl (
                        full_name,
                        email,
                        password_hash,
                        role
                    )
                    VALUES (%s, %s, %s, 'operator')
                    RETURNING
                        user_id,
                        full_name,
                        email,
                        role,
                        created_at
                    """,
                    (
                        name,
                        email,
                        password_hash,
                    ),
                )

                user = cursor.fetchone()

            conn.commit()

    except DatabaseError:
        raise HTTPException(
            status_code=503,
            detail="Account creation unavailable.",
        ) from None

    return OperatorAccount(**user)


@router.get(
    "/operators",
    response_model=list[OperatorAccount],
)
def list_operators(
    admin: dict = Depends(require_admin),
):
    try:
        with get_connection() as conn:
            with conn.cursor(
                row_factory=dict_row
            ) as cursor:

                cursor.execute(
                    """
                    SELECT
                        user_id,
                        full_name,
                        email,
                        role,
                        created_at
                    FROM passenger_counting.users_tbl
                    WHERE role = 'operator'
                    ORDER BY user_id DESC
                    """
                )

                return cursor.fetchall()

    except DatabaseError:
        raise HTTPException(
            status_code=503,
            detail="Account service unavailable.",
        ) from None
