# SmartKash Backend

The SmartKash backend is a Spring Boot REST API for identity, wallet, transaction, ledger, agent, merchant, savings, recharge, bill-payment, and loan workflows.

## Engineering Approach

- Domain-oriented packages with controller, service, repository, DTO, mapper, and entity layers
- Firebase ID-token verification followed by JWT-based API sessions
- Spring Security authorization for customer and administrative operations
- Transactional wallet updates with pessimistic locking
- Immutable debit and credit ledger entries
- Idempotency protection for money-changing requests
- PostgreSQL schema evolution through Flyway migrations
- Bean Validation, structured API errors, health checks, and OpenAPI documentation

## Main API Areas

| Area | Base path |
| --- | --- |
| Authentication | `/api/auth` |
| Users and profiles | `/api/users` |
| Wallet | `/api/wallet` |
| Add Money | `/api/add-money/requests` |
| Send Money | `/api/send-money` |
| Cash Out and agents | `/api/cash-out`, `/api/agents` |
| Merchant payments | `/api/payments`, `/api/merchants` |
| Bill payment | `/api/pay-bill` |
| Recharge | `/api/recharge` |
| Savings | `/api/savings/goals` |
| Loans | `/api/loans/requests` |
| Transactions | `/api/transactions` |
| Administration | `/admin` |

## Local Setup

Use the root `.env.example` as the configuration template and keep the populated `services/backend/.env` file local.

```powershell
.\mvnw.cmd spring-boot:run
```

Flyway applies the schema migrations automatically. When the service is ready, the health endpoint returns `{"status":"UP"}`:

```powershell
curl http://localhost:8080/actuator/health
```

Swagger UI is available at `http://localhost:8080/swagger-ui/index.html`.

## Tests

```powershell
.\mvnw.cmd test
.\mvnw.cmd -DskipTests package
```

## Security Notes

- Store database credentials, JWT secrets, and Firebase credentials in environment variables.
- Never store raw PIN values; PIN verification is handled by the backend.
- Require authentication, PIN confirmation, and idempotency for protected wallet operations.
- Apply balance changes and ledger writes in the same database transaction.
- Keep uploaded profile images and service-account files outside version control.
