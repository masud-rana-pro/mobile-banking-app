# SmartKash Security Plan

## Authentication

- Flutter uses Firebase Phone Auth test phone numbers and fixed OTP codes in MVP.
- Flutter is a full cross-platform app, but Firebase Phone Auth local verification should start with Android and Web on the Windows development machine.
- Real SMS OTP is not used to avoid billing requirements.
- Flutter sends Firebase ID token to Spring Boot.
- Spring Boot verifies the Firebase token.
- Spring Boot creates or finds the minimal persisted user record by Firebase UID and verified Firebase phone number.
- Spring Boot issues its own backend JWT for API access.
- Backend JWT role comes from the persisted user record.

## Authorization

- Use simple `users.role`: `CUSTOMER`, `MERCHANT`, `ADMIN`.
- Admin routes and admin APIs require authenticated `ADMIN` role.
- Customer and merchant users must not access admin pages or admin APIs.
- User profile update must resolve the user from the authenticated backend JWT/Firebase UID and must not accept a user ID from the request body.
- Avoid complex role/permission management in MVP Phase 1.

## PIN Security

- PIN must be hashed in the backend.
- Raw PIN must never be stored.
- MVP PIN setup uses exactly 5 numeric digits.
- `POST /api/auth/set-pin` requires authenticated backend JWT and resolves the user from Firebase UID; it must not accept a user ID in the request body.
- PIN setup stores only a BCrypt hash plus PIN setup metadata.
- Raw PIN must never be logged or returned in an API response.
- PIN verification must happen only in the backend.
- PIN verification compares raw request PIN with the stored BCrypt hash using `PasswordEncoder.matches`.
- PIN verification tracks failed attempts and blocks verification temporarily after 5 wrong attempts for 15 minutes.
- Money-changing APIs require authenticated user plus PIN confirmation.
- PIN verification attempts must be rate-limited.
- After multiple wrong PIN attempts, money-changing actions must be temporarily blocked.
## UI Design Rule

- Before starting Flutter UI design work, ask the user for sample/reference images and use them as visual direction.

## Money-Changing API Security

Every money-changing request must validate:

- Authenticated backend JWT.
- User account status.
- PIN confirmation.
- Sender wallet status.
- Sender balance, when debit is required.
- Idempotency key.
- Feature-specific receiver or target resource.

Every money-changing operation must run in a database transaction and use optimistic locking or another safe locking strategy for wallet balance updates.

## QR Send Money Security

QR Send Money must validate:

- QR payload format.
- Registered receiver user/account.
- Receiver account status.
- Sender balance.
- PIN.
- Idempotency key.

The backend must not trust QR data without resolving it against registered backend records.

## Secret Management

Do not hardcode:

- Database credentials.
- Firebase credentials.
- JWT secrets.
- Environment-specific values.

Use environment variables based on `.env.example`.

## Audit

Admin actions such as Add Money approval, Add Money rejection, Loan approval, and Loan rejection should create admin audit log records.

Critical money operations such as Send Money, Merchant Payment, Savings Deposit, Mobile Recharge, and Add Money approval should also be auditable through transaction references, ledger entries, and audit records where appropriate.

## API Safety Rules

- Controllers must be thin and must not contain business logic.
- Business rules must live in service classes.
- Repositories must only handle database access.
- Entities must not be returned directly from APIs.
- DTOs must be used for request and response payloads.
- Bean Validation annotations should validate incoming request DTOs.
- Global exception handling should return consistent API errors.
