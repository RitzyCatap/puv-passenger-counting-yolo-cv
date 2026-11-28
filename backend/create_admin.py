import getpass
import re
import warnings

from psycopg import Error as DatabaseError

from db import get_connection
from app.core.security import (
    hash_password,
    validate_password,
)


def main():
    print("\n===== SAKAYSENSE ADMIN ACCOUNT SETUP =====")

    try:
        with get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT current_database()")
                database = cursor.fetchone()[0]

                if database != "puv_passenger_counting_dev":
                    print("Unexpected database. Setup cancelled.")
                    return 1

                print("Development database verified.")

                cursor.execute("""
                    SELECT COUNT(*)
                    FROM passenger_counting.users_tbl
                    WHERE role = 'admin'
                """)

                if cursor.fetchone()[0] > 0:
                    print("An administrator already exists.")
                    print("No account was created.")
                    return 1

    except DatabaseError:
        print("Database connection failed.")
        return 1

    full_name = input("Admin full name: ").strip()

    if not full_name or len(full_name) > 100:
        print("Invalid full name.")
        return 1

    email = input("Admin email: ").strip().lower()

    if (
        len(email) > 150
        or not re.fullmatch(
            r"[^@\s]+@[^@\s]+\.[^@\s]+",
            email,
        )
    ):
        print("Invalid email address.")
        return 1

    try:
        with warnings.catch_warnings():
            warnings.simplefilter(
                "error",
                getpass.GetPassWarning,
            )

            password = getpass.getpass("Admin password: ")

            confirmation = getpass.getpass(
                "Confirm admin password: "
            )

    except getpass.GetPassWarning:
        print("Secure password input unavailable.")
        return 1

    if password != confirmation:
        print("Passwords do not match.")
        return 1

    try:
        validate_password(password)
        password_hash = hash_password(password)

    except ValueError as error:
        print(str(error))
        return 1

    del password
    del confirmation

    try:
        with get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT current_database()")

                if cursor.fetchone()[0] != (
                    "puv_passenger_counting_dev"
                ):
                    print("Unexpected database. Setup cancelled.")
                    return 1

                cursor.execute("""
                    LOCK TABLE passenger_counting.users_tbl
                    IN SHARE ROW EXCLUSIVE MODE
                """)

                cursor.execute("""
                    SELECT COUNT(*)
                    FROM passenger_counting.users_tbl
                    WHERE role = 'admin'
                """)

                if cursor.fetchone()[0] > 0:
                    print("An administrator already exists.")
                    return 1

                cursor.execute("""
                    SELECT user_id
                    FROM passenger_counting.users_tbl
                    WHERE LOWER(email) = %s
                """, (email,))

                if cursor.fetchone() is not None:
                    print("Email already registered.")
                    return 1

                cursor.execute("""
                    INSERT INTO passenger_counting.users_tbl (
                        full_name,
                        email,
                        password_hash,
                        role
                    )
                    VALUES (%s, %s, %s, %s)
                    RETURNING user_id
                """, (
                    full_name,
                    email,
                    password_hash,
                    "admin",
                ))

                user_id = cursor.fetchone()[0]

                cursor.execute("""
                    SELECT
                        role,
                        LEFT(password_hash, 10) = '$argon2id$'
                    FROM passenger_counting.users_tbl
                    WHERE user_id = %s
                """, (user_id,))

                role, secure_hash = cursor.fetchone()

                if role != "admin" or not secure_hash:
                    raise RuntimeError(
                        "Account verification failed."
                    )

            conn.commit()

    except (DatabaseError, RuntimeError) as error:
        print("Account creation failed.")
        print("Error type:", type(error).__name__)
        print("SQLSTATE:", getattr(error, "sqlstate", None))
        print("No successful account creation confirmed.")
        return 1

    print("\n===== ADMIN ACCOUNT CREATED =====")
    print("User ID:", user_id)
    print("Full name:", full_name)
    print("Email:", email)
    print("Role: admin")
    print("Password storage: Argon2id")
    print("Database: puv_passenger_counting_dev")
    print("ADMIN ACCOUNT SETUP PASSED")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
