import unittest
from unittest.mock import patch

from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from psycopg import OperationalError

from app.core.authorization import (
    get_current_user,
    require_admin,
    require_operator,
)
from app.core.tokens import create_access_token


class AuthorizationTests(unittest.TestCase):

    def sample_user(self, role="admin"):
        return {
            "user_id": 1,
            "full_name": "Test User",
            "email": "test@example.com",
            "role": role,
        }

    def credentials(self, role="admin"):
        return HTTPAuthorizationCredentials(
            scheme="Bearer",
            credentials=create_access_token(1, role),
        )

    def resolve_user(self, user, role="admin"):
        with patch(
            "app.core.authorization.get_connection"
        ) as mock_connection:

            cursor = (
                mock_connection.return_value
                .__enter__.return_value
                .cursor.return_value
                .__enter__.return_value
            )

            cursor.fetchone.return_value = user

            return get_current_user(
                self.credentials(role)
            )

    def assert_http_error(self, expected, callback):
        with self.assertRaises(HTTPException) as error:
            callback()

        self.assertEqual(
            error.exception.status_code,
            expected,
        )

    def test_01_missing_credentials(self):
        self.assert_http_error(
            401,
            lambda: get_current_user(None),
        )

    def test_02_invalid_token(self):
        credentials = HTTPAuthorizationCredentials(
            scheme="Bearer",
            credentials="invalid-token",
        )

        self.assert_http_error(
            401,
            lambda: get_current_user(credentials),
        )

    def test_03_invalid_authentication_scheme(self):
        credentials = HTTPAuthorizationCredentials(
            scheme="Basic",
            credentials="invalid",
        )

        self.assert_http_error(
            401,
            lambda: get_current_user(credentials),
        )

    def test_04_valid_admin(self):
        user = self.resolve_user(
            self.sample_user("admin")
        )

        self.assertEqual(user["role"], "admin")

    def test_05_valid_operator(self):
        user = self.resolve_user(
            self.sample_user("operator"),
            role="operator",
        )

        self.assertEqual(user["role"], "operator")

    def test_06_deleted_account(self):
        self.assert_http_error(
            401,
            lambda: self.resolve_user(None),
        )

    def test_07_changed_database_role(self):
        self.assert_http_error(
            401,
            lambda: self.resolve_user(
                self.sample_user("operator"),
                role="admin",
            ),
        )

    def test_08_invalid_database_role(self):
        self.assert_http_error(
            401,
            lambda: self.resolve_user(
                self.sample_user("unknown")
            ),
        )

    def test_09_admin_permission_granted(self):
        user = self.sample_user("admin")

        self.assertEqual(
            require_admin(user),
            user,
        )

    def test_10_operator_admin_access_denied(self):
        self.assert_http_error(
            403,
            lambda: require_admin(
                self.sample_user("operator")
            ),
        )

    def test_11_operator_permission_granted(self):
        user = self.sample_user("operator")

        self.assertEqual(
            require_operator(user),
            user,
        )

    def test_12_admin_operator_only_access_denied(self):
        self.assert_http_error(
            403,
            lambda: require_operator(
                self.sample_user("admin")
            ),
        )

    def test_13_database_failure(self):
        with patch(
            "app.core.authorization.get_connection",
            side_effect=OperationalError(
                "Test connection failure"
            ),
        ):
            self.assert_http_error(
                503,
                lambda: get_current_user(
                    self.credentials()
                ),
            )

    def test_14_sensitive_fields_not_exposed(self):
        source = self.sample_user()
        source["password_hash"] = "private-hash"

        user = self.resolve_user(source)

        self.assertNotIn(
            "password_hash",
            user,
        )

    def test_15_current_user_route_registered(self):
        from main import app

        self.assertIn(
            "/api/auth/me",
            app.openapi()["paths"],
        )

    def test_16_puv_routes_require_bearer_auth(self):
        from main import app

        paths = app.openapi()["paths"]

        routes = [
            ("/puvs/", "get"),
            ("/puvs/", "post"),
            ("/puvs/{puv_id}", "get"),
            ("/puvs/{puv_id}", "put"),
            ("/puvs/{puv_id}", "delete"),
        ]

        for path, method in routes:
            with self.subTest(
                path=path,
                method=method,
            ):
                self.assertTrue(
                    paths[path][method].get("security")
                )

    def test_17_admin_dependency_on_write_routes(self):
        from fastapi.testclient import TestClient
        from main import app

        routes = [
            ("POST", "/puvs/", {
                "puv_type": "Jeepney",
                "capacity": 20,
            }),
            ("PUT", "/puvs/1", {
                "puv_type": "Modern Jeepney",
                "capacity": 30,
            }),
            ("DELETE", "/puvs/1", None),
        ]

        credentials = create_access_token(
            1,
            "operator",
        )

        headers = {
            "Authorization": f"Bearer {credentials}"
        }

        with patch(
            "app.core.authorization.get_connection"
        ) as mock_auth_connection, patch(
            "app.api.routes.puvs.get_connection"
        ) as mock_puv_connection:

            cursor = (
                mock_auth_connection.return_value
                .__enter__.return_value
                .cursor.return_value
                .__enter__.return_value
            )

            cursor.fetchone.return_value = (
                self.sample_user("operator")
            )

            with TestClient(app) as client:
                for method, path, body in routes:
                    with self.subTest(
                        method=method,
                        path=path,
                    ):
                        kwargs = {"headers": headers}

                        if body is not None:
                            kwargs["json"] = body

                        response = client.request(
                            method,
                            path,
                            **kwargs,
                        )

                        self.assertEqual(
                            response.status_code,
                            403,
                            response.text,
                        )

            mock_puv_connection.assert_not_called()

    def test_18_shared_access_on_read_routes(self):
        from fastapi.testclient import TestClient
        from main import app

        paths = [
            "/puvs/",
            "/puvs/1",
            "/api/auth/me",
        ]

        with patch(
            "app.core.authorization.get_connection"
        ) as mock_auth_connection, patch(
            "app.api.routes.puvs.get_connection"
        ) as mock_puv_connection:

            auth_cursor = (
                mock_auth_connection.return_value
                .__enter__.return_value
                .cursor.return_value
                .__enter__.return_value
            )

            puv_cursor = (
                mock_puv_connection.return_value
                .__enter__.return_value
                .cursor.return_value
                .__enter__.return_value
            )

            record = {
                "puv_id": 1,
                "puv_type": "Jeepney",
                "capacity": 20,
                "created_at": None,
            }

            puv_cursor.fetchall.return_value = [
                record
            ]

            puv_cursor.fetchone.return_value = record

            with TestClient(app) as client:
                for path in paths:
                    with self.subTest(
                        path=path,
                        role="unauthenticated",
                    ):
                        response = client.get(path)

                        self.assertEqual(
                            response.status_code,
                            401,
                            response.text,
                        )

                mock_auth_connection.assert_not_called()
                mock_puv_connection.assert_not_called()

                for role in ["admin", "operator"]:
                    auth_cursor.fetchone.return_value = (
                        self.sample_user(role)
                    )

                    token = create_access_token(1, role)

                    headers = {
                        "Authorization": f"Bearer {token}"
                    }

                    for path in paths:
                        with self.subTest(
                            path=path,
                            role=role,
                        ):
                            response = client.get(
                                path,
                                headers=headers,
                            )

                            self.assertEqual(
                                response.status_code,
                                200,
                                response.text,
                            )

                            data = response.json()

                            if path == "/api/auth/me":
                                self.assertEqual(
                                    data["role"],
                                    role,
                                )

                                self.assertNotIn(
                                    "password_hash",
                                    data,
                                )
                            elif path == "/puvs/":
                                self.assertEqual(
                                    data,
                                    [record],
                                )
                            else:
                                self.assertEqual(
                                    data,
                                    record,
                                )


if __name__ == "__main__":
    unittest.main(verbosity=2)
