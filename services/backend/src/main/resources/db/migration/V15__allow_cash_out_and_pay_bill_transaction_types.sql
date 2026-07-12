ALTER TABLE transactions
    DROP CONSTRAINT IF EXISTS chk_transactions_type;

ALTER TABLE transactions
    ADD CONSTRAINT chk_transactions_type
        CHECK (type IN (
            'ADD_MONEY',
            'SEND_MONEY',
            'RECEIVE_MONEY',
            'MERCHANT_PAYMENT',
            'CASH_OUT',
            'PAY_BILL',
            'SAVINGS_DEPOSIT',
            'MOBILE_RECHARGE',
            'LOAN_REQUEST'
        ));

ALTER TABLE idempotency_keys
    DROP CONSTRAINT IF EXISTS chk_idempotency_keys_operation_type;

ALTER TABLE idempotency_keys
    ADD CONSTRAINT chk_idempotency_keys_operation_type
        CHECK (operation_type IN (
            'ADD_MONEY',
            'SEND_MONEY',
            'MERCHANT_PAYMENT',
            'CASH_OUT',
            'PAY_BILL',
            'MOBILE_RECHARGE',
            'SAVINGS_DEPOSIT',
            'LOAN_DISBURSEMENT'
        ));
