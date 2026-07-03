# Step 25: Loan Admin Decision Flow

## 1. Step title

Step 25-এ SmartKash backend-এ Loan admin approval/rejection status-only flow তৈরি করা হয়েছে।

## 2. What was implemented

এই step-এ admin loan request approve বা reject করতে পারবে:

- `POST /admin/loans/requests/{id}/approve`
- `POST /admin/loans/requests/{id}/reject`
- admin loan decision request DTO
- admin loan decision service
- admin loan decision controller
- pessimistic lock for loan request
- `reviewed_by` এবং `reviewed_at` update
- admin audit log

## 3. Why this step is status-only

SmartKash MVP Phase 1 loan scope অনুযায়ী approval/rejection শুধু request status update করবে। Loan disbursement, wallet credit, repayment, installment tracking future scope। তাই এই step কোনো wallet balance change, transaction record, ledger entry, idempotency record তৈরি করে না।

## 4. Files/folders changed

- `services/backend/src/main/java/com/smartkash/admin/controller/AdminLoanDecisionController.java`
- `services/backend/src/main/java/com/smartkash/admin/dto/request/AdminLoanDecisionRequest.java`
- `services/backend/src/main/java/com/smartkash/admin/service/AdminLoanDecisionService.java`
- `services/backend/src/main/java/com/smartkash/admin/service/impl/AdminLoanDecisionServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/loan/entity/LoanRequest.java`
- `services/backend/src/main/java/com/smartkash/loan/repository/LoanRequestRepository.java`
- `docs/backend-api-plan.md`
- `docs/database-plan.md`
- `docs/admin-plan.md`
- `docs/codex-progress.md`

## 5. Important request DTO snippet

```java
public record AdminLoanDecisionRequest(
        @Size(max = 255, message = "Note must be 255 characters or less.")
        String note
) {
}
```

- `note`: admin optional reason লিখতে পারে।
- `@Size`: note 255 character-এর বেশি হতে পারবে না।
- idempotency key নেই, কারণ এই flow money-changing নয়।

## 6. Important entity snippet

```java
public void approve(User adminUser) {
    status = LoanStatus.APPROVED;
    reviewedBy = adminUser;
    reviewedAt = Instant.now();
}
```

Approval করলে status `APPROVED` হয়, কে review করেছে এবং কখন করেছে তা save হয়।

```java
public void reject(User adminUser) {
    status = LoanStatus.REJECTED;
    reviewedBy = adminUser;
    reviewedAt = Instant.now();
}
```

Reject করলে status `REJECTED` হয়। Wallet balance বা transaction touch করা হয় না।

## 7. Important repository snippet

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("select l from LoanRequest l where l.id = :id")
Optional<LoanRequest> findByIdForUpdate(Long id);
```

- loan request row lock করে।
- একই request একই সময়ে দুই admin approve/reject করার ঝুঁকি কমায়।
- status update safe হয়।

## 8. Important service snippet

```java
LoanRequest loanRequest = loanRequestRepository.findByIdForUpdate(requestId)
        .orElseThrow(() -> new ResourceNotFoundException("Loan request was not found."));
if (loanRequest.getStatus() != LoanStatus.PENDING) {
    throw new IllegalArgumentException("Only pending Loan requests can be approved or rejected.");
}
```

- request না থাকলে `404`।
- request pending না হলে `400`।
- already approved/rejected request আবার decision করা যাবে না।

```java
adminAuditLogService.recordAdminAction(
        adminUser,
        AuditAction.LOAN_APPROVE,
        AuditTargetType.LOAN_REQUEST,
        String.valueOf(savedRequest.getId()),
        "Approved Loan request. note=" + nullToEmpty(request.note())
);
```

Audit log রাখে, যাতে admin decision trace করা যায়।

## 9. Important controller snippet

```java
@PostMapping("/{id}/approve")
public ResponseEntity<LoanRequestResponse> approve(
        @AuthenticationPrincipal JwtPrincipal principal,
        @PathVariable Long id,
        @Valid @RequestBody AdminLoanDecisionRequest request
) {
    return ResponseEntity.ok(adminLoanDecisionService.approve(principal, id, request));
}
```

- `POST /admin/loans/requests/{id}/approve`
- admin principal নেয়।
- request body validate করে।
- service layer-এ business logic delegate করে।

## 10. How this works in SmartKash flow

1. Customer loan request create করে।
2. Admin `/admin/loans/requests` দিয়ে pending loans দেখে।
3. Admin approve বা reject endpoint call করে।
4. Backend loan request lock করে।
5. Status update করে।
6. `reviewed_by` এবং `reviewed_at` save করে।
7. Admin audit log তৈরি করে।

## 11. Common mistakes and cautions

- Loan approve মানে wallet credit নয়।
- এই step-এ transaction/ledger/idempotency তৈরি করা যাবে না।
- Already approved/rejected loan আবার approve/reject করা যাবে না।
- Customer/Merchant JWT দিয়ে admin endpoint call করলে `403 Forbidden` হওয়া উচিত।
- `application-local.yml` commit করা যাবে না।

## 12. Manual verification commands

Backend build/test:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Expected output:

- Maven শেষে `BUILD SUCCESS`
- compile error থাকবে না।

Approval API check:

```http
POST /admin/loans/requests/{id}/approve
Authorization: Bearer <admin-jwt>
Content-Type: application/json

{
  "note": "Approved for demo"
}
```

Expected output:

- HTTP `200 OK`
- response `status` হবে `APPROVED`
- `reviewedAt` null থাকবে না

Reject API check:

```http
POST /admin/loans/requests/{id}/reject
Authorization: Bearer <admin-jwt>
Content-Type: application/json

{
  "note": "Rejected for demo"
}
```

Expected output:

- HTTP `200 OK`
- response `status` হবে `REJECTED`
- `reviewedAt` null থাকবে না

Database check:

```sql
SELECT id, status, reviewed_by, reviewed_at FROM loan_requests ORDER BY id DESC LIMIT 5;
SELECT action, target_type, target_id, details FROM admin_audit_logs ORDER BY created_at DESC LIMIT 5;
SELECT transaction_reference, type, amount FROM transactions ORDER BY created_at DESC LIMIT 5;
SELECT transaction_reference, entry_type, amount FROM ledger_entries ORDER BY created_at DESC LIMIT 5;
```

Expected output:

- loan request status `APPROVED` বা `REJECTED`
- `reviewed_by` এবং `reviewed_at` set
- audit action `LOAN_APPROVE` বা `LOAN_REJECT`
- loan decision-এর জন্য নতুন wallet credit/transaction/ledger হওয়া উচিত না

## 13. Git commands used

```powershell
git status --short --branch
git diff --check
git add <step-25-files>
git commit -m "step-25: add loan admin decision flow"
git push
```

## 14. What I learned

এই step-এ শিখলাম সব approval flow money-changing নয়। Loan MVP Phase 1 status-only হওয়ায় শুধু status, review metadata এবং audit log দরকার; wallet/ledger/transaction future disbursement step-এর জন্য রাখা হয়েছে।
