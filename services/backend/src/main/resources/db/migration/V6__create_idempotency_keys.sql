CREATE TABLE idempotency_keys (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    idempotency_key VARCHAR(128) NOT NULL,
    request_hash VARCHAR(128) NOT NULL,
    operation_type VARCHAR(40) NOT NULL,
    status VARCHAR(32) NOT NULL,
    response_body TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_idempotency_keys_user_id
        FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT uk_idempotency_keys_user_key
        UNIQUE (user_id, idempotency_key),
    CONSTRAINT chk_idempotency_keys_operation_type
        CHECK (operation_type IN (
            'ADD_MONEY',
            'SEND_MONEY',
            'MERCHANT_PAYMENT',
            'MOBILE_RECHARGE',
            'SAVINGS_DEPOSIT',
            'LOAN_DISBURSEMENT'
        )),
    CONSTRAINT chk_idempotency_keys_status
        CHECK (status IN ('PROCESSING', 'COMPLETED', 'FAILED'))
);

CREATE INDEX idx_idempotency_keys_user_operation
    ON idempotency_keys (user_id, operation_type);

CREATE INDEX idx_idempotency_keys_expires_at
    ON idempotency_keys (expires_at);
