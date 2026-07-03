# Step 24: Add Money Admin Decision Flow

## 1. Step title

Step 24-এ SmartKash backend-এ Add Money admin approval/rejection flow তৈরি করা হয়েছে।

## 2. What was implemented

এই step-এ admin এখন pending Add Money request approve বা reject করতে পারবে:

- `POST /admin/add-money/requests/{id}/approve`
- `POST /admin/add-money/requests/{id}/reject`
- approval request DTO with `idempotencyKey`
- approval response DTO with request status, transaction reference, wallet balance after
- admin decision service
- pessimistic lock for Add Money request
- pessimistic lock for wallet
- wallet credit method
- transaction record creation
- immutable ledger entry creation
- idempotency completion
- admin audit log

## 3. Why this step is important

এটি SmartKash backend-এর প্রথম real money-changing flow। Add Money approve করলে wallet balance বাড়ে। তাই শুধু status update করলে চলবে না; transaction, ledger, idempotency, locking, audit সব একসাথে করতে হয়।

## 4. Approval flow

Approval হলে backend:

1. Admin JWT verify করে।
2. Idempotency key reserve/validate করে।
3. Add Money request lock করে।
4. Request `PENDING` কিনা check করে।
5. Customer wallet lock করে।
6. Wallet active কিনা check করে।
7. Wallet balance credit করে।
8. `ADD_MONEY` transaction record তৈরি করে।
9. `CREDIT` ledger entry তৈরি করে।
10. Add Money request `APPROVED` করে।
11. Admin audit log তৈরি করে।
12. Idempotency key completed করে।

## 5. Rejection flow

Reject হলে backend:

1. Admin JWT verify করে।
2. Idempotency key reserve/validate করে।
3. Add Money request lock করে।
4. Request `PENDING` কিনা check করে।
5. Request `REJECTED` করে।
6. Admin audit log তৈরি করে।
7. Idempotency completed করে।

Reject wallet balance change করে না এবং ledger/transaction তৈরি করে না।

## 6. Files/folders changed

- `services/backend/src/main/java/com/smartkash/admin/controller/AdminAddMoneyDecisionController.java`
- `services/backend/src/main/java/com/smartkash/admin/dto/request/AdminAddMoneyDecisionRequest.java`
- `services/backend/src/main/java/com/smartkash/admin/dto/response/AdminAddMoneyDecisionResponse.java`
- `services/backend/src/main/java/com/smartkash/admin/service/AdminAddMoneyDecisionService.java`
- `services/backend/src/main/java/com/smartkash/admin/service/impl/AdminAddMoneyDecisionServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/addmoney/entity/AddMoneyRequest.java`
- `services/backend/src/main/java/com/smartkash/addmoney/repository/AddMoneyRequestRepository.java`
- `services/backend/src/main/java/com/smartkash/wallet/entity/Wallet.java`
- `services/backend/src/main/java/com/smartkash/wallet/repository/WalletRepository.java`
- `docs/backend-api-plan.md`
- `docs/database-plan.md`
- `docs/admin-plan.md`
- `docs/security-plan.md`
- `docs/codex-progress.md`

## 7. Important request DTO snippet

```java
public record AdminAddMoneyDecisionRequest(
        @NotBlank(message = "Idempotency key is required.")
        @Size(max = 128, message = "Idempotency key must be 128 characters or less.")
        String idempotencyKey,

        @Size(max = 255, message = "Note must be 255 characters or less.")
        String note
) {
}
```

- `idempotencyKey`: duplicate approve/reject ঠেকানোর জন্য required।
- `note`: admin optional note দিতে পারে।
- validation থাকায় blank key বা বড় note reject হবে।

## 8. Important wallet snippet

```java
public BigDecimal credit(BigDecimal amount) {
    balance = balance.add(amount);
    return balance;
}
```

এই method wallet balance বাড়ায় এবং balance after return করে। Approval flow ছাড়া অন্য কোথাও arbitrary balance set করা হয়নি।

## 9. Important locking snippets

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("select r from AddMoneyRequest r where r.id = :id")
Optional<AddMoneyRequest> findByIdForUpdate(Long id);
```

Add Money request lock করে, যাতে একই request একসাথে দুই admin approve করতে না পারে।

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("select w from Wallet w where w.user.id = :userId")
Optional<Wallet> findByUserIdForUpdate(Long userId);
```

Wallet lock করে, যাতে balance update concurrent request-এ conflict না করে।

## 10. Important approval service snippet

```java
Wallet wallet = walletRepository.findByUserIdForUpdate(addMoneyRequest.getUser().getId())
        .orElseThrow(() -> new ResourceNotFoundException("Customer wallet was not found."));
ensureActiveWallet(wallet);

BigDecimal balanceAfter = wallet.credit(addMoneyRequest.getAmount());
String transactionReference = uniqueTransactionReference();
```

- customer wallet locked অবস্থায় load হয়।
- wallet active কিনা check হয়।
- balance credit হয়।
- unique transaction reference তৈরি হয়।

```java
TransactionRecord transaction = new TransactionRecord(
        transactionReference,
        addMoneyRequest.getUser(),
        TransactionType.ADD_MONEY,
        TransactionStatus.SUCCESS,
        addMoneyRequest.getAmount(),
        null,
        "Add Money request approved by admin"
);
transactionRecordRepository.save(transaction);
```

User-facing transaction record তৈরি করে, যা statement/transaction history-তে দেখা যাবে।

```java
ledgerEntryRepository.save(new LedgerEntry(
        wallet,
        addMoneyRequest.getUser(),
        transactionReference,
        null,
        LedgerEntryType.CREDIT,
        addMoneyRequest.getAmount(),
        balanceAfter,
        "Add Money wallet credit"
));
```

Immutable credit ledger entry তৈরি করে। এই ledger entry update/delete করা যাবে না।

## 11. Important idempotency snippet

```java
IdempotencyKey idempotencyKey = reserveOrValidateIdempotency(
        adminUser,
        request.idempotencyKey(),
        requestHash
);
```

এই line একই key দিয়ে duplicate approve/reject ঠেকায়। একই key ও একই request আবার এলে duplicate wallet credit না করে existing completed state return করে।

```java
idempotencyKeyService.markCompleted(
        idempotencyKey,
        "APPROVED:" + savedRequest.getId() + ":" + transactionReference
);
```

Approval শেষে idempotency completed হয় এবং transaction reference response body text-এ রাখা হয়।

## 12. Important audit snippet

```java
adminAuditLogService.recordAdminAction(
        adminUser,
        AuditAction.ADD_MONEY_APPROVE,
        AuditTargetType.ADD_MONEY_REQUEST,
        String.valueOf(savedRequest.getId()),
        "Approved Add Money request. transactionReference=" + transactionReference
);
```

Admin কে, কোন request approve করেছে, কোন transaction reference হয়েছে, তা audit log-এ থাকে।

## 13. How this works in SmartKash flow

1. Customer Add Money request create করে।
2. Admin `/admin/add-money/requests` দিয়ে pending requests দেখে।
3. Admin approve endpoint call করে idempotency key সহ।
4. Backend wallet credit করে।
5. Transaction history-তে `ADD_MONEY` record তৈরি হয়।
6. Ledger table-এ immutable `CREDIT` entry তৈরি হয়।
7. Admin audit log তৈরি হয়।

## 14. Common mistakes and cautions

- একই Add Money request দুইবার approve করা যাবে না।
- Same idempotency key দিয়ে different request/action করা যাবে না।
- Wallet balance direct setter দিয়ে change করা যাবে না।
- Ledger entry update/delete করা যাবে না।
- Reject করলে wallet balance change হওয়া যাবে না।
- Customer/Merchant JWT দিয়ে admin endpoint call করলে `403 Forbidden` হওয়া উচিত।
- `application-local.yml` commit করা যাবে না।

## 15. Manual verification commands

Backend build/test:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Expected output:

- Maven শেষে `BUILD SUCCESS`
- compile error থাকবে না।

API approval check:

```http
POST /admin/add-money/requests/{id}/approve
Authorization: Bearer <admin-jwt>
Content-Type: application/json

{
  "idempotencyKey": "approve-add-money-1",
  "note": "Approved for demo"
}
```

Expected output:

- HTTP `200 OK`
- response `request.status` হবে `APPROVED`
- `transactionReference` null হবে না
- `walletBalanceAfter` আগের balance + request amount হবে

Duplicate idempotency check:

```http
POST /admin/add-money/requests/{same-id}/approve
Authorization: Bearer <admin-jwt>
Content-Type: application/json

{
  "idempotencyKey": "approve-add-money-1",
  "note": "Approved for demo"
}
```

Expected output:

- HTTP `200 OK`
- wallet balance আর বাড়বে না
- duplicate transaction/ledger হবে না

Reject check:

```http
POST /admin/add-money/requests/{id}/reject
Authorization: Bearer <admin-jwt>
Content-Type: application/json

{
  "idempotencyKey": "reject-add-money-1",
  "note": "Rejected for demo"
}
```

Expected output:

- HTTP `200 OK`
- response `request.status` হবে `REJECTED`
- `transactionReference` null থাকবে
- wallet balance change হবে না

Database check:

```powershell
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
SELECT id, status, approved_by, approved_at FROM add_money_requests ORDER BY id DESC LIMIT 5;
SELECT id, user_id, balance, version FROM wallets ORDER BY id DESC LIMIT 5;
SELECT transaction_reference, type, status, amount FROM transactions ORDER BY created_at DESC LIMIT 5;
SELECT transaction_reference, entry_type, amount, balance_after FROM ledger_entries ORDER BY created_at DESC LIMIT 5;
SELECT idempotency_key, operation_type, status, response_body FROM idempotency_keys ORDER BY created_at DESC LIMIT 5;
SELECT action, target_type, target_id, details FROM admin_audit_logs ORDER BY created_at DESC LIMIT 5;
```

Expected output:

- approved request status `APPROVED`
- wallet balance credited once
- one `ADD_MONEY` transaction
- one `CREDIT` ledger entry
- idempotency status `COMPLETED`
- audit action `ADD_MONEY_APPROVE`

## 16. Git commands used

```powershell
git status --short --branch
git diff --check
git add <step-24-files>
git commit -m "step-24: add add money admin decision flow"
git push
```

## 17. What I learned

এই step-এ শিখলাম money-changing backend flow কখনো শুধু balance update নয়। Wallet balance, transaction record, immutable ledger entry, idempotency, locking এবং audit log একসাথে না করলে financial-style app unsafe হয়ে যায়।
