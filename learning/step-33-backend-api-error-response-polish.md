# Step 33: Backend API Error Response Polish

## 1. Step title

এই ধাপে SmartKash backend API error response polish করা হয়েছে।

## 2. What was implemented

এই ধাপে নতুন business feature যোগ করা হয়নি। শুধু backend API error response আরও consistent করা হয়েছে।

যা করা হয়েছে:

- Missing JWT হলে JSON `401 Unauthorized` response।
- Invalid/expired JWT হলে JSON `401 Unauthorized` response।
- Non-admin user admin API call করলে JSON `403 Forbidden` response।
- Validation error হলে JSON `400 Bad Request` response।
- Duplicate/constraint conflict হলে JSON `409 Conflict` response।
- Missing resource হলে JSON `404 Not Found` response।
- Unexpected error হলে safe JSON `500 Internal Server Error` response।

## 3. Why this step is needed

Flutter app যখন backend API call করবে, তখন success response এর পাশাপাশি error response-ও predictable হতে হবে।

যদি প্রতিটি error আলাদা format এ আসে, তাহলে Flutter side-এ error message দেখানো কঠিন হবে। তাই আমরা backend-এ একটি common error format রাখছি:

```json
{
  "timestamp": "2026-07-07T10:00:00Z",
  "status": 401,
  "error": "Unauthorized",
  "message": "Authentication is required.",
  "path": "/api/wallet/me",
  "errors": []
}
```

এই format Flutter app-কে সহজে বুঝতে সাহায্য করবে কোন error user-কে দেখাতে হবে, আর কোন error developer/debugging এর জন্য।

## 4. Which files/folders were changed

এই files update করা হয়েছে:

- `services/backend/src/main/java/com/smartkash/security/JwtAuthenticationFilter.java`
- `services/backend/src/main/java/com/smartkash/security/SecurityConfig.java`
- `services/backend/src/main/java/com/smartkash/common/exception/GlobalExceptionHandler.java`
- `docs/backend-api-plan.md`
- `docs/security-plan.md`
- `docs/test-checklist.md`
- `docs/codex-progress.md`
- `learning/step-33-backend-api-error-response-polish.md`

## 5. Important code snippets

### Invalid JWT handling in `JwtAuthenticationFilter`

```java
try {
    principal = jwtService.parseToken(token);
} catch (IllegalArgumentException exception) {
    writeUnauthorizedResponse(request, response);
    return;
}
```

ব্যাখ্যা:

- `jwtService.parseToken(token)` backend JWT parse এবং validate করে।
- token invalid, expired, বা badly formatted হলে `IllegalArgumentException` throw হতে পারে।
- আগে এই error filter layer থেকে default error হিসেবে বের হতে পারত।
- এখন `writeUnauthorizedResponse(...)` call করে same JSON error format ফেরত দেওয়া হয়।
- `return` দিয়ে filter chain থামিয়ে দেওয়া হয়, যাতে invalid token নিয়ে request controller পর্যন্ত না যায়।

### Unauthorized JSON response

```java
ApiErrorResponse errorResponse = ApiErrorResponse.of(
        HttpStatus.UNAUTHORIZED.value(),
        HttpStatus.UNAUTHORIZED.getReasonPhrase(),
        "Invalid or expired backend JWT.",
        request.getRequestURI(),
        List.of()
);
```

ব্যাখ্যা:

- `HttpStatus.UNAUTHORIZED.value()` মানে `401`।
- `getReasonPhrase()` থেকে `Unauthorized` text পাওয়া যায়।
- message user/developer friendly রাখা হয়েছে।
- `request.getRequestURI()` কোন API path-এ error হয়েছে তা রাখে।
- `List.of()` মানে extra field-level errors নেই।

### Missing JWT handling in `SecurityConfig`

```java
.exceptionHandling(exception -> exception
        .authenticationEntryPoint((request, response, authException) -> {
            ApiErrorResponse errorResponse = ApiErrorResponse.of(
                    HttpStatus.UNAUTHORIZED.value(),
                    HttpStatus.UNAUTHORIZED.getReasonPhrase(),
                    "Authentication is required.",
                    request.getRequestURI(),
                    List.of()
            );
            response.setStatus(HttpStatus.UNAUTHORIZED.value());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            objectMapper.writeValue(response.getWriter(), errorResponse);
        })
)
```

ব্যাখ্যা:

- `authenticationEntryPoint` কাজ করে যখন protected API call করা হয় কিন্তু login/JWT নেই।
- `Authentication is required.` message দিয়ে clear করে যে token লাগবে।
- `response.setStatus(401)` HTTP status set করে।
- `response.setContentType(application/json)` Flutter/API client-কে জানায় response JSON।
- `objectMapper.writeValue(...)` Java object কে JSON response বানায়।

### Forbidden admin access handling

```java
.accessDeniedHandler((request, response, accessDeniedException) -> {
    ApiErrorResponse errorResponse = ApiErrorResponse.of(
            HttpStatus.FORBIDDEN.value(),
            HttpStatus.FORBIDDEN.getReasonPhrase(),
            "You do not have permission to access this resource.",
            request.getRequestURI(),
            List.of()
    );
    response.setStatus(HttpStatus.FORBIDDEN.value());
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    objectMapper.writeValue(response.getWriter(), errorResponse);
})
```

ব্যাখ্যা:

- user authenticated হলেও যদি role ঠিক না হয়, তখন `403 Forbidden` হবে।
- উদাহরণ: `CUSTOMER` role দিয়ে `/admin/users` call করলে।
- এতে Flutter app বুঝতে পারবে user logged in আছে, কিন্তু permission নেই।

### Global conflict handling

```java
@ExceptionHandler(DataIntegrityViolationException.class)
public ResponseEntity<ApiErrorResponse> handleDataIntegrityViolationException(
        DataIntegrityViolationException exception,
        HttpServletRequest request
) {
    return error(
            HttpStatus.CONFLICT,
            "Request conflicts with existing data.",
            request.getRequestURI(),
            List.of()
    );
}
```

ব্যাখ্যা:

- database unique constraint fail হলে Spring `DataIntegrityViolationException` throw করতে পারে।
- উদাহরণ: same mobile number, same merchant number, duplicate idempotency key।
- raw database error user-কে দেখানো unsafe।
- তাই safe message দেওয়া হয়েছে: `Request conflicts with existing data.`
- HTTP status `409 Conflict` ব্যবহার করা হয়েছে।

### Safe unexpected error handling

```java
@ExceptionHandler(Exception.class)
public ResponseEntity<ApiErrorResponse> handleUnexpectedException(Exception exception, HttpServletRequest request) {
    return error(
            HttpStatus.INTERNAL_SERVER_ERROR,
            "Unexpected server error.",
            request.getRequestURI(),
            List.of()
    );
}
```

ব্যাখ্যা:

- কোনো unhandled exception হলে backend এখন generic safe message দেবে।
- stack trace, secret, SQL detail, Firebase key, JWT detail response body-তে যাবে না।
- server log-এ debug করা যাবে, কিন্তু API response safe থাকবে।

## 6. Why no business feature was added

এই step-এর লক্ষ্য ছিল API response polish করা। তাই এই ধাপে wallet, ledger, add money, send money, payment, recharge, savings, loan, admin business logic, migration, বা Flutter UI যোগ করা হয়নি।

## 7. How this fits into SmartKash flow

SmartKash Flutter app সব API call করার সময় একই error shape পাবে।

উদাহরণ:

- token না থাকলে login screen দেখানো যাবে।
- permission না থাকলে access denied message দেখানো যাবে।
- validation error হলে form field-এর নিচে error দেখানো যাবে।
- idempotency/duplicate conflict হলে user-কে retry বা new request key ব্যবহার করতে বলা যাবে।

## 8. Common mistakes and cautions

- JWT missing আর invalid JWT একই জিনিস না। Missing হলে `Authentication is required.`, invalid হলে `Invalid or expired backend JWT.`
- `403 Forbidden` মানে user logged in কিন্তু permission নেই।
- `401 Unauthorized` মানে authentication লাগবে বা token invalid।
- raw database error কখনও API response-এ দেওয়া উচিত না।
- generic `Exception` handler রাখলেও server logs দেখা গুরুত্বপূর্ণ।
- Flutter side-এ শুধু HTTP status না, response body-এর `message` এবং `errors` field-ও handle করতে হবে।

## 9. Manual verification commands

Backend compile/test:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
.\mvnw.cmd spring-boot:run
```

Protected API without JWT:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/api/wallet/me
```

Expected output:

- HTTP status: `401`
- JSON body message: `Authentication is required.`

Protected API with invalid JWT:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/api/wallet/me -Headers @{ Authorization = "Bearer wrong-token" }
```

Expected output:

- HTTP status: `401`
- JSON body message: `Invalid or expired backend JWT.`

Admin API with non-admin JWT:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/admin/users -Headers @{ Authorization = "Bearer <customer-jwt>" }
```

Expected output:

- HTTP status: `403`
- JSON body message: `You do not have permission to access this resource.`

Validation error example:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/api/auth/firebase-login -Method POST -ContentType "application/json" -Body "{}"
```

Expected output:

- HTTP status: `400`
- JSON body message: `Request validation failed.`
- `errors` array contains field-level validation messages.

General git check:

```powershell
cd /d D:\github\my-kash
git status
```

Expected output:

- only local-only `application-local.yml` may remain modified
- no Step 33 source/docs/learning files should be uncommitted after commit

## 10. Git commands used

```powershell
git status --short --branch
git diff --check
git add <step-33-files>
git commit -m "step-33: polish backend api error responses"
git push
git status --short --branch
```

## 11. What I learned from this step

এই step থেকে শিখলাম:

- API success response যেমন গুরুত্বপূর্ণ, error response-ও ততটাই গুরুত্বপূর্ণ।
- Spring Security error আর Controller error আলাদা layer থেকে আসে, তাই দুই জায়গাতেই JSON handling দরকার।
- `401`, `403`, `400`, `404`, `409`, `500` status আলাদা অর্থ বহন করে।
- Flutter app সহজে integrate করার জন্য backend error format consistent হওয়া দরকার।
- Sensitive error detail user-facing response-এ দেওয়া নিরাপদ নয়।
