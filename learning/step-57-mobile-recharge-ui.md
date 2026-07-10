# Step 57: Mobile Recharge UI

## 1. Step title

Step 57-এ SmartKash Flutter app-এ Mobile Recharge UI তৈরি করা হয়েছে।

## 2. কী implement করা হয়েছে

- Home screen-এর `Recharge` action এখন Mobile Recharge screen খুলে।
- Operator select করার UI যোগ করা হয়েছে।
- Mobile number, amount, note input যোগ করা হয়েছে।
- PIN confirmation step যোগ করা হয়েছে।
- Existing backend `POST /api/recharge` API call করা হয়েছে।
- Existing backend `GET /api/recharge` দিয়ে recent recharge list দেখানো হয়েছে।
- Successful recharge হলে wallet balance refresh করা হয়েছে।
- Stable idempotency key per recharge attempt ব্যবহার করা হয়েছে।

## 3. কেন এই step দরকার

Backend Step 30-এ demo Mobile Recharge wallet debit flow তৈরি ছিল। কিন্তু Flutter UI না থাকলে user app থেকে recharge করতে পারত না। এই step backend-এর existing safe money-changing recharge API-কে frontend-এর সাথে যুক্ত করে।

## 4. কোন files/folders change হয়েছে

- `apps/mobile/lib/features/recharge/data/recharge_repository.dart`
- `apps/mobile/lib/features/recharge/domain/mobile_recharge_record.dart`
- `apps/mobile/lib/features/recharge/providers/recharge_providers.dart`
- `apps/mobile/lib/features/recharge/presentation/mobile_recharge_screen.dart`
- `apps/mobile/lib/app/router/app_router.dart`
- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `docs/codex-progress.md`
- `docs/test-checklist.md`
- `learning/step-57-mobile-recharge-ui.md`

## 5. Important code snippets

```dart
Future<MobileRechargeRecord> createRecharge({
  required String operator,
  required String mobileNumber,
  required double amount,
  required String pin,
  required String idempotencyKey,
  String? note,
}) async {
  final response = await _apiClient.post<Map<String, dynamic>>(
    '/api/recharge',
    data: {
      'operator': operator,
      'mobileNumber': mobileNumber,
      'amount': amount,
      'pin': pin,
      'idempotencyKey': idempotencyKey,
      if (note != null && note.isNotEmpty) 'note': note,
    },
  );

  return MobileRechargeRecord.fromJson(response.data ?? const {});
}
```

Block-by-block ব্যাখ্যা:

- `createRecharge`: backend recharge API call করার repository method।
- `operator`: backend enum value যেমন `GP`, `ROBI`, `BANGLALINK`।
- `mobileNumber`: recharge target mobile number।
- `amount`: wallet থেকে debit হওয়া amount।
- `pin`: raw PIN local storage-এ রাখা হয় না; শুধু confirmation request-এ backend-এ যায়।
- `idempotencyKey`: duplicate recharge ঠেকানোর জন্য required।
- `_apiClient.post`: centralized API client JWT token attach করে।
- `MobileRechargeRecord.fromJson`: backend response model class-এ convert করে।

```dart
setState(() {
  _idempotencyKey ??= ref
      .read(rechargeRepositoryProvider)
      .createIdempotencyKey();
  _currentStep = _RechargeStep.pin;
});
```

ব্যাখ্যা:

- Amount/details valid হলে PIN step-এ যাওয়া হয়।
- `_idempotencyKey ??=` মানে একই recharge attempt-এ key একবারই তৈরি হবে।
- Retry করলে একই key reuse হবে, তাই backend duplicate wallet debit আটকাতে পারে।

```dart
ref.read(walletRefreshProvider)();
ref.read(mobileRechargeRefreshProvider)();
```

ব্যাখ্যা:

- Recharge success হলে wallet balance কমে।
- তাই wallet provider refresh করা হয়।
- Recharge history list-ও refresh করা হয় যেন নতুন recharge record দেখা যায়।

```dart
GoRoute(
  path: MobileRechargeScreen.routePath,
  name: MobileRechargeScreen.routeName,
  builder: (context, state) => const MobileRechargeScreen(),
),
```

ব্যাখ্যা:

- Router-এ `/mobile-recharge` route যোগ করা হয়েছে।
- Home screen থেকে `context.pushNamed(MobileRechargeScreen.routeName)` দিয়ে screen খোলা যায়।

## 6. SmartKash flow-তে কীভাবে কাজ করে

1. User Home থেকে `Recharge` চাপবে।
2. Operator select করবে।
3. Mobile number, amount, note দেবে।
4. PIN step-এ যাবে।
5. PIN দিয়ে recharge submit করবে।
6. Flutter backend `POST /api/recharge` call করবে।
7. Backend PIN verify করবে, wallet lock করে debit করবে, transaction/ledger/recharge/idempotency record তৈরি করবে।
8. Flutter result screen দেখাবে।
9. Wallet balance এবং recharge history refresh হবে।

## 7. কেন real recharge provider নেই

SmartKash zero-budget learning MVP। এখানে কোনো real recharge provider, payment gateway, SMS top-up API, বা billing integration নেই। Backend demo success record তৈরি করে এবং wallet debit করে learning flow দেখায়।

## 8. Common mistakes and cautions

- PIN Flutter storage-এ রাখা যাবে না।
- Idempotency key প্রতি retry-তে নতুন করলে duplicate debit হতে পারে।
- Real recharge provider API যোগ করা যাবে না, কারণ MVP zero-budget learning scope।
- Operator value backend enum-এর সাথে match করতে হবে।
- `application-local.yml`, `.env`, Firebase service account JSON commit করা যাবে না।

## 9. Manual verification commands

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
SELECT id, operator, mobile_number, amount, status, transaction_reference FROM mobile_recharges ORDER BY id DESC LIMIT 10;
SELECT transaction_reference, type, status, amount FROM transactions ORDER BY id DESC LIMIT 10;
SELECT transaction_reference, entry_type, amount, balance_after FROM ledger_entries ORDER BY id DESC LIMIT 10;
SELECT idempotency_key, operation_type, status FROM idempotency_keys ORDER BY id DESC LIMIT 10;
```

Expected output:

- Home থেকে Recharge screen খুলবে।
- Valid number/amount/PIN দিলে success result দেখাবে।
- Recent Recharges list-এ নতুন record দেখা যাবে।
- Wallet balance কমবে।
- Database-এ mobile recharge, transaction, ledger, idempotency completed record দেখা যাবে।

## 10. Git commands used

```powershell
git status --short --branch
dart format <step-57-dart-files>
git diff --check
git add <step-57-files>
git commit -m "step-57: add mobile recharge UI"
git push
```

## 11. কী শিখলাম

Mobile Recharge UI money-changing flow হওয়ায় শুধু form বানালেই হয় না। PIN confirmation, idempotency, wallet refresh, history refresh, backend enum matching, এবং clear error handling একসাথে লাগতে হয়।
