# SmartKash

SmartKash is a full-stack digital wallet application built with Flutter and Spring Boot. It brings authentication, account management, wallet operations, transaction history, QR-based payments, savings, and loan requests into one consistent mobile experience.

The repository focuses on the engineering behind a wallet platform: secure identity, transactional balance updates, immutable ledger records, idempotent money operations, role-aware agent and merchant flows, and a responsive feature-first Flutter client.

## Highlights

- Firebase phone authentication with backend-issued JWT sessions
- Customer, agent, and merchant account workflows
- Add Money, Send Money, Cash Out, Merchant Payment, and Pay Bill
- Mobile Recharge, savings goals, deposits, and loan requests
- Contact and QR-based recipient selection
- PIN-protected transactions with hold-to-confirm interaction
- Wallet balance, transaction receipts, searchable history, and details
- Profile images, account editing, and notification device registration
- PostgreSQL persistence with versioned Flyway migrations
- Immutable ledger entries, wallet locking, and idempotency protection

## Architecture

```text
Flutter client
    |  Firebase ID token / JWT / REST
Spring Boot API
    |  JPA transactions / Flyway
PostgreSQL
```

The mobile app uses a feature-first structure with Riverpod for state management, `go_router` for navigation, Dio for API access, and secure local token storage. The backend separates controllers, services, repositories, entities, DTOs, and mappers by business domain.

Money-changing operations are executed inside database transactions. Wallet rows are locked before updates, every balance change produces a transaction record and ledger entry, and client-provided idempotency keys prevent duplicate processing.

## Technology

| Area | Stack |
| --- | --- |
| Mobile | Flutter, Dart, Riverpod, go_router, Dio |
| Authentication | Firebase Phone Auth, Spring Security, JWT |
| Backend | Java 21, Spring Boot 3, Spring Data JPA |
| Data | PostgreSQL, Flyway, Hibernate |
| Device features | Contacts, QR generation/scanning, image picker, secure storage |
| API tooling | Bean Validation, Actuator, OpenAPI/Swagger |

## Repository Layout

```text
apps/mobile/        Flutter application
services/backend/   Spring Boot REST API and database migrations
.env.example        Environment variable template
```

## Run Locally

### Prerequisites

- Flutter SDK with Android tooling
- Java 21
- PostgreSQL
- A Firebase project with Phone Authentication configured

### 1. Configure the environment

Copy `.env.example` to `services/backend/.env` and replace the placeholders with local values. Secrets and Firebase service-account files must remain outside Git.

Create the PostgreSQL database and user referenced by your environment variables, then start the backend:

```powershell
cd services/backend
.\mvnw.cmd spring-boot:run
```

Verify it is ready:

```powershell
curl http://localhost:8080/actuator/health
```

### 2. Run the mobile app

For an Android emulator:

```powershell
cd apps/mobile
flutter pub get
flutter run --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

For a physical Android phone connected over USB:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080
cd apps/mobile
flutter run
```

## Verification

```powershell
cd services/backend
.\mvnw.cmd test

cd ..\..\apps\mobile
flutter analyze
flutter test
```

## Configuration and Security

The committed configuration contains placeholders only. Database credentials, JWT secrets, Firebase Admin credentials, signing keys, generated builds, runtime uploads, and machine-specific files are excluded from version control.

This project implements wallet behavior in a local development environment. External banking, billing, recharge, KYC, and settlement providers are not connected, and the software is not intended to process real funds.
