CREATE TABLE admin_audit_logs (
    id BIGSERIAL PRIMARY KEY,
    admin_user_id BIGINT NOT NULL,
    action VARCHAR(64) NOT NULL,
    target_type VARCHAR(64) NOT NULL,
    target_id VARCHAR(128),
    details TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_admin_audit_logs_admin_user_id
        FOREIGN KEY (admin_user_id) REFERENCES users (id),
    CONSTRAINT chk_admin_audit_logs_action
        CHECK (action IN (
            'ADD_MONEY_APPROVE',
            'ADD_MONEY_REJECT',
            'LOAN_APPROVE',
            'LOAN_REJECT',
            'USER_STATUS_CHANGE',
            'MERCHANT_STATUS_CHANGE'
        )),
    CONSTRAINT chk_admin_audit_logs_target_type
        CHECK (target_type IN (
            'ADD_MONEY_REQUEST',
            'LOAN_REQUEST',
            'USER',
            'MERCHANT'
        ))
);

CREATE INDEX idx_admin_audit_logs_admin_user_created_at
    ON admin_audit_logs (admin_user_id, created_at DESC);

CREATE INDEX idx_admin_audit_logs_target
    ON admin_audit_logs (target_type, target_id);
