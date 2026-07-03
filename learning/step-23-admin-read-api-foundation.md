# Step 23: Admin Read API Foundation

## 1. Step title

Step 23-এ SmartKash backend-এ minimal admin read API foundation তৈরি করা হয়েছে।

## 2. What was implemented

এই step-এ `/admin/**` routes শুধু `ADMIN` role-এর জন্য secure করা হয়েছে এবং read-only admin endpoints যোগ করা হয়েছে:

- `GET /admin/users`
- `GET /admin/transactions`
- `GET /admin/add-money/requests`
- `GET /admin/loans/requests`
- `GET /admin/recharges`
- `GET /admin/payments`
- `GET /admin/audit-logs`

আরও যোগ হয়েছে:

- `AdminReadController`
- `AdminReadService`
- `AdminReadServiceImpl`
- `AdminAuditLogResponse`
- `AdminAuditLogMapper`
- repository read methods
- security config update

## 3. Why this step is needed

Admin panel বা admin API ছাড়া Add Money request, Loan request, user list, transaction list, audit logs দেখা যাবে না। MVP-তে full dashboard দরকার নেই, কিন্তু minimal read endpoints দরকার যাতে admin future approval/rejection কাজ করার আগে data দেখতে পারে।

## 4. Why this is read-only

এই step admin approval/rejection করে না। কোনো wallet balance change করে না। কোনো transaction বা ledger create করে না। কারণ approval/rejection future money-changing step হতে পারে এবং সেখানে PIN/idempotency/wallet locking/ledger/audit rules carefully লাগবে।

## 5. Files/folders changed

- `services/backend/src/main/java/com/smartkash/security/SecurityConfig.java`
- `services/backend/src/main/java/com/smartkash/admin/controller/AdminReadController.java`
- `services/backend/src/main/java/com/smartkash/admin/service/AdminReadService.java`
- `services/backend/src/main/java/com/smartkash/admin/service/impl/AdminReadServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/admin/dto/response/AdminAuditLogResponse.java`
- `services/backend/src/main/java/com/smartkash/admin/mapper/AdminAuditLogMapper.java`
- `services/backend/src/main/java/com/smartkash/addmoney/repository/AddMoneyRequestRepository.java`
- `services/backend/src/main/java/com/smartkash/loan/repository/LoanRequestRepository.java`
- `services/backend/src/main/java/com/smartkash/recharge/repository/MobileRechargeRepository.java`
- `services/backend/src/main/java/com/smartkash/transaction/repository/TransactionRecordRepository.java`
- `services/backend/src/main/java/com/smartkash/audit/repository/AdminAuditLogRepository.java`
- `docs/backend-api-plan.md`
- `docs/codex-progress.md`

## 6. Important security snippet

```java
.authorizeHttpRequests(auth -> auth
        .requestMatchers(
                "/api/auth/firebase-login",
                "/actuator/health",
                "/actuator/info",
                "/v3/api-docs/**",
                "/swagger-ui/**",
                "/swagger-ui.html"
        ).permitAll()
        .requestMatchers("/admin/**").hasRole("ADMIN")
        .anyRequest().authenticated()
)
```

### Security explanation

- `permitAll()`: login, health, swagger docs public থাকে।
- `.requestMatchers("/admin/**").hasRole("ADMIN")`: admin route access করতে JWT role অবশ্যই `ADMIN` হতে হবে।
- `.anyRequest().authenticated()`: অন্য API গুলো login করা user ছাড়া access করা যাবে না।
- Spring Security internally `hasRole("ADMIN")` মানে `ROLE_ADMIN` authority check করে।

## 7. Important controller snippet

```java
@RestController
@RequestMapping("/admin")
public class AdminReadController {
```

- `@RestController`: REST API controller।
- `@RequestMapping("/admin")`: সব admin route `/admin` দিয়ে শুরু।

```java
@GetMapping("/users")
public ResponseEntity<List<UserResponse>> users() {
    return ResponseEntity.ok(adminReadService.getUsers());
}
```

- `GET /admin/users` user list return করে।
- Controller business logic করে না; service call করে।

```java
@GetMapping("/payments")
public ResponseEntity<List<Object>> payments() {
    return ResponseEntity.ok(adminReadService.getPayments());
}
```

Payment persistence এখনো নেই, তাই এই endpoint এখন empty list return করে। Future merchant payment table/API হলে এটা real response DTO দেবে।

## 8. Important service snippet

```java
@Transactional(readOnly = true)
public List<TransactionResponse> getTransactions() {
    return transactionRecordRepository.findAllByOrderByCreatedAtDesc()
            .stream()
            .map(transactionRecordMapper::toResponse)
            .toList();
}
```

- `@Transactional(readOnly = true)`: database write হবে না।
- `findAllByOrderByCreatedAtDesc()`: newest transaction আগে আসে।
- `map(transactionRecordMapper::toResponse)`: entity সরাসরি response না দিয়ে DTO বানায়।

```java
public List<Object> getPayments() {
    return List.of();
}
```

এই method intentionally empty list দেয়, কারণ merchant payment feature এখনো persistence তৈরি করেনি।

## 9. Important audit mapper snippet

```java
public AdminAuditLogResponse toResponse(AdminAuditLog auditLog) {
    User adminUser = auditLog.getAdminUser();
    return new AdminAuditLogResponse(
            auditLog.getId(),
            adminUser.getId(),
            adminUser.getMobileNumber(),
            auditLog.getAction(),
            auditLog.getTargetType(),
            auditLog.getTargetId(),
            auditLog.getDetails(),
            auditLog.getCreatedAt()
    );
}
```

Audit log entity থেকে admin-friendly response তৈরি করে। এতে কোন admin user action করেছে তা দেখা যাবে।

## 10. Repository methods

```java
List<AddMoneyRequest> findAllByOrderByCreatedAtDesc();
List<LoanRequest> findAllByOrderByCreatedAtDesc();
List<MobileRecharge> findAllByOrderByCreatedAtDesc();
List<TransactionRecord> findAllByOrderByCreatedAtDesc();
List<AdminAuditLog> findAllByOrderByCreatedAtDesc();
```

এই methods admin list views-এ newest-first data দেখানোর জন্য।

## 11. How this works in SmartKash flow

1. Admin Firebase login করে backend JWT পাবে, যেখানে role `ADMIN`।
2. Admin `/admin/users` বা `/admin/add-money/requests` call করবে।
3. Spring Security `/admin/**` route-এ `ADMIN` role check করবে।
4. Role ঠিক হলে controller service call করবে।
5. Service repository থেকে data read করে DTO response return করবে।

## 12. Common mistakes and cautions

- Customer/Merchant JWT দিয়ে `/admin/**` call করলে `403 Forbidden` হওয়া উচিত।
- Admin endpoint-এ approval/rejection logic accidentally যোগ করা যাবে না।
- Admin list API দিয়ে wallet balance mutate করা যাবে না।
- Entity সরাসরি response হিসেবে return করা যাবে না।
- `application-local.yml` commit করা যাবে না।
- Payment endpoint এখন empty list দেবে; এটা expected।

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

API security check:

```http
GET /admin/users
Authorization: Bearer <customer-or-merchant-jwt>
```

Expected output:

- HTTP `403 Forbidden`

```http
GET /admin/users
Authorization: Bearer <admin-jwt>
```

Expected output:

- HTTP `200 OK`
- users list আসবে।

Admin read endpoints:

```http
GET /admin/transactions
GET /admin/add-money/requests
GET /admin/loans/requests
GET /admin/recharges
GET /admin/payments
GET /admin/audit-logs
Authorization: Bearer <admin-jwt>
```

Expected output:

- HTTP `200 OK`
- data না থাকলে `[]`
- `/admin/payments` এখন `[]` return করবে, কারণ payment persistence এখনো future scope।

Database check:

```powershell
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
\dt
SELECT * FROM admin_audit_logs ORDER BY created_at DESC LIMIT 5;
```

Expected output:

- Existing tables দেখা যাবে।
- audit log table empty হতে পারে, কারণ admin state-changing action এখনো নেই।

## 14. Git commands used

```powershell
git status --short --branch
git diff --check
git add <step-23-files>
git commit -m "step-23: add admin read api foundation"
git push
```

## 15. What I learned

এই step-এ শিখলাম কীভাবে Spring Security দিয়ে admin route protect করতে হয়, কীভাবে read-only admin APIs বানাতে হয়, এবং কেন admin state-changing actions আলাদা controlled step-এ করা উচিত।
