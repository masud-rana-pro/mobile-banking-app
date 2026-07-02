# Step 10: PIN Setup Foundation

## 1. Step title

Step 10 - SmartKash backend PIN setup foundation.

## 2. কী implement করা হয়েছে

এই step-এ শুধু backend PIN setup foundation যোগ করা হয়েছে:

- `users` table-এ PIN-related fields যোগ করার জন্য Flyway migration তৈরি করা হয়েছে।
- `pin_hash`, `pin_set`, `pin_updated_at` fields যোগ করা হয়েছে।
- `POST /api/auth/set-pin` endpoint যোগ করা হয়েছে।
- Endpoint authenticated backend JWT ছাড়া accessible নয়।
- Request body-তে `pin` এবং `confirmPin` নেওয়া হয়েছে।
- PIN exactly 5 digit numeric হতে হবে।
- `pin` এবং `confirmPin` match না করলে request reject হয়।
- PIN BCrypt দিয়ে backend-এ hash করে save করা হয়।
- Raw PIN database, response, log কোথাও রাখা হয়নি।

এই step-এ PIN verification, rate limiting, temporary block, wallet, ledger, transaction, add money, send money, payment, savings, loan, recharge, admin business feature বা money-changing API যোগ করা হয়নি।

## 3. কেন PIN setup দরকার

SmartKash-এর future money-changing operation যেমন Send Money, Payment, Add Money approval, Savings Deposit, Recharge এগুলোতে user confirmation দরকার হবে। Mobile financial app flow-তে PIN হলো user-এর transaction confirmation secret।

এই step-এ শুধু PIN set করার foundation করা হয়েছে, যাতে পরে PIN verification এবং money-changing API নিরাপদভাবে build করা যায়।

## 4. কেন raw PIN কখনো store করা যাবে না

Raw PIN database-এ থাকলে database leak হলে user-এর PIN সরাসরি expose হয়ে যাবে। তাই raw PIN:

- database-এ রাখা যাবে না
- API response-এ ফেরত দেওয়া যাবে না
- log করা যাবে না
- Flutter app-এ save করা যাবে না

শুধু hash store করা হবে।

## 5. কেন backend-এ PIN hash করা হয়েছে

PIN security backend responsibility। Flutter app raw PIN শুধু secure API request হিসেবে পাঠাবে। Backend PIN validate করে hash করবে। এতে:

- database raw PIN জানে না
- frontend PIN store করে না
- hashing rule backend-controlled থাকে
- future PIN verification backend-only করা যাবে

## 6. কেন authenticated JWT/Firebase UID ব্যবহার করা হয়েছে

`POST /api/auth/set-pin` user ID নেয় না। Backend JWT থেকে `JwtPrincipal` নেয়, তারপর `principal.firebaseUid()` দিয়ে current user খুঁজে।

এতে এক user অন্য user-এর PIN set করতে পারে না।

## 7. কেন request body থেকে user ID নেওয়া হয়নি

PIN খুব sensitive field। যদি request body থেকে `userId` নেওয়া হয়, malicious user অন্য user ID পাঠিয়ে অন্য account-এর PIN set করার চেষ্টা করতে পারে। তাই request body-তে শুধু:

- `pin`
- `confirmPin`

থাকে। Ownership JWT/Firebase UID থেকে আসে।

## 8. কোন files/folders create বা change হয়েছে

- `services/backend/src/main/resources/db/migration/V2__add_user_pin_fields.sql`
- `services/backend/src/main/java/com/smartkash/auth/dto/request/SetPinRequest.java`
- `services/backend/src/main/java/com/smartkash/auth/dto/response/PinSetupResponse.java`
- `services/backend/src/main/java/com/smartkash/auth/controller/AuthController.java`
- `services/backend/src/main/java/com/smartkash/auth/service/AuthService.java`
- `services/backend/src/main/java/com/smartkash/auth/service/impl/AuthServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/security/SecurityConfig.java`
- `services/backend/src/main/java/com/smartkash/user/entity/User.java`
- `docs/backend-api-plan.md`
- `docs/security-plan.md`
- `docs/database-plan.md`
- `docs/codex-progress.md`
- `learning/step-10-pin-setup-foundation.md`

## 9. Important code/config snippets

### Flyway migration

```sql
ALTER TABLE users
    ADD COLUMN pin_hash VARCHAR(255),
    ADD COLUMN pin_set BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN pin_updated_at TIMESTAMPTZ;
```

Line-by-line Bangla ব্যাখ্যা:

- `ALTER TABLE users` existing `users` table change করে।
- `pin_hash VARCHAR(255)` BCrypt hash রাখার জন্য field যোগ করে।
- raw PIN নয়, শুধু hash store হবে।
- `pin_set BOOLEAN NOT NULL DEFAULT FALSE` user PIN set করেছে কি না track করে।
- `DEFAULT FALSE` existing user rows safe রাখে।
- `pin_updated_at TIMESTAMPTZ` PIN কখন set/update হয়েছে তা রাখে।

### Request DTO

```java
public record SetPinRequest(
        @NotBlank(message = "PIN is required.")
        @Pattern(regexp = "\\d{5}", message = "PIN must be exactly 5 digits.")
        String pin,

        @NotBlank(message = "Confirm PIN is required.")
        @Pattern(regexp = "\\d{5}", message = "Confirm PIN must be exactly 5 digits.")
        String confirmPin
) {
}
```

Block-by-block Bangla ব্যাখ্যা:

- `record` immutable request DTO তৈরি করে।
- `pin` user-এর new PIN নেয়।
- `@NotBlank` empty PIN আটকায়।
- `@Pattern(regexp = "\\d{5}")` exactly 5 numeric digit enforce করে।
- `confirmPin` confirmation হিসেবে নেয়।
- confirm PIN-তেও একই validation দেওয়া হয়েছে।
- এই DTO-তে `userId` নেই, কারণ user JWT থেকে resolve হয়।

কেন 5 digit:

- MVP-তে 5 digit PIN simple এবং mobile financial app-style flow-এর সাথে পরিচিত।
- Future-এ policy বদলালে validation pattern update করা যাবে।

### Response DTO

```java
public record PinSetupResponse(
        boolean pinSet,
        Instant pinUpdatedAt
) {
}
```

ব্যাখ্যা:

- `pinSet` frontend-কে বলে PIN setup হয়েছে।
- `pinUpdatedAt` কখন PIN update হয়েছে তা বলে।
- raw PIN বা PIN hash response-এ নেই।

### Controller endpoint

```java
@PostMapping("/set-pin")
public ResponseEntity<PinSetupResponse> setPin(
        @AuthenticationPrincipal JwtPrincipal principal,
        @Valid @RequestBody SetPinRequest request
) {
    return ResponseEntity.ok(authService.setPin(principal, request));
}
```

Line-by-line Bangla ব্যাখ্যা:

- `@PostMapping("/set-pin")` endpoint path হলো `POST /api/auth/set-pin`।
- `@AuthenticationPrincipal JwtPrincipal principal` authenticated JWT user নেয়।
- `@Valid` request validation চালায়।
- `@RequestBody SetPinRequest` JSON body থেকে PIN request নেয়।
- Controller business logic করে না।
- `authService.setPin(...)` service layer-এ কাজ পাঠায়।

### Service PIN hashing logic

```java
@Transactional
public PinSetupResponse setPin(JwtPrincipal principal, SetPinRequest request) {
    if (!request.pin().equals(request.confirmPin())) {
        throw new IllegalArgumentException("PIN and confirm PIN must match.");
    }

    User user = userRepository.findByFirebaseUid(principal.firebaseUid())
            .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));

    user.setPinHash(passwordEncoder.encode(request.pin()));
    User savedUser = userRepository.save(user);

    return new PinSetupResponse(savedUser.isPinSet(), savedUser.getPinUpdatedAt());
}
```

Block-by-block Bangla ব্যাখ্যা:

- `@Transactional` PIN update এক database transaction-এ রাখে।
- `pin` এবং `confirmPin` match না করলে error throw করে।
- `principal.firebaseUid()` দিয়ে authenticated user খোঁজা হয়।
- request body থেকে user ID নেওয়া হয়নি।
- `passwordEncoder.encode(request.pin())` raw PIN কে BCrypt hash করে।
- `user.setPinHash(...)` hash entity-তে set করে এবং metadata update করে।
- `userRepository.save(user)` database update করে।
- response শুধু `pinSet` এবং `pinUpdatedAt` দেয়।

### User entity changes

```java
@Column(name = "pin_hash", length = 255)
private String pinHash;

@Column(name = "pin_set", nullable = false)
private boolean pinSet;

@Column(name = "pin_updated_at")
private Instant pinUpdatedAt;
```

ব্যাখ্যা:

- `pinHash` BCrypt hash রাখে।
- `pinSet` PIN setup status রাখে।
- `pinUpdatedAt` PIN update timestamp রাখে।

```java
public void setPinHash(String pinHash) {
    this.pinHash = pinHash;
    this.pinSet = true;
    this.pinUpdatedAt = Instant.now();
}
```

ব্যাখ্যা:

- method-এর নাম hash set করছে, raw PIN নয়।
- hash set হলে `pinSet` true হয়।
- একই সঙ্গে timestamp update হয়।

### PasswordEncoder config

```java
@Bean
PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}
```

ব্যাখ্যা:

- Spring bean হিসেবে `PasswordEncoder` register করা হয়েছে।
- `BCryptPasswordEncoder` one-way hash তৈরি করে।
- একই raw PIN বারবার hash করলে আলাদা hash হতে পারে, কারণ BCrypt salt use করে।
- Future PIN verification-এ `passwordEncoder.matches(rawPin, pinHash)` ব্যবহার করা যাবে।

### Security config change

```java
.requestMatchers(
        "/api/auth/firebase-login",
        "/actuator/health",
        "/actuator/info",
        "/v3/api-docs/**",
        "/swagger-ui/**",
        "/swagger-ui.html"
).permitAll()
```

ব্যাখ্যা:

- আগে `/api/auth/**` public ছিল।
- এখন শুধু `/api/auth/firebase-login` public।
- `/api/auth/set-pin` authenticated JWT ছাড়া access করা যাবে না।
- Health/docs endpoints public রাখা হয়েছে development convenience-এর জন্য।

## 10. কেন PIN verification/rate limit/money-changing features এখন করা হয়নি

এই step-এর scope শুধু PIN setup। Verification এবং rate limit আলাদা step হওয়া উচিত, কারণ সেখানে:

- wrong PIN attempt count
- temporary block
- backend-only verification
- money-changing API guard

এসব design লাগবে। Wallet/money API যোগ করলে ledger, transaction, idempotency, audit log সব একসাথে আসবে, তাই এখন করা হয়নি।

## 11. SmartKash auth/security flow-তে এটি কীভাবে fit করে

1. User Firebase test OTP দিয়ে login করে।
2. Backend Firebase token verify করে user create/find করে।
3. Backend JWT issue করে।
4. User JWT দিয়ে `POST /api/auth/set-pin` call করে।
5. Backend JWT Firebase UID দিয়ে user খুঁজে।
6. Backend PIN validate করে BCrypt hash save করে।
7. Future money-changing API PIN verify করবে।

## 12. Common mistakes and cautions

- Raw PIN database-এ রাখা যাবে না।
- Raw PIN API response-এ দেওয়া যাবে না।
- Raw PIN log করা যাবে না।
- `set-pin` endpoint public রাখা যাবে না।
- Request body-তে user ID নেওয়া যাবে না।
- PIN hash frontend-এ পাঠানো যাবে না।
- Local `application-local.yml` commit করা যাবে না।
- PIN verification এই step-এ নেই, তাই এই endpoint দিয়ে money transaction secure হয়েছে ধরে নেওয়া যাবে না।

## 13. Manual verification commands

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
SELECT id, mobile_number, pin_set, pin_updated_at FROM users;
```

General:

```cmd
cd /d D:\github\my-kash
git status
```

## 14. Git commands used

```cmd
git status --short --branch
git diff --check
git add <step-10-files>
git commit -m "step-10: add PIN setup foundation"
git push
```

## 15. এই step থেকে কী শিখলাম

এই step-এ শিখলাম PIN setup করতে raw PIN কখনো store করা যায় না। Backend JWT দিয়ে current user resolve করতে হয়, request body থেকে user ID নেওয়া নিরাপদ নয়। BCrypt `PasswordEncoder` দিয়ে PIN hash করলে database leak হলেও raw PIN জানা যায় না। তবে PIN setup আর PIN verification আলাদা concern, তাই verification/rate limit future step-এ করা হবে।
