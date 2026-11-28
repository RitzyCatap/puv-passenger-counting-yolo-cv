from fastapi import Depends, HTTPException, status
from fastapi.security import (
    HTTPAuthorizationCredentials,
    HTTPBearer,
)
from psycopg import Error as DatabaseError
from psycopg.rows import dict_row

from db import get_connection

from app.core.tokens import (
    ALLOWED_ROLES,
    TokenError,
    decode_access_token,
)


bearer_scheme = HTTPBearer(auto_error=False)


def unauthorized() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Authentication required or session invalid.",
        headers={"WWW-Authenticate": "Bearer"},
    )


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(
        bearer_scheme
    ),
) -> dict:
    if credentials is None:
        raise unauthorized()

    if credentials.scheme.lower() != "bearer":
        raise unauthorized()

    try:
        claims = decode_access_token(
            credentials.credentials
        )
    except TokenError:
        raise unauthorized() from None

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
                        role
                    FROM passenger_counting.users_tbl
                    WHERE user_id = %s
                    AND NOT EXISTS (
                        SELECT 1
                        FROM passenger_counting.revoked_tokens_tbl
                        WHERE token_id = %s
                    )
                    """,
                    (claims["user_id"], claims["token_id"]),
                )

                user = cursor.fetchone()

    except DatabaseError:
        raise HTTPException(
            status_code=503,
            detail="Authentication service unavailable.",
        ) from None

    if user is None:
        raise unauthorized()

    if user["role"] not in ALLOWED_ROLES:
        raise unauthorized()

    if user["role"] != claims["role"]:
        raise unauthorized()

    return {
        "user_id": user["user_id"],
        "full_name": user["full_name"],
        "email": user["email"],
        "role": user["role"],
    }


def require_admin(
    user: dict = Depends(get_current_user),
) -> dict:
    if user["role"] != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Administrator access is required.",
        )

    return user


def require_operator(
    user: dict = Depends(get_current_user),
) -> dict:
    if user["role"] != "operator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operator access is required.",
        )

    return user
