# SmartKash Mobile

The SmartKash client is a Flutter application for customer, agent, and merchant wallet workflows. It uses a feature-first architecture and shares one responsive codebase across Flutter-supported platforms, with Android as the primary tested target.

## Features

- Firebase phone authentication and secure session storage
- Profile completion, avatar upload, account editing, and PIN setup
- Wallet dashboard and real-time balance refresh
- Add Money, Send Money, Cash Out, Merchant Payment, and Pay Bill
- Mobile Recharge, savings goals, and loan requests
- Recipient selection through manual entry, device contacts, and QR scanning
- Transaction confirmation, receipts, history, search, and details
- Personal QR generation and downloadable QR sharing

## Structure

```text
lib/app/       Router, theme, configuration, and application shell
lib/core/      Networking, storage, errors, and shared infrastructure
lib/features/  Business features grouped by domain
lib/shared/    Reusable widgets, models, providers, and services
assets/        Brand and interface images
test/          Flutter tests
```

## Configuration

The backend URL is supplied with the `SMARTKASH_API_BASE_URL` Dart define. Firebase values are also provided through Dart defines; private Admin SDK credentials must never be included in the mobile app.

Android emulator:

```powershell
flutter pub get
flutter run --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

Physical Android phone over USB:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080
flutter run
```

## Quality Checks

```powershell
flutter analyze
flutter test
flutter build apk --debug
```
