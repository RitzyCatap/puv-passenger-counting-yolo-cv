import os
from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import uuid4

import jwt
from dotenv import load_dotenv


ENV_PATH = Path(__file__).resolve().parents[2] / ".env"

load_dotenv(ENV_PATH)

JWT_ALGORITHM = "HS256"
JWT_ISSUER = "sakaysense-api"
JWT_AUDIENCE = "sakaysense-client"
ACCESS_TOKEN_MINUTES = 30

ALLOWED_ROLES = {"admin", "operator"}


class TokenError(Exception):
    pass


def _get_secret_key() -> str:
    secret = os.getenv("JWT_SECRET_KEY", "")

    if len(secret.encode("utf-8")) < 32:
        raise RuntimeError(
            "JWT_SECRET_KEY must be securely configured."
        )

    return secret


def create_access_token(
    user_id: int,
    role: str,
) -> str:
    if (
        type(user_id) is not int
        or user_id <= 0
        or user_id > 2147483647
    ):
        raise ValueError("Invalid user ID.")

    if role not in ALLOWED_ROLES:
        raise ValueError("Invalid user role.")

    now = datetime.now(timezone.utc)

    expires_at = now + timedelta(
        minutes=ACCESS_TOKEN_MINUTES
    )

    payload = {
        "sub": str(user_id),
        "role": role,
        "iat": now,
        "nbf": now,
        "exp": expires_at,
        "jti": str(uuid4()),
        "iss": JWT_ISSUER,
        "aud": JWT_AUDIENCE,
        "token_type": "access",
    }

    return jwt.encode(
        payload,
        _get_secret_key(),
        algorithm=JWT_ALGORITHM,
    )


def decode_access_token(token: str) -> dict:
    if not isinstance(token, str):
        raise TokenError("Invalid access token.")

    if not token or len(token) > 8192:
        raise TokenError("Invalid access token.")

    try:
        payload = jwt.decode(
            token,
            _get_secret_key(),
            algorithms=[JWT_ALGORITHM],
            issuer=JWT_ISSUER,
            audience=JWT_AUDIENCE,
            options={
                "require": [
                    "sub",
                    "role",
                    "iat",
                    "nbf",
                    "exp",
                    "jti",
                    "iss",
                    "aud",
                    "token_type",
                ]
            },
        )

        if payload["token_type"] != "access":
            raise TokenError("Invalid token type.")

        if payload["role"] not in ALLOWED_ROLES:
            raise TokenError("Invalid user role.")

        subject = payload["sub"]

        if not isinstance(subject, str):
            raise TokenError("Invalid user identity.")

        if not subject.isascii() or not subject.isdigit():
            raise TokenError("Invalid user identity.")

        user_id = int(subject)

        if user_id <= 0 or user_id > 2147483647:
            raise TokenError("Invalid user identity.")

        if (
            not isinstance(payload["jti"], str)
            or not payload["jti"]
        ):
            raise TokenError("Invalid token identifier.")

        return {
            "user_id": user_id,
            "role": payload["role"],
            "token_id": payload["jti"],
            "expires_at": payload["exp"],
        }

    except jwt.ExpiredSignatureError:
        raise TokenError("Access token has expired.") from None

    except (
        jwt.InvalidTokenError,
        ValueError,
        TypeError,
    ):
        raise TokenError("Invalid access token.") from None
