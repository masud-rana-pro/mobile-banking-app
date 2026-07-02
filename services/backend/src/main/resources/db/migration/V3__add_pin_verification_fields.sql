ALTER TABLE users
    ADD COLUMN pin_failed_attempts INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN pin_blocked_until TIMESTAMPTZ;
