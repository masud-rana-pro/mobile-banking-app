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

## Flutter Auth Flow Foundation

- `AuthController` syncs an existing Firebase signed-in user with the backend login API.
- `AuthSessionState` exposes initial, unauthenticated, authenticating, authenticated, and failure states.
- Backend JWT is saved only after `POST /api/auth/firebase-login` succeeds.
- Sign-out clears Firebase session and backend JWT storage.
- No login UI, OTP UI, route guard, wallet UI, or PIN UI is expected yet.

## Flutter Reference UI Shell

- Home screen follows the provided reference structure: header, profile/balance area, action grid, see-more control, promo strip, quick features, and bottom navigation.
- Login screen follows the provided reference structure: top bar, language toggle, brand mark, account input, verification input, next bar, and numeric keypad.
- SmartKash UI uses original branding, text, and different standard colors from the reference screenshots.
- No bKash logo, exact bKash colors, or copied promotional artwork is used.
- Login UI remains presentation-first and does not store PIN in Flutter.

## Flutter Generated Brand Assets

- `apps/mobile/assets/images/` contains SmartKash-generated logo/header/promo assets.
- `pubspec.yaml` registers `assets/images/`.
- Home header uses a generated SmartKash header image with readable overlay.
- Home promo card uses a generated SmartKash fintech banner image.
- Login screen uses the generated SmartKash logo mark.
- Manual Flutter run should not show `Unable to load asset` errors.
- Android launcher icon uses the generated SmartKash mark instead of the default Flutter icon.
- Web favicon and PWA icons use the generated SmartKash mark instead of the default Flutter icon.
- Web manifest theme color uses the SmartKash teal theme.

## Flutter Firebase OTP Login UI

- Login screen sends Firebase Phone Auth OTP using test phone numbers only.
- Login screen verifies the fixed Firebase test OTP and signs in to Firebase.
- Firebase ID token is sent to backend `/api/auth/firebase-login` after OTP verification.
- Backend JWT is saved through secure token storage when backend login succeeds.
- Login UI shows loading, info, and error states.
- If backend Firebase Admin env is missing, the UI shows a clear backend login error.
- PIN is not stored or verified in Flutter during this step.

## Flutter Auth Route Guard

- Opening the app while unauthenticated redirects to the Login screen.
- Successful Firebase OTP plus backend JWT login redirects to Home.
- Home header shows the authenticated phone number and backend role from the backend JWT response.
- Logout clears Firebase/backend local session and returns to Login.
- Restarting the app attempts to restore an existing Firebase session and sync backend JWT.
- This step does not add PIN setup UI, wallet UI, QR scanner UI, or money-changing feature UI.

## Flutter PIN Setup UI

- `GET /api/users/me` exposes `pinSet` and `pinUpdatedAt` only; raw PIN and PIN hash are never returned.
- Authenticated users with `pinSet=false` are routed to `/pin-setup` before Home.
- PIN setup screen accepts exactly 5 digits and asks for confirmation.
- Mismatched PIN and confirm PIN shows a user-facing error.
- Successful `POST /api/auth/set-pin` updates auth state to `pinSet=true` and routes to Home.
- Flutter does not store the raw PIN locally.
- This step does not add PIN reset, biometric login, wallet UI, QR scanner UI, or money-changing feature UI.

## Backend Local Env Import

- `services/backend/.env` exists locally and is ignored by Git.
- Spring Boot imports `optional:file:.env[.properties]` from the backend working directory.
- Backend logs should say `Firebase Admin SDK initialized for project ...` when Firebase Admin values are valid.
- Firebase private key values with surrounding quotes and escaped `\n` should be normalized before credential parsing.
- Backend logs must not print the Firebase private key.
- `.env`, Firebase service account JSON, and machine-specific secrets must remain unstaged.
- A fake Firebase token should return `401 Invalid Firebase ID token`, confirming backend verification is active.

## Firebase Android Client Package Alignment

- `apps/mobile/android/app/google-services.json` must contain a Firebase Android client with package name `com.smartkash.app`.
- `apps/mobile/android/app/build.gradle` must use `namespace 'com.smartkash.app'`.
- `apps/mobile/android/app/build.gradle` must use `applicationId 'com.smartkash.app'`.
- `MainActivity.kt` must use package `com.smartkash.app`.
- `flutter run` should pass `:app:processDebugGoogleServices` without `No matching client found for package name`.
- The duplicate ignored copy at `apps/mobile/android/google-services.json` is not used by Gradle; the active file is under `android/app/`.

## Firebase OTP Error Handling

- When tapping `Send OTP`, the login UI must not show raw platform text such as `TypeError ... JavaScriptObject`.
- Firebase phone verification failures should show a readable message, for example invalid phone number, too many attempts, Phone Auth disabled, or Android app not authorized.
- A Firebase failure message should not mean backend login was bypassed; Firebase verification must still be required before backend JWT login.
- If the app is running on Chrome/Web, the login UI should explain that the current OTP setup is Android-only unless Firebase Web app config is added.
