# SmartKash Codex Progress

## Current Project

- Project name: SmartKash
- MVP type: zero-budget learning MVP
- Current branch: main

## Completed Steps

- Step 00 planning foundation: planning files, architecture rules, Bengali learning workflow, Git/GitHub workflow rules, and progress tracking file prepared.
- Step 00b learning documentation rules: strengthened the Bengali learning file requirements before Step 01.
- Step 01 project structure: created focused root folders for the future Flutter app, Spring Boot backend, helper scripts, and added a project `.gitignore`.
- Step 02 Flutter app skeleton: created the Android-first Flutter shell under `apps/mobile/` with Riverpod, go_router, base theme/config, feature-first folders, and a placeholder home screen.

## Last Commit

- Last commit message: `step-01: add project structure`
- Last commit hash: `d259883`

## Important Architecture Decisions

- Flutter Android-first app.
- Flutter architecture: Riverpod + feature-first folders.
- Spring Boot backend root package: `com.smartkash`.
- Backend architecture: clean layered feature modules with controller, service, service implementation, repository, entity, DTO, mapper, enums, exception, config, security, firebase, notification, util, and audit.
- Main business database: PostgreSQL.
- Migration tool: Flyway.
- Firebase usage: Phone Auth test OTP and important FCM alerts only.
- Send Money must support both registered mobile number and QR receiver selection.
- Wallet balance is stored for fast reads, backed by immutable ledger entries.
- Money-changing operations require transactions, safe wallet locking, idempotency keys, and audit logs.

## Manual Setup Completed By User

- Repository workspace created at `D:\github\my-kash`.
- Project name changed to SmartKash.
- GitHub remote `origin` is configured and push worked for previous workflow commits.

## Pending Manual Setup

- Confirm GitHub remote exists and is accessible.
- Confirm local Java, Flutter, and PostgreSQL tools before implementation.
- Configure Firebase test phone numbers later when Firebase setup begins.
- Create real local environment file from `.env.example` later; do not commit secrets.

## Known Issues

- No implementation code exists yet.
- Step 02 creates a Flutter skeleton only; no business features, Firebase packages, API calls, QR scan, wallet, or transaction logic exist yet.
- `flutter create` timed out in the sandbox, so the minimal Flutter skeleton was created manually and verified with Flutter tooling.
- The Step 02 commit hash will be reported after commit.

## Next Recommended Step

- Step 03: add Spring Boot backend skeleton under `services/backend/` after reviewing the planning docs.

## Standard Step Completion Format

Every future step must end with:

1. Step completed
2. Changed files
3. Verification commands run
4. Git status summary
5. Commit message
6. Push status
7. Learning file created/updated
8. Next recommended step
