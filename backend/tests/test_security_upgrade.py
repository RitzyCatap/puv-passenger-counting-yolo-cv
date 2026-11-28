
import unittest
from unittest.mock import patch

from fastapi import HTTPException
from starlette.requests import Request

from app.core import rate_limit
from app.core.tokens import (
    create_access_token,
    decode_access_token,
)
from app.core.authorization import (
    require_admin,
)


class SecurityUpgradeTests(unittest.TestCase):

    def setUp(self):
        rate_limit._attempts.clear()

    def tearDown(self):
        rate_limit._attempts.clear()

    def request(self, host="127.0.0.1"):
        return Request({
            "type": "http",
            "method": "POST",
            "path": "/api/auth/login",
            "headers": [],
            "client": (host, 12345),
        })

    def test_unique_token_identifiers(self):
        first = decode_access_token(
            create_access_token(1, "admin")
        )

        second = decode_access_token(
            create_access_token(1, "admin")
        )

        self.assertNotEqual(
            first["token_id"],
            second["token_id"],
        )

    def test_operator_cannot_create_accounts(self):
        with self.assertRaises(HTTPException) as error:
            require_admin({"role": "operator"})

        self.assertEqual(
            error.exception.status_code,
            403,
        )

    def test_admin_permission(self):
        user = {"role": "admin"}

        self.assertEqual(
            require_admin(user),
            user,
        )

    def test_login_limit_blocks_excess_requests(self):
        with patch.object(
            rate_limit,
            "monotonic",
            return_value=100,
        ):
            for _ in range(rate_limit.MAX_ATTEMPTS):
                rate_limit.enforce_login_rate_limit(
                    self.request()
                )

            with self.assertRaises(HTTPException) as error:
                rate_limit.enforce_login_rate_limit(
                    self.request()
                )

            self.assertEqual(
                error.exception.status_code,
                429,
            )

    def test_rate_limit_expires(self):
        with patch.object(
            rate_limit,
            "monotonic",
            return_value=100,
        ):
            for _ in range(rate_limit.MAX_ATTEMPTS):
                rate_limit.enforce_login_rate_limit(
                    self.request()
                )

        with patch.object(
            rate_limit,
            "monotonic",
            return_value=161,
        ):
            rate_limit.enforce_login_rate_limit(
                self.request()
            )

    def test_separate_clients(self):
        for _ in range(rate_limit.MAX_ATTEMPTS):
            rate_limit.enforce_login_rate_limit(
                self.request()
            )

        rate_limit.enforce_login_rate_limit(
            self.request("127.0.0.2")
        )


if __name__ == "__main__":
    unittest.main()
