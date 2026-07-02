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
- `created_at`
- `updated_at`

Use a simple role field for MVP Phase 1. Do not create a complex role/permission system unless absolutely needed later.

Step 07 creates only the minimal identity foundation: Firebase UID, mobile number, role, status, and timestamps. PIN storage is intentionally left for a later dedicated PIN security step.

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
- `created_at`
- `updated_at`

Wallet balance is stored for fast reads.

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

### add_money_requests

- `id`
- `user_id`
- `amount`
- `source_type`
- `status`: `PENDING`, `APPROVED`, `REJECTED`
- `approved_by`
- `approved_at`
- `created_at`

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

### savings_deposits

- `id`
- `savings_goal_id`
- `user_id`
- `amount`
- `transaction_reference`
- `created_at`

### loan_requests

- `id`
- `user_id`
- `amount`
- `purpose`
- `status`: `PENDING`, `APPROVED`, `REJECTED`
- `reviewed_by`
- `reviewed_at`
- `created_at`

MVP Phase 1 loan approval/rejection only updates request status.

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
- `key`
- `request_type`
- `response_reference`
- `created_at`

This table prevents duplicate money-changing requests.

### admin_audit_logs

- `id`
- `admin_user_id`
- `action`
- `target_type`
- `target_id`
- `details`
- `created_at`
