CREATE TABLE transactions (
    id BIGSERIAL PRIMARY KEY,
    transaction_reference VARCHAR(64) NOT NULL,
    user_id BIGINT NOT NULL,
    type VARCHAR(40) NOT NULL,
    status VARCHAR(32) NOT NULL,
    amount NUMERIC(19, 2) NOT NULL,
    counterparty_user_id BIGINT,
    description VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_transactions_reference UNIQUE (transaction_reference),
    CONSTRAINT fk_transactions_user_id FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_transactions_counterparty_user_id FOREIGN KEY (counterparty_user_id) REFERENCES users (id),
    CONSTRAINT chk_transactions_amount_non_negative CHECK (amount >= 0),
    CONSTRAINT chk_transactions_type CHECK (type IN (
        'ADD_MONEY',
        'SEND_MONEY',
        'RECEIVE_MONEY',
        'MERCHANT_PAYMENT',
        'SAVINGS_DEPOSIT',
        'MOBILE_RECHARGE',
        'LOAN_REQUEST'
    )),
    CONSTRAINT chk_transactions_status CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'REJECTED', 'CANCELLED'))
);

CREATE TABLE ledger_entries (
    id BIGSERIAL PRIMARY KEY,
    wallet_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    transaction_reference VARCHAR(64) NOT NULL,
    linked_entry_id BIGINT,
    entry_type VARCHAR(32) NOT NULL,
    amount NUMERIC(19, 2) NOT NULL,
    balance_after NUMERIC(19, 2) NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ledger_entries_wallet_id FOREIGN KEY (wallet_id) REFERENCES wallets (id),
    CONSTRAINT fk_ledger_entries_user_id FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_ledger_entries_transaction_reference FOREIGN KEY (transaction_reference) REFERENCES transactions (transaction_reference),
    CONSTRAINT fk_ledger_entries_linked_entry_id FOREIGN KEY (linked_entry_id) REFERENCES ledger_entries (id),
    CONSTRAINT chk_ledger_entries_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_ledger_entries_balance_after_non_negative CHECK (balance_after >= 0),
    CONSTRAINT chk_ledger_entries_type CHECK (entry_type IN ('DEBIT', 'CREDIT', 'REVERSAL'))
);

CREATE INDEX idx_transactions_user_created_at ON transactions (user_id, created_at DESC);
CREATE INDEX idx_transactions_type_status ON transactions (type, status);
CREATE INDEX idx_ledger_entries_wallet_created_at ON ledger_entries (wallet_id, created_at DESC);
CREATE INDEX idx_ledger_entries_transaction_reference ON ledger_entries (transaction_reference);
