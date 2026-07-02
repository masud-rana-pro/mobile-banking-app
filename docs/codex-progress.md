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

## Last Commit

- Last commit message: `step-06c: switch to manual verification workflow`
- Last commit hash: reported in the Step 06c completion summary after commit finalization.

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
- Backend JWT is stateless and contains only minimal temporary claims: Firebase UID, phone number when available, and a temporary role.
- Current role claim is a temporary `CUSTOMER` placeholder until persisted user roles are added in a later database/user step.
- Send Money must support both registered mobile number and QR receiver selection.
- Wallet balance is stored for fast reads, backed by immutable ledger entries.
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
- `flutter create` timed out in the sandbox, so the minimal Flutter skeleton was created manually and verified with Flutter tooling.
- Global `mvn` is not available in the Codex session, so backend verification should use Maven Wrapper `.\mvnw.cmd`.
- Flyway works against local PostgreSQL 17.10 after adding `flyway-database-postgresql`, but logs a warning that this Flyway version officially tested support up to PostgreSQL 16.
- Android debug APK builds successfully after using Flutter v2 embedding metadata, AGP `8.6.0`, and installed NDK `28.2.13676358`; Flutter warns these AGP/Kotlin versions should be upgraded in a future maintenance step.
- Heavy verification commands are now user-run by default unless explicitly requested, to reduce token and execution limit usage.

## Next Recommended Step

- Wait for the user's manual verification result for Step 06c workflow docs. After that, Step 07 can add minimal user/profile database foundation with Flyway migration and persisted role/status planning, without wallet or money-changing business features.

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
