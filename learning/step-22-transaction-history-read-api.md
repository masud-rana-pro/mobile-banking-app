# Step 22: Transaction History Read API

## 1. Step title

Step 22-এ SmartKash backend-এ transaction history read API foundation তৈরি করা হয়েছে।

## 2. What was implemented

এই step-এ transaction records পড়ার জন্য read-only API যোগ করা হয়েছে:

- `GET /api/transactions`
- `GET /api/transactions/{id}`
- `TransactionResponse` DTO
- `TransactionRecordMapper`
- `TransactionQueryService`
- `TransactionQueryServiceImpl`
- `TransactionController`
- repository filter query

## 3. Why this step is needed

SmartKash app-এ Statement/Transaction history feature দরকার। User পরে Add Money, Send Money, Payment, Recharge, Savings Deposit করলে transaction records তৈরি হবে। এই step সেই records দেখানোর foundation তৈরি করে।

## 4. Why this is read-only

Transaction history API কখনো wallet balance change করবে না। এটি শুধু existing transaction records পড়ে। Money movement তৈরি করার কাজ future dedicated flow-তে হবে, যেখানে PIN, idempotency, wallet locking, transaction record, ledger entry একসাথে handle করা হবে।

## 5. Files/folders changed

- `services/backend/src/main/java/com/smartkash/transaction/repository/TransactionRecordRepository.java`
- `services/backend/src/main/java/com/smartkash/transaction/dto/response/TransactionResponse.java`
- `services/backend/src/main/java/com/smartkash/transaction/mapper/TransactionRecordMapper.java`
- `services/backend/src/main/java/com/smartkash/transaction/service/TransactionQueryService.java`
- `services/backend/src/main/java/com/smartkash/transaction/service/impl/TransactionQueryServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/transaction/controller/TransactionController.java`
- `docs/backend-api-plan.md`
- `docs/codex-progress.md`

## 6. Important repository snippet

```java
@Query("""
        select t
        from TransactionRecord t
        where t.user.id = :userId
          and (:type is null or t.type = :type)
          and (:status is null or t.status = :status)
          and (:fromTime is null or t.createdAt >= :fromTime)
          and (:toTime is null or t.createdAt <= :toTime)
        order by t.createdAt desc
        """)
List<TransactionRecord> findCurrentUserTransactions(
        Long userId,
        TransactionType type,
        TransactionStatus status,
        Instant from,
        Instant to
);
```

### Repository explanation

- `select t`: transaction entity select করে; `t` একটি ছোট alias।
- `where t.user.id = :userId`: শুধু authenticated current user-এর records return করে।
- `:type is null or t.type = :type`: type না দিলে সব type, দিলে matching type।
- `:status is null or t.status = :status`: status না দিলে সব status, দিলে matching status।
- `:fromTime is null or t.createdAt >= :fromTime`: from date দিলে তার পরের records।
- `:toTime is null or t.createdAt <= :toTime`: to date দিলে তার আগের records।
- `order by transaction.createdAt desc`: newest transaction আগে দেখায়।

```java
Optional<TransactionRecord> findByIdAndUserId(Long id, Long userId);
```

এই method নিশ্চিত করে user শুধু নিজের transaction details দেখতে পারে। অন্য user-এর transaction ID দিলে 404 হবে।

## 7. Important response DTO snippet

```java
public record TransactionResponse(
        Long id,
        String transactionReference,
        TransactionType type,
        TransactionStatus status,
        BigDecimal amount,
        Long counterpartyUserId,
        String counterpartyMobileNumber,
        String description,
        Instant createdAt
) {
}
```

- `id`: internal transaction ID।
- `transactionReference`: receipt/reference number।
- `type`: transaction type, যেমন `SEND_MONEY`, `ADD_MONEY`।
- `status`: `PENDING`, `SUCCESS`, `FAILED` ইত্যাদি।
- `amount`: transaction amount।
- `counterpartyUserId`: অন্য user থাকলে তার ID।
- `counterpartyMobileNumber`: অন্য user থাকলে তার mobile number।
- `description`: ছোট description।
- `createdAt`: transaction কবে তৈরি হয়েছে।

## 8. Important mapper snippet

```java
User counterparty = transaction.getCounterpartyUser();
return new TransactionResponse(
        transaction.getId(),
        transaction.getTransactionReference(),
        transaction.getType(),
        transaction.getStatus(),
        transaction.getAmount(),
        counterparty == null ? null : counterparty.getId(),
        counterparty == null ? null : counterparty.getMobileNumber(),
        transaction.getDescription(),
        transaction.getCreatedAt()
);
```

Mapper entity থেকে DTO বানায়। Counterparty না থাকলে null return করে, তাই API response safe থাকে।

## 9. Important service snippet

```java
@Transactional(readOnly = true)
public List<TransactionResponse> getCurrentUserTransactions(
        JwtPrincipal principal,
        TransactionType type,
        TransactionStatus status,
        Instant from,
        Instant to
) {
    User user = currentUser(principal);
    return transactionRecordRepository.findCurrentUserTransactions(user.getId(), type, status, from, to)
            .stream()
            .map(transactionRecordMapper::toResponse)
            .toList();
}
```

- `@Transactional(readOnly = true)`: এটি read operation, তাই database write হবে না।
- `currentUser(principal)`: JWT থেকে current persisted user খুঁজে।
- `findCurrentUserTransactions`: current user এবং optional filters দিয়ে query করে।
- `map(transactionRecordMapper::toResponse)`: entity API response হিসেবে expose না করে DTO বানায়।

## 10. Important controller snippet

```java
@GetMapping
public ResponseEntity<List<TransactionResponse>> currentUserTransactions(
        @AuthenticationPrincipal JwtPrincipal principal,
        @RequestParam(required = false) TransactionType type,
        @RequestParam(required = false) TransactionStatus status,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to
) {
    return ResponseEntity.ok(transactionQueryService.getCurrentUserTransactions(principal, type, status, from, to));
}
```

- `GET /api/transactions` endpoint।
- `type`, `status`, `from`, `to` optional query parameters।
- `@DateTimeFormat`: ISO date-time parse করতে সাহায্য করে।
- Controller business logic না করে service call করে।

```java
@GetMapping("/{id}")
public ResponseEntity<TransactionResponse> currentUserTransaction(
        @AuthenticationPrincipal JwtPrincipal principal,
        @PathVariable Long id
) {
    return ResponseEntity.ok(transactionQueryService.getCurrentUserTransaction(principal, id));
}
```

এই endpoint একটি transaction receipt/details return করে। Ownership service layer-এ check হয়।

## 11. How this works in SmartKash flow

1. User backend JWT সহ `/api/transactions` call করে।
2. Backend JWT থেকে current user resolve করে।
3. Backend শুধু ওই user-এর transactions query করে।
4. Optional filter দিলে type/status/date অনুযায়ী result কমে যায়।
5. Response DTO হিসেবে transaction list ফেরত আসে।

## 12. Common mistakes and cautions

- Transaction history API দিয়ে transaction create করা যাবে না।
- অন্য user-এর transaction দেখানো যাবে না।
- Entity সরাসরি return করা যাবে না।
- Date filter ISO format-এ দিতে হবে।
- এখন অনেক user empty list পেতে পারে, কারণ money-changing flow এখনো transaction create করছে না।

## 13. Manual verification commands

Backend build/test:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Expected output:

- Maven শেষে `BUILD SUCCESS` দেখাবে।
- Compilation error থাকবে না।

Database check:

```powershell
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
\d transactions
SELECT * FROM transactions ORDER BY created_at DESC LIMIT 5;
```

Expected output:

- `transactions` table আগে থেকেই থাকবে।
- table empty হতে পারে, এটি normal কারণ money-changing flow এখনো transaction তৈরি করছে না।

API check:

```http
GET /api/transactions
Authorization: Bearer <backend-jwt>
```

Expected output:

- HTTP `200 OK`
- current user-এর transaction list আসবে।
- এখন list `[]` empty হতে পারে।

```http
GET /api/transactions?type=ADD_MONEY&status=SUCCESS
Authorization: Bearer <backend-jwt>
```

Expected output:

- HTTP `200 OK`
- matching records থাকলে list, না থাকলে `[]`।

```http
GET /api/transactions/999999
Authorization: Bearer <backend-jwt>
```

Expected output:

- current user-এর এমন transaction না থাকলে HTTP `404 Not Found`।

## 14. Git commands used

```powershell
git status --short --branch
git diff --check
git add <step-22-files>
git commit -m "step-22: add transaction history read api"
git push
```

## 15. What I learned

এই step-এ শিখলাম কীভাবে read-only API বানাতে হয়, current user ownership enforce করতে হয়, optional filters ব্যবহার করতে হয়, এবং entity থেকে DTO response তৈরি করতে হয়।
