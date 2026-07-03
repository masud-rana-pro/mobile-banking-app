# Step 12: Wallet Database Foundation

## 1. Step title

Step 12 - SmartKash wallet database/read foundation.

## 2. কী implement করা হয়েছে

এই step-এ wallet foundation তৈরি করা হয়েছে:

- `wallets` table-এর জন্য Flyway migration যোগ করা হয়েছে।
- `WalletStatus` enum তৈরি করা হয়েছে।
- `Wallet` JPA entity তৈরি করা হয়েছে।
- `WalletRepository` তৈরি করা হয়েছে।
- `WalletResponse` DTO তৈরি করা হয়েছে।
- `WalletMapper` তৈরি করা হয়েছে।
- `WalletService` এবং `WalletServiceImpl` তৈরি করা হয়েছে।
- read-only `GET /api/wallet/me` endpoint তৈরি করা হয়েছে।

এই step-এ wallet auto-create, balance add/subtract, ledger entry, transaction record, add money, send money, payment, savings, recharge, loan, বা money-changing API implement করা হয়নি।

## 3. কেন wallet database foundation দরকার

SmartKash app-এর core হলো wallet balance। কিন্তু balance update করা risky কাজ, কারণ প্রতিটি balance change immutable ledger এবং transaction record দিয়ে backed হতে হবে। তাই প্রথমে wallet read model এবং database structure তৈরি করা হয়েছে।

## 4. Wallet table migration

```sql
CREATE TABLE wallets (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    balance NUMERIC(19, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    status VARCHAR(32) NOT NULL,
    version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_wallets_user_id UNIQUE (user_id),
    CONSTRAINT fk_wallets_user_id FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT chk_wallets_balance_non_negative CHECK (balance >= 0),
    CONSTRAINT chk_wallets_status CHECK (status IN ('ACTIVE', 'BLOCKED'))
);
```

Block-by-block Bangla ব্যাখ্যা:

- `wallets` table user wallet data রাখে।
- `id BIGSERIAL PRIMARY KEY` wallet row-এর primary key।
- `user_id BIGINT NOT NULL` wallet কোন user-এর তা বোঝায়।
- `balance NUMERIC(19, 2)` টাকা decimal হিসেবে রাখে।
- `DEFAULT 0.00` নতুন wallet balance zero হবে।
- `currency VARCHAR(3)` currency code, MVP-তে `BDT`।
- `status` wallet active/blocked কিনা বোঝায়।
- `version` optimistic locking-এর জন্য রাখা হয়েছে।
- `created_at` এবং `updated_at` timestamp রাখে।
- `UNIQUE (user_id)` এক user-এর একটাই wallet নিশ্চিত করে।
- `FOREIGN KEY` নিশ্চিত করে wallet valid user ছাড়া তৈরি হবে না।
- `CHECK (balance >= 0)` negative balance আটকায়।
- `CHECK status` invalid wallet status আটকায়।

## 5. কেন optimistic version field রাখা হয়েছে

```java
@Version
@Column(nullable = false)
private Long version;
```

ব্যাখ্যা:

- Future money-changing operation একই wallet একসাথে update করতে পারে।
- `@Version` optimistic locking enable করে।
- Concurrent update conflict হলে Hibernate detect করতে পারবে।
- এই step-এ balance mutation নেই, কিন্তু future safe update-এর জন্য foundation তৈরি হলো।

## 6. WalletStatus enum

```java
public enum WalletStatus {
    ACTIVE,
    BLOCKED
}
```

ব্যাখ্যা:

- `ACTIVE` wallet normal use-এর জন্য।
- `BLOCKED` wallet blocked হলে future money-changing operation বন্ধ থাকবে।

## 7. Wallet entity

```java
@Entity
@Table(name = "wallets")
public class Wallet {
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;
}
```

ব্যাখ্যা:

- `@Entity` JPA entity।
- `@Table(name = "wallets")` database table map করে।
- `@OneToOne` এক user-এর এক wallet relation।
- `FetchType.LAZY` user data প্রয়োজন না হলে load করবে না।
- `@JoinColumn(name = "user_id")` wallets table-এর FK column।

## 8. Wallet repository

```java
public interface WalletRepository extends JpaRepository<Wallet, Long> {
    Optional<Wallet> findByUserId(Long userId);
    boolean existsByUserId(Long userId);
}
```

ব্যাখ্যা:

- `JpaRepository` common database methods দেয়।
- `findByUserId` current user-এর wallet খুঁজতে ব্যবহার হয়।
- `existsByUserId` future wallet creation duplicate check-এ লাগতে পারে।

## 9. Wallet response DTO

```java
public record WalletResponse(
        Long id,
        Long userId,
        BigDecimal balance,
        String currency,
        WalletStatus status,
        Instant createdAt,
        Instant updatedAt
) {
}
```

ব্যাখ্যা:

- API response entity নয়, DTO।
- `balance` read-only ভাবে দেখানো হয়।
- `currency` future multi-currency consideration সহজ করে।
- `status` wallet active/blocked কিনা জানায়।
- ledger/transaction data এখানে নেই।

## 10. Wallet service

```java
@Transactional(readOnly = true)
public WalletResponse getCurrentUserWallet(JwtPrincipal principal) {
    User user = userRepository.findByFirebaseUid(principal.firebaseUid())
            .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));

    Wallet wallet = walletRepository.findByUserId(user.getId())
            .orElseThrow(() -> new ResourceNotFoundException("Wallet is not created yet."));

    return walletMapper.toResponse(wallet);
}
```

Line-by-line Bangla ব্যাখ্যা:

- `@Transactional(readOnly = true)` read-only database operation।
- `principal.firebaseUid()` authenticated user identity দেয়।
- request body থেকে user ID নেওয়া হয়নি।
- user না থাকলে 404-style error।
- wallet না থাকলে 404-style error।
- entity directly return না করে mapper দিয়ে DTO return করা হয়েছে।

## 11. Wallet controller

```java
@GetMapping("/me")
public ResponseEntity<WalletResponse> currentUserWallet(@AuthenticationPrincipal JwtPrincipal principal) {
    return ResponseEntity.ok(walletService.getCurrentUserWallet(principal));
}
```

ব্যাখ্যা:

- Endpoint হলো `GET /api/wallet/me`।
- Authenticated JWT principal থেকে current user পাওয়া যায়।
- Controller thin থাকে।
- Business/read logic service layer-এ।

## 12. কেন wallet auto-create করা হয়নি

Wallet auto-create করলে lifecycle decision দরকার:

- user login-এর সময় wallet হবে কি?
- PIN setup-এর পর wallet হবে কি?
- admin approval লাগবে কি?
- merchant wallet কবে হবে?

এই decision আলাদা step-এ করা ভালো। তাই এখন শুধু table/read foundation।

## 13. কেন balance mutation করা হয়নি

Balance change করলে অবশ্যই লাগবে:

- immutable ledger entries
- user-facing transaction records
- idempotency key
- audit log
- database transaction
- safe locking

এই step এগুলো ছাড়া balance change করে না, সেটাই deliberate safety choice।

## 14. SmartKash flow-তে এটি কীভাবে fit করে

1. User Firebase login করে।
2. Backend persisted user record তৈরি করে।
3. User PIN setup/verify করে।
4. Wallet foundation read endpoint তৈরি হলো।
5. Future step wallet creation করবে।
6. তার পর ledger/transaction foundation ছাড়া balance mutate করা হবে না।

## 15. Common mistakes and cautions

- Wallet balance `double` দিয়ে রাখা যাবে না; `BigDecimal/NUMERIC` দরকার।
- Wallet update ledger ছাড়া করা যাবে না।
- Request body থেকে user ID নিয়ে wallet read করা যাবে না।
- Wallet auto-create এই step-এর scope না।
- `application-local.yml` commit করা যাবে না।
- `@Version` বাদ দিলে future concurrent update risky হবে।

## 16. Manual verification commands

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
\d wallets
SELECT * FROM wallets;
SELECT * FROM flyway_schema_history;
```

General:

```cmd
cd /d D:\github\my-kash
git status
```

## 17. Git commands used

```cmd
git status --short --branch
git diff --check
git add <step-12-files>
git commit -m "step-12: add wallet database foundation"
git push
```

## 18. এই step থেকে কী শিখলাম

এই step-এ শিখলাম wallet balance system বানানোর আগে database model, ownership, status, DTO, mapper, repository, service, controller আলাদা করে foundation করা দরকার। Money balance update সবচেয়ে sensitive part, তাই ledger/transaction/idempotency ছাড়া balance mutate করা ঠিক না।
