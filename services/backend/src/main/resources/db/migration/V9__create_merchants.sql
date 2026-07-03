CREATE TABLE merchants (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    business_name VARCHAR(120) NOT NULL,
    merchant_number VARCHAR(32) NOT NULL,
    business_type VARCHAR(80) NOT NULL,
    status VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_merchants_user_id
        FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT uk_merchants_user_id UNIQUE (user_id),
    CONSTRAINT uk_merchants_merchant_number UNIQUE (merchant_number),
    CONSTRAINT chk_merchants_status
        CHECK (status IN ('ACTIVE', 'INACTIVE', 'BLOCKED'))
);

CREATE INDEX idx_merchants_status
    ON merchants (status);
