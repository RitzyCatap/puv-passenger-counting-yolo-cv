import unittest
from unittest.mock import patch

from fastapi import HTTPException
from pydantic import ValidationError
from psycopg import OperationalError

from app.api.routes.auth import (
    LoginRequest,
    login,
)

from app.core.security import hash_password
from app.core.tokens import decode_access_token


class AuthenticationTests(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.password = "SakaySense-Test-2026!"

        cls.password_hash = hash_password(
            cls.password
        )

    def sample_user(self, role="admin"):
        return {
            "user_id": 1,
            "full_name": "Test User",
            "email": "test@example.com",
            "password_hash": self.password_hash,
            "role": role,
        }

    def run_login(
        self,
        users,
        email="test@example.com",
        password=None,
    ):
        if password is None:
            password = self.password

        with patch(
            "app.api.routes.auth.get_connection"
        ) as mock_connection:

            cursor = (
                mock_connection.return_value
                .__enter__.return_value
                .cursor.return_value
                .__enter__.return_value
            )

            cursor.fetchall.return_value = users

            return login(
                LoginRequest(
                    email=email,
                    password=password,
                )
            )

    def assert_invalid_login(self, callback):
        with self.assertRaises(
            HTTPException
        ) as error:
            callback()

        self.assertEqual(
            error.exception.status_code,
            401,
        )

        self.assertEqual(
            error.exception.detail,
            "Invalid email or password.",
        )

    def test_01_admin_login(self):
        response = self.run_login(
            [self.sample_user("admin")]
        )

        self.assertEqual(
            response.user.role,
            "admin",
        )

        self.assertEqual(
            response.user.user_id,
            1,
        )

    def test_02_operator_login(self):
        response = self.run_login(
            [self.sample_user("operator")]
        )

        self.assertEqual(
            response.user.role,
            "operator",
        )

    def test_03_token_is_valid(self):
        response = self.run_login(
            [self.sample_user()]
        )

        claims = decode_access_token(
            response.access_token
        )

        self.assertEqual(
            claims["user_id"],
            1,
        )

        self.assertEqual(
            claims["role"],
            "admin",
        )

    def test_04_wrong_password_rejected(self):
        self.assert_invalid_login(
            lambda: self.run_login(
                [self.sample_user()],
                password="WrongPassword123!",
            )
        )

    def test_05_unknown_account_rejected(self):
        self.assert_invalid_login(
            lambda: self.run_login([])
        )

    def test_06_invalid_role_rejected(self):
        self.assert_invalid_login(
            lambda: self.run_login(
                [self.sample_user("superadmin")]
            )
        )

    def test_07_duplicate_email_rejected(self):
        self.assert_invalid_login(
            lambda: self.run_login(
                [
                    self.sample_user(),
                    self.sample_user(),
                ]
            )
        )

    def test_08_password_hash_not_exposed(self):
        response = self.run_login(
            [self.sample_user()]
        )

        data = response.model_dump()

        self.assertNotIn(
            "password_hash",
            data,
        )

        self.assertNotIn(
            "password_hash",
            data["user"],
        )

        self.assertNotIn(
            "password",
            data["user"],
        )

    def test_09_token_expiration(self):
        response = self.run_login(
            [self.sample_user()]
        )

        self.assertEqual(
            response.expires_in,
            1800,
        )

        self.assertEqual(
            response.token_type,
            "bearer",
        )

    def test_10_empty_email_rejected(self):
        with self.assertRaises(
            ValidationError
        ):
            LoginRequest(
                email="",
                password=self.password,
            )

    def test_11_empty_password_rejected(self):
        with self.assertRaises(
            ValidationError
        ):
            LoginRequest(
                email="test@example.com",
                password="",
            )

    def test_12_long_password_rejected(self):
        with self.assertRaises(
            ValidationError
        ):
            LoginRequest(
                email="test@example.com",
                password="A" * 129,
            )

    def test_13_email_normalized(self):
        with patch(
            "app.api.routes.auth.get_connection"
        ) as mock_connection:

            cursor = (
                mock_connection.return_value
                .__enter__.return_value
                .cursor.return_value
                .__enter__.return_value
            )

            cursor.fetchall.return_value = [
                self.sample_user()
            ]

            login(
                LoginRequest(
                    email=" TEST@EXAMPLE.COM ",
                    password=self.password,
                )
            )

            self.assertEqual(
                cursor.execute.call_args.args[1],
                ("test@example.com",),
            )

    def test_14_database_failure_handled(self):
        with patch(
            "app.api.routes.auth.get_connection",
            side_effect=OperationalError(
                "Test connection failure"
            ),
        ):
            with self.assertRaises(
                HTTPException
            ) as error:
                login(
                    LoginRequest(
                        email="test@example.com",
                        password=self.password,
                    )
                )

            self.assertEqual(
                error.exception.status_code,
                503,
            )

    def test_15_invalid_stored_hash(self):
        user = self.sample_user()
        user["password_hash"] = "invalid-hash"

        self.assert_invalid_login(
            lambda: self.run_login([user])
        )

    def test_16_login_route_registered(self):
        from main import app

        self.assertIn(
            "/api/auth/login",
            app.openapi()["paths"],
        )

        self.assertIn(
            "post",
            app.openapi()["paths"][
                "/api/auth/login"
            ],
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
