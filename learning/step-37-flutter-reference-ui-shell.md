# Step 37: Flutter Reference UI Shell

## 1. Step title

এই ধাপে SmartKash Flutter অ্যাপে reference image অনুযায়ী Home screen এবং Login screen-এর basic UI shell তৈরি করা হয়েছে।

## 2. What was implemented

- Home screen-এ profile header, balance button, action grid, see-more button, promo banner, quick features এবং bottom navigation যোগ করা হয়েছে।
- Login screen-এ top bar, language toggle style, SmartKash logo mark, account number input, Firebase test OTP input preview, next bar এবং numeric keypad যোগ করা হয়েছে।
- App theme-এর main color bKash-এর pink tone থেকে আলাদা করে SmartKash-এর জন্য teal/blue based standard color রাখা হয়েছে।
- Route configuration-এ `/login` route যোগ করা হয়েছে।
- UI reference rule docs-এ লিখে রাখা হয়েছে, যেন ভবিষ্যতে screen design করার আগে প্রয়োজন হলে user-এর কাছ থেকে reference image চাওয়া হয়।

## 3. Why reference images are used

User যে screenshot দিয়েছে, সেগুলো layout direction বোঝার জন্য ব্যবহার করা হয়েছে:

- top profile area কোথায় থাকবে
- balance button কীভাবে visible থাকবে
- main feature grid কীভাবে সাজানো থাকবে
- promo banner এবং quick features কোথায় থাকবে
- login screen-এ keypad এবং next bar কীভাবে থাকবে

কিন্তু SmartKash bKash clone নয়। তাই:

- bKash logo ব্যবহার করা হয়নি
- bKash-এর exact pink color theme ব্যবহার করা হয়নি
- original promotional artwork copy করা হয়নি
- text, color, icons এবং branding SmartKash-এর নিজের রাখা হয়েছে

## 4. Why we did not implement real auth or business logic

এই ধাপের scope শুধু UI shell। তাই এখানে:

- real Firebase OTP send/verify করা হয়নি
- backend login API call করা হয়নি
- PIN store করা হয়নি
- wallet, transaction, send money, recharge বা QR logic যোগ করা হয়নি

এগুলো পরের focused steps-এ করা হবে, যাতে প্রতিটি কাজ আলাদা করে শেখা ও verify করা যায়।

## 5. Files/folders created or changed

- `apps/mobile/lib/app/theme/app_theme.dart`
- `apps/mobile/lib/app/router/app_router.dart`
- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `apps/mobile/lib/features/auth/presentation/login_screen.dart`
- `docs/codex-instructions.md`
- `docs/ui-screen-plan.md`
- `docs/test-checklist.md`
- `docs/codex-progress.md`
- `learning/step-37-flutter-reference-ui-shell.md`

## 6. Important code/config snippets

### Theme color

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF008F7A),
),
scaffoldBackgroundColor: const Color(0xFFF5F7FA),
```

### Bangla explanation

- `ColorScheme.fromSeed` দিয়ে পুরো app-এর color system তৈরি হয়।
- `0xFF008F7A` হলো SmartKash-এর teal seed color।
- এটি reference screenshot-এর pink color থেকে আলাদা, তাই branding copy হয় না।
- `scaffoldBackgroundColor` app-এর সাধারণ screen background light gray করে।

### Login route

```dart
GoRoute(
  path: LoginScreen.routePath,
  name: LoginScreen.routeName,
  builder: (context, state) => const LoginScreen(),
),
```

### Bangla explanation

- `GoRoute` দিয়ে `/login` screen app router-এ register করা হয়েছে।
- `path` হলো browser/app route path।
- `name` দিয়ে code থেকে route call করা সহজ হয়।
- `builder` LoginScreen widget return করে।

### Home header

```dart
Container(
  height: 238,
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF00796B), Color(0xFF2446A6)],
    ),
  ),
)
```

### Bangla explanation

- Home screen-এর top area fixed height দেওয়া হয়েছে।
- teal এবং blue gradient SmartKash-এর own theme তৈরি করে।
- এই area-তে avatar, user name, balance button এবং action icons থাকে।

### Action grid

```dart
GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: _actions.length,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 4,
    mainAxisExtent: 96,
  ),
)
```

### Bangla explanation

- `GridView.builder` feature buttons repeat করে।
- `crossAxisCount: 4` মানে এক row-তে ৪টি feature থাকবে।
- `mainAxisExtent: 96` প্রতিটি grid item-এর height stable রাখে।
- `NeverScrollableScrollPhysics` দেওয়া হয়েছে কারণ পুরো screen already scrollable।

### Login OTP keypad

```dart
void _onNumberTap(String value) {
  if (_otpCode.length >= 6) {
    return;
  }

  setState(() => _otpCode += value);
}
```

### Bangla explanation

- keypad থেকে number চাপলে `_otpCode` variable-এ digit যোগ হয়।
- OTP ৬ digit-এর বেশি হতে দেওয়া হয় না।
- `setState` UI refresh করে, ফলে OTP preview-তে star দেখা যায়।
- এটি শুধু UI preview; real Firebase OTP verification এখনো করা হয়নি।

### OTP preview

```dart
Text(
  otpCode.isEmpty
      ? 'Enter test OTP'
      : List.filled(otpCode.length, '*').join(),
)
```

### Bangla explanation

- OTP empty হলে hint text দেখায়।
- digit দিলে actual OTP না দেখিয়ে `*` দেখায়।
- এটি security habit শেখার জন্য ভালো, যদিও এই ধাপে real OTP verify করা হচ্ছে না।

## 7. How this works in the SmartKash app flow

Home screen ভবিষ্যতে user-এর main dashboard হবে। এখান থেকে Send Money, Recharge, Payment, Savings, Loan, QR scan ইত্যাদি feature open হবে।

Login screen ভবিষ্যতে Firebase test OTP flow-এর visual starting point হবে। এখন শুধু UI shell আছে। পরের step-এ Firebase test OTP এবং backend JWT login flow-এর সাথে connect করা যাবে।

## 8. Common mistakes and cautions

- Reference image দেখে exact logo/color copy করা যাবে না।
- bKash promotional image বা icon directly ব্যবহার করা যাবে না।
- PIN বা OTP local storage-এ save করা যাবে না।
- Widget-এর মধ্যে API call সরাসরি রাখা যাবে না।
- Future screen design করার আগে screen-specific reference দরকার হলে user-এর কাছ থেকে image চাইতে হবে।
- Large bitmap asset দরকার হলে correct size, format এবং content instruction নিয়ে asset তৈরি বা সংগ্রহ করতে হবে।

## 9. Manual verification commands

Flutter:

```bat
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
flutter run -d chrome --dart-define=SMARTKASH_API_BASE_URL=http://localhost:8080
```

General:

```bat
cd /d D:\github\my-kash
git status
```

## 10. Expected manual output

- App open করলে Home screen-এ teal/blue header দেখা যাবে।
- Header-এ user avatar, name, `Tap for Balance`, search এবং notification icon থাকবে।
- Main white panel-এ ৮টি action থাকবে: Send Money, Recharge, Cash Out, Payment, Add Money, Pay Bill, Savings, Loan।
- Promo strip এবং Quick Features section দেখা যাবে।
- Bottom navigation-এ Home, Account, Scan QR, Inbox থাকবে।
- Account tab অথবা header notification icon চাপলে Login screen open হবে।
- Login screen-এ phone input, Firebase Test OTP preview, Next bar এবং numeric keypad দেখা যাবে।
- keypad দিয়ে ৬ digit দিলে Next bar active color দেখাবে।
- এখনো real OTP/backend login হবে না। এটা expected।

## 11. Git commands used

```bat
git status --short --branch
git diff --check
git add <step-37-files>
git commit -m "step-37: add Flutter reference UI shell"
git push
```

## 12. What I learned from this step

এই ধাপে শিখলাম কীভাবে reference image থেকে layout idea নেওয়া যায়, কিন্তু branding copy না করে নিজের app-এর original UI তৈরি করা যায়। আরও শিখলাম Flutter-এ dashboard layout, route setup, theme color, keypad UI এবং future auth flow-এর জন্য clean visual shell তৈরি করার পদ্ধতি।

## 13. Step 37b run fix note

Step 37-এর পরে Flutter app run/check করার সময় `flutter analyze` fail করছিল, কারণ project-এর lint rules warning/info-কেও issue হিসেবে ধরছিল।

### What was fixed

- Home screen থেকে unused `AppConfig` import remove করা হয়েছে।
- Deprecated `withOpacity(...)` call replace করে `withValues(alpha: ...)` ব্যবহার করা হয়েছে।
- Static Quick Features section-এ const usage ঠিক করা হয়েছে।
- Login screen-এর `Next` bar color opacity একইভাবে update করা হয়েছে।

### Important snippet

```dart
color: Colors.white.withValues(alpha: enabled ? 1 : 0.72),
```

### Bangla explanation

- `Colors.white` হলো base color।
- `withValues(alpha: ...)` দিয়ে color-এর transparency set করা হয়।
- `enabled ? 1 : 0.72` মানে button active হলে full white, inactive হলে হালকা transparent white।
- আগে `withOpacity(...)` ব্যবহার করা হয়েছিল, কিন্তু নতুন Flutter lint সেটিকে deprecated দেখাচ্ছিল।

### Verification result

```bat
cd /d D:\github\my-kash\apps\mobile
flutter analyze
```

Expected output:

```text
No issues found!
```

### Note

`flutter build web` sandbox timeout-এর কারণে Codex environment-এ শেষ করা যায়নি। তাই local CMD/IDE থেকে নিচের command চালিয়ে final run/build verify করতে হবে:

```bat
cd /d D:\github\my-kash\apps\mobile
flutter run -d chrome --dart-define=SMARTKASH_API_BASE_URL=http://localhost:8080
flutter build web
```
