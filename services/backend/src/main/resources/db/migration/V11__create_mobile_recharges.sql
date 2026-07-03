CREATE TABLE mobile_recharges (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    operator VARCHAR(40) NOT NULL,
    mobile_number VARCHAR(20) NOT NULL,
    amount NUMERIC(19, 2) NOT NULL,
    status VARCHAR(32) NOT NULL,
    transaction_reference VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_mobile_recharges_user_id
        FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT chk_mobile_recharges_amount_positive
        CHECK (amount > 0),
    CONSTRAINT chk_mobile_recharges_status
        CHECK (status IN ('SUCCESS', 'FAILED')),
    CONSTRAINT chk_mobile_recharges_operator
        CHECK (operator IN ('GP', 'ROBI', 'BANGLALINK', 'TELETALK', 'AIRTEL'))
);

CREATE INDEX idx_mobile_recharges_user_created_at
    ON mobile_recharges (user_id, created_at DESC);

CREATE INDEX idx_mobile_recharges_status_created_at
    ON mobile_recharges (status, created_at DESC);
