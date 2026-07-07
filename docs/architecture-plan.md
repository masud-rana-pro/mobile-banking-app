# SmartKash Architecture Plan

## System Overview

```text
Flutter Cross-Platform App
  -> Android / iOS / Web / Windows / Linux / macOS
  -> Firebase Phone Auth test OTP
  -> Spring Boot REST API
  -> PostgreSQL
  -> Firebase Cloud Messaging

Spring Web Admin
  -> Spring Boot Admin Routes
  -> PostgreSQL
```

## Backend Dependencies

- Spring Boot
- Spring Web
- Spring Security
- Spring Data JPA
- Hibernate
- PostgreSQL Driver
- Lombok
- Bean Validation
- Firebase Admin SDK
- JWT library
- Flyway for database migrations
- Spring Boot Actuator for health checks
- OpenAPI/Swagger for API documentation

## Backend Layered Architecture

Root package: `com.smartkash`.

Feature modules:

- `com.smartkash.auth`
- `com.smartkash.user`
- `com.smartkash.wallet`
- `com.smartkash.ledger`
- `com.smartkash.transaction`
- `com.smartkash.idempotency`
- `com.smartkash.addmoney`
- `com.smartkash.sendmoney`
- `com.smartkash.payment`
- `com.smartkash.savings`
- `com.smartkash.loan`
- `com.smartkash.recharge`
- `com.smartkash.merchant`
- `com.smartkash.notification`
- `com.smartkash.admin`
- `com.smartkash.common`
- `com.smartkash.config`
- `com.smartkash.security`

Each feature module should use this internal structure when needed:

- `controller`
- `service`
- `service.impl`
- `repository`
- `entity`
- `dto.request`
- `dto.response`
- `mapper`
- `enums`

Common backend layers/packages:

- `controller`
- `service`
- `service.impl`
- `repository`
- `entity`
- `dto`
- `dto.request`
- `dto.response`
- `mapper`
- `enums`
- `exception`
- `config`
- `security`
- `firebase`
- `notification`
- `util`
- `audit`

Use `enums` as the Java package name for enum classes. Avoid a package literally named `enum` because `enum` is a Java keyword.

## Backend Layer Rules

- Controllers are thin.
- Business logic stays in service layer.
- Major modules use service interfaces and implementation classes.
- Repositories only handle database access.
- Entities are not exposed directly in API responses.
- DTOs are used for request and response payloads.
- Mappers convert between entities and DTOs.
- Enums are used for fixed statuses and types.
- Bean Validation validates input DTOs.
- Global exception handling returns consistent API errors.
- Money-changing operations use transactions.
- Wallet balance updates use optimistic locking or another safe locking strategy.
- Idempotency keys protect money-changing APIs from duplicate processing.
- Audit logs are used for admin actions and critical money operations.

## Flutter Feature-First Architecture

Use Riverpod for state management.

SmartKash is now planned as a Flutter full cross-platform app. Supported Flutter platforms are Android, iOS, Web, Windows, Linux, and macOS. Android remains the primary local testing target on the current Windows machine, and Web can also be tested locally on Windows.

Platform limitations:

- Windows desktop builds require Visual Studio Desktop development with C++ workload.
- iOS and macOS builds require macOS with Xcode.
- Linux builds require a Linux environment.

```text
android/
ios/
web/
windows/
linux/
macos/
lib/main.dart
lib/app/
lib/app/router/
lib/app/theme/
lib/app/config/
lib/core/
lib/core/constants/
lib/core/errors/
lib/core/network/
lib/core/storage/
lib/core/security/
lib/core/utils/
lib/features/
lib/features/auth/
lib/features/home/
lib/features/wallet/
lib/features/add_money/
lib/features/send_money/
lib/features/payment/
lib/features/transactions/
lib/features/savings/
lib/features/loan/
lib/features/recharge/
lib/features/notification/
lib/features/profile/
lib/features/qr/
lib/shared/
lib/shared/widgets/
lib/shared/models/
lib/shared/services/
```

Feature internals when needed:

```text
data/
domain/
presentation/
providers/
```

Flutter rules:

- Keep UI widgets clean.
- API calls stay in repository/service classes, not widgets.
- Use DTO/model classes for API payloads.
- Use secure storage for JWT and sensitive tokens.
- Do not store PIN in Flutter.
- Send PIN only for transaction confirmation over secure API.
- Use a centralized API client.
- Use centralized error handling.
- Keep Firebase Auth logic separated from UI screens.
- Keep QR scan logic inside a dedicated QR feature/module.

Step 35 adds the Flutter API client foundation:

- `dio` is the centralized HTTP client dependency.
- `flutter_secure_storage` stores the backend JWT only.
- `AppConfig.backendBaseUrl` uses `SMARTKASH_API_BASE_URL` from Dart defines, with Android emulator default `http://10.0.2.2:8080`.
- `ApiClient` attaches `Authorization: Bearer <token>` when a backend JWT exists.
- `ApiException` maps backend `ApiErrorResponse` JSON into a Flutter-friendly exception.
- `BackendAuthRepository` exchanges Firebase ID token with `POST /api/auth/firebase-login` and saves the backend JWT.
- Feature UI must call repositories/providers, not `Dio` directly.

## Flutter To Spring Boot Flow

- User opens Flutter app.
- User logs in with mobile number using Firebase Phone Auth test OTP.
- Flutter receives Firebase ID token.
- Flutter sends Firebase ID token to Spring Boot.
- Spring Boot verifies Firebase token.
- Spring Boot creates or finds the user and returns backend JWT.
- Flutter uses backend JWT for future API requests.

## Spring Boot To PostgreSQL Flow

- Spring Boot owns all business logic.
- PostgreSQL stores users, wallets, ledger entries, transactions, merchants, savings, loans, recharges, idempotency keys, and audit logs.
- Flutter must not write directly to PostgreSQL.
- Firebase stores auth identity only; core business data remains in PostgreSQL.

## Firebase Auth Test OTP Flow

- MVP uses Firebase test phone numbers and fixed OTP codes.
- Real SMS OTP is not used.
- This avoids billing requirements and keeps the project zero-budget.

## FCM Flow

- Flutter registers device for FCM.
- Flutter sends FCM token to backend.
- Backend stores token in `firebase_devices`.
- Backend sends important transaction alerts when configured.
- Local backend notification testing may be limited.
- Full FCM testing can happen after backend deployment.

## Wallet And Ledger Flow

- Wallet balance is stored for fast reads.
- Every balance change creates immutable ledger entries.
- Every money movement creates user-facing transaction records.
- Ledger entries are never updated or deleted.
- Corrections use reversal ledger entries.
- Wallet-to-wallet transfers create linked debit and credit ledger entries under the same transaction reference.

## QR Send Money Flow

- Flutter scans or receives QR payload.
- Flutter sends QR payload, amount, PIN, and idempotency key to backend.
- Backend validates QR payload.
- Backend resolves receiver from registered account data.
- Backend validates receiver account status.
- Backend validates sender balance and PIN.
- Backend checks idempotency key.
- Backend creates linked ledger entries and transaction records.

## Admin Flow

- Admin logs in through Spring web admin.
- Admin routes require `ADMIN` role.
- Admin can view users, transactions, add-money requests, loan requests, recharges, payments, and audit logs.
- Admin can approve/reject Add Money requests.
- Admin can approve/reject Loan requests.
- Admin actions are recorded in `admin_audit_logs`.
