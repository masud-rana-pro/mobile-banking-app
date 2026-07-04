# SmartKash Backend API Plan

## Client Platform Scope

The Spring Boot backend serves the SmartKash Flutter full cross-platform app. Supported Flutter clients are Android, iOS, Web, Windows, Linux, and macOS. API contracts must stay platform-neutral so the same backend can support every Flutter target.

## Backend Technology Stack

- Spring Boot
- Spring Web
- Spring Security
- Spring Data JPA
- Hibernate
- PostgreSQL Driver
- Lombok
- Bean Validation
- Firebase Admin SDK
- JWT library
- Flyway for database migration
- Spring Boot Actuator for health checks
- OpenAPI/Swagger for API documentation

## Backend Package Architecture

Root package: `com.smartkash`.

Feature modules:

- `com.smartkash.auth`
- `com.smartkash.user`
- `com.smartkash.wallet`
- `com.smartkash.ledger`
- `com.smartkash.transaction`
- `com.smartkash.idempotency`
- `com.smartkash.addmoney`
- `com.smartkash.sendmoney`
- `com.smartkash.payment`
- `com.smartkash.savings`
- `com.smartkash.loan`
- `com.smartkash.recharge`
- `com.smartkash.merchant`
- `com.smartkash.notification`
- `com.smartkash.admin`
- `com.smartkash.common`
- `com.smartkash.config`
- `com.smartkash.security`

Each feature module should use this internal structure when needed:

- `controller`
- `service`
- `service.impl`
- `repository`
- `entity`
- `dto.request`
- `dto.response`
- `mapper`
- `enums`

Example:

```text
com.smartkash.wallet.controller
com.smartkash.wallet.service
com.smartkash.wallet.service.impl
com.smartkash.wallet.repository
com.smartkash.wallet.entity
com.smartkash.wallet.dto.request
com.smartkash.wallet.dto.response
com.smartkash.wallet.mapper
com.smartkash.wallet.enums
```

## Backend Coding Rules

- Controllers must be thin.
- Business logic must stay in the service layer.
- Use service interfaces and implementation classes for major modules.
- Repositories should only handle database access.
- Entities must not be exposed directly in API responses.
- DTOs must be used for request and response payloads.
- Mappers should convert between Entity and DTO.
- Enums should be used for fixed statuses and types.
- Use Bean Validation annotations for input validation.
- Use global exception handling.
- Use database transactions for money-changing operations.
- Use optimistic locking or another safe locking strategy for wallet balance updates.
- Use idempotency keys for money-changing APIs.
- Use audit logs for admin actions and critical money operations.
- Do not hardcode secrets.
- Do not store raw PIN.
- Do not update or delete immutable ledger entries.
- Use reversal ledger entries for corrections.

## Important Backend Enums

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

## Auth APIs

- `POST /api/auth/firebase-login`: verify Firebase token and issue backend JWT.
- `POST /api/auth/set-pin`: set hashed PIN for authenticated user.
- PIN setup requires authenticated backend JWT, accepts `pin` and `confirmPin`, validates exactly 5 numeric digits, hashes the PIN with BCrypt, and never returns the raw PIN.
- `POST /api/auth/verify-pin`: verify PIN in backend only.
- PIN verification requires authenticated backend JWT, validates a 5-digit PIN, compares it with BCrypt, tracks failed attempts, and temporarily blocks verification after 5 wrong attempts for 15 minutes.
- `POST /api/devices/fcm-token`: save/update FCM device token.

## User APIs

- `GET /api/users/me`: read the authenticated user's persisted user/profile foundation record.
- `PUT /api/users/me/profile`: create or update the authenticated user's minimal profile fields: `fullName`, `email`, and `avatarUrl`.
- Profile update resolves the user from the authenticated backend JWT/Firebase UID and never accepts a user ID in the request body.
- Firebase login now creates or finds the minimal persisted `users` record by Firebase UID, using the Firebase phone number as the unique SmartKash mobile number.
- New Firebase-linked users start as `CUSTOMER` and `ACTIVE` until later profile, PIN, merchant, or admin management steps update them.
- Firebase login creates or finds the user's zero-balance wallet lifecycle record.
- Firebase login does not create PINs, transactions, ledgers, idempotency records, or money-changing records.

## Wallet APIs

- `GET /api/wallet/me`: get current user's wallet balance.
- Step 12 wallet foundation exposes wallet read only. It does not create wallets automatically, mutate balances, create ledger entries, or create transaction records.
- Step 15 links wallet lifecycle to Firebase login so each authenticated user has one zero-balance `BDT` wallet. This is not a money movement and does not create ledger entries or transaction records.

## Add Money APIs

- `POST /api/add-money/requests`: create Add Money request.
- `GET /api/add-money/requests`: list current user's Add Money requests.
- Step 17 implements customer Add Money request create/list foundation only. New requests are saved as `PENDING`; no admin approval, wallet credit, ledger entry, transaction record, idempotency record, or FCM alert is created yet.

## Send Money APIs

- `POST /api/send-money/resolve-receiver`: resolve and validate a receiver by registered mobile number or SmartKash QR payload before transfer.
- `POST /api/send-money`: send money using registered mobile number or QR payload.
- Required validation: authenticated user, PIN, receiver, account status, sender balance, idempotency key.
- Successful wallet-to-wallet transfer must create linked debit and credit ledger entries under one transaction reference.
- Step 26 implements receiver validation only. It accepts either `mobileNumber` or QR payload format `SMARTKASH_USER:<mobile-number>`, resolves the receiver from registered backend users, checks sender/receiver account status, prevents self-transfer, and checks receiver wallet status. It does not debit wallets, credit wallets, verify PIN, create transaction records, create ledger entries, or use idempotency yet.
- Step 27 implements `POST /api/send-money` wallet-to-wallet transfer. It accepts either `mobileNumber` or QR payload, validates authenticated active sender, receiver, PIN, idempotency key, active sender/receiver wallets, and sufficient sender balance. A successful transfer debits sender wallet, credits receiver wallet, creates sender `SEND_MONEY` and receiver `RECEIVE_MONEY` transaction records, creates linked `DEBIT` and `CREDIT` ledger entries under the sender transfer reference, and completes the idempotency key.

## Payment APIs

- `POST /api/payments/merchant`: pay merchant by merchant number/account number.
- Merchant payment debits customer wallet and credits merchant wallet.
- Step 18 adds merchant profile foundation with `POST /api/merchants/me` and `GET /api/merchants/me`. Merchant payment is still future scope and no wallet debit/credit is implemented yet.
- Step 28 implements `POST /api/payments/merchant`. It validates authenticated active customer, active merchant profile, active merchant user, PIN, idempotency key, active customer/merchant wallets, and sufficient customer balance. A successful payment debits the customer wallet, credits the merchant wallet, creates `MERCHANT_PAYMENT` transaction records for customer and merchant, creates linked debit/credit ledger entries under the customer payment reference, and completes the idempotency key.

## Transaction APIs

- `GET /api/transactions`: list user transactions with date/type/status filters.
- `GET /api/transactions/{id}`: get receipt/details for one transaction.
- Step 13 creates transaction and ledger persistence foundation only. It does not expose transaction APIs yet and does not create money movement records.
- Step 22 implements read-only transaction history APIs. The list endpoint supports optional `type`, `status`, `from`, and `to` query parameters and returns only the authenticated user's transaction records. It does not create, update, or delete transactions and does not create ledger entries or wallet balance changes.

## Savings APIs

- `POST /api/savings/goals`: create savings goal.
- `GET /api/savings/goals`: list savings goals.
- `POST /api/savings/goals/{id}/deposit`: deposit from wallet to savings goal.
- Step 21 implements savings goal create/list foundation only. New goals start as `ACTIVE` with `currentAmount = 0.00`; no wallet debit, savings deposit, ledger entry, transaction record, idempotency record, PIN confirmation, or FCM alert is created yet.
- Savings deposit remains future scope and must follow full money-changing API rules.

## Loan APIs

- `POST /api/loans/requests`: create loan request.
- `GET /api/loans/requests`: list current user's loan requests.
- Step 19 implements customer Loan request create/list foundation only. New requests are saved as `PENDING`; no admin approval/rejection, wallet disbursement, repayment, installment tracking, ledger entry, transaction record, idempotency record, or notification is created yet.

## Recharge APIs

- `POST /api/recharge`: create demo mobile recharge.
- `GET /api/recharge`: list current user's mobile recharge records.
- Step 20 implements demo mobile recharge create/list foundation only. New demo records are saved as `SUCCESS` for learning/demo flow, but no wallet debit, real provider call, ledger entry, transaction record, idempotency record, PIN confirmation, or FCM alert is created yet.
- A later real wallet-debit recharge step must require authenticated user, PIN confirmation, idempotency key, active wallet, sufficient balance, transaction record, immutable ledger entry, and provider/demo-provider status handling.

## Minimal Admin APIs

All admin routes require authenticated `ADMIN` role.

- `GET /admin/users`
- `GET /admin/transactions`
- `GET /admin/add-money/requests`
- `POST /admin/add-money/requests/{id}/approve`
- `POST /admin/add-money/requests/{id}/reject`
- `GET /admin/loans/requests`
- `POST /admin/loans/requests/{id}/approve`
- `POST /admin/loans/requests/{id}/reject`
- `GET /admin/recharges`
- `GET /admin/payments`
- `GET /admin/audit-logs`

Step 16 adds admin audit log persistence foundation only. It does not implement `GET /admin/audit-logs` or wire audit logging into admin approval/rejection APIs yet.

Step 23 implements the minimal read-only admin API foundation for `GET /admin/users`, `GET /admin/transactions`, `GET /admin/add-money/requests`, `GET /admin/loans/requests`, `GET /admin/recharges`, `GET /admin/payments`, and `GET /admin/audit-logs`. All `/admin/**` routes require authenticated `ADMIN` role. Step 23 does not implement approval, rejection, analytics, settings, dashboards, complex role management, wallet mutation, or money-changing admin actions.

Step 28 updates `GET /admin/payments` to return `MERCHANT_PAYMENT` transaction records after merchant payment persistence exists.

Step 24 implements Add Money admin approval/rejection. Approval requires `ADMIN` role and an idempotency key, locks the Add Money request and customer wallet, changes the request to `APPROVED`, credits the customer wallet, creates a user-facing `ADD_MONEY` transaction record, creates an immutable `CREDIT` ledger entry, stores idempotency completion, and records an admin audit log in one database transaction. Rejection changes only the request status to `REJECTED`, stores idempotency completion, and records an audit log; it does not change wallet balance or create ledger/transaction records.

Step 25 implements Loan admin approval/rejection status-only flow. Approval or rejection requires `ADMIN` role, locks the loan request, updates `status`, `reviewed_by`, and `reviewed_at`, and records an admin audit log. It does not disburse money, credit wallets, create transactions, create ledger entries, create idempotency records, or manage repayments/installments.

## Idempotency Rule

All money-changing APIs must accept a unique `clientRequestId` or `idempotencyKey`. If the same key is submitted again for the same request type and user, the backend must not create duplicate ledger entries, transaction records, or wallet changes.

Step 14 adds the `idempotency_keys` persistence foundation and internal service helper only. It does not expose idempotency through a public API and does not wire idempotency into money-changing flows yet.

Applies to:

- Send Money
- Merchant Payment
- Add Money approval
- Savings deposit
- Mobile Recharge
- Future Loan wallet credit if added later
