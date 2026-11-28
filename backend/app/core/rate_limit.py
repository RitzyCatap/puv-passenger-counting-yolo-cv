
from collections import deque
from threading import Lock
from time import monotonic

from fastapi import HTTPException, Request


MAX_ATTEMPTS = 10
WINDOW_SECONDS = 60
MAX_CLIENTS = 10000

_attempts = {}
_lock = Lock()


def enforce_login_rate_limit(request: Request):
    client = (
        request.client.host
        if request.client
        else "unknown"
    )

    now = monotonic()

    with _lock:
        for key in list(_attempts):
            entries = _attempts[key]

            while entries and (
                now - entries[0] >= WINDOW_SECONDS
            ):
                entries.popleft()

            if not entries:
                del _attempts[key]

        if client not in _attempts:
            if len(_attempts) >= MAX_CLIENTS:
                raise HTTPException(
                    status_code=429,
                    detail="Please try again later.",
                    headers={"Retry-After": "60"},
                )

            _attempts[client] = deque()

        entries = _attempts[client]

        if len(entries) >= MAX_ATTEMPTS:
            raise HTTPException(
                status_code=429,
                detail="Too many login requests.",
                headers={"Retry-After": "60"},
            )

        entries.append(now)
