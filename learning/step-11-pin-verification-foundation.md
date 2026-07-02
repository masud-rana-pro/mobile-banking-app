# Step 11: PIN Verification Foundation

## 1. Step title

Step 11 - SmartKash backend PIN verification foundation.

## 2. কী implement করা হয়েছে

এই step-এ backend-only PIN verification foundation যোগ করা হয়েছে:

- `users` table-এ PIN failed attempt tracking fields যোগ করা হয়েছে।
- `POST /api/auth/verify-pin` endpoint যোগ করা হয়েছে।
- Endpoint authenticated backend JWT ছাড়া accessible নয়।
- Request body-তে শুধু `pin` নেওয়া হয়েছে।
- PIN exactly 5 digit numeric হতে হবে।
- Backend stored BCrypt hash-এর সাথে raw request PIN compare করে।
- ভুল PIN দিলে failed attempt count বাড়ে।
- 5 বার ভুল PIN দিলে 15 মিনিটের জন্য PIN verification block হয়।
- সঠিক PIN দিলে failed attempt count reset হয়।
- Response raw PIN বা PIN hash কখনো return করে না।

এই step-এ wallet, ledger, transaction, send money, payment, add money, recharge, savings, loan, admin business feature, বা money-changing API যোগ করা হয়নি।

## 3. কেন PIN verification দরকার

Step 10-এ PIN setup করা হয়েছে, কিন্তু PIN verify করার endpoint ছিল না। Future money-changing operation-এর আগে backend-কে user PIN verify করতে হবে। এই step সেই verification foundation তৈরি করে।

## 4. কেন raw PIN store বা return করা যাবে না

Raw PIN শুধু request-এর সময় backend memory-তে আসে। এরপর:

- database-এ raw PIN রাখা হয় না
- response-এ raw PIN দেওয়া হয় না
- log করা হয় না
- Flutter app-এ save করার rule নেই

Database-এ শুধু BCrypt hash থাকে।

## 5. কোন files/folders create বা change হয়েছে

- `services/backend/src/main/resources/db/migration/V3__add_pin_verification_fields.sql`
- `services/backend/src/main/java/com/smartkash/auth/dto/request/VerifyPinRequest.java`
- `services/backend/src/main/java/com/smartkash/auth/dto/response/PinVerificationResponse.java`
- `services/backend/src/main/java/com/smartkash/auth/controller/AuthController.java`
- `services/backend/src/main/java/com/smartkash/auth/service/AuthService.java`
- `services/backend/src/main/java/com/smartkash/auth/service/impl/AuthServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/user/entity/User.java`
- `docs/backend-api-plan.md`
- `docs/security-plan.md`
- `docs/database-plan.md`
- `docs/codex-instructions.md`
- `docs/codex-progress.md`
- `learning/step-11-pin-verification-foundation.md`

## 6. Important code/config snippets

### Flyway migration

```sql
ALTER TABLE users
    ADD COLUMN pin_failed_attempts INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN pin_blocked_until TIMESTAMPTZ;
```

Line-by-line Bangla ব্যাখ্যা:

- `ALTER TABLE users` existing users table update করে।
- `pin_failed_attempts` wrong PIN attempt count রাখে।
- `NOT NULL DEFAULT 0` existing user rows-এর জন্য safe default।
- `pin_blocked_until` PIN verification কখন পর্যন্ত blocked থাকবে তা রাখে।

### Verify PIN request DTO

```java
public record VerifyPinRequest(
        @NotBlank(message = "PIN is required.")
        @Pattern(regexp = "\\d{5}", message = "PIN must be exactly 5 digits.")
        String pin
) {
}
```

ব্যাখ্যা:

- `pin` required।
- PIN exactly 5 digit numeric হতে হবে।
- request body-তে `userId` নেই।
- authenticated user JWT/Firebase UID থেকে resolve হয়।

### Verify PIN response DTO

```java
public record PinVerificationResponse(
        boolean verified,
        int remainingAttempts,
        Instant blockedUntil
) {
}
```

ব্যাখ্যা:

- `verified` PIN ঠিক কি না জানায়।
- `remainingAttempts` কতবার চেষ্টা বাকি আছে জানায়।
- `blockedUntil` থাকলে user কখন পর্যন্ত blocked তা জানায়।
- raw PIN বা hash response-এ নেই।

### Controller endpoint

```java
@PostMapping("/verify-pin")
public ResponseEntity<PinVerificationResponse> verifyPin(
        @AuthenticationPrincipal JwtPrincipal principal,
        @Valid @RequestBody VerifyPinRequest request
) {
    return ResponseEntity.ok(authService.verifyPin(principal, request));
}
```

Block-by-block Bangla ব্যাখ্যা:

- `@PostMapping("/verify-pin")` endpoint path হলো `POST /api/auth/verify-pin`।
- `@AuthenticationPrincipal` current authenticated user নেয়।
- `@Valid` DTO validation চালায়।
- Controller business logic করে না।
- Service layer PIN verification করে।

### Service constants

```java
private static final int MAX_PIN_ATTEMPTS = 5;
private static final int PIN_BLOCK_MINUTES = 15;
```

ব্যাখ্যা:

- 5 বার wrong PIN দিলে block হবে।
- block duration 15 মিনিট।
- MVP foundation হিসেবে simple fixed values রাখা হয়েছে।

### PIN verification logic

```java
if (!user.isPinSet() || user.getPinHash() == null) {
    throw new IllegalArgumentException("PIN is not set.");
}
```

ব্যাখ্যা:

- PIN set না থাকলে verify করা যাবে না।
- hash না থাকলে backend verification সম্ভব নয়।

```java
if (user.getPinBlockedUntil() != null && user.getPinBlockedUntil().isAfter(now)) {
    return pinVerificationResponse(false, user);
}
```

ব্যাখ্যা:

- user already blocked থাকলে password hash compare করা হয় না।
- response-এ blocked time ফেরত যায়।

```java
if (passwordEncoder.matches(request.pin(), user.getPinHash())) {
    user.resetPinFailures();
    User savedUser = userRepository.save(user);
    return pinVerificationResponse(true, savedUser);
}
```

ব্যাখ্যা:

- `matches` raw request PIN ও stored BCrypt hash compare করে।
- correct হলে failed attempt reset হয়।
- verified true return হয়।

```java
user.recordWrongPinAttempt(MAX_PIN_ATTEMPTS, now.plus(PIN_BLOCK_MINUTES, ChronoUnit.MINUTES));
User savedUser = userRepository.save(user);
return pinVerificationResponse(false, savedUser);
```

ব্যাখ্যা:

- wrong PIN হলে failed attempt count বাড়ে।
- max attempt হলে block time set হয়।
- verified false return হয়।

### User entity helper methods

```java
public void recordWrongPinAttempt(int maxAttempts, Instant blockedUntil) {
    this.pinFailedAttempts += 1;
    if (this.pinFailedAttempts >= maxAttempts) {
        this.pinBlockedUntil = blockedUntil;
    }
}
```

ব্যাখ্যা:

- wrong attempt count increase করে।
- max attempt হলে block time set করে।

```java
public void resetPinFailures() {
    this.pinFailedAttempts = 0;
    this.pinBlockedUntil = null;
}
```

ব্যাখ্যা:

- correct PIN দিলে failed count reset করে।
- block time clear করে।

## 7. কেন authenticated JWT/Firebase UID ব্যবহার করা হয়েছে

PIN verification sensitive operation। Request body থেকে user ID নিলে অন্য user-এর PIN verify করার চেষ্টা হতে পারে। তাই backend JWT থেকে Firebase UID নিয়ে current user resolve করা হয়েছে।

## 8. কেন wallet/money API এখন করা হয়নি

PIN verification foundation money-changing API না। Wallet API করলে লাগবে:

- wallet balance
- immutable ledger
- transaction records
- idempotency key
- audit logs
- safe locking

তাই এই step শুধু PIN verification foundation।

## 9. UI sample image rule

User বলেছেন UI design শুরু করার আগে sample image দেবেন। তাই docs-এ note করা হয়েছে: Flutter UI design work শুরু করার আগে Codex user-এর কাছে sample/reference images চাইবে এবং সেগুলো visual direction হিসেবে ব্যবহার করবে।

## 10. SmartKash flow-তে এটি কীভাবে fit করে

1. User Firebase OTP দিয়ে login করে।
2. Backend JWT পায়।
3. User PIN setup করে।
4. User PIN verify করে।
5. Future money-changing API PIN verification require করবে।

## 11. Common mistakes and cautions

- Raw PIN log করা যাবে না।
- PIN hash response-এ দেওয়া যাবে না।
- `verify-pin` public করা যাবে না।
- user ID request body থেকে নেওয়া যাবে না।
- PIN block expired হলে future step-এ আরো refined behavior লাগতে পারে।
- এই endpoint এখনো money-changing confirmation হিসেবে কোনো transaction চালায় না।

## 12. Manual verification commands

Backend:

```cmd
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Optional runtime check:

```cmd
.\mvnw.cmd spring-boot:run
```

Database check:

```cmd
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
\d users
SELECT id, mobile_number, pin_set, pin_failed_attempts, pin_blocked_until FROM users;
```

General:

```cmd
cd /d D:\github\my-kash
git status
```

## 13. Git commands used

```cmd
git status --short --branch
git diff --check
git add <step-11-files>
git commit -m "step-11: add PIN verification foundation"
git push
```

## 14. এই step থেকে কী শিখলাম

এই step-এ শিখলাম PIN verify করার সময় raw PIN কখনো store/return করা যায় না। BCrypt `matches` দিয়ে raw PIN ও stored hash compare করতে হয়। Wrong attempt tracking এবং temporary block brute-force attack কমাতে সাহায্য করে। User ownership সবসময় JWT/Firebase UID থেকে resolve করা নিরাপদ।
