# Codex Instructions For SmartKash

## Project Rules

- This is a zero-budget learning MVP.
- Do not use paid services.
- Do not integrate real money movement.
- Do not integrate real bank APIs.
- Do not integrate real payment gateways.
- Do not integrate real recharge providers.
- Do not integrate real KYC providers.
- Do not use real SMS OTP billing.
- Use Firebase Phone Auth test phone numbers and fixed OTP codes for MVP.
- Do not hardcode secrets, credentials, JWT secrets, database URLs, Firebase keys, or environment-specific values.
- Use `.env.example` as the environment template.

## Planning-First Workflow

- Update planning files before implementation when requirements change.
- Do not create Flutter, Spring Boot, database migration, or feature code until the matching plan is clear.
- Implement the project step by step.
- Keep each implementation step focused.
- After each implementation step, summarize files changed, lightweight checks run, and manual verification commands for the user.

## Git And GitHub Workflow

Codex must use Git and GitHub for every implementation step.

For every step:

1. Check current repo status first with `git status`.
2. Review relevant planning docs before editing.
3. Make only focused changes for the current step.
4. Do not mix unrelated features in the same step.
5. Update or create the required Bangla learning file under `learning/`.
6. Run only lightweight checks when needed, such as file existence checks, `rg` checks, safe formatting, or dependency/config review.
7. Show `git status` after changes.
8. Create a meaningful commit.
9. Push the commit to GitHub.
10. Stop and provide a short summary with manual verification commands for the user to run locally.

Commit message format:

```text
step-XX: short action summary
```

Examples:

- `step-01: add project structure`
- `step-02: add Flutter app skeleton`
- `step-03: add Spring Boot backend skeleton`
- `step-04: configure PostgreSQL and Flyway`
- `step-05: configure Firebase auth foundation`

After each successful step, push to GitHub with `git push`. If upstream is not set, use `git push -u origin main` for the `main` branch. If the current branch is not `main`, push the current branch name.

## Organization Rules

- Keep each step small and focused.
- Do not implement multiple major modules in one step.
- Do not rewrite unrelated planning files unnecessarily.
- Do not generate huge summaries unless needed.
- Do not paste full unchanged files in the final response.
- Only summarize changed files, lightweight checks, manual verification commands, commit message, push status, learning file, and next step.
- Always follow the existing planning docs.
- Always follow the Bengali learning documentation rule.
- Update `docs/codex-progress.md` after every implementation step.

## Manual Verification Workflow

To reduce unnecessary token and execution limit usage, Codex must not automatically run heavy build or test commands in every step unless the user explicitly asks.

Do not automatically run these commands:

- `flutter analyze`
- `flutter test`
- `flutter build apk`
- `flutter build web`
- `mvn test`
- `mvn package`
- `.\mvnw.cmd test`
- `.\mvnw.cmd -q -DskipTests package`

Instead, for normal implementation steps, Codex should:

1. Make focused code, dependency, config, or documentation changes for the requested step.
2. Update the required Bangla learning file.
3. Update `docs/codex-progress.md`.
4. Run only lightweight checks when necessary, such as file existence checks, `rg` checks, safe formatting, or dependency file review.
5. Provide the exact manual verification commands for the user to run locally in IDE/CMD.
6. Commit and push the changes to GitHub.
7. Stop and wait for the user's manual verification result.

If the user reports that manual verification passed, continue to the next requested step. If the user reports errors, fix only those errors in a focused fix step.

Flutter manual verification commands should usually include:

```powershell
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
flutter build web
```

Backend manual verification commands should usually include:

```powershell
cd services/backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

## Step Completion Response Format

At the end of every step, Codex must respond with:

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

## Backend Architecture Rules

- Use Spring Boot under root package `com.smartkash`.
- Include Spring Web, Spring Security, Spring Data JPA, Hibernate, PostgreSQL Driver, Lombok, Validation, Firebase Admin SDK, JWT library, Flyway, Actuator, and OpenAPI/Swagger when backend setup begins.
- Use clean layered architecture.
- Feature modules should follow consistent packages: `controller`, `service`, `service.impl`, `repository`, `entity`, `dto.request`, `dto.response`, `mapper`, and `enums` when needed.
- Use `enums` as the Java package name; do not create a package literally named `enum` because `enum` is a Java keyword.
- Controllers must be thin.
- Business logic must stay in service layer.
- Use service interfaces and implementation classes for major modules.
- Repositories should only handle database access.
- Entities should not be exposed directly in API responses.
- DTOs must be used for request and response payloads.
- Mappers should convert between Entity and DTO.
- Enums should be used for fixed statuses and types.
- Use Bean Validation annotations for input validation.
- Use global exception handling.
- Use transactions for money-changing operations.
- Use optimistic locking or a safe locking strategy for wallet balance updates.
- Use audit logs for admin actions and critical money operations.

## Flutter Architecture Rules

- SmartKash is a Flutter full cross-platform app.
- Supported Flutter platforms are Android, iOS, Web, Windows, Linux, and macOS.
- Android remains the primary local testing target on Windows.
- Web can also be tested locally on Windows.
- Windows desktop builds require Visual Studio Desktop development with C++ workload.
- iOS/macOS builds require macOS with Xcode.
- Linux builds require a Linux environment.
- Use Riverpod for state management.
- Use feature-first folders under `lib/features`.
- Keep UI widgets clean.
- API calls must stay in repository/service classes, not inside widgets.
- Use DTO/model classes for API payloads.
- Use secure storage for JWT and sensitive tokens.
- Do not store PIN in Flutter app.
- PIN should be sent only for transaction confirmation over secure API.
- Use centralized API client and centralized error handling.
- Use clear route management under `lib/app/router`.
- Use reusable shared widgets for buttons, input fields, loading states, error states, and transaction cards.
- Keep Firebase Auth logic separated from UI screens.
- Keep QR scan logic inside a dedicated QR feature/module.

## Learning Documentation Rule

Every future implementation step must create or update one Bengali learning file inside the `learning/` folder.

The learning file must teach the actual code, configuration, and structure changed in that step. It must not be only a short summary.

Learning file naming format:

```text
learning/step-XX-topic-name.md
```

Examples:

- `learning/step-01-project-setup.md`
- `learning/step-02-flutter-app-setup.md`
- `learning/step-03-spring-boot-backend-setup.md`
- `learning/step-04-firebase-auth-test-otp.md`
- `learning/step-05-spring-security-jwt.md`
- `learning/step-06-postgresql-database-setup.md`
- `learning/step-07-wallet-ledger-design.md`

Each learning file must be written in Bangla and include:

1. Step title
2. What was implemented
3. Why this step is needed
4. Which files were created or changed
5. Important code snippets
6. Important config snippets, when config is created or changed
7. Bangla explanation of important code/config, line-by-line or block-by-block
8. Why each created/changed file, folder, class, config, or command exists
9. How this step connects to the SmartKash app flow
10. Common mistakes and cautions
11. How to test or verify this step
12. Git commands used in this step
13. Short summary of what was learned

Do not skip the learning file for any implementation step. Do not write only a short summary. Include important snippets and explain them clearly enough that a beginner can follow the actual implementation step by step. Keep the explanation beginner-friendly but technically correct. Update the learning file in the same step where the code/config/structure is implemented. Planning-only steps can also create or update learning notes when useful.

When a step creates folders, the learning file must explain why each important folder exists. When a step creates classes, the learning file must explain each important class responsibility. When a step changes config, the learning file must explain the relevant config keys and why they are needed. When lightweight checks are run, include the commands and what their output means. When heavy verification is deferred to the user, include the manual verification commands.

## Feature Rules

- Keep Send Money support for both registered mobile number and QR-based receiver selection.
- QR Send Money must validate QR payload, registered receiver account, account status, sender balance, PIN, and idempotency key.
- Use idempotency keys for every money-changing API.
- Use simple user roles only: `CUSTOMER`, `MERCHANT`, `ADMIN`.
- Do not introduce a complex role/permission system in MVP Phase 1.
- Admin pages and admin APIs must require `ADMIN` role.
- Customer and merchant users must not access admin pages or admin APIs.

## Required Backend Enums

- `UserRole`: `CUSTOMER`, `MERCHANT`, `ADMIN`
- `UserStatus`: `ACTIVE`, `BLOCKED`, `PENDING`
- `WalletStatus`: `ACTIVE`, `BLOCKED`
- `TransactionType`: `ADD_MONEY`, `SEND_MONEY`, `RECEIVE_MONEY`, `MERCHANT_PAYMENT`, `SAVINGS_DEPOSIT`, `MOBILE_RECHARGE`, `LOAN_REQUEST`
- `TransactionStatus`: `PENDING`, `SUCCESS`, `FAILED`, `REJECTED`, `CANCELLED`
- `LedgerEntryType`: `DEBIT`, `CREDIT`, `REVERSAL`
- `AddMoneyStatus`: `PENDING`, `APPROVED`, `REJECTED`
- `LoanStatus`: `PENDING`, `APPROVED`, `REJECTED`
- `RechargeStatus`: `SUCCESS`, `FAILED`
- `MerchantStatus`: `ACTIVE`, `INACTIVE`, `BLOCKED`
- `NotificationType`: `ADD_MONEY`, `SEND_MONEY`, `PAYMENT`, `RECHARGE`, `SAVINGS`, `LOAN`

## Wallet And Ledger Rules

- Store wallet balance for fast reads.
- Every balance change must be backed by immutable ledger entries.
- Ledger entries must never be updated or deleted after creation.
- Corrections must use reversal ledger entries.
- Every money movement must create ledger entries and user-facing transaction records.
- Wallet-to-wallet transfers must create linked debit and credit ledger entries under the same transaction reference.

## Loan MVP Rule

In MVP Phase 1, loan approval or rejection only updates loan request status. Loan disbursement, wallet credit, repayment, and installment tracking are future scope.
