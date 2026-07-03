# Step 19: Loan Request Foundation

## 1. Step title

Step 19 - SmartKash Loan request foundation.

## 2. কী implement করা হয়েছে

এই step-এ customer Loan request create/list foundation তৈরি করা হয়েছে:

- `loan_requests` table তৈরি করা হয়েছে।
- `LoanStatus` enum তৈরি করা হয়েছে।
- `LoanRequest` JPA entity তৈরি করা হয়েছে।
- `LoanRequestRepository` তৈরি করা হয়েছে।
- Request/response DTO তৈরি করা হয়েছে।
- Mapper, service, service implementation তৈরি করা হয়েছে।
- `POST /api/loans/requests` endpoint তৈরি করা হয়েছে।
- `GET /api/loans/requests` endpoint তৈরি করা হয়েছে।

এই step-এ admin approval/rejection, loan disbursement, wallet credit, repayment, installment tracking, ledger entry, transaction record, idempotency, audit log, বা notification implement করা হয়নি।

## 3. MVP Phase 1 loan scope

SmartKash MVP Phase 1-এ loan feature খুব ছোট:

```text
Customer -> Loan Request -> PENDING
Admin later -> APPROVED or REJECTED status only
```

Disbursement, wallet credit, repayment, installment tracking future scope।

## 4. Migration snippet

```sql
CREATE TABLE loan_requests (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    amount NUMERIC(19, 2) NOT NULL,
    purpose VARCHAR(255) NOT NULL,
    status VARCHAR(32) NOT NULL,
    reviewed_by BIGINT,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Block-by-block ব্যাখ্যা:

- `id`: loan request primary key।
- `user_id`: কোন customer request করেছে।
- `amount`: requested loan amount।
- `purpose`: loan-এর কারণ।
- `status`: শুরুতে `PENDING`।
- `reviewed_by`: future admin review user id।
- `reviewed_at`: future admin review time।
- `created_at`, `updated_at`: timing।

## 5. LoanStatus enum

```java
public enum LoanStatus {
    PENDING,
    APPROVED,
    REJECTED
}
```

ব্যাখ্যা:

- `PENDING`: customer request করেছে, admin review করেনি।
- `APPROVED`: future admin status update।
- `REJECTED`: future admin status update।

## 6. Entity snippet

```java
public LoanRequest(User user, BigDecimal amount, String purpose) {
    this.user = user;
    this.amount = amount;
    this.purpose = purpose;
    this.status = LoanStatus.PENDING;
}
```

ব্যাখ্যা:

- request create করার সময় user backend principal থেকে আসে।
- amount `BigDecimal`, কারণ টাকা/amount float দিয়ে রাখা ঠিক নয়।
- নতুন request সবসময় `PENDING`।

## 7. DTO validation snippet

```java
public record CreateLoanRequest(
        @NotNull
        @DecimalMin(value = "1.00")
        BigDecimal amount,

        @NotBlank
        @Size(max = 255)
        String purpose
) {
}
```

ব্যাখ্যা:

- amount missing হলে validation error।
- amount কমপক্ষে `1.00`।
- purpose blank হতে পারবে না।
- purpose max 255 character।

## 8. Service snippet

```java
User user = currentUser(principal);
ensureActiveUser(user);
LoanRequest loanRequest = new LoanRequest(user, request.amount(), request.purpose());
return loanRequestMapper.toResponse(loanRequestRepository.save(loanRequest));
```

ব্যাখ্যা:

- JWT principal থেকে current user resolve করা হয়।
- blocked/pending user request create করতে পারে না।
- entity `PENDING` status নিয়ে তৈরি হয়।
- save-এর পর response DTO return হয়।

## 9. কেন wallet credit হয়নি

Loan request create করা মানে loan money disburse করা নয়। Wallet credit করলে সেটা money-changing operation হবে, যেখানে লাগবে:

- admin approval
- idempotency key
- wallet locking
- ledger entry
- transaction record
- audit log
- notification

এই step শুধু request record রাখে।

## 10. Manual verification commands

Backend:

```cmd
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Database:

```cmd
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
\d loan_requests
SELECT * FROM flyway_schema_history;
```

API check after backend is running:

```cmd
POST /api/loans/requests
GET /api/loans/requests
```

Expected API create body:

```json
{
  "amount": 5000,
  "purpose": "Small business support"
}
```

## 11. Expected output

- `.\mvnw.cmd test` should show `BUILD SUCCESS`.
- package command should finish without errors.
- `\d loan_requests` should show `id`, `user_id`, `amount`, `purpose`, `status`, `reviewed_by`, `reviewed_at`, `created_at`, `updated_at`.
- successful create response should return `status: "PENDING"`.
- `loan_requests` table should not create wallet/ledger/transaction rows.
- `git status` should show only local `application-local.yml` if it remains changed.

## 12. Git commands used

```cmd
git status --short --branch
git diff --check
git add <step-19-files>
git commit -m "step-19: add loan request foundation"
git push
```

## 13. এই step থেকে কী শিখলাম

এই step থেকে শিখলাম loan request আর loan disbursement আলাদা জিনিস। Request pending হিসেবে রাখা safe; future admin step শুধু status approve/reject করবে। Wallet credit বা repayment future scope।
