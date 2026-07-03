CREATE TABLE wallets (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    balance NUMERIC(19, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    status VARCHAR(32) NOT NULL,
    version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_wallets_user_id UNIQUE (user_id),
    CONSTRAINT fk_wallets_user_id FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT chk_wallets_balance_non_negative CHECK (balance >= 0),
    CONSTRAINT chk_wallets_status CHECK (status IN ('ACTIVE', 'BLOCKED'))
);
