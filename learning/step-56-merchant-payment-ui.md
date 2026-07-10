# Step 56: Merchant Payment UI Completion

## 1. Step title

Step 56-এ SmartKash Merchant Payment UI properly complete করা হয়েছে।

## 2. কী implement করা হয়েছে

- Backend-এ merchant resolve endpoint যোগ করা হয়েছে: `GET /api/payments/merchant/resolve`.
- Flutter Merchant Payment screen থেকে dummy merchant data remove করা হয়েছে।
- Merchant number দিলে backend থেকে real merchant validate/resolve করা হচ্ছে।
- Payment attempt-এর জন্য stable idempotency key রাখা হয়েছে।
- Payment success হলে wallet balance refresh করা হচ্ছে।
- Progress/test checklist update করা হয়েছে।

## 3. কেন এই step দরকার

Merchant Payment money-changing feature। User যদি ভুল merchant number দেয়, inactive merchant দেয়, নিজের merchant account-এ payment করতে চায়, বা merchant wallet inactive থাকে, তাহলে amount/PIN screen-এ যাওয়া উচিত না। তাই payment করার আগে backend দিয়ে merchant resolve করা দরকার।

## 4. কোন files/folders change হয়েছে

- `services/backend/src/main/java/com/smartkash/payment/controller/MerchantPaymentController.java`
- `services/backend/src/main/java/com/smartkash/payment/service/MerchantPaymentService.java`
- `services/backend/src/main/java/com/smartkash/payment/service/impl/MerchantPaymentServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/payment/dto/response/MerchantPaymentTargetResponse.java`
- `apps/mobile/lib/features/payment/data/payment_repository.dart`
- `apps/mobile/lib/features/payment/domain/merchant_payment_target.dart`
- `apps/mobile/lib/features/payment/presentation/merchant_payment_screen.dart`
- `docs/codex-progress.md`
- `docs/test-checklist.md`
- `learning/step-56-merchant-payment-ui.md`

## 5. Important backend snippets

```java
@GetMapping("/merchant/resolve")
public ResponseEntity<MerchantPaymentTargetResponse> resolveMerchant(
        @AuthenticationPrincipal JwtPrincipal principal,
        @RequestParam String merchantNumber
) {
    return ResponseEntity.ok(merchantPaymentService.resolveMerchant(principal, merchantNumber));
}
```

Block-by-block ব্যাখ্যা:

- `@GetMapping("/merchant/resolve")`: `/api/payments/merchant/resolve` route তৈরি করে।
- `@AuthenticationPrincipal JwtPrincipal principal`: authenticated logged-in user কে backend JWT থেকে নেয়।
- `@RequestParam String merchantNumber`: query parameter থেকে merchant number নেয়।
- `merchantPaymentService.resolveMerchant(...)`: controller thin থাকে; আসল validation service layer-এ যায়।

```java
public MerchantPaymentTargetResponse resolveMerchant(JwtPrincipal principal, String merchantNumber) {
    User customer = currentUser(principal);
    ensureActiveUser(customer, "Only active users can make merchant payments.");

    Merchant merchant = merchantRepository.findByMerchantNumber(normalizeMerchantNumber(merchantNumber))
            .orElseThrow(() -> new ResourceNotFoundException("Merchant account was not found."));
    ensureActiveMerchant(merchant);

    User merchantUser = merchant.getUser();
    ensureActiveUser(merchantUser, "Merchant user account is not active.");
    ensureNotPayingOwnMerchant(customer, merchantUser);
    walletRepository.findByUserId(merchantUser.getId())
            .filter(wallet -> wallet.getStatus() == WalletStatus.ACTIVE)
            .orElseThrow(() -> new IllegalArgumentException("Merchant wallet is not active."));
```

Block-by-block ব্যাখ্যা:

- `currentUser(principal)`: logged-in customer database user resolve করে।
- `ensureActiveUser(customer, ...)`: blocked/pending customer payment করতে পারবে না।
- `findByMerchantNumber(...)`: merchant number real database merchant কিনা check করে।
- `ensureActiveMerchant(merchant)`: merchant status `ACTIVE` না হলে payment করা যাবে না।
- `merchant.getUser()`: merchant নিজেও একটি user account, তাই তার user status check হয়।
- `ensureNotPayingOwnMerchant(...)`: নিজের merchant account-এ নিজে payment block করে।
- `walletRepository.findByUserId(...)`: merchant wallet আছে এবং active কিনা check করে।

```java
return new MerchantPaymentTargetResponse(
        merchantUser.getId(),
        merchant.getMerchantNumber(),
        merchant.getBusinessName(),
        merchant.getBusinessType(),
        merchant.getStatus()
);
```

ব্যাখ্যা:

- Flutter UI-তে শুধু safe merchant information পাঠানো হয়।
- Entity direct response হিসেবে পাঠানো হয়নি।
- `businessName`, `merchantNumber`, `businessType`, `status` UI confirm screen-এ দেখানো যায়।

## 6. Important Flutter snippets

```dart
Future<MerchantPaymentTarget> resolveMerchant({
  required String merchantNumber,
}) async {
  final response = await _apiClient.get<Map<String, dynamic>>(
    '/api/payments/merchant/resolve',
    queryParameters: {'merchantNumber': merchantNumber},
  );

  return MerchantPaymentTarget.fromJson(response.data ?? const {});
}
```

Block-by-block ব্যাখ্যা:

- `resolveMerchant`: payment করার আগে merchant lookup করে।
- `_apiClient.get`: centralized API client ব্যবহার হয়, তাই backend JWT automatically attach হয়।
- `queryParameters`: merchant number URL query parameter হিসেবে যায়।
- `MerchantPaymentTarget.fromJson`: raw JSON UI-তে ছড়ায় না, model class-এ convert হয়।

```dart
final result = await repository.payMerchant(
  merchantNumber: target.merchantNumber,
  amount: amount,
  pin: pin,
  idempotencyKey: _idempotencyKey ??= repository.createIdempotencyKey(),
  note: _noteController.text.trim(),
);
```

Block-by-block ব্যাখ্যা:

- `target.merchantNumber`: backend-resolved merchant number ছাড়া payment হয় না।
- `amount`: user-entered payment amount।
- `pin`: PIN Flutter-এ store হয় না; শুধু confirmation request-এ backend-এ যায়।
- `_idempotencyKey ??=`: একই payment attempt-এর key একবার তৈরি হয়, retry করলে একই key থাকে।
- `note`: optional note; empty হলে backend payload-এ বাদ দেওয়া যায়।

```dart
ref.read(walletRefreshProvider)();
```

ব্যাখ্যা:

- Payment success হলে customer wallet balance বদলায়।
- তাই Home screen-এ ফিরে গেলে old balance না দেখিয়ে fresh backend wallet balance load করতে provider invalidate করা হয়।

## 7. কেন dummy merchant remove করা হয়েছে

আগের Step 56 work-in-progress UI `Demo Merchant` দেখাচ্ছিল। এতে user ভাবতে পারত merchant valid, কিন্তু backend payment fail করতে পারত। Money-changing UI-তে এই ধরনের dummy data unsafe। এখন amount/PIN screen-এ যাওয়ার আগে backend merchant validation বাধ্যতামূলক।

## 8. Idempotency key কেন stable রাখা হলো

যদি user payment submit করার পর network timeout পায় এবং আবার same attempt retry করে, নতুন idempotency key তৈরি হলে duplicate payment হওয়ার ঝুঁকি থাকে। তাই amount/PIN stage-এ একবার key তৈরি হয় এবং same screen attempt-এ সেটিই reuse হয়।

## 9. SmartKash flow-তে এটা কীভাবে কাজ করে

1. User Home থেকে `Payment` চাপবে।
2. Merchant number দেবে।
3. Flutter backend resolve API call করবে।
4. Backend merchant/user/wallet/status/self-payment validate করবে।
5. Valid হলে amount screen খুলবে।
6. User amount/note দেবে।
7. User PIN দেবে।
8. Flutter backend payment API call করবে।
9. Backend PIN, idempotency, wallet lock, debit/credit, transaction, ledger সব handle করবে।
10. Flutter success result দেখাবে এবং wallet refresh করবে।

## 10. Common mistakes and cautions

- Dummy merchant name দিয়ে payment flow চালানো যাবে না।
- Merchant number না resolve করে amount/PIN screen দেখানো যাবে না।
- PIN Flutter local storage-এ রাখা যাবে না।
- Same retry attempt-এ নতুন idempotency key তৈরি করলে duplicate transaction হতে পারে।
- Backend `application-local.yml` বা `.env` commit করা যাবে না।
- Firebase/Admin secret JSON commit করা যাবে না।

## 11. Manual verification commands

Backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
.\mvnw.cmd spring-boot:run
```

Flutter:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter run --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

Database check:

```sql
SELECT id, balance FROM wallets ORDER BY id;
SELECT transaction_reference, type, status, amount FROM transactions ORDER BY id DESC LIMIT 10;
SELECT transaction_reference, entry_type, amount, balance_after FROM ledger_entries ORDER BY id DESC LIMIT 10;
SELECT idempotency_key, operation_type, status FROM idempotency_keys ORDER BY id DESC LIMIT 10;
```

Expected output:

- Invalid merchant number দিলে readable error দেখাবে।
- Valid merchant দিলে real business name দেখাবে।
- Successful payment result screen-এ amount, merchant, reference, new balance দেখাবে।
- Database-এ customer debit, merchant credit, transaction, ledger, idempotency completed record দেখা যাবে।

## 12. Git commands used

```powershell
git status --short --branch
git diff --check
git add <step-56-files>
git commit -m "step-56: complete merchant payment UI"
git push
```

## 13. কী শিখলাম

Merchant Payment UI শুধু form না; backend validation, authenticated API, idempotency, wallet refresh, error handling, এবং real merchant resolve একসাথে লাগতে হয়। Money-changing screen বানানোর সময় dummy data বাদ দিয়ে backend সত্যতা যাচাই করাই safest approach।
