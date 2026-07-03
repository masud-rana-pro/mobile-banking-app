CREATE TABLE savings_goals (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    target_amount NUMERIC(19, 2) NOT NULL,
    current_amount NUMERIC(19, 2) NOT NULL DEFAULT 0.00,
    target_date DATE,
    status VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_savings_goals_user_id
        FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT chk_savings_goals_target_amount_positive
        CHECK (target_amount > 0),
    CONSTRAINT chk_savings_goals_current_amount_non_negative
        CHECK (current_amount >= 0),
    CONSTRAINT chk_savings_goals_status
        CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED'))
);

CREATE INDEX idx_savings_goals_user_created_at
    ON savings_goals (user_id, created_at DESC);

CREATE INDEX idx_savings_goals_user_status
    ON savings_goals (user_id, status);
