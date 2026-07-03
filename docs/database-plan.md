# SmartKash Database Plan

## Client Platform Scope

PostgreSQL remains the single source of truth for SmartKash business data regardless of Flutter platform. Android, iOS, Web, Windows, Linux, and macOS clients must all access business data through the Spring Boot API, never directly through the database.

## Database

Use PostgreSQL for the main business database.

Use Flyway for versioned database migrations when implementation starts. Do not create ad hoc schema changes outside migrations.

## Important Enums

- `UserRole`: `CUSTOMER`, `MERCHANT`, `ADMIN`
- `UserStatus`: `ACTIVE`, `BLOCKED`, `PENDING`
- `WalletStatus`: `ACTIVE`, `BLOCKED`
- `TransactionType`: `ADD_MONEY`, `SEND_MONEY`, `RECEIVE_MONEY`, `MERCHANT_PAYMENT`, `SAVINGS_DEPOSIT`, `MOBILE_RECHARGE`, `LOAN_REQUEST`
- `TransactionStatus`: `PENDING`, `SUCCESS`, `FAILED`, `REJECTED`, `CANCELLED`
- `LedgerEntryType`: `DEBIT`, `CREDIT`, `REVERSAL`
- `AddMoneyStatus`: `PENDING`, `APPROVED`, `REJECTED`
- `LoanStatus`: `PENDING`, `APPROVED`, `REJECTED`
- `RechargeStatus`: `SUCCESS`, `FAILED`
- `MerchantStatus`: `ACTIVE`, `INACTIVE`, `BLOCKED`
- `NotificationType`: `ADD_MONEY`, `SEND_MONEY`, `PAYMENT`, `RECHARGE`, `SAVINGS`, `LOAN`

## Persistence Rules

- Entities are database models only and must not be exposed directly in API responses.
- DTOs must be used for request and response payloads.
- Mappers convert between entity and DTO objects.
- Use optimistic locking or another safe locking strategy for wallet balance updates.
- Use database transactions for all money-changing operations.
- Use immutable ledger entries for all balance changes.
- Use reversal ledger entries for corrections.
- Use audit logs for admin actions and critical money operations.

## Core Tables

### users

- `id`
- `mobile_number`
- `firebase_uid`
- `role`: `CUSTOMER`, `MERCHANT`, `ADMIN`
- `status`
- `pin_hash`
- `pin_set`
- `pin_updated_at`
- `pin_failed_attempts`
- `pin_blocked_until`
- `created_at`
- `updated_at`

Use a simple role field for MVP Phase 1. Do not create a complex role/permission system unless absolutely needed later.

Step 07 creates only the minimal identity foundation: Firebase UID, mobile number, role, status, and timestamps. Step 10 adds PIN setup fields. Step 11 adds PIN verification attempt tracking fields. `pin_hash` stores only a BCrypt hash; raw PIN must never be stored.

### user_profiles

- `id`
- `user_id`
- `full_name`
- `email`
- `avatar_url`
- `created_at`
- `updated_at`

Profile fields stay minimal in the first foundation step. KYC/NID/provider-backed identity fields are not part of the zero-budget MVP foundation.

### wallets

- `id`
- `user_id`
- `balance`
- `currency`
- `status`
- `version`
- `created_at`
- `updated_at`

Wallet balance is stored for fast reads. Step 12 creates the wallet table and read model foundation only. Step 15 creates a zero-balance wallet lifecycle record when a Firebase-linked user logs in and has no wallet yet. `version` supports optimistic locking in future money-changing wallet updates. Wallet balance changes must not be implemented without immutable ledger entries and user-facing transaction records.

### ledger_entries

- `id`
- `wallet_id`
- `user_id`
- `transaction_reference`
- `linked_entry_id`
- `entry_type`: `DEBIT`, `CREDIT`, `REVERSAL`
- `amount`
- `balance_after`
- `description`
- `created_at`

Ledger entries are immutable. They must never be updated or deleted. Corrections must use reversal ledger entries.

Wallet-to-wallet transfers must create linked debit and credit ledger entries under the same transaction reference.

Step 13 creates only the ledger and transaction database foundation. No application service creates ledger entries or transaction records yet. Future money-changing services must create user-facing transaction records and immutable ledger entries together inside one database transaction.

### transactions

- `id`
- `transaction_reference`
- `user_id`
- `type`
- `status`
- `amount`
- `counterparty_user_id`
- `description`
- `created_at`

Transactions are user-facing records for statements and receipts.

Step 13 transaction records are schema/entity/repository foundation only. Transaction history APIs and money-changing transaction creation are future scope.

### add_money_requests

- `id`
- `user_id`
- `amount`
- `source_type`
- `status`: `PENDING`, `APPROVED`, `REJECTED`
- `approved_by`
- `approved_at`
- `note`
- `created_at`
- `updated_at`

Step 17 creates the Add Money request foundation only. Customer requests start as `PENDING`. Step 24 adds admin approval/rejection. Approval credits the customer wallet, creates a user-facing transaction record, creates an immutable credit ledger entry, stores idempotency completion, and records admin audit logs. Rejection updates request status and audit/idempotency only; it does not change wallet balance.

### merchants

- `id`
- `user_id`
- `business_name`
- `merchant_number`
- `business_type`
- `status`
- `created_at`
- `updated_at`

A merchant is also a user account with `role = MERCHANT`. Each merchant has a wallet like a normal user. The `merchants` table stores only business-specific information.

Step 18 creates merchant profile foundation only. Creating a merchant profile changes the current user role to `MERCHANT` and stores business-specific data. It does not implement merchant payment, wallet debit/credit, ledger entries, transaction records, or admin merchant management.

Relationship:

```text
users.role = MERCHANT
wallets.user_id -> users.id
merchants.user_id -> users.id
```

### savings_goals

- `id`
- `user_id`
- `name`
- `target_amount`
- `current_amount`
- `target_date`
- `status`
- `created_at`
- `updated_at`

Step 21 creates the savings goal foundation only. New goals start with `current_amount = 0.00` and `status = ACTIVE`. It does not create savings deposits, debit wallets, create ledger entries, create transaction records, use idempotency keys, or send FCM alerts yet.

### savings_deposits

- `id`
- `savings_goal_id`
- `user_id`
- `amount`
- `transaction_reference`
- `created_at`

Savings deposits are future scope because they are money-changing operations. A later deposit step must require authenticated user, PIN confirmation, idempotency key, active wallet, sufficient balance, wallet locking, transaction record, and immutable ledger entries.

### loan_requests

- `id`
- `user_id`
- `amount`
- `purpose`
- `status`: `PENDING`, `APPROVED`, `REJECTED`
- `reviewed_by`
- `reviewed_at`
- `created_at`
- `updated_at`

MVP Phase 1 loan approval/rejection only updates request status. Step 19 creates customer loan request create/list foundation only. Loan disbursement, wallet credit, repayment, installment tracking, transaction records, ledger entries, idempotency, and notifications are future scope.

### mobile_recharges

- `id`
- `user_id`
- `operator`
- `mobile_number`
- `amount`
- `status`
- `transaction_reference`
- `created_at`

Use `mobile_recharges`, not `recharge_requests`, because MVP recharge is demo success, not admin approval.

Step 20 creates the mobile recharge demo record foundation only. It stores an authenticated user's requested operator, mobile number, amount, and `SUCCESS`/`FAILED` status. It does not debit the wallet, call a real recharge provider, create ledger entries, create transaction records, use idempotency keys, or send FCM alerts yet. `transaction_reference` is nullable until a later money-changing recharge step connects recharge records to transaction and ledger records.

### firebase_devices

- `id`
- `user_id`
- `fcm_token`
- `device_type`
- `active`
- `created_at`
- `updated_at`

### idempotency_keys

- `id`
- `user_id`
- `idempotency_key`
- `request_hash`
- `operation_type`
- `status`: `PROCESSING`, `COMPLETED`, `FAILED`
- `response_body`
- `created_at`
- `updated_at`
- `expires_at`

This table prevents duplicate money-changing requests.

Step 14 creates the idempotency key database foundation only. Future money-changing services must reserve an idempotency key before processing, compare the request hash on retry, and return the saved result instead of creating duplicate wallet, ledger, or transaction records.

### admin_audit_logs

- `id`
- `admin_user_id`
- `action`
- `target_type`
- `target_id`
- `details`
- `created_at`

Step 16 creates the admin audit log database foundation only. Future admin approval/rejection services must write audit records when they change Add Money, Loan, User, or Merchant state.
