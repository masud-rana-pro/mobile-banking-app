# Step 15: Wallet Creation Lifecycle

## 1. Step title

Step 15 - SmartKash wallet creation lifecycle.

## 2. কী implement করা হয়েছে

এই step-এ Firebase login flow-এর সাথে wallet lifecycle connect করা হয়েছে:

- `WalletService` interface-এ `ensureWalletForUser(User user)` method যোগ করা হয়েছে।
- `WalletServiceImpl`-এ missing wallet হলে zero-balance wallet create করার logic যোগ করা হয়েছে।
- `AuthServiceImpl`-এ successful Firebase login-এর পর wallet ensure করা হয়েছে।
- Relevant planning docs এবং `docs/codex-progress.md` update করা হয়েছে।

এই step-এ wallet balance change, Add Money, Send Money, Payment, Recharge, Savings, Loan, transaction history, ledger creation, বা idempotency flow implement করা হয়নি।

## 3. কেন wallet lifecycle দরকার

User login করার পর SmartKash app-এ wallet balance দেখাতে হবে। কিন্তু Step 12-এ শুধু wallet table/read foundation ছিল; user তৈরি হলেও wallet auto-create হচ্ছিল না। তাই `GET /api/wallet/me` অনেক user-এর জন্য `Wallet is not created yet.` error দিতে পারত।

এই step-এর goal হলো:

- user থাকলে তার wallet আছে কি না check করা।
- wallet না থাকলে একবার zero-balance wallet তৈরি করা।
- একই user-এর একাধিক wallet তৈরি না করা।

## 4. কেন zero-balance wallet money movement নয়

```text
Initial wallet balance = 0.00 BDT
```

ব্যাখ্যা:

- নতুন wallet তৈরি করা মানে user-এর balance বাড়ানো বা কমানো নয়।
- তাই এখানে ledger entry বা transaction record তৈরি করা হয়নি।
- Future Add Money/Send Money/Payment-এ balance change হলে তখন অবশ্যই ledger এবং transaction record লাগবে।

## 5. Changed files

- `services/backend/src/main/java/com/smartkash/wallet/service/WalletService.java`
- `services/backend/src/main/java/com/smartkash/wallet/service/impl/WalletServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/auth/service/impl/AuthServiceImpl.java`
- `docs/backend-api-plan.md`
- `docs/database-plan.md`
- `docs/security-plan.md`
- `docs/codex-progress.md`
- `learning/step-15-wallet-creation-lifecycle.md`

## 6. WalletService interface snippet

```java
public interface WalletService {

    WalletResponse getCurrentUserWallet(JwtPrincipal principal);

    Wallet ensureWalletForUser(User user);
}
```

Line-by-line ব্যাখ্যা:

- `WalletResponse getCurrentUserWallet(...)`: authenticated user-এর wallet API response দেয়।
- `Wallet ensureWalletForUser(User user)`: user-এর wallet আছে কি না check করবে, না থাকলে create করবে।
- `User user` backend-trusted persisted user entity, request body থেকে user id নেওয়া হচ্ছে না।
- `Wallet` return করা হচ্ছে internal backend use-এর জন্য; এটি public API response নয়।

## 7. WalletServiceImpl snippet

```java
private static final String DEFAULT_CURRENCY = "BDT";
```

ব্যাখ্যা:

- SmartKash MVP Bangladesh-focused, তাই initial wallet currency `BDT`।
- Hardcoded secret নয়; এটি business constant।

```java
@Override
@Transactional
public Wallet ensureWalletForUser(User user) {
    return walletRepository.findByUserId(user.getId())
            .orElseGet(() -> walletRepository.save(
                    new Wallet(user, BigDecimal.ZERO, DEFAULT_CURRENCY, WalletStatus.ACTIVE)
            ));
}
```

Block-by-block ব্যাখ্যা:

- `@Transactional`: wallet check এবং create একই database transaction-এর মধ্যে হয়।
- `findByUserId(user.getId())`: user-এর existing wallet আছে কি না খোঁজা হয়।
- `orElseGet(...)`: wallet না থাকলে শুধু তখন create করা হয়।
- `new Wallet(...)`: নতুন wallet entity তৈরি হয়।
- `BigDecimal.ZERO`: initial balance zero।
- `DEFAULT_CURRENCY`: currency `BDT`।
- `WalletStatus.ACTIVE`: wallet usable/readable active state।
- `walletRepository.save(...)`: database-এ wallet row save করে।

## 8. AuthServiceImpl snippet

```java
User user = findOrCreateUser(firebaseToken.getUid(), phoneNumber);
walletService.ensureWalletForUser(user);
String role = user.getRole().name();
```

Block-by-block ব্যাখ্যা:

- `findOrCreateUser(...)`: Firebase UID দিয়ে user খুঁজে বা create করে।
- `walletService.ensureWalletForUser(user)`: user-এর wallet না থাকলে zero-balance wallet তৈরি করে।
- `String role = ...`: wallet ensure হওয়ার পর JWT role তৈরি করার আগের existing logic।
- এই flow-তে PIN, ledger, transaction, বা money operation নেই।

## 9. কেন AuthService থেকে wallet ensure করা হলো

Firebase login হলো backend-এর trusted entry point:

1. Firebase token verify হয়।
2. Backend user create/find করে।
3. Backend জানে user identity valid।
4. সেই trusted user-এর জন্য wallet ensure করা safe।

Flutter app বা request body থেকে user id নিয়ে wallet create করা unsafe, কারণ user অন্যের user id পাঠাতে পারে।

## 10. কেন ledger/transaction তৈরি হয়নি

Ledger এবং transaction record দরকার balance change হলে। কিন্তু initial zero-balance wallet create করলে কোনো টাকা ঢুকছে না বা বের হচ্ছে না। তাই:

- no ledger entry
- no transaction record
- no idempotency key
- no PIN confirmation

Future balance-changing operation এ এগুলো বাধ্যতামূলক হবে।

## 11. How this fits into SmartKash flow

1. User Firebase test OTP দিয়ে login করবে।
2. Flutter Firebase ID token backend-এ পাঠাবে।
3. Backend token verify করবে।
4. Backend `users` table-এ user find/create করবে।
5. Backend `wallets` table-এ user-এর wallet find/create করবে।
6. Backend JWT return করবে।
7. Flutter পরে `GET /api/wallet/me` call করলে wallet balance `0.00 BDT` দেখতে পারবে।

## 12. Common mistakes and cautions

- Wallet create করার সময় balance non-zero দেওয়া যাবে না।
- Wallet creation-কে Add Money হিসেবে treat করা যাবে না।
- User-supplied user id দিয়ে wallet create করা যাবে না।
- একই user-এর multiple wallet create করা যাবে না।
- Wallet balance update method এখনো add করা যাবে না।
- Ledger ছাড়া balance mutation করা যাবে না।
- Old Flyway migrations edit করা যাবে না; এই step-এ migration দরকার হয়নি।

## 13. Manual verification commands

Backend:

```cmd
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Optional backend run:

```cmd
.\mvnw.cmd spring-boot:run
```

Database check:

```cmd
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
\d wallets
SELECT id, user_id, balance, currency, status, version, created_at, updated_at FROM wallets;
```

API flow check after backend is running:

```cmd
POST /api/auth/firebase-login
GET /api/wallet/me
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
git add <step-15-files>
git commit -m "step-15: add wallet creation lifecycle"
git push
```

## 15. এই step থেকে কী শিখলাম

এই step থেকে শিখলাম user identity তৈরি হওয়া আর wallet balance change করা এক জিনিস নয়। Login-এর সময় zero-balance wallet create করা safe lifecycle কাজ, কিন্তু wallet balance বাড়ানো/কমানো money-changing কাজ। তাই future money operation-এর আগে ledger, transaction, idempotency, PIN, এবং locking একসাথে ব্যবহার করতে হবে।
