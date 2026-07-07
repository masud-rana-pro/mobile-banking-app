# SmartKash Test Checklist

## Planning Files

- Confirm all requested planning files exist.
- Confirm `learning/README.md` exists.
- Confirm docs mention zero-budget learning MVP.
- Confirm backend dependency plan includes Spring Web, Security, Data JPA, Hibernate, PostgreSQL Driver, Lombok, Validation, Firebase Admin SDK, JWT, Flyway, Actuator, and OpenAPI/Swagger.
- Confirm backend package plan uses `com.smartkash` with feature modules and layered internals.
- Confirm Flutter plan uses Riverpod and feature-first folders.
- Confirm Flutter platform folders exist for Android, iOS, Web, Windows, Linux, and macOS.
- Confirm Android and Web can be verified locally on Windows.
- Confirm Windows desktop limitation is documented: Visual Studio Desktop development with C++ workload.
- Confirm iOS/macOS limitation is documented: macOS with Xcode.
- Confirm Linux limitation is documented: Linux environment.

## Auth And Security

- Firebase Phone Auth uses test phone numbers and fixed OTP codes.
- Real SMS OTP is not required.
- Backend verifies Firebase token.
- Backend issues JWT.
- PIN is hashed.
- Raw PIN is never stored.
- PIN verification happens only in backend.
- PIN attempts are rate-limited.
- Multiple wrong PIN attempts temporarily block money-changing actions.

## Wallet And Ledger

- Wallet balance is stored for fast reads.
- Every balance change creates immutable ledger entries.
- Ledger entries are never updated or deleted.
- Corrections use reversal ledger entries.
- Money movement creates user-facing transaction records.
- Wallet-to-wallet transfers create linked debit and credit ledger entries under the same transaction reference.
- Money-changing operations use database transactions.
- Wallet balance updates use optimistic locking or another safe locking strategy.

## Send Money

- Send Money supports registered mobile number.
- Send Money supports QR-based receiver selection.
- QR payload resolves only a registered receiver account.
- Backend validates QR payload, receiver status, sender balance, PIN, and idempotency key.
- Duplicate idempotency key does not create duplicate transfer.

## Merchant Payment

- Merchant is a user with `role = MERCHANT`.
- Merchant has a wallet.
- `merchants` table stores business details only.
- Customer wallet is debited.
- Merchant wallet is credited.

## Admin

- Admin routes require `ADMIN` role.
- Customer cannot access admin routes.
- Merchant cannot access admin routes.
- Admin routes list matches `docs/backend-api-plan.md`.
- Add Money approval creates wallet credit, ledger entry, transaction record, and audit log.
- Loan approval/rejection only updates request status.

## Idempotency

- Send Money requires idempotency key.
- Merchant Payment requires idempotency key.
- Add Money approval requires idempotency key.
- Savings deposit requires idempotency key.
- Mobile Recharge requires idempotency key.
- Future Loan wallet credit must require idempotency key.

## Notifications

- FCM is used only for important transaction alerts.
- Local backend notification testing limitations are documented.
- Full FCM testing is planned after backend deployment.

## Learning Documentation

- Every future implementation step creates or updates one Bangla learning file.
- Learning file follows `learning/step-XX-topic-name.md`.
- Learning file includes important code snippets and clear Bangla explanation.

## Backend Coding Rules

- Controllers are thin.
- Business logic lives in services.
- Major modules use service interfaces and implementation classes.
- Repositories only handle database access.
- Entities are not exposed directly in API responses.
- DTOs and mappers are used.
- Bean Validation validates request DTOs.
- Global exception handling returns consistent errors.

## API Error Outputs

- Protected API without `Authorization: Bearer <token>` returns JSON `401 Unauthorized`.
- Protected API with invalid/expired backend JWT returns JSON `401 Unauthorized`.
- Customer or merchant user calling `/admin/**` returns JSON `403 Forbidden`.
- Invalid request body returns JSON `400 Bad Request` with field errors.
- Duplicate unique values or database constraint conflicts return JSON `409 Conflict`.
- Missing resources return JSON `404 Not Found`.
- Unexpected server errors return JSON `500 Internal Server Error` with a safe generic message.

## Local E2E Seed Data

- `scripts/dev/seed-e2e-data.sql` is local development seed data only.
- Seed data is not a Flyway migration and must not run automatically in production.
- Seed script requires a BCrypt hash for demo PIN `12345`; raw PIN is never inserted.
- Seed script creates one admin, 15 customers, 15 merchants, profiles, wallets, and at least 15 rows for each main business table.
- Seed count output should be checked after running the script.
- `docs/backend-e2e-api-test-guide.md` explains expected manual database and API outputs.

## Flutter API Client Foundation

- `flutter pub get` resolves `dio` and `flutter_secure_storage`.
- Flutter API base URL can be changed with `--dart-define=SMARTKASH_API_BASE_URL=<url>`.
- Android emulator default backend URL is `http://10.0.2.2:8080`.
- Web/desktop local backend URL should usually be `http://localhost:8080`.
- Backend JWT is stored in secure storage.
- PIN is not stored in Flutter.
- API requests attach `Authorization: Bearer <backend-jwt>` only when a token exists.
- Backend `ApiErrorResponse` JSON maps to Flutter `ApiException`.
