# Step 06: Backend Auth JWT Foundation

## 1. Step title

Step 06-এর title: **Backend Firebase Login এবং JWT Foundation**.

এই step-এ Spring Boot backend-এ Firebase ID token verify করে SmartKash backend JWT issue করার foundation তৈরি করা হয়েছে। এটি authentication/security foundation মাত্র; user profile persistence, wallet, PIN, ledger, transaction, payment, recharge, savings, loan, admin business feature কোনোটি implement করা হয়নি।

## 2. What was implemented

এই step-এ implement করা হয়েছে:

- `POST /api/auth/firebase-login` endpoint।
- Firebase ID token request DTO।
- Auth token response DTO।
- Thin auth controller।
- Auth service interface এবং implementation।
- Firebase token verifier ব্যবহার করে token validate করার flow।
- Backend JWT generate এবং parse করার `JwtService`।
- JWT properties config।
- Stateless Spring Security config।
- Bearer token filter foundation।
- JWT principal object।
- Global exception handler।
- Standard API error response।
- JWT service unit test।
- `.env.example` এবং `application-local.yml`-এ `JWT_EXPIRATION_MINUTES`।
- `docs/codex-progress.md` update।
- এই Bangla learning file।

## 3. Why backend JWT is needed after Firebase verification

Firebase Phone Auth user-এর phone number verify করে এবং Flutter app-কে Firebase ID token দেয়। কিন্তু SmartKash backend-এর নিজের API security, role handling, admin/customer separation, future PIN checking, wallet access, এবং transaction authorization দরকার।

তাই flow হবে:

1. Firebase phone OTP test mode দিয়ে user verify হয়।
2. Flutter Firebase ID token নেয়।
3. Flutter backend-এ Firebase ID token পাঠায়।
4. Backend Firebase token verify করে।
5. Backend নিজের JWT issue করে।
6. Flutter future API calls-এ backend JWT পাঠাবে।

Backend JWT দরকার কারণ SmartKash business authorization backend-এর control-এ থাকবে।

## 4. Difference between Firebase ID token and backend JWT

Firebase ID token:

- Firebase issue করে।
- Phone auth identity prove করে।
- Backend verify করে।
- SmartKash role/wallet/business permission সরাসরি রাখে না।

Backend JWT:

- Spring Boot backend issue করে।
- SmartKash API access-এর জন্য ব্যবহার হবে।
- Minimal claims রাখে: Firebase UID, phone number, temporary role।
- Future step-এ persisted user role/status থেকে claim তৈরি হবে।

## 5. How `POST /api/auth/firebase-login` works

Endpoint:

```http
POST /api/auth/firebase-login
Content-Type: application/json

{
  "firebaseIdToken": "firebase-id-token-from-flutter"
}
```

Flow:

1. Controller request receive করে।
2. Bean Validation check করে `firebaseIdToken` blank কিনা।
3. Controller service call করে।
4. Service Firebase ID token verify করে।
5. Valid হলে Firebase UID এবং phone number নেয়।
6. Backend JWT generate করে।
7. Response-এ bearer token return করে।

Controller code:

```java
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/firebase-login")
    public ResponseEntity<AuthTokenResponse> firebaseLogin(@Valid @RequestBody FirebaseLoginRequest request) {
        return ResponseEntity.ok(authService.loginWithFirebase(request));
    }
}
```

Explanation:

- `@RestController` class-কে REST API controller বানায়।
- `@RequestMapping("/api/auth")` সব endpoint-এর base path।
- Controller শুধু request নেয় এবং service call করে; business logic controller-এ নেই।
- `@Valid` DTO validation চালায়।
- `ResponseEntity.ok(...)` success response return করে।

## 6. How Spring Security is configured

Security config:

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity httpSecurity) throws Exception {
        return httpSecurity
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                "/api/auth/**",
                                "/actuator/health",
                                "/actuator/info",
                                "/v3/api-docs/**",
                                "/swagger-ui/**",
                                "/swagger-ui.html"
                        ).permitAll()
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                .build();
    }
}
```

Block explanation:

- `@Configuration` Spring config class।
- `@EnableWebSecurity` Spring Security enable করে।
- CSRF disabled, কারণ REST API stateless JWT use করবে।
- `SessionCreationPolicy.STATELESS` session তৈরি করবে না।
- `/api/auth/**` public রাখা হয়েছে, যাতে login endpoint token নিতে পারে।
- health/docs endpoints public রাখা হয়েছে developer verification-এর জন্য।
- Future APIs authenticated হবে।
- JWT filter username/password filter-এর আগে run করবে।

## 7. How JWT is generated and validated

JWT generation:

```java
String token = Jwts.builder()
        .subject(firebaseUid)
        .claim(PHONE_NUMBER_CLAIM, phoneNumber)
        .claim(ROLE_CLAIM, role)
        .issuedAt(Date.from(issuedAt))
        .expiration(Date.from(expiresAt))
        .signWith(secretKey())
        .compact();
```

Explanation:

- `subject(firebaseUid)` JWT subject হিসেবে Firebase UID রাখে।
- `phone_number` claim phone number রাখে, যদি Firebase token-এ থাকে।
- `role` claim temporary role রাখে।
- `issuedAt` token কখন issue হয়েছে।
- `expiration` token কখন expire হবে।
- `signWith(secretKey())` environment-based secret দিয়ে sign করে।
- `compact()` final JWT string বানায়।

JWT validation/parsing:

```java
Claims claims = Jwts.parser()
        .verifyWith(secretKey())
        .build()
        .parseSignedClaims(token)
        .getPayload();
```

Explanation:

- Parser একই secret দিয়ে signature verify করে।
- Signature invalid বা expired হলে exception হবে।
- Valid হলে claims পাওয়া যায়।

JWT filter:

```java
String authorizationHeader = request.getHeader(HttpHeaders.AUTHORIZATION);

if (authorizationHeader == null || !authorizationHeader.startsWith(BEARER_PREFIX)) {
    filterChain.doFilter(request, response);
    return;
}
```

Explanation:

- `Authorization` header পড়ে।
- Header না থাকলে request normal security chain-এ যায়।
- `Bearer ` prefix না থাকলে JWT parse করা হয় না।

## 8. Why JWT secret must be environment-based

JWT secret দিয়ে backend token sign করে। Secret leak হলে attacker fake JWT বানাতে পারে। তাই:

- Secret code-এ hardcode করা যাবে না।
- `.env.example` শুধু placeholder রাখে।
- Real secret local/prod environment variable থেকে আসবে।
- `JWT_SECRET` কমপক্ষে 32 bytes হওয়া দরকার।

Config:

```yaml
smartkash:
  security:
    jwt:
      secret: ${JWT_SECRET:change-me-in-local-env}
      expiration-minutes: ${JWT_EXPIRATION_MINUTES:60}
```

Explanation:

- `JWT_SECRET` environment variable থেকে secret আসে।
- `JWT_EXPIRATION_MINUTES` token কত মিনিট valid থাকবে।
- Default শুধু local placeholder; real run-এ strong secret দিতে হবে।

## 9. Why PIN/user/wallet/business features are not implemented in this step

এই step-এর scope authentication foundation। তাই করা হয়নি:

- PIN setup।
- PIN hash storage।
- User table।
- User role/status persistence।
- Wallet table।
- Wallet creation।
- Ledger entries।
- Transaction records।
- Money-changing APIs।

কারণ এগুলো database schema, wallet rules, ledger consistency, idempotency, and audit logging-এর সাথে যুক্ত। আলাদা focused step-এ করলে শেখা এবং testing clean থাকে।

## 10. Which files/folders were created or changed

Created:

- `services/backend/src/main/java/com/smartkash/auth/controller/AuthController.java`
- `services/backend/src/main/java/com/smartkash/auth/dto/request/FirebaseLoginRequest.java`
- `services/backend/src/main/java/com/smartkash/auth/dto/response/AuthTokenResponse.java`
- `services/backend/src/main/java/com/smartkash/auth/service/AuthService.java`
- `services/backend/src/main/java/com/smartkash/auth/service/impl/AuthServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/common/exception/AuthException.java`
- `services/backend/src/main/java/com/smartkash/common/exception/GlobalExceptionHandler.java`
- `services/backend/src/main/java/com/smartkash/common/response/ApiErrorResponse.java`
- `services/backend/src/main/java/com/smartkash/security/JwtAuthenticationFilter.java`
- `services/backend/src/main/java/com/smartkash/security/JwtPrincipal.java`
- `services/backend/src/main/java/com/smartkash/security/JwtProperties.java`
- `services/backend/src/main/java/com/smartkash/security/JwtService.java`
- `services/backend/src/main/java/com/smartkash/security/JwtToken.java`
- `services/backend/src/main/java/com/smartkash/security/SecurityConfig.java`
- `services/backend/src/test/java/com/smartkash/security/JwtServiceTests.java`
- `learning/step-06-backend-auth-jwt-foundation.md`

Changed:

- `.env.example`
- `services/backend/src/main/resources/application-local.yml`
- `docs/codex-progress.md`

## 11. Important code/config snippets

Request DTO:

```java
public record FirebaseLoginRequest(
        @NotBlank(message = "Firebase ID token is required.")
        String firebaseIdToken
) {
}
```

Response DTO:

```java
public record AuthTokenResponse(
        String tokenType,
        String accessToken,
        Instant expiresAt,
        String firebaseUid,
        String phoneNumber,
        String role
) {
}
```

Service method:

```java
public AuthTokenResponse loginWithFirebase(FirebaseLoginRequest request) {
    FirebaseToken firebaseToken = verifyFirebaseToken(request.firebaseIdToken());
    String phoneNumber = phoneNumber(firebaseToken);
    JwtToken jwtToken = jwtService.generateToken(firebaseToken.getUid(), phoneNumber, DEFAULT_ROLE);

    return new AuthTokenResponse(
            "Bearer",
            jwtToken.accessToken(),
            jwtToken.expiresAt(),
            firebaseToken.getUid(),
            phoneNumber,
            DEFAULT_ROLE
    );
}
```

JWT principal:

```java
public record JwtPrincipal(
        String firebaseUid,
        String phoneNumber,
        String role
) {

    public Collection<? extends GrantedAuthority> authorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + role));
    }
}
```

## 12. Line-by-line or block-by-block Bangla explanation of snippets

### Request DTO

```java
@NotBlank(message = "Firebase ID token is required.")
```

Request body-তে token blank হলে validation error হবে।

```java
String firebaseIdToken
```

Flutter থেকে পাওয়া Firebase ID token এই field-এ আসবে।

### Response DTO

```java
String tokenType
```

Response token type, যেমন `Bearer`।

```java
String accessToken
```

Backend-issued JWT।

```java
Instant expiresAt
```

Token কখন expire হবে।

```java
String firebaseUid
```

Firebase user identity।

```java
String phoneNumber
```

Firebase token থেকে পাওয়া phone number, যদি থাকে।

```java
String role
```

Temporary role placeholder। Future database user role থেকে আসবে।

### Auth service

```java
FirebaseToken firebaseToken = verifyFirebaseToken(request.firebaseIdToken());
```

Firebase ID token valid কিনা verify করে।

```java
String phoneNumber = phoneNumber(firebaseToken);
```

Firebase claims থেকে phone number বের করে।

```java
JwtToken jwtToken = jwtService.generateToken(firebaseToken.getUid(), phoneNumber, DEFAULT_ROLE);
```

Backend JWT তৈরি করে।

### JWT principal

```java
String firebaseUid,
String phoneNumber,
String role
```

Authenticated request-এর minimal identity data।

```java
return List.of(new SimpleGrantedAuthority("ROLE_" + role));
```

Spring Security authority তৈরি করে, যেমন `ROLE_CUSTOMER`।

## 13. Common mistakes and cautions

- Firebase ID token আর backend JWT এক জিনিস নয়।
- JWT secret ছোট বা weak হলে security risk।
- JWT secret code-এ hardcode করা যাবে না।
- Firebase Admin service account JSON commit করা যাবে না।
- Login endpoint-এ user/wallet auto-create করা এই step-এর scope নয়।
- PIN setup এই step-এ করা যাবে না।
- Money-changing API auth foundation ছাড়া implement করা যাবে না।
- Controller-এ business logic লেখা যাবে না।
- Entities directly API response করা যাবে না।
- Temporary `CUSTOMER` role future persisted role নয়।

## 14. How to verify this step

Backend verification:

```powershell
cd services/backend
$env:DATABASE_URL="jdbc:postgresql://localhost:5432/smartkash_db"
$env:DATABASE_USERNAME="smartkash_admin"
$env:DATABASE_PASSWORD="<your-local-database-password>"
$env:SPRING_PROFILES_ACTIVE="local"
$env:JWT_SECRET="<at-least-32-byte-local-secret>"
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

General verification:

```powershell
git status --short
git diff --cached --stat
```

Expected:

- Context loads।
- JWT service unit test passes।
- Maven package succeeds।
- No user/wallet/business migration is created।
- No Firebase service account JSON is staged।

## 15. Git commands used in this step

```powershell
git status --short
git add .env.example services/backend/src/main/resources/application-local.yml services/backend/src/main/java/com/smartkash/auth services/backend/src/main/java/com/smartkash/security services/backend/src/main/java/com/smartkash/common docs/codex-progress.md learning/step-06-backend-auth-jwt-foundation.md
git diff --cached --stat
git commit -m "step-06: add backend auth jwt foundation"
git push
git status --short
```

## 16. What I learned from this step

এই step থেকে শিখলাম Firebase Phone Auth identity verify করার পর backend নিজের JWT issue করে API access control করতে পারে। Spring Security stateless করলে session লাগে না। JWT claim minimal রাখা উচিত। Strong secret environment variable থেকে আসতে হবে। User, wallet, PIN, ledger, এবং business logic আলাদা step-এ রাখলে architecture পরিষ্কার থাকে।
