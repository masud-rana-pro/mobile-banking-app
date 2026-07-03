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

## Last Commit

- Last commit message: `step-23: add admin read api foundation`
- Last commit hash: pending until Step 23 commit finalization.

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
- Android application ID is `com.imran.smartkash`.
- Flutter platform folders are present for Android, iOS, Web, Windows, Linux, and macOS.

## Pending Manual Setup

- Confirm GitHub remote exists and is accessible.
- Configure Firebase test phone numbers and fixed OTP codes in Firebase Console.
- Place Android client `google-services.json` manually at `apps/mobile/android/app/google-services.json` only if needed for local Android Firebase runs; do not commit it.
- Provide Firebase Admin SDK values through environment variables when backend token verification is tested.
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
- `flutter create` timed out in the sandbox, so the minimal Flutter skeleton was created manually and verified with Flutter tooling.
- Global `mvn` is not available in the Codex session, so backend verification should use Maven Wrapper `.\mvnw.cmd`.
- Flyway works against local PostgreSQL 17.10 after adding `flyway-database-postgresql`, but logs a warning that this Flyway version officially tested support up to PostgreSQL 16.
- Android debug APK builds successfully after using Flutter v2 embedding metadata, AGP `8.6.0`, and installed NDK `28.2.13676358`; Flutter warns these AGP/Kotlin versions should be upgraded in a future maintenance step.
- Heavy verification commands are now user-run by default unless explicitly requested, to reduce token and execution limit usage.

## Next Recommended Step

- Ask the user to run Step 23 manual verification commands. After verification passes, the next recommended step is Add Money admin approval/rejection foundation with wallet credit still handled carefully through money-changing rules.

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
