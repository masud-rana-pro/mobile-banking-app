# Step 07: User/Profile Database Foundation

## 1. Step title

Step 07 - SmartKash minimal user/profile database foundation.

## 2. কী implement করা হয়েছে

এই step-এ backend side-এ শুধু user/profile foundation তৈরি করা হয়েছে:

- Flyway migration দিয়ে `users` table তৈরি করা হয়েছে।
- Flyway migration দিয়ে `user_profiles` table তৈরি করা হয়েছে।
- `UserRole` এবং `UserStatus` enum তৈরি করা হয়েছে।
- `User` এবং `UserProfile` JPA entity তৈরি করা হয়েছে।
- `UserRepository` এবং `UserProfileRepository` তৈরি করা হয়েছে।
- API response DTO তৈরি করা হয়েছে।
- Entity থেকে DTO বানানোর জন্য mapper তৈরি করা হয়েছে।
- `UserService` এবং `UserServiceImpl` তৈরি করা হয়েছে।
- read-only `GET /api/users/me` endpoint তৈরি করা হয়েছে।
- `ResourceNotFoundException` এবং তার global handler যোগ করা হয়েছে।

এই step-এ wallet, ledger, transaction, PIN, admin business feature, add money, send money, payment, savings, loan, recharge কোনো কিছু implement করা হয়নি।

## 3. কেন user/profile database foundation দরকার

Firebase Phone Auth শুধু user-এর phone authentication করে। কিন্তু SmartKash-এর business data যেমন role, status, wallet, transaction, merchant profile, admin access এগুলো Firebase-এ রাখা হবে না। এগুলো PostgreSQL database-এ থাকবে।

তাই backend-এর নিজস্ব `users` table দরকার, যাতে Firebase identity-এর সাথে SmartKash-এর business user account link করা যায়।

## 4. কেন Firebase UID store করা হয়েছে

Firebase login successful হলে Firebase একটি unique UID দেয়। সেই UID দিয়ে backend বুঝবে কোন Firebase user কোন SmartKash database user-এর সাথে connected।

```sql
firebase_uid VARCHAR(128) NOT NULL
```

Block-by-block ব্যাখ্যা:

- `firebase_uid` হলো Firebase user-এর stable identity।
- `VARCHAR(128)` রাখা হয়েছে কারণ UID string হয়।
- `NOT NULL` মানে Firebase UID ছাড়া SmartKash user তৈরি হবে না।

```sql
CONSTRAINT uk_users_firebase_uid UNIQUE (firebase_uid)
```

ব্যাখ্যা:

- একই Firebase account দিয়ে একাধিক SmartKash user row তৈরি হওয়া আটকায়।
- Auth linking safe রাখে।

## 5. কেন mobile number unique হওয়া দরকার

SmartKash flow-তে Send Money receiver mobile number দিয়ে খুঁজে পাওয়া যাবে। তাই একই mobile number একাধিক user-এর হলে টাকা ভুল account-এ যেতে পারে।

```sql
mobile_number VARCHAR(32) NOT NULL
CONSTRAINT uk_users_mobile_number UNIQUE (mobile_number)
```

ব্যাখ্যা:

- `mobile_number` user-এর primary lookup identity হিসেবে কাজ করবে।
- `UNIQUE` duplicate account আটকায়।
- `VARCHAR(32)` country code সহ mobile number রাখার জন্য যথেষ্ট।

## 6. কেন role/status enum দরকার

Role দিয়ে user-এর type বোঝা যায়:

```java
public enum UserRole {
    CUSTOMER,
    MERCHANT,
    ADMIN
}
```

ব্যাখ্যা:

- `CUSTOMER` সাধারণ app user।
- `MERCHANT` merchant account, পরে payment receive করবে।
- `ADMIN` minimal admin panel/API access পাবে।

Status দিয়ে account usable কি না বোঝা যায়:

```java
public enum UserStatus {
    ACTIVE,
    BLOCKED,
    PENDING
}
```

ব্যাখ্যা:

- `ACTIVE` account ব্যবহার করা যাবে।
- `BLOCKED` account blocked; future money-changing action বন্ধ থাকবে।
- `PENDING` account এখনও fully ready না।

## 7. কেন Flyway migration ব্যবহার করা হয়েছে

Database table manually তৈরি করলে codebase আর database-এর history আলাদা হয়ে যায়। Flyway migration রাখলে কোন table কখন তৈরি হয়েছে সেটা Git history-তে থাকে।

```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    firebase_uid VARCHAR(128) NOT NULL,
    mobile_number VARCHAR(32) NOT NULL,
    role VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Block-by-block ব্যাখ্যা:

- `CREATE TABLE users` নতুন users table তৈরি করে।
- `id BIGSERIAL PRIMARY KEY` auto-increment numeric primary key।
- `firebase_uid` Firebase identity রাখে।
- `mobile_number` registered phone number রাখে।
- `role` user type রাখে।
- `status` account state রাখে।
- `created_at` row creation time রাখে।
- `updated_at` last update time রাখে।

```sql
CREATE TABLE user_profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    full_name VARCHAR(120),
    email VARCHAR(160),
    avatar_url VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_user_profiles_user_id UNIQUE (user_id),
    CONSTRAINT fk_user_profiles_user_id FOREIGN KEY (user_id) REFERENCES users (id)
);
```

Block-by-block ব্যাখ্যা:

- `user_profiles` table optional profile details রাখে।
- `user_id` দিয়ে profile কোন user-এর তা বোঝায়।
- `full_name`, `email`, `avatar_url` minimal profile field।
- `UNIQUE (user_id)` মানে এক user-এর একটি profile।
- `FOREIGN KEY` নিশ্চিত করে profile কোনো valid user ছাড়া তৈরি হবে না।

## 8. কেন wallet/ledger/business features implement করা হয়নি

এই step-এর scope শুধু identity foundation। Wallet বা ledger যোগ করলে money-changing architecture, locking, transaction boundary, idempotency, audit log সব একসাথে আসবে। সেটা বড় এবং riskier step হয়ে যাবে। তাই user/profile আগে, money foundation পরে।

## 9. কোন files/folders create বা change হয়েছে

- `services/backend/src/main/resources/db/migration/V1__create_user_profile_tables.sql`
- `services/backend/src/main/java/com/smartkash/user/enums/UserRole.java`
- `services/backend/src/main/java/com/smartkash/user/enums/UserStatus.java`
- `services/backend/src/main/java/com/smartkash/user/entity/User.java`
- `services/backend/src/main/java/com/smartkash/user/entity/UserProfile.java`
- `services/backend/src/main/java/com/smartkash/user/repository/UserRepository.java`
- `services/backend/src/main/java/com/smartkash/user/repository/UserProfileRepository.java`
- `services/backend/src/main/java/com/smartkash/user/dto/response/UserResponse.java`
- `services/backend/src/main/java/com/smartkash/user/dto/response/UserProfileResponse.java`
- `services/backend/src/main/java/com/smartkash/user/mapper/UserMapper.java`
- `services/backend/src/main/java/com/smartkash/user/service/UserService.java`
- `services/backend/src/main/java/com/smartkash/user/service/impl/UserServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/user/controller/UserController.java`
- `services/backend/src/main/java/com/smartkash/common/exception/ResourceNotFoundException.java`
- `services/backend/src/main/java/com/smartkash/common/exception/GlobalExceptionHandler.java`
- `docs/backend-api-plan.md`
- `docs/database-plan.md`
- `docs/codex-progress.md`

## 10. Important code/config snippets

### User entity

```java
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "firebase_uid", nullable = false, unique = true, length = 128)
    private String firebaseUid;

    @Column(name = "mobile_number", nullable = false, unique = true, length = 32)
    private String mobileNumber;
}
```

ব্যাখ্যা:

- `@Entity` class-টিকে JPA database entity বানায়।
- `@Table(name = "users")` entity কোন table-এর সাথে map হবে তা বলে।
- `@Id` primary key field।
- `@GeneratedValue(strategy = GenerationType.IDENTITY)` PostgreSQL identity/serial value use করবে।
- `@Column(... unique = true)` database uniqueness rule-এর সাথে entity mapping মেলায়।

### Role/status mapping

```java
@Enumerated(EnumType.STRING)
@Column(nullable = false, length = 32)
private UserRole role;
```

ব্যাখ্যা:

- `@Enumerated(EnumType.STRING)` enum database-এ text হিসেবে রাখে।
- এতে database value readable থাকে, যেমন `CUSTOMER`।
- ordinal number হিসেবে রাখলে enum order change করলে bug হতে পারে, তাই string ভালো।

### Repository

```java
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByFirebaseUid(String firebaseUid);
    boolean existsByFirebaseUid(String firebaseUid);
    boolean existsByMobileNumber(String mobileNumber);
}
```

ব্যাখ্যা:

- `JpaRepository<User, Long>` common CRUD method দেয়।
- `findByFirebaseUid` Firebase login identity থেকে persisted SmartKash user খুঁজবে।
- `existsByFirebaseUid` duplicate check করতে future step-এ কাজে লাগবে।
- `existsByMobileNumber` mobile duplicate check করতে কাজে লাগবে।

### Service

```java
@Transactional(readOnly = true)
public UserResponse getCurrentUser(JwtPrincipal principal) {
    User user = userRepository.findByFirebaseUid(principal.firebaseUid())
            .orElseThrow(() -> new ResourceNotFoundException("User profile is not created yet."));

    return userMapper.toResponse(user);
}
```

ব্যাখ্যা:

- `@Transactional(readOnly = true)` read-only database operation safe রাখে।
- `principal.firebaseUid()` backend JWT থেকে Firebase UID নেয়।
- `findByFirebaseUid` database user খুঁজে।
- user না পেলে `ResourceNotFoundException` throw করে।
- entity সরাসরি return না করে mapper দিয়ে DTO return করা হয়।

### Controller

```java
@GetMapping("/me")
public ResponseEntity<UserResponse> currentUser(@AuthenticationPrincipal JwtPrincipal principal) {
    return ResponseEntity.ok(userService.getCurrentUser(principal));
}
```

ব্যাখ্যা:

- `/api/users/me` endpoint current authenticated user profile read করে।
- `@AuthenticationPrincipal` Spring Security context থেকে JWT principal নেয়।
- Controller business logic রাখে না; service call করে।
- Response DTO হিসেবে `UserResponse` return করে।

## 11. DTO/mapper/service কেন আছে

- Entity database model, API response নয়।
- DTO API response shape ঠিক করে।
- Mapper entity থেকে DTO বানায়।
- Service business/read logic রাখে।
- Controller শুধু HTTP request/response handle করে।

এই separation future wallet, transaction, admin feature clean রাখতে সাহায্য করবে।

## 12. SmartKash auth flow-তে এটি কীভাবে fit করে

বর্তমান flow:

1. Flutter Firebase test OTP দিয়ে login করবে।
2. Flutter Firebase ID token backend-এ পাঠাবে।
3. Backend Firebase token verify করে backend JWT issue করবে।
4. Future step-এ backend Firebase UID দিয়ে `users` table-এ user create/find করবে।
5. এই step-এর `GET /api/users/me` সেই persisted user/profile read করার foundation।

## 13. Common mistakes and cautions

- `enum` নামে Java package বানানো যাবে না; `enum` Java keyword। তাই `enums` ব্যবহার করা হয়েছে।
- Entity সরাসরি API response হিসেবে return করা উচিত নয়।
- Firebase UID unique না করলে duplicate user তৈরি হতে পারে।
- Mobile number unique না করলে Send Money receiver ভুল হতে পারে।
- Flyway migration manually edit করলে already-applied migration mismatch হতে পারে।
- PIN field এই step-এ যোগ করা হয়নি, কারণ PIN security আলাদা dedicated step হবে।
- Wallet table এই step-এ যোগ করা হয়নি, কারণ wallet/ledger needs transaction, locking, idempotency, and audit design.

## 14. Manual verification commands

Backend:

```cmd
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Database check:

```cmd
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
\dt
SELECT * FROM flyway_schema_history;
```

General:

```cmd
cd /d D:\github\my-kash
git status
```

## 15. Git commands used in this step

```cmd
git status --short --branch
git diff -- services/backend/src/main/resources/application-local.yml
git status --short
git add <step-07-files>
git commit -m "step-07: add user profile database foundation"
git push
```

## 16. এই step থেকে কী শিখলাম

এই step-এ শিখলাম কীভাবে Firebase identity-কে backend database identity-এর সাথে যুক্ত করার foundation তৈরি করতে হয়। User/profile table, enum, entity, repository, DTO, mapper, service, controller আলাদা রাখলে project বড় হলেও structure clean থাকে। Flyway migration database history track করে, আর DTO API response কে entity থেকে আলাদা রাখে।
