from argon2 import PasswordHasher
from argon2.exceptions import (
    VerifyMismatchError,
    VerificationError,
    InvalidHashError,
)
from argon2.low_level import Type


_password_hasher = PasswordHasher(
    time_cost=3,
    memory_cost=65536,
    parallelism=4,
    hash_len=32,
    salt_len=16,
    type=Type.ID,
)

MIN_PASSWORD_LENGTH = 8
MAX_PASSWORD_LENGTH = 128


def validate_password(password: str) -> None:
    if not isinstance(password, str):
        raise ValueError("Password must be a string.")

    if len(password) < MIN_PASSWORD_LENGTH:
        raise ValueError(
            "Password must contain at least 8 characters."
        )

    if len(password) > MAX_PASSWORD_LENGTH:
        raise ValueError(
            "Password must not exceed 128 characters."
        )

    if not password.strip():
        raise ValueError(
            "Password cannot contain only whitespace."
        )


def hash_password(password: str) -> str:
    validate_password(password)
    return _password_hasher.hash(password)


def verify_password(
    password: str,
    password_hash: str,
) -> bool:
    if not isinstance(password, str):
        return False

    if not isinstance(password_hash, str):
        return False

    if not password or not password_hash:
        return False

    if len(password) > MAX_PASSWORD_LENGTH:
        return False

    try:
        return _password_hasher.verify(
            password_hash,
            password,
        )
    except (
        VerifyMismatchError,
        VerificationError,
        InvalidHashError,
    ):
        return False


def password_needs_rehash(password_hash: str) -> bool:
    try:
        return _password_hasher.check_needs_rehash(
            password_hash
        )
    except (InvalidHashError, TypeError, ValueError):
        return True
