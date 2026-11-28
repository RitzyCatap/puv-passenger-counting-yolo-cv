
CREATE TABLE IF NOT EXISTS
passenger_counting.revoked_tokens_tbl (
    token_id TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL CHECK (user_id > 0),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_revoked_tokens_expiration
ON passenger_counting.revoked_tokens_tbl (expires_at);
