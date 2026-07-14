# SmartKash Codex Progress

## Current Project

- Project name: SmartKash
- MVP type: zero-budget learning MVP
- Current branch: main

## Completed Steps

- Step 00 planning foundation: planning files, architecture rules, Bengali learning workflow, Git/GitHub workflow rules, and progress tracking file prepared.
- Step 00b learning documentation rules: strengthened the Bengali learning file requirements before Step 01.
- Step 01 project structure: created focused root folders for the future Flutter app, Spring Boot backend, helper scripts, and added a project `.gitignore`.
- Step 02 Flutter app skeleton: created the initial Flutter shell under `apps/mobile/` with Riverpod, go_router, base theme/config, feature-first folders, and a placeholder home screen.
- Step 03 Spring Boot backend skeleton: created the Maven/Java 21 Spring Boot backend shell under `services/backend/` with base dependencies, environment-based config placeholders, package markers, Maven Wrapper, and context-load test.
- Step 04 PostgreSQL and Flyway foundation: enabled local datasource/JPA/Flyway configuration through environment variables, added the empty Flyway migration folder, and documented Maven Wrapper verification against the local PostgreSQL database.
- Step 05 Firebase Auth foundation: added Flutter Firebase Core/Auth dependencies, opt-in Firebase initialization, auth service/provider structure, Android client config instructions, backend Firebase Admin environment-property foundation, and Firebase ID token verifier skeleton without login API/JWT/user creation.
- Step 06 backend auth JWT foundation: added `POST /api/auth/firebase-login`, Firebase token verification service flow, backend JWT generation/parsing, stateless Spring Security foundation, DTO validation, global API error responses, and JWT unit coverage without user/wallet/PIN/business persistence.
- Step 06b cross-platform planning and structure update: changed project direction from Flutter Android-first to Flutter full cross-platform, added/verified Android, iOS, Web, Windows, Linux, and macOS platform folders, preserved existing Flutter app structure and backend foundations, and documented platform limitations.
- Step 06c manual verification workflow: updated Codex workflow rules so heavy Flutter/backend build and test commands are not run automatically unless explicitly requested; Codex now commits/pushes focused changes and provides manual verification commands for the user.
- Step 07 user/profile database foundation: added Flyway migration for minimal `users` and `user_profiles` tables, JPA entities, repositories, role/status enums, response DTOs, mapper/service/controller foundation, and read-only `GET /api/users/me` without wallet, PIN, ledger, transaction, or money-changing features.
- Step 08 Firebase login user persistence: linked `POST /api/auth/firebase-login` to the persisted `users` table so valid Firebase tokens create or find a minimal user record and issue backend JWTs with the persisted role, without wallet, PIN, profile editing, or money-changing features.
- Step 09 user profile completion foundation: added authenticated `PUT /api/users/me/profile` to create or update minimal profile fields using the JWT/Firebase UID, without accepting user IDs or adding wallet, PIN, or money-changing features.
- Step 10 PIN setup foundation: added user PIN fields, BCrypt password encoder, authenticated `POST /api/auth/set-pin`, 5-digit PIN validation, backend-only hashing, and PIN setup response metadata without PIN verification, rate limiting, wallet, or money-changing features.
- Step 11 PIN verification foundation: added authenticated `POST /api/auth/verify-pin`, BCrypt PIN matching, failed attempt tracking, 15-minute temporary block after 5 wrong attempts, and UI sample-image workflow reminder without wallet or money-changing APIs.
- Step 12 wallet database foundation: added `wallets` table, wallet entity/repository/DTO/mapper/service/controller, optimistic version field, and read-only `GET /api/wallet/me` without wallet creation, balance mutation, ledger, transaction, or money-changing APIs.
- Step 13 ledger and transaction database foundation: added `transactions` and `ledger_entries` tables, enums, entities, and repositories for immutable ledger/user-facing transaction records without APIs, wallet balance changes, or money movement.
- Step 14 idempotency key database foundation: added `idempotency_keys` table, enums, entity, repository, and internal service helper foundation without controllers, public APIs, wallet balance mutation, or money-changing flows.
- Step 15 wallet creation lifecycle: linked Firebase login to backend wallet provisioning so authenticated users get one zero-balance `BDT` wallet when missing, without ledger entries, transaction records, wallet balance mutation APIs, or money-changing flows.
- Step 16 admin audit log foundation: added `admin_audit_logs` table, audit action/target enums, entity, repository, and internal service helper foundation without admin APIs or approval/rejection flow integration.
- Step 17 Add Money request foundation: added `add_money_requests` table, status/source enums, entity, repository, DTOs, mapper, service, and authenticated customer create/list APIs that save `PENDING` requests only without wallet credit, ledger entries, transaction records, idempotency records, FCM alerts, or admin approval flows.
- Step 18 merchant profile foundation: added `merchants` table, merchant status enum, entity, repository, DTOs, mapper, service, and authenticated current-user create/read APIs that promote the user role to `MERCHANT` without payment, wallet debit/credit, ledger entries, or transaction records.
- Step 19 Loan request foundation: added `loan_requests` table, loan status enum, entity, repository, DTOs, mapper, service, and authenticated customer create/list APIs that save `PENDING` requests only without approval/rejection, disbursement, wallet credit, repayment, installments, ledger entries, or transaction records.
- Step 20 Mobile recharge foundation: added `mobile_recharges` table, operator/status enums, entity, repository, DTOs, mapper, service, and authenticated customer demo create/list APIs that save recharge records only without wallet debit, provider integration, ledger entries, transaction records, idempotency records, PIN confirmation, or FCM alerts.
- Step 21 Savings goal foundation: added `savings_goals` table, goal status enum, entity, repository, DTOs, mapper, service, and authenticated customer create/list APIs that save goal records only without savings deposits, wallet debit, ledger entries, transaction records, idempotency records, PIN confirmation, or FCM alerts.
- Step 22 Transaction history read API foundation: added authenticated read-only transaction list/detail APIs, response DTO, mapper, service, and filtered repository query without creating, updating, or deleting transactions, ledger entries, or wallet balances.
- Step 23 Admin read API foundation: added `ADMIN`-only security for `/admin/**`, read-only admin endpoints for users, transactions, add-money requests, loan requests, recharges, payments placeholder, and audit logs without approval/rejection, dashboard analytics, settings, role management, wallet mutation, or money-changing actions.
- Step 24 Add Money admin approval/rejection: added `ADMIN` approval/rejection endpoints with idempotency, locked request/wallet reads, wallet credit on approval, `ADD_MONEY` transaction record, immutable credit ledger entry, idempotency completion, and admin audit logs; rejection updates status/audit/idempotency only without wallet balance changes.
- Step 25 Loan admin approval/rejection: added `ADMIN` status-only loan decision endpoints with locked loan request reads, `reviewed_by`, `reviewed_at`, and admin audit logs without wallet credit, disbursement, transaction records, ledger entries, idempotency records, repayment, or installments.
- Step 26 Send Money receiver validation: added authenticated receiver resolve API for registered mobile number or SmartKash QR payload, validating active sender, registered active receiver, self-transfer block, and active receiver wallet without wallet transfer, PIN verification, idempotency, transaction records, or ledger entries.
- Step 27 Send Money transfer flow: added authenticated money-changing `POST /api/send-money` with mobile/QR receiver selection, PIN confirmation, idempotency, locked sender/receiver wallets, balance debit/credit, sender/receiver transaction records, and linked immutable ledger entries.
- Step 28 Merchant Payment transfer flow: added authenticated money-changing `POST /api/payments/merchant` with merchant number lookup, PIN confirmation, idempotency, locked customer/merchant wallets, customer debit, merchant credit, merchant payment transaction records, linked immutable ledger entries, and admin payments read support.
- Step 29 Savings Deposit transfer flow: added authenticated money-changing `POST /api/savings/goals/{id}/deposit` with PIN confirmation, idempotency, locked savings goal and wallet, wallet debit, goal current amount update, auto-complete when target is reached, `SAVINGS_DEPOSIT` transaction record, and immutable debit ledger entry.
- Step 30 Mobile Recharge wallet debit flow: updated demo `POST /api/recharge` to require PIN and idempotency, lock and debit the user wallet, create a `MOBILE_RECHARGE` transaction record, create an immutable debit ledger entry, attach the transaction reference to the recharge record, and keep the zero-budget no-provider demo success rule.
- Step 31 FCM transaction alert foundation: added `firebase_devices` migration, authenticated FCM token registration API, notification device entity/repository/DTO/mapper/service, FCM properties, and transaction alert service boundary that skips safely when FCM is disabled or Firebase Admin is not configured.
- Step 32 Transaction alert wiring: connected `TransactionAlertService` to Add Money decisions, Loan decisions, Send Money, Merchant Payment, Savings Deposit, and Mobile Recharge success paths while keeping FCM delivery optional and non-blocking.
- Step 33 API error response polish: added consistent JSON error handling for missing/invalid JWT, forbidden admin access, validation errors, duplicate/constraint conflicts, missing resources, and safe unexpected server errors.
- Step 34 local E2E seed and API verification guide: added a dev-only PostgreSQL seed script for demo users/profiles/wallets and at least 15 rows in each main business table, plus a manual backend E2E API test guide with expected outputs.
- Step 35 Flutter API client foundation: added Dio, secure token storage, centralized API client/providers, backend auth repository, backend token model, configurable API base URL, and Flutter-side API error mapping without adding UI screens or feature flows.
- Step 36 Flutter auth flow foundation: added auth session state/status, Riverpod auth controller, Firebase current-user backend JWT sync, and local sign-out coordination without adding login/OTP UI or visual screen design.
- Step 37 Flutter reference UI shell: recorded the user's reference-image UI rule and added SmartKash-original Home and Login UI shells inspired by the provided layout/hierarchy while using different branding and colors.
- Step 37b Flutter UI run fix: cleaned analyzer-blocking UI shell warnings by removing an unused import, replacing deprecated opacity calls, and fixing const lint issues so Flutter analysis passes again.
- Step 38 Flutter generated brand assets: generated original SmartKash logo/header/promo images, registered Flutter assets, and wired them into Home and Login UI without copying reference-brand artwork.
- Step 38b Flutter launcher and web icon polish: replaced default Android launcher and web favicon/PWA icons with the generated SmartKash logo mark and aligned web theme colors.
- Step 39 Firebase OTP login UI: wired Login screen to Firebase Phone Auth test OTP, Firebase sign-in, backend JWT sync, loading/info/error states, and Android Google Services config support without adding PIN or wallet feature UI.
- Step 40 Flutter auth route guard and logged-in Home state: made routing depend on backend-authenticated session state, restored Firebase/backend session on startup, redirected unauthenticated users to Login, and showed logged-in phone/role plus sign-out on Home without adding feature API screens.
- Step 41 PIN setup UI flow: exposed safe `pinSet` metadata in `GET /api/users/me`, added Flutter PIN setup API/repository/controller state, added a SmartKash PIN setup screen, and routed authenticated users with missing PIN to setup before Home without storing PIN in Flutter.
- Step 42 backend local env import: configured Spring Boot to import ignored `services/backend/.env` during local runs, normalized Firebase private key formatting, completed Firebase service account JSON fields, and verified Firebase Admin initialization without committing secrets.
- Step 43 Firebase Android package alignment: aligned Android `namespace`, `applicationId`, and `MainActivity` package with the provided Firebase Android client config package `com.smartkash.app`.
- Step 44 Firebase OTP error handling fix: wrapped Firebase phone verification failures in an app-safe exception and mapped them to clear user-facing messages instead of leaking platform TypeError text.
- Step 45 Firebase OTP platform guard: blocked unsupported Chrome/Web OTP attempts with a clear message because the current Firebase client setup is Android-only.
- Step 46 backend env import hardening: made Spring Boot import the ignored backend `.env` both when run from `services/backend` and when run from the repository root/IDE.
- Step 47 login timeout and retry UX fix: increased Flutter API timeouts, mapped backend timeout/connection errors to clear messages, aligned app package constant, and kept OTP verification retry available after backend login failure.
- Step 48 backend login diagnostics: replaced the generic Flutter backend-login env message with the actual backend error and added safe backend logging for Firebase token verification failures.
- Step 49 local JWT secret setup: added a 64-character local-only JWT secret to ignored `services/backend/.env` and documented the 32-byte minimum requirement.
- Step 50 Firebase Admin SDK properties mapping: fixed backend Firebase Admin property binding so local `.env` Firebase values map correctly into Spring configuration.
- Step 51 wallet balance home dashboard: connected Flutter Home balance display to authenticated backend wallet API and refreshed wallet state on app start.
- Step 52 transaction history UI: added Flutter transaction list/detail UI connected to backend read-only transaction APIs.
- Step 53 Add Money request UI: added Flutter Add Money request create/list UI connected to backend pending request APIs.
- Step 54 Send Money wizard UI: added Flutter Send Money mobile receiver resolve, amount, PIN, and result flow connected to backend transfer API.
- Step 55 QR Send Money foundation UI: added QR payload display/paste flow for Send Money receiver selection foundation.
- Step 56 Merchant Payment UI completion: added backend merchant resolve API, connected Flutter Merchant Payment to real backend merchant validation, removed dummy merchant data, kept one stable idempotency key per payment attempt, refreshed wallet balance after success, and documented manual verification outputs.
- Step 57 Mobile Recharge UI: added Flutter demo Mobile Recharge screen connected to existing backend wallet-debit recharge API, including operator selection, number/amount/note entry, PIN confirmation, stable idempotency key per attempt, recharge history list, wallet refresh, and manual verification documentation.
- Step 58 Savings Goal UI: added Flutter Savings screen connected to existing backend goal create/list and wallet-debit deposit APIs, including goal progress cards, optional target date, PIN-confirmed deposits, stable idempotency key per deposit attempt, wallet refresh, and manual verification documentation.
- Step 59 Loan request/status UI: added Flutter Loan screen connected to existing backend loan request create/list APIs, showing MVP Phase 1 status-only behavior without wallet disbursement, repayment, installments, or money-changing flow.
- Step 60 Registration/profile flow: added profile completion registration step after Firebase login and PIN setup, added URL-based profile image support in Flutter, added Account screen from bottom navigation, exposed profile completion in auth state, and hardened Firebase login so stale backend JWT does not block login/register.
- Step 61 Backend-stored profile image flow: replaced profile image URL input with Flutter image picker upload, added backend multipart profile image upload, stored files under the configured backend profile image folder, saved generated `avatar_image_id` references in PostgreSQL, and exposed profile images through a backend image read endpoint.
- Step 62 Notification inbox placeholder UI: added a Flutter Inbox screen from bottom navigation that documents important transaction alert categories and local FCM limitations without adding notification history schema or extra backend APIs.
- Step 63 Home MVP placeholder polish: added clear bottom-sheet notices for currently out-of-scope Home actions such as Cash Out, Pay Bill, and See More instead of leaving taps silent.
- Step 64 Quick Features demo navigation cleanup: made Home Quick Features actionable by linking History to Transactions, Teletalk to Recharge, Transfer to Send Money, Goals to Savings, and adding honest MVP notices for Rewards and Offers.
- Step 65 Local demo seed data: ran the existing E2E seed script against local PostgreSQL so the main SmartKash tables have at least 15 valid rows for app testing, with seed PIN `12345` for generated demo users.
- Step 66 Instant Add Money and Inbox Transactions: changed Add Money from admin approval/pending flow to instant customer top-up with idempotency, wallet credit, transaction record, immutable credit ledger entry, refreshed Flutter Add Money UI, and redesigned Inbox with Transactions/Notifications tabs plus receipt bottom sheet.
- Step 67 Complete Inbox transaction coverage: added loan request transaction records so Loan also appears in Inbox transaction history, and expanded the Inbox Notifications tab to cover the planned core areas: Add Money, Send Money, Merchant Payment, Statement, Transactions, Savings, Loan, and Mobile Recharge.
- Step 68 Home header visual polish: updated the Flutter Home header so the profile image uses the user's backend avatar when available, balance is hidden behind a tap-to-reveal chip, the top background image is displayed in a clear separate band without controls over it, and Home spacing labels are closer to the provided reference.
- Step 69 Cash Out and Pay Bill working demo flows: added backend `POST /api/cash-out` and `POST /api/pay-bill` wallet-debit demo APIs with PIN verification, idempotency, locked wallet debit, transaction records, immutable debit ledger entries, optional FCM alerts, Flutter Cash Out and Pay Bill screens, Home navigation, Inbox transaction labels, and clean verification for backend compile/tests plus Flutter analyze/tests.
- Step 70 Inbox-first transaction history polish: removed feature-screen bottom transaction lists from Add Money and Mobile Recharge, ensured all successful money-related Flutter flows invalidate the shared Inbox transaction provider, expanded the Home action grid height to avoid bottom overflow warnings, and improved Inbox transaction load errors with visible backend/API details for manual debugging.

## Last Commit

- Last commit message: pending Step 70 commit.
- Last commit hash: pending Step 70 commit.

## Important Architecture Decisions

- Flutter full cross-platform app.
- Supported Flutter platforms: Android, iOS, Web, Windows, Linux, and macOS.
- Android remains the primary local testing target on Windows.
- Web can also be tested locally on Windows.
- Windows desktop builds require Visual Studio Desktop development with C++ workload.
- iOS/macOS builds require macOS with Xcode.
- Linux builds require a Linux environment.
- Flutter architecture: Riverpod + feature-first folders.
- Spring Boot backend root package: `com.smartkash`.
- Backend architecture: clean layered feature modules with controller, service, service implementation, repository, entity, DTO, mapper, enums, exception, config, security, firebase, notification, util, and audit.
- Main business database: PostgreSQL.
- Migration tool: Flyway.
- Firebase usage: Phone Auth test OTP and important FCM alerts only.
- Firebase Phone Auth uses test phone numbers and fixed OTP only in MVP; real SMS OTP is not used.
- Flutter Firebase initialization is opt-in until local Firebase Android client config is provided.
- Spring Boot Firebase Admin config uses environment variables only; service account JSON must not be committed.
- Spring Boot verifies Firebase ID tokens before issuing a backend JWT.
- Backend JWT is stateless and contains minimal claims from the persisted user record: Firebase UID, mobile number, and role.
- Minimal persisted user foundation uses `users.firebase_uid` and `users.mobile_number` as unique identifiers.
- Minimal persisted role/status values use `UserRole` and `UserStatus` enums.
- `GET /api/users/me` is read-only and returns the current persisted user/profile record when it exists.
- Firebase login creates or finds the minimal persisted user record and ensures one zero-balance wallet exists, but does not create PIN, ledger, transaction, idempotency, or money-changing records.
- Firebase login now also ensures one zero-balance wallet exists for the authenticated user, but does not create ledger, transaction, idempotency, or money-changing records.
- `PUT /api/users/me/profile` creates or updates only the authenticated user's minimal profile fields and resolves ownership from JWT/Firebase UID.
- `POST /api/auth/set-pin` requires backend JWT, resolves the user from Firebase UID, validates a 5-digit numeric PIN, stores only a BCrypt hash, and returns only PIN setup metadata.
- `POST /api/auth/verify-pin` requires backend JWT, checks the raw request PIN against the stored BCrypt hash, tracks failed attempts, and blocks PIN verification for 15 minutes after 5 wrong attempts.
- Before Flutter UI design work starts, Codex must ask the user for sample/reference images and use them as the visual direction.
- Send Money must support both registered mobile number and QR receiver selection.
- Wallet balance is stored for fast reads, backed by immutable ledger entries.
- Step 12 wallet foundation creates the wallet table/read model only; balance mutation is intentionally blocked until ledger and transaction foundations exist.
- Step 13 ledger/transaction foundation adds persistence only; services must later create transaction records and immutable ledger entries together in one database transaction when money movement is implemented.
- Step 14 idempotency foundation stores one key per user plus request hash, operation type, status, optional saved response body, and expiry time so future money-changing APIs can safely handle retries.
- Step 15 wallet lifecycle creates only the initial wallet record with zero balance and `ACTIVE` status; future balance changes still require ledger entries and transaction records.
- Step 16 admin audit foundation records future admin state changes with action, target type, target id, details, and admin user reference.
- Step 17 Add Money request foundation allows authenticated customers to create/list pending funding requests, but the request itself is not a wallet balance change.
- Step 18 merchant profile foundation keeps merchant business data in `merchants` and role in `users.role = MERCHANT`, matching the planned merchant model.
- Step 19 Loan request foundation follows MVP Phase 1 scope: approval/rejection will only update status later; disbursement and repayment remain future scope.
- Step 20 Mobile recharge foundation follows the zero-budget MVP rule: recharge creates a demo record only and does not call a real recharge provider or change wallet balance.
- Step 21 Savings goal foundation creates savings targets only. Depositing money into savings remains a future money-changing step that must use PIN, idempotency, wallet locking, transactions, and immutable ledger entries.
- Step 22 Transaction history API is read-only and user-scoped. It can return empty lists until future money-changing flows create transaction records.
- Step 23 Admin read API foundation protects `/admin/**` with `ROLE_ADMIN` and keeps the admin panel minimal and read-only until dedicated approval/rejection steps are implemented.
- Step 24 Add Money approval is the first backend money-changing flow. It uses admin role protection, idempotency, request/wallet locking, wallet credit, transaction record, immutable ledger entry, and audit log in one database transaction.
- Step 25 Loan approval follows MVP Phase 1 scope and is intentionally status-only with audit logging; future loan disbursement must be a separate money-changing flow.
- Step 26 Send Money receiver validation supports both registered mobile number and QR receiver selection. The MVP QR payload format is `SMARTKASH_USER:<mobile-number>`, and it must resolve to an active registered receiver with an active wallet before future transfer processing.
- Step 27 Send Money transfer is the first customer wallet-to-wallet money-changing flow. It uses PIN verification, idempotency, pessimistic wallet locking, balance debit/credit, sender `SEND_MONEY` transaction, receiver `RECEIVE_MONEY` transaction, and linked debit/credit ledger entries.
- Step 28 Merchant Payment uses the same money-changing safety model as Send Money, but resolves the receiving account through `merchants.merchant_number` and credits the merchant user's wallet.
- Step 29 Savings Deposit uses the money-changing safety model for a one-sided wallet debit into a savings goal balance. The wallet ledger records the debit, while the savings goal tracks the saved amount.
- Step 30 Mobile Recharge uses the money-changing safety model for a demo provider-less wallet debit. The recharge record is marked `SUCCESS` locally and references the wallet debit transaction.
- Step 31 keeps notifications limited to important transaction alerts. Device tokens are persisted in PostgreSQL, and FCM sending is isolated in `TransactionAlertService` so controllers and business services do not contain Firebase Messaging details.
- Step 32 keeps notification delivery out of controllers and uses the `TransactionAlertService` boundary from business services after successful state changes.
- Step 33 standardizes backend error responses with `ApiErrorResponse` so Flutter can handle authentication, authorization, validation, conflict, not-found, and unexpected errors through one response shape.
- Step 34 keeps E2E seed data outside Flyway migrations. Local demo data is loaded manually through `scripts/dev/seed-e2e-data.sql` and must not be treated as production data.
- Step 35 centralizes Flutter backend communication through `ApiClient`, maps backend `ApiErrorResponse` into `ApiException`, and stores only backend JWT values in secure storage.
- Step 36 separates auth orchestration from UI: Firebase Auth remains in `FirebasePhoneAuthService`, backend JWT exchange remains in `BackendAuthRepository`, and `AuthController` coordinates state for future screens.
- Step 37 establishes the UI reference rule: use provided screenshots for layout direction only, keep SmartKash branding/colors original, and ask for more screen-specific references or asset dimensions before future visual screen work when needed.
- Step 37b keeps the UI shell presentation-only while making analyzer output clean enough for local Flutter run/build verification.
- Step 38 uses generated raster assets for visual polish while keeping paths centralized in `AppAssets`; final production icons can later be optimized/resized or replaced with vector/adaptive-icon assets.
- Step 38b uses the generated SmartKash mark for Android launcher and web PWA icons so the installed app/browser tab no longer uses Flutter default branding.
- Step 39 keeps Firebase Phone Auth logic in `FirebasePhoneAuthService`, backend JWT exchange in `BackendAuthRepository`, session orchestration in `AuthController`, and UI rendering in `LoginScreen`.
- Step 40 keeps route decisions in a Riverpod-backed `GoRouter` provider. Home is reachable only after `AuthSessionStatus.authenticated`, and app startup tries to restore an existing Firebase session before syncing backend JWT.
- Step 41 exposes only PIN metadata (`pinSet`, `pinUpdatedAt`) to Flutter. Raw PIN and PIN hash remain backend-only. Flutter sends PIN only when saving setup through `POST /api/auth/set-pin`.
- Step 42 uses Spring Boot config import `optional:file:.env[.properties]` from the backend working directory. The `.env` file remains ignored by Git and must not be committed. Firebase private key formatting is normalized before Google credential parsing.
- Step 43 uses Android application ID `com.smartkash.app` because the provided Firebase Android client config contains package name `com.smartkash.app`.
- Step 44 keeps Firebase platform exceptions out of UI state by converting phone auth failures into a small local `FirebasePhoneAuthException` model before the controller builds user-facing copy.
- Step 45 confirms Firebase OTP is currently Android-only until a Firebase Web app config is added for Chrome/Web.
- Step 46 imports both `optional:file:.env[.properties]` and `optional:file:services/backend/.env[.properties]` so Firebase Admin env values are found from CLI and IDE run modes.
- Step 47 treats Firebase OTP and backend JWT login as two separate stages. If backend login times out after OTP, the UI keeps the OTP verification session available for retry instead of resetting to Send OTP.
- Step 48 keeps Firebase ID tokens out of logs but logs Firebase verification error code/message so local login failures can be diagnosed without guessing.
- Step 49 keeps JWT secrets local-only. `services/backend/.env` is ignored, and `JWT_SECRET` must be at least 32 bytes for HMAC signing.
- Step 56 resolves merchant accounts through `GET /api/payments/merchant/resolve` before showing the amount/PIN screens. Flutter must not use dummy merchant data for payment.
- Step 56 keeps a stable merchant payment idempotency key for one payment attempt, so retrying the same attempt does not create a second payment.
- Step 57 keeps Mobile Recharge as a zero-budget demo flow. Flutter calls the existing backend `/api/recharge` API, and the backend handles PIN verification, idempotency, wallet debit, transaction record, and ledger entry.
- Step 58 keeps Savings Goal creation separate from Savings Deposit. Goal creation does not change wallet balance; deposit uses backend PIN verification, idempotency, wallet debit, transaction record, and ledger entry.
- Step 59 keeps Loan MVP Phase 1 status-only. Flutter can create/list requests, but approval/rejection only changes request status and does not credit wallet or create repayment schedules.
- Step 60 registration flow is OTP-first and profile-completion-after-login. Existing users with PIN and profile go to Home; new/minimal users complete PIN and profile before Home. Profile image is URL-based to avoid paid storage services.
- Step 60 keeps `/api/auth/firebase-login` free from stale backend JWT interference on both Flutter API client and backend JWT filter.
- Step 61 stores profile images in the backend-controlled profile image folder for the learning MVP. PostgreSQL stores only the generated `avatar_image_id`, and Flutter displays images through the backend `/api/users/profile-images/{imageId}` URL.
- Step 62 keeps notification history out of scope. The Inbox screen is a lightweight user-facing placeholder for the existing FCM transaction alert plan, not a persisted message center.
- Step 63 keeps disabled MVP features honest in the UI. Out-of-scope Home actions should explain why they are unavailable instead of pretending to work or doing nothing.
- Step 64 keeps the Home demo path practical. Quick Features should lead to real implemented screens when available and show clear MVP notices when not available.
- Step 65 uses local-only seed data for testing. Seed users, wallets, transactions, requests, merchants, devices, and audit rows are demo data only and must not be treated as real financial records.
- Step 66 changes the active Add Money direction: customer submit instantly credits the wallet. Add Money no longer has active admin approve/reject endpoints in the MVP, but the existing `add_money_requests` table is reused as the top-up record table to avoid rewriting committed Flyway migrations.
- Step 66 places transaction history inside the Flutter Inbox tab, using a `Transactions` tab with search and a receipt bottom sheet, while `Notifications` remains a lightweight alert/offer view until persisted notification history is added.
- Step 67 ensures the planned Loan feature also contributes a `LOAN_REQUEST` transaction history record when a user submits a loan request. This record is status/history only and does not disburse money or create ledger entries.
- Step 68 keeps Home UI reference-driven while preserving SmartKash branding: user controls live in a separate top band, the generated header image remains clear, and balance is revealed only after the user taps the balance chip.
- Step 69 keeps Cash Out and Pay Bill as local learning MVP demo flows: they debit the SmartKash wallet and create ledger/transaction history, but they do not integrate real agent settlement, biller validation, provider callbacks, or external money movement.
- Step 70 makes Inbox the single transaction-history surface in the Flutter app. Feature screens can show immediate success receipts/messages, but long transaction lists should live in Inbox > Transactions.
- Money-changing operations require transactions, safe wallet locking, idempotency keys, and audit logs.
- Codex uses a manual verification workflow by default: do focused changes, update learning/progress docs, run lightweight checks only, commit/push, and provide manual verification commands.

## Manual Setup Completed By User

- Repository workspace created at `D:\github\my-kash`.
- Project name changed to SmartKash.
- GitHub remote `origin` is configured and push worked for previous workflow commits.
- Java 21 is available locally.
- Local PostgreSQL database `smartkash_db` is ready.
- Local PostgreSQL owner/user `smartkash_admin` is ready.
- Firebase project name is `SmartKash`.
- Android application ID is `com.smartkash.app`, matching the provided Firebase Android client config.
- Flutter platform folders are present for Android, iOS, Web, Windows, Linux, and macOS.
- Firebase test phone number is configured by the user as `01575634380` / `+8801575634380`.
- Firebase test OTP is configured by the user as `123456`.
- Android client `google-services.json` has been placed by the user at `apps/mobile/android/app/google-services.json`.
- Backend local `.env` has been created by the user at `services/backend/.env` and synchronized with Firebase Admin service account metadata. It remains local-only and ignored.

## Pending Manual Setup

- Confirm GitHub remote exists and is accessible.
- Install Visual Studio Desktop development with C++ workload before Windows desktop builds.
- Use macOS with Xcode before iOS/macOS builds.
- Use a Linux environment before Linux desktop builds.
- Create real local environment file from `.env.example` later; do not commit secrets.

## Known Issues

- Step 04 configures PostgreSQL/Flyway foundation only; no business APIs, Firebase Auth logic, JWT issuing, wallet, transaction, ledger, business schema, Flyway migration scripts, admin pages, or feature logic exist yet.
- Step 05 configures Firebase foundation only; no full login/register UI, backend login API, JWT issuing, PIN setup, PostgreSQL user records, wallet records, or business feature logic exists yet.
- Step 06 configures backend auth/JWT foundation only; it does not create PostgreSQL user records, wallet records, PIN setup, admin authorization persistence, or business feature logic.
- Step 06b changes direction and platform structure only; it does not add login/register UI, wallet, ledger, transaction, payment, QR, recharge, savings, loan, admin business features, or database schema.
- Step 07 creates only user/profile identity schema and read-only user foundation; no wallet, ledger, PIN, automatic user creation during login, admin user management, or money-changing API exists yet.
- Step 08 links Firebase login to persisted users only; no wallet creation, PIN setup, profile editing, admin management, or money-changing API exists yet.
- Step 09 adds minimal profile completion only; no wallet creation, PIN setup, admin profile management, KYC/NID fields, or money-changing API exists yet.
- Step 10 adds PIN setup only; no PIN verification, PIN rate limiting, temporary blocking, wallet creation, admin management, or money-changing API exists yet.
- Step 11 adds PIN verification only; no wallet creation, money-changing API, admin management, or Flutter UI design exists yet.
- Step 12 adds wallet database/read foundation only; no wallet auto-creation, balance mutation, ledger, transaction, admin management, or money-changing API exists yet.
- Step 13 adds ledger and transaction persistence only; no transaction history API, wallet balance mutation, idempotency table, admin management, or money-changing API exists yet.
- Step 14 adds idempotency persistence and internal helper only; it is not wired into Add Money, Send Money, Payment, Recharge, Savings, Loan, wallet mutation, or admin approval flows yet.
- Step 15 creates initial wallet records during login only; it does not implement wallet top-up, send money, payment, recharge, savings, loan, transaction history, or admin flows.
- Step 16 adds admin audit persistence only; it does not implement admin list APIs, approval/rejection APIs, or feature flow integration yet.
- Step 17 creates pending Add Money requests only; it does not implement admin approval/rejection, wallet credit, ledger entries, transaction records, idempotency usage, audit logging, or FCM alerts yet.
- Step 18 creates merchant profiles only; it does not implement merchant payment, QR payment, wallet debit/credit, admin merchant management, or merchant settlement.
- Step 19 creates pending Loan requests only; it does not implement admin approval/rejection, wallet disbursement, repayment, installments, ledger entries, transaction records, idempotency usage, audit logging, or FCM alerts yet.
- Step 20 creates demo Mobile Recharge records only; it does not implement wallet debit, PIN confirmation, idempotency usage, provider integration, ledger entries, transaction records, audit logging, or FCM alerts yet.
- Step 21 creates Savings Goal records only; it does not implement savings deposits, wallet debit, PIN confirmation, idempotency usage, ledger entries, transaction records, audit logging, or FCM alerts yet.
- Step 22 exposes transaction records for reading only; most current users may see an empty list until future money-changing flows create transaction records.
- Step 23 exposes minimal admin read APIs only; it does not create admin dashboards, analytics, advanced settings, complex role management, approvals, rejections, wallet mutation, or money-changing actions.
- Step 24 implements only Add Money admin approval/rejection; it does not implement loan approval, send money, merchant payment, mobile recharge wallet debit, savings deposit, FCM alerts, or frontend UI.
- Step 25 implements Loan admin approval/rejection status updates only; it does not implement loan disbursement, repayment, installments, wallet credit, transaction records, ledger entries, idempotency usage, FCM alerts, or frontend UI.
- Step 26 implements Send Money receiver validation only; it does not verify PIN, check sender balance, mutate wallets, create transaction records, create ledger entries, store idempotency records, send FCM alerts, or build Flutter UI.
- Step 27 implements backend Send Money transfer only; it does not build Flutter UI, QR scanner UI, FCM alerts, merchant payment, savings deposit, mobile recharge wallet debit, or admin screens.
- Step 28 implements backend Merchant Payment transfer only; it does not build Flutter UI, QR scanner UI, FCM alerts, merchant settlement, refunds, chargebacks, or provider/payment gateway integration.
- Step 29 implements backend Savings Deposit only; it does not build Flutter UI, FCM alerts, savings withdrawal, goal cancellation flow, interest/profit calculation, or separate savings wallet accounting.
- Step 30 implements backend demo Mobile Recharge wallet debit only; it does not integrate a real recharge provider, billing API, refund flow, FCM alerts, or Flutter UI.
- Step 31 implements FCM backend foundation only; it does not wire FCM alerts into every money-changing service yet, does not create Flutter notification UI, and does not require real deployed FCM delivery during local development.
- Step 32 wires backend alert calls only; it does not add Flutter notification permissions/UI, background handlers, notification preferences, or guaranteed local FCM delivery.
- Step 33 improves response consistency only; it does not add new business APIs, Flutter UI, database migrations, or external integrations.
- Step 34 adds local testing data and documentation only; it does not change backend production schema, add APIs, bypass Firebase authentication, or create real money movement.
- Step 35 adds Flutter networking/storage foundation only; it does not add login screens, wallet screens, QR scanner UI, feature API integration, PIN storage, or visual design.
- Step 36 adds Flutter auth state/controller foundation only; it does not add login/OTP screens, route guards, wallet feature UI, PIN UI, or final app visual design.
- Step 37 adds visual UI shells only; it does not connect real Firebase OTP submission, backend login button actions, wallet APIs, QR scanner, feature APIs, or real promotional images.
- Step 37b fixes analyzer-blocking UI shell warnings only; it does not wire Firebase OTP, backend login actions, wallet APIs, QR scanner, or feature APIs.
- Step 38 adds image assets and UI polish only; it does not wire Firebase OTP, backend login actions, wallet APIs, QR scanner, app launcher icons, or feature APIs.
- Step 38b updates app icons only; it does not implement adaptive icon XML, splash screen polish, Firebase OTP, backend login actions, wallet APIs, QR scanner, or feature APIs.
- Step 39 wires login/auth only; it does not implement PIN setup UI, wallet dashboard API UI, money-changing flows, QR scanner UI, or feature APIs.
- Step 40 adds auth routing only; it does not implement PIN setup UI, wallet balance API UI, profile completion UI, money-changing feature screens, QR scanner UI, or admin UI.
- Step 41 adds PIN setup UI only; it does not add PIN reset, biometric login, wallet dashboard API UI, money-changing screens, QR scanner UI, or feature APIs.
- Step 42 adds environment loading only; it does not add mock auth, bypass Firebase token verification, change business APIs, or commit secrets.
- Step 43 fixes Firebase Android package mismatch only; it does not add new login UI, wallet UI, business APIs, money-changing flows, or commit Firebase secret files.
- Step 44 fixes OTP error messaging only; it does not bypass Firebase verification, add fake login, change backend auth, or implement wallet/feature screens.
- Step 45 adds only a Flutter platform guard; it does not implement Web Firebase Phone Auth config, bypass OTP, or change backend authentication.
- Step 46 changes only Spring config import paths; it does not commit `.env`, Firebase Admin JSON, local machine secrets, or change authentication rules.
- Step 47 improves Flutter login retry/network messaging only; it does not bypass Firebase, create mock login, or change backend auth rules.
- Step 48 improves diagnostics only; it does not bypass Firebase verification, log raw tokens, change JWT rules, or commit secrets.
- Step 49 changes only local ignored `.env` and documentation; it does not commit the generated JWT secret or change auth security rules.
- Step 56 completes Merchant Payment UI for registered active merchants only; it does not add merchant QR payment, refund/chargeback, payment gateway integration, settlement reports, or admin merchant payment approval.
- Step 57 adds Mobile Recharge UI only; it does not integrate a real recharge provider, SMS/top-up gateway, refund flow, operator package catalog, or provider callback handling.
- Step 58 adds Savings Goal UI and deposit UI only; it does not add savings withdrawal, cancellation, profit/interest calculation, recurring deposits, or separate savings wallet accounting.
- Step 59 adds Loan request/status UI only; it does not add loan disbursement, wallet credit, repayment, installments, interest calculation, or loan contract documents.
- Step 60 adds profile completion/account UI only; it does not add paid image upload storage, KYC/NID verification, or real identity verification.
- Step 61 adds local backend profile image storage only; it does not add paid cloud storage, image cropping, camera capture, admin image moderation, CDN delivery, or production-grade object storage.
- Step 62 adds Inbox UI only; it does not add notification history tables, unread counts, push permission prompts, local notification rendering, or admin notification management.
- Step 63 added UI placeholder notices only; Step 69 later replaced Cash Out and Pay Bill placeholders with wallet-debit demo APIs and Flutter screens.
- Step 64 updates navigation only; it does not add new backend APIs, campaign/reward engines, offer eligibility rules, or additional money-changing flows.
- Step 65 inserts local demo records only; it does not change production schema, add migrations, bypass Firebase auth, or create real money movement.
- Step 66 does not integrate real bank APIs, payment gateways, provider callbacks, or real money movement. Add Money remains a local learning MVP top-up.
- Step 67 does not add loan disbursement, repayment, installments, or wallet credit. It only adds transaction-history visibility for loan requests.
- Step 68 adds in-app merchant/agent account opening and real agent-backed Cash Out wallet credit/debit; it does not allow one user account to be both merchant and agent, and it does not add real bank/agent settlement.
- Recipient image enhancement adds authenticated user/agent resolver endpoints and wires Cash Out, Mobile Recharge, and Pay Bill recipient cards, PIN screens, hold-confirm screens, and receipt screens to show real profile images when the entered number belongs to a registered SmartKash user or agent.
- `flutter create` timed out in the sandbox, so the minimal Flutter skeleton was created manually and verified with Flutter tooling.
- Global `mvn` is not available in the Codex session, so backend verification should use Maven Wrapper `.\mvnw.cmd`.
- Flyway works against local PostgreSQL 17.10 after adding `flyway-database-postgresql`, but logs a warning that this Flyway version officially tested support up to PostgreSQL 16.
- Android debug APK builds successfully after using Flutter v2 embedding metadata, AGP `8.6.0`, and installed NDK `28.2.13676358`; Flutter warns these AGP/Kotlin versions should be upgraded in a future maintenance step.
- Heavy verification commands are now user-run by default unless explicitly requested, to reduce token and execution limit usage.

## Next Recommended Step

- Manually run the app with backend running, create a merchant account on one test mobile number, create an agent account on another test mobile number, then verify Payment and Cash Out from a separate funded customer account.

## Standard Step Completion Format

Every future step must end with:

1. Step completed
2. Changed files
3. Lightweight checks run
4. Manual verification commands
5. Git status summary
6. Commit message
7. Commit hash
8. Push status
9. Learning file created/updated
10. Next recommended step
