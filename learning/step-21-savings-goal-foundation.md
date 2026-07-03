# Step 21: Savings Goal Foundation

## 1. Step title

Step 21-এ SmartKash backend-এ savings goal foundation তৈরি করা হয়েছে।

## 2. What was implemented

এই step-এ user নিজের savings goal তৈরি এবং list করতে পারবে:

- `savings_goals` database table
- `SavingsGoalStatus` enum
- `SavingsGoal` JPA entity
- `SavingsGoalRepository`
- request/response DTO
- mapper
- service interface ও implementation
- thin controller
- authenticated APIs:
  - `POST /api/savings/goals`
  - `GET /api/savings/goals`

## 3. Why this step is needed

SmartKash-এ Goal Savings feature থাকবে। User আগে goal তৈরি করবে, যেমন “Laptop Fund” বা “Emergency Fund”। কিন্তু goal তৈরি করা money movement নয়। তাই এই step-এ শুধু goal record তৈরি করা হয়েছে; deposit পরে আলাদা step-এ হবে।

## 4. Why savings deposit is not implemented yet

Savings deposit করলে wallet থেকে টাকা savings goal-এ যাবে। তাই সেটা money-changing operation। এর জন্য PIN confirmation, idempotency key, wallet lock, transaction record, immutable ledger entry লাগবে। এই step focused রাখতে deposit API implement করা হয়নি।

## 5. Files/folders changed

- `services/backend/src/main/resources/db/migration/V12__create_savings_goals.sql`
- `services/backend/src/main/java/com/smartkash/savings/enums/SavingsGoalStatus.java`
- `services/backend/src/main/java/com/smartkash/savings/entity/SavingsGoal.java`
- `services/backend/src/main/java/com/smartkash/savings/repository/SavingsGoalRepository.java`
- `services/backend/src/main/java/com/smartkash/savings/dto/request/CreateSavingsGoalRequest.java`
- `services/backend/src/main/java/com/smartkash/savings/dto/response/SavingsGoalResponse.java`
- `services/backend/src/main/java/com/smartkash/savings/mapper/SavingsGoalMapper.java`
- `services/backend/src/main/java/com/smartkash/savings/service/SavingsGoalService.java`
- `services/backend/src/main/java/com/smartkash/savings/service/impl/SavingsGoalServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/savings/controller/SavingsGoalController.java`
- `docs/database-plan.md`
- `docs/backend-api-plan.md`
- `docs/codex-progress.md`

## 6. Important migration snippet

```sql
CREATE TABLE savings_goals (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    target_amount NUMERIC(19, 2) NOT NULL,
    current_amount NUMERIC(19, 2) NOT NULL DEFAULT 0.00,
    target_date DATE,
    status VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### Migration explanation

- `CREATE TABLE savings_goals`: savings goal রাখার table তৈরি করে।
- `id BIGSERIAL PRIMARY KEY`: প্রতিটি goal-এর unique ID।
- `user_id BIGINT NOT NULL`: goal কোন user-এর সেটা বোঝায়।
- `name VARCHAR(100)`: goal name, যেমন “Laptop Fund”।
- `target_amount NUMERIC(19, 2)`: user কত টাকা জমাতে চায়।
- `current_amount NUMERIC(19, 2) DEFAULT 0.00`: goal তৈরির সময় জমা থাকে 0 টাকা।
- `target_date DATE`: optional deadline।
- `status VARCHAR(32)`: `ACTIVE`, `COMPLETED`, বা `CANCELLED`।
- `created_at`, `updated_at`: audit/timeline tracking।

```sql
CONSTRAINT fk_savings_goals_user_id
    FOREIGN KEY (user_id) REFERENCES users (id)
```

এই constraint নিশ্চিত করে savings goal কোনো existing user-এর সাথে linked।

```sql
CONSTRAINT chk_savings_goals_target_amount_positive
    CHECK (target_amount > 0)
```

Target amount অবশ্যই 0-এর বেশি হতে হবে।

```sql
CONSTRAINT chk_savings_goals_current_amount_non_negative
    CHECK (current_amount >= 0)
```

Current amount negative হতে পারবে না।

## 7. Important enum snippet

```java
public enum SavingsGoalStatus {
    ACTIVE,
    COMPLETED,
    CANCELLED
}
```

- `ACTIVE`: goal চালু আছে।
- `COMPLETED`: future deposit flow-তে target পূরণ হলে ব্যবহার হবে।
- `CANCELLED`: user/admin পরে goal cancel করলে ব্যবহার হতে পারে।

## 8. Important entity snippet

```java
@Entity
@Table(name = "savings_goals")
public class SavingsGoal {
```

- `@Entity`: class-টি JPA database entity।
- `@Table`: entity কোন database table map করে।

```java
@ManyToOne(fetch = FetchType.LAZY, optional = false)
@JoinColumn(name = "user_id", nullable = false)
private User user;
```

একজন user-এর একাধিক savings goal থাকতে পারে। তাই `ManyToOne` relation ব্যবহার করা হয়েছে।

```java
public SavingsGoal(User user, String name, BigDecimal targetAmount, LocalDate targetDate) {
    this.user = user;
    this.name = name;
    this.targetAmount = targetAmount;
    this.targetDate = targetDate;
    this.currentAmount = BigDecimal.ZERO;
    this.status = SavingsGoalStatus.ACTIVE;
}
```

নতুন goal তৈরি হলে current amount 0 এবং status `ACTIVE` হয়। এখানে wallet balance change করা হয়নি।

## 9. Important request DTO snippet

```java
public record CreateSavingsGoalRequest(
        @NotBlank(message = "Savings goal name is required.")
        @Size(max = 100, message = "Savings goal name must be 100 characters or less.")
        String name,

        @NotNull(message = "Target amount is required.")
        @DecimalMin(value = "1.00", message = "Target amount must be at least 1.00.")
        BigDecimal targetAmount,

        @Future(message = "Target date must be in the future.")
        LocalDate targetDate
) {
}
```

- `@NotBlank`: name খালি হতে পারবে না।
- `@Size`: name 100 character-এর বেশি হবে না।
- `@NotNull`: target amount অবশ্যই দিতে হবে।
- `@DecimalMin`: target amount কমপক্ষে 1.00।
- `@Future`: target date দিলে future date হতে হবে।

## 10. Important service snippet

```java
@Transactional
public SavingsGoalResponse createCurrentUserGoal(JwtPrincipal principal, CreateSavingsGoalRequest request) {
    User user = currentUser(principal);
    ensureActiveUser(user);
    SavingsGoal goal = new SavingsGoal(
            user,
            request.name(),
            request.targetAmount(),
            request.targetDate()
    );
    return savingsGoalMapper.toResponse(savingsGoalRepository.save(goal));
}
```

- `@Transactional`: save operation একটি transaction-এর মধ্যে হয়।
- `currentUser(principal)`: JWT থেকে current user resolve করে।
- `ensureActiveUser(user)`: only ACTIVE user goal create করতে পারবে।
- `new SavingsGoal(...)`: নতুন goal entity তৈরি করে।
- `save(goal)`: database-এ save করে।
- `mapper.toResponse(...)`: entity না দিয়ে response DTO return করে।

## 11. Important controller snippet

```java
@PostMapping
public ResponseEntity<SavingsGoalResponse> createGoal(
        @AuthenticationPrincipal JwtPrincipal principal,
        @Valid @RequestBody CreateSavingsGoalRequest request
) {
    return ResponseEntity.status(HttpStatus.CREATED)
            .body(savingsGoalService.createCurrentUserGoal(principal, request));
}
```

- `POST /api/savings/goals` endpoint তৈরি করে।
- authenticated user principal নেয়।
- request validation চালায়।
- controller নিজে logic না করে service call করে।

## 12. How this works in SmartKash flow

1. User Firebase login করে backend JWT পায়।
2. User savings goal create request পাঠায়।
3. Backend JWT থেকে user খুঁজে।
4. Backend user active কিনা check করে।
5. Backend `savings_goals` table-এ goal save করে।
6. Response-এ goal details ফেরত দেয়।

## 13. Common mistakes and cautions

- Savings goal create করা আর savings deposit এক জিনিস না।
- এই step-এ wallet balance touch করা যাবে না।
- Deposit endpoint বানানো যাবে না, কারণ সেটা money-changing API।
- `current_amount` manually request body থেকে নেওয়া যাবে না।
- Entity সরাসরি API response হিসেবে return করা যাবে না।
- `application-local.yml` commit করা যাবে না।

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
\d savings_goals
SELECT * FROM flyway_schema_history;
```

Expected output:

- `savings_goals` table দেখা যাবে।
- columns থাকবে: `id`, `user_id`, `name`, `target_amount`, `current_amount`, `target_date`, `status`, `created_at`, `updated_at`।
- Flyway history-তে `V12__create_savings_goals.sql` success হিসেবে দেখা যাবে।

API check:

```http
POST /api/savings/goals
Authorization: Bearer <backend-jwt>
Content-Type: application/json

{
  "name": "Laptop Fund",
  "targetAmount": 50000,
  "targetDate": "2026-12-31"
}
```

Expected output:

- HTTP `201 Created`
- response body-তে `status` হবে `ACTIVE`
- `currentAmount` হবে `0`

```http
GET /api/savings/goals
Authorization: Bearer <backend-jwt>
```

Expected output:

- HTTP `200 OK`
- current user-এর savings goals list আসবে।

## 15. Git commands used

```powershell
git status --short --branch
git diff --check
git add <step-21-files>
git commit -m "step-21: add savings goal foundation"
git push
```

## 16. What I learned

এই step-এ শিখলাম কীভাবে money movement ছাড়া savings goal foundation তৈরি করা যায়। Goal create/list safe foundation, আর real deposit আলাদা money-changing step হিসেবে PIN/idempotency/ledger সহ করা উচিত।
