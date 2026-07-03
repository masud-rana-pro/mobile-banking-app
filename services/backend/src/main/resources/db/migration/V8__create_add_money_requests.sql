CREATE TABLE add_money_requests (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    amount NUMERIC(19, 2) NOT NULL,
    source_type VARCHAR(40) NOT NULL,
    status VARCHAR(32) NOT NULL,
    approved_by BIGINT,
    approved_at TIMESTAMPTZ,
    note VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_add_money_requests_user_id
        FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_add_money_requests_approved_by
        FOREIGN KEY (approved_by) REFERENCES users (id),
    CONSTRAINT chk_add_money_requests_amount_positive
        CHECK (amount > 0),
    CONSTRAINT chk_add_money_requests_source_type
        CHECK (source_type IN ('DEMO_BANK', 'DEMO_CARD', 'MANUAL')),
    CONSTRAINT chk_add_money_requests_status
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED'))
);

CREATE INDEX idx_add_money_requests_user_created_at
    ON add_money_requests (user_id, created_at DESC);

CREATE INDEX idx_add_money_requests_status_created_at
    ON add_money_requests (status, created_at DESC);
