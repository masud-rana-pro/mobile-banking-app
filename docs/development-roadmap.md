# SmartKash Development Roadmap

## Phase 0: Planning

- Create planning files.
- Create `learning/README.md`.
- Lock zero-budget MVP assumptions.
- Keep planning-first workflow.
- Add Git/GitHub workflow rules.
- Create `docs/codex-progress.md`.
- Commit and push planning/workflow changes before implementation.

## Required Workflow For Every Step

1. Run `git status`.
2. Review relevant planning docs.
3. Make focused changes only.
4. Update the matching Bangla learning file under `learning/`.
5. Run only lightweight checks when needed, unless the user explicitly asks for heavy verification.
6. Run `git status` again.
7. Commit using `step-XX: short action summary`.
8. Push to GitHub.
9. Update `docs/codex-progress.md`.
10. Stop with the standard step completion summary and manual verification commands.

## Manual Verification Workflow

To reduce unnecessary token and execution limit usage, Codex should not automatically run heavy build/test commands in every step unless the user explicitly asks.

Do not automatically run:

- `flutter analyze`
- `flutter test`
- `flutter build apk`
- `flutter build web`
- `mvn test`
- `mvn package`
- `.\mvnw.cmd test`
- `.\mvnw.cmd -q -DskipTests package`

Codex should still commit and push after each focused coding/config/doc step. Then the user runs the manual verification commands locally and reports the result.

If manual verification passes, continue to the next step. If manual verification fails, fix only the reported errors in a focused fix step.

## Commit Message Examples

- `step-01: add project structure`
- `step-02: add Flutter app skeleton`
- `step-03: add Spring Boot backend skeleton`
- `step-04: configure PostgreSQL and Flyway`
- `step-05: configure Firebase auth foundation`

## Phase 1: Project Setup

- Create shared Flutter full cross-platform app foundation.
- Verify Android and Web locally on Windows.
- Create Spring Boot backend.
- Add Spring Web, Spring Security, Spring Data JPA, Hibernate, PostgreSQL Driver, Lombok, Validation, Firebase Admin SDK, JWT library, Flyway, Actuator, and OpenAPI/Swagger.
- Set backend root package to `com.smartkash`.
- Create backend layered package skeleton for major modules.
- Create Flutter feature-first folder skeleton with Riverpod.
- Configure PostgreSQL connection using environment variables.
- Configure Firebase test project placeholders.
- Create Bengali learning file for this step.

## Phase 2: Platform-Specific Polishing And Auth/Security

- Polish platform-specific setup for Android, iOS, Web, Windows, Linux, and macOS as needed.
- Keep Android as the primary local testing target on Windows.
- Use Web as the second local verification target on Windows.
- Remember Windows desktop builds require Visual Studio Desktop development with C++ workload.
- Remember iOS/macOS builds require macOS with Xcode.
- Remember Linux builds require a Linux environment.
- Add Firebase token verification in backend.
- Issue backend JWT.
- Add mobile user model.
- Add PIN setup and hashed storage.
- Add PIN verification with rate limiting and temporary transaction block.
- Create Bengali learning file for this step.

## Phase 3: Production Packaging And Database Foundation

- Add production packaging steps for each platform only when needed.
- Add users, wallets, ledger entries, transactions, idempotency keys, and audit logs.
- Add simple roles: `CUSTOMER`, `MERCHANT`, `ADMIN`.
- Create Bengali learning file for this step.

## Phase 4: Wallet And Ledger

- Implement wallet balance read.
- Implement immutable ledger rules.
- Implement linked debit/credit ledger entries for wallet-to-wallet transfer.
- Implement reversal entry planning for corrections.
- Add transaction boundaries and safe wallet locking strategy.
- Create Bengali learning file for this step.

## Phase 5: Core Money Features

- Add Money request and admin approval.
- Send Money by mobile number.
- QR Send Money receiver resolution and validation.
- Merchant Payment.
- Create Bengali learning files for each implementation step.

## Phase 6: User Records

- Transaction list.
- Transaction receipt.
- Statement filters by date/type/status.
- Create Bengali learning file for this step.

## Phase 7: Savings, Loan, Recharge

- Goal savings and savings deposit.
- Loan request with admin approval/rejection status only.
- Demo mobile recharge using `mobile_recharges`.
- Create Bengali learning files for each implementation step.

## Phase 8: Admin And Notifications

- Minimal admin web panel.
- Admin role protection.
- FCM important alerts.
- Audit logs.
- Create Bengali learning files for each implementation step.

## Phase 9: Testing And Review

- Manual app flow tests.
- API tests.
- Security tests.
- Idempotency tests.
- Ledger consistency tests.
- Create Bengali learning file for testing.
