# Step 20: Mobile Recharge Foundation

## 1. Step title

Step 20-এ SmartKash backend-এ demo mobile recharge foundation তৈরি করা হয়েছে।

## 2. What was implemented

এই step-এ শুধু mobile recharge record রাখার foundation করা হয়েছে:

- `mobile_recharges` database table
- `MobileOperator` enum
- `RechargeStatus` enum
- `MobileRecharge` JPA entity
- `MobileRechargeRepository`
- request/response DTO
- mapper
- service interface ও implementation
- thin controller
- authenticated API:
  - `POST /api/recharge`
  - `GET /api/recharge`

## 3. Why this step is needed

SmartKash MVP-তে mobile recharge feature থাকবে, কিন্তু zero-budget learning MVP হওয়ায় real recharge provider ব্যবহার করা হবে না। তাই প্রথমে demo recharge record save করার foundation দরকার। পরে wallet debit, PIN, idempotency, transaction, ledger, notification আলাদা step-এ যোগ করা যাবে।

## 4. Why this is demo-only

এই step-এ recharge request করলে backend record save করে `SUCCESS` status দেয়, কিন্তু user wallet থেকে টাকা কাটে না। কারণ wallet balance change করলে অবশ্যই transaction record, immutable ledger entry, PIN verification, idempotency key, safe wallet locking দরকার। সেগুলো এখনো এই step-এর scope না।

## 5. Files/folders changed

- `services/backend/src/main/resources/db/migration/V11__create_mobile_recharges.sql`
- `services/backend/src/main/java/com/smartkash/recharge/enums/MobileOperator.java`
- `services/backend/src/main/java/com/smartkash/recharge/enums/RechargeStatus.java`
- `services/backend/src/main/java/com/smartkash/recharge/entity/MobileRecharge.java`
- `services/backend/src/main/java/com/smartkash/recharge/repository/MobileRechargeRepository.java`
- `services/backend/src/main/java/com/smartkash/recharge/dto/request/CreateMobileRechargeRequest.java`
- `services/backend/src/main/java/com/smartkash/recharge/dto/response/MobileRechargeResponse.java`
- `services/backend/src/main/java/com/smartkash/recharge/mapper/MobileRechargeMapper.java`
- `services/backend/src/main/java/com/smartkash/recharge/service/MobileRechargeService.java`
- `services/backend/src/main/java/com/smartkash/recharge/service/impl/MobileRechargeServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/recharge/controller/MobileRechargeController.java`
- `docs/database-plan.md`
- `docs/backend-api-plan.md`
- `docs/codex-progress.md`

## 6. Important migration snippet

```sql
CREATE TABLE mobile_recharges (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    operator VARCHAR(40) NOT NULL,
    mobile_number VARCHAR(20) NOT NULL,
    amount NUMERIC(19, 2) NOT NULL,
    status VARCHAR(32) NOT NULL,
    transaction_reference VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### Migration explanation

- `CREATE TABLE mobile_recharges`: recharge record রাখার table তৈরি করে।
- `id BIGSERIAL PRIMARY KEY`: প্রতিটি recharge record-এর unique ID।
- `user_id BIGINT NOT NULL`: কোন user recharge করেছে তা users table-এর সাথে link করবে।
- `operator VARCHAR(40) NOT NULL`: GP/ROBI/BANGLALINK/TELETALK/AIRTEL operator রাখে।
- `mobile_number VARCHAR(20) NOT NULL`: যে number-এ recharge করা হচ্ছে।
- `amount NUMERIC(19, 2) NOT NULL`: recharge amount decimal হিসেবে রাখে।
- `status VARCHAR(32) NOT NULL`: demo flow-তে `SUCCESS` বা `FAILED`।
- `transaction_reference VARCHAR(64)`: future transaction/ledger integration-এর জন্য nullable placeholder।
- `created_at TIMESTAMPTZ`: record কখন তৈরি হয়েছে।

```sql
CONSTRAINT fk_mobile_recharges_user_id
    FOREIGN KEY (user_id) REFERENCES users (id)
```

এটি নিশ্চিত করে যে recharge record কোনো existing user-এর সাথেই linked হবে।

```sql
CONSTRAINT chk_mobile_recharges_amount_positive
    CHECK (amount > 0)
```

amount অবশ্যই 0-এর বেশি হতে হবে।

```sql
CONSTRAINT chk_mobile_recharges_operator
    CHECK (operator IN ('GP', 'ROBI', 'BANGLALINK', 'TELETALK', 'AIRTEL'))
```

শুধু allowed operator values database-এ save হবে।

## 7. Important enum snippet

```java
public enum MobileOperator {
    GP,
    ROBI,
    BANGLALINK,
    TELETALK,
    AIRTEL
}
```

এই enum fixed operator list দেয়। এতে typo কমে যায়, যেমন `Grameen` বা `gp` ভুলভাবে save হবে না।

```java
public enum RechargeStatus {
    SUCCESS,
    FAILED
}
```

Recharge status fixed রাখার জন্য enum ব্যবহার করা হয়েছে।

## 8. Important entity snippet

```java
@Entity
@Table(name = "mobile_recharges")
public class MobileRecharge {
```

- `@Entity`: এই class database table-এর model।
- `@Table(name = "mobile_recharges")`: entity কোন table map করবে তা বলে।

```java
@ManyToOne(fetch = FetchType.LAZY, optional = false)
@JoinColumn(name = "user_id", nullable = false)
private User user;
```

প্রতিটি recharge একটি user-এর সাথে linked। `LAZY` ব্যবহার করা হয়েছে যাতে দরকার না হলে user object database থেকে load না হয়।

```java
@Enumerated(EnumType.STRING)
@Column(nullable = false, length = 40)
private MobileOperator operator;
```

Operator enum database-এ string হিসেবে save হবে। এতে enum order বদলালেও data corrupt হবে না।

```java
public MobileRecharge(User user, MobileOperator operator, String mobileNumber, BigDecimal amount) {
    this.user = user;
    this.operator = operator;
    this.mobileNumber = mobileNumber;
    this.amount = amount;
    this.status = RechargeStatus.SUCCESS;
}
```

Constructor demo recharge record তৈরি করে এবং MVP demo flow হিসেবে status `SUCCESS` set করে। এখানে wallet balance touch করা হয়নি।

## 9. Important DTO snippet

```java
public record CreateMobileRechargeRequest(
        @NotNull(message = "Operator is required.")
        MobileOperator operator,

        @NotBlank(message = "Mobile number is required.")
        @Pattern(regexp = "^[0-9]{10,15}$", message = "Mobile number must contain 10 to 15 digits.")
        String mobileNumber,

        @NotNull(message = "Amount is required.")
        @DecimalMin(value = "1.00", message = "Amount must be at least 1.00.")
        BigDecimal amount
) {
}
```

- `@NotNull`: operator/amount খালি রাখা যাবে না।
- `@NotBlank`: mobile number empty string হতে পারবে না।
- `@Pattern`: mobile number শুধু digit এবং 10-15 character হতে হবে।
- `@DecimalMin`: amount কমপক্ষে 1.00 হতে হবে।
- DTO ব্যবহার করায় API input entity-র সাথে সরাসরি bind হচ্ছে না।

## 10. Important service snippet

```java
@Transactional
public MobileRechargeResponse createDemoRecharge(JwtPrincipal principal, CreateMobileRechargeRequest request) {
    User user = currentUser(principal);
    ensureActiveUser(user);
    MobileRecharge recharge = new MobileRecharge(
            user,
            request.operator(),
            request.mobileNumber(),
            request.amount()
    );
    return mobileRechargeMapper.toResponse(mobileRechargeRepository.save(recharge));
}
```

- `@Transactional`: database save operation এক transaction-এর ভিতরে চলে।
- `currentUser(principal)`: JWT থেকে Firebase UID নিয়ে persisted user খুঁজে।
- `ensureActiveUser(user)`: blocked/pending user recharge record তৈরি করতে পারবে না।
- `new MobileRecharge(...)`: entity তৈরি করে।
- `save(recharge)`: database-এ record save করে।
- `mapper.toResponse(...)`: entity সরাসরি API response-এ না দিয়ে DTO return করে।

## 11. Important controller snippet

```java
@PostMapping
public ResponseEntity<MobileRechargeResponse> createDemoRecharge(
        @AuthenticationPrincipal JwtPrincipal principal,
        @Valid @RequestBody CreateMobileRechargeRequest request
) {
    return ResponseEntity.status(HttpStatus.CREATED)
            .body(mobileRechargeService.createDemoRecharge(principal, request));
}
```

- `@PostMapping`: `POST /api/recharge` endpoint।
- `@AuthenticationPrincipal`: authenticated JWT user পাওয়া যায়।
- `@Valid`: request DTO validation চালায়।
- Controller নিজে business logic করে না; service-কে call করে।

## 12. How this fits into SmartKash flow

1. User Firebase login করে backend JWT পায়।
2. User mobile recharge request পাঠায়।
3. Backend JWT principal থেকে current user resolve করে।
4. Backend active user কিনা check করে।
5. Backend `mobile_recharges` table-এ demo record save করে।
6. Response-এ recharge record ফেরত দেয়।

এই flow এখনো wallet থেকে টাকা কাটে না। পরে real money-changing recharge step-এ PIN, idempotency, wallet debit, transaction, ledger যোগ হবে।

## 13. Common mistakes and cautions

- এই step-কে real recharge ভাবা যাবে না।
- Wallet balance কমানো যাবে না, কারণ ledger/transaction/idempotency/PIN wire করা হয়নি।
- Real recharge provider API key যোগ করা যাবে না।
- `application-local.yml` বা secret config commit করা যাবে না।
- `transaction_reference` এখন nullable; এই step-এ null থাকাই expected।
- mobile number validation country-perfect নয়; MVP foundation হিসেবে simple digit validation রাখা হয়েছে।

## 14. Manual verification commands

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
\d mobile_recharges
SELECT * FROM flyway_schema_history;
```

Expected output:

- `mobile_recharges` table দেখা যাবে।
- columns থাকবে: `id`, `user_id`, `operator`, `mobile_number`, `amount`, `status`, `transaction_reference`, `created_at`।
- Flyway history-তে `V11__create_mobile_recharges.sql` success হিসেবে দেখা যাবে।

API check:

```http
POST /api/recharge
Authorization: Bearer <backend-jwt>
Content-Type: application/json

{
  "operator": "GP",
  "mobileNumber": "01712345678",
  "amount": 100
}
```

Expected output:

- HTTP `201 Created`
- response body-তে `status` হবে `SUCCESS`
- `transactionReference` হবে `null`
- database-এ নতুন row তৈরি হবে

```http
GET /api/recharge
Authorization: Bearer <backend-jwt>
```

Expected output:

- HTTP `200 OK`
- current user-এর recharge records list আসবে

## 15. Git commands used

```powershell
git status --short --branch
git diff --check
git add <step-20-files>
git commit -m "step-20: add mobile recharge foundation"
git push
```

## 16. What I learned

এই step-এ শিখলাম কীভাবে real provider বা wallet debit ছাড়া একটি demo feature foundation তৈরি করা যায়। Entity, DTO, mapper, service, controller আলাদা রাখলে code clean থাকে এবং পরের step-এ money-changing rules যোগ করা সহজ হয়।
