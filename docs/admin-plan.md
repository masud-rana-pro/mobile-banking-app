# SmartKash Admin Plan

## Scope

The MVP admin panel is minimal. It supports operational review and status actions only.

Do not add full dashboards, analytics, reports, advanced settings, or complex role management in MVP Phase 1.

Admin functionality remains backend-owned through Spring Boot routes/APIs. The Flutter cross-platform direction does not add admin business features in this step.

## Access Control

- Admin web routes and admin APIs require authenticated `ADMIN` role.
- Customers and merchants must not access admin pages or APIs.
- Admin actions should be written to `admin_audit_logs`.
- Step 16 creates the `admin_audit_logs` persistence foundation and internal service helper only. Admin audit list APIs and approval/rejection flow integration are future scope.
- Admin controllers must stay thin and delegate approval/rejection logic to services.
- Admin APIs must use request/response DTOs and must not expose entities directly.

## Admin Pages

- Users list
- Transactions list
- Add Money requests list
- Loan requests list
- Recharges list
- Payments list
- Audit logs list

## Admin API Routes

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

Step 23 implements the minimal read-only admin API foundation for these `GET` routes. All `/admin/**` routes require authenticated `ADMIN` role. Approval/rejection routes, dashboards, analytics, advanced settings, and complex role management remain future scope.

Step 24 implements Add Money approval/rejection only. Approval is a money-changing admin action and must create wallet credit, transaction record, immutable ledger entry, idempotency record, and audit log. Rejection must not change wallet balance.

## Admin Actions

### Add Money Approval

- Validate request is pending.
- Validate admin role.
- Validate idempotency key.
- Credit customer wallet.
- Create immutable ledger entry.
- Create user-facing transaction record.
- Create admin audit log.
- Step 24 implements approval wallet credit, transaction, ledger, idempotency, and audit logging. FCM alert is still future notification scope.

### Add Money Rejection

- Validate request is pending.
- Validate admin role.
- Update request status to rejected.
- Create audit log.

### Loan Approval Or Rejection

- Validate loan request is pending.
- Validate admin role.
- Update status to approved or rejected.
- Create audit log.

Loan disbursement, wallet credit, repayment, and installment tracking are future scope.
