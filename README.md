# SmartKash

SmartKash is a zero-budget learning MVP for a bKash-like wallet app. The project will be built step by step with a Flutter full cross-platform app, a Spring Boot backend, PostgreSQL for business data, Firebase Phone Auth test OTP, and Firebase Cloud Messaging for important transaction alerts.

This repository now contains the shared Flutter cross-platform app foundation, Spring Boot backend foundation, PostgreSQL/Flyway setup, Firebase foundation, backend JWT foundation, planning docs, and Bangla learning notes. Future work should still follow the planning-first step workflow and avoid adding unrelated features in the same step.

## MVP Features

- Add Money with admin approval
- Send Money by registered mobile number
- Send Money by QR-based receiver selection
- Merchant Payment
- Statement and transaction receipts
- Goal-based Savings
- Loan request with admin approval or rejection status
- Demo Mobile Recharge
- Minimal Spring web admin panel
- Bengali learning documentation for every future implementation step

## Tech Scope

- Flutter full cross-platform app
- Supported Flutter platforms: Android, iOS, Web, Windows, Linux, and macOS
- Android remains the primary local testing target on Windows
- Web can also be tested locally on Windows
- Windows desktop builds require Visual Studio Desktop development with C++ workload
- iOS/macOS builds require macOS with Xcode
- Linux builds require a Linux environment
- Riverpod state management
- Spring Boot REST API and minimal web admin
- Spring Web, Spring Security, Spring Data JPA, Hibernate, Bean Validation
- PostgreSQL Driver, Flyway database migrations, Lombok
- Firebase Admin SDK, JWT library, Spring Boot Actuator, OpenAPI/Swagger
- PostgreSQL database
- Firebase Phone Auth test phone numbers and fixed OTP codes
- Firebase Cloud Messaging for important alerts only
- JWT-based backend API authentication after Firebase token verification

## Architecture Scope

- Backend root package: `com.smartkash`.
- Backend uses clean layered architecture: controller, service, service implementation, repository, entity, DTO, mapper, enums, exception, config, security, firebase, notification, util, and audit.
- Flutter uses a feature-first architecture with `lib/app`, `lib/core`, `lib/features`, and `lib/shared`.
- API calls must stay outside widgets in repository/service classes.
- Entities must not be exposed directly in API responses; request and response DTOs are required.
- Money-changing operations must use database transactions, idempotency keys, audit logs, and a safe wallet locking strategy.

## Important MVP Boundaries

This is a zero-budget learning MVP, not a real licensed financial service.

The MVP will not integrate real bank APIs, payment gateways, recharge providers, KYC providers, real SMS OTP, or real money movement. Firebase Phone Auth must use test phone numbers and fixed OTP codes to avoid SMS billing requirements.

## Wallet And Ledger Rule

Wallet balance will be stored for fast reads, but every balance change must be backed by immutable ledger entries and user-facing transaction records. Ledger entries must never be updated or deleted after creation. Any correction must be done using reversal ledger entries.

Wallet-to-wallet transfers must create linked debit and credit ledger entries under the same transaction reference.

## Learning Rule

Every future implementation step must create or update a Bengali learning file inside `learning/`.

File naming format:

```text
learning/step-XX-topic-name.md
```

See `learning/README.md` and `docs/codex-instructions.md` for the required format.

## Git And Step Workflow

Every implementation step must use Git and GitHub:

1. Check `git status`.
2. Review the relevant planning docs.
3. Make only focused changes for the current step.
4. Update or create the required Bangla learning file in `learning/`.
5. Run relevant verification commands or tests when possible.
6. Check `git status` again.
7. Commit with `step-XX: short action summary`.
8. Push to GitHub.
9. Stop with a short step completion summary.

Track step progress in `docs/codex-progress.md`.

## Environment

Use `.env.example` as the template for local configuration. Do not hardcode database credentials, Firebase credentials, JWT secrets, or environment-specific values in source code.

## Local Android Run

For real phone or emulator testing on Windows, avoid hardcoding a changing WiFi/LAN IP address. Start the Spring Boot backend first, then run the helper script:

```powershell
cd D:\github\my-kash
.\scripts\dev\run_mobile_real_phone.ps1
```

The script runs `adb reverse tcp:8080 tcp:8080` and starts Flutter with `SMARTKASH_API_BASE_URL=http://127.0.0.1:8080`, so the Android app can reach the PC backend through USB debugging.

From Windows CMD, use the wrapper:

```bat
cd /d D:\github\my-kash
scripts\dev\run_mobile_real_phone.cmd
```

If you intentionally test over WiFi instead of USB, run Flutter with:

```powershell
cd D:\github\my-kash\apps\mobile
flutter run --dart-define "SMARTKASH_API_BASE_URL=http://<PC-LAN-IP>:8080"
```
