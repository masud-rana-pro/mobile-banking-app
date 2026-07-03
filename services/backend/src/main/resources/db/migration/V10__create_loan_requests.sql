CREATE TABLE loan_requests (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    amount NUMERIC(19, 2) NOT NULL,
    purpose VARCHAR(255) NOT NULL,
    status VARCHAR(32) NOT NULL,
    reviewed_by BIGINT,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_loan_requests_user_id
        FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_loan_requests_reviewed_by
        FOREIGN KEY (reviewed_by) REFERENCES users (id),
    CONSTRAINT chk_loan_requests_amount_positive
        CHECK (amount > 0),
    CONSTRAINT chk_loan_requests_status
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED'))
);

CREATE INDEX idx_loan_requests_user_created_at
    ON loan_requests (user_id, created_at DESC);

CREATE INDEX idx_loan_requests_status_created_at
    ON loan_requests (status, created_at DESC);
