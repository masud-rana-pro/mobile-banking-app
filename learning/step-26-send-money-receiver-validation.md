# Step 26: Send Money Receiver Validation Foundation

## 1. Step Title

Step 26-এ SmartKash backend-এ Send Money করার আগে receiver খুঁজে বের করা এবং validate করার foundation যোগ করা হয়েছে।

## 2. What Was Implemented

এই step-এ একটি authenticated API যোগ করা হয়েছে:

```http
POST /api/send-money/resolve-receiver
```

এই API দুইভাবে receiver খুঁজতে পারে:

```json
{
  "mobileNumber": "01712345678"
}
```

অথবা QR payload দিয়ে:

```json
{
  "qrPayload": "SMARTKASH_USER:01712345678"
}
```

এই step-এ যা validate হয়:

- sender backend JWT দিয়ে authenticated কিনা
- sender user record আছে কিনা
- sender account `ACTIVE` কিনা
- request-এ `mobileNumber` অথবা `qrPayload` এর যেকোনো একটি আছে কিনা
- QR payload SmartKash format কিনা
- receiver registered user কিনা
- receiver account `ACTIVE` কিনা
- sender এবং receiver একই account কিনা
- receiver wallet আছে কিনা
- receiver wallet `ACTIVE` কিনা

এই step-এ money transfer করা হয়নি।

## 3. Why This Step Is Needed

Send Money একটি money-changing feature। টাকা পাঠানোর আগে backend-কে নিশ্চিত হতে হবে receiver সত্যিই SmartKash-এর registered active user কিনা। QR code scan করলেও QR payload সরাসরি বিশ্বাস করা যাবে না। Payload থেকে mobile number বের করে backend database-এর registered user এবং wallet-এর সাথে মিলিয়ে validate করতে হবে।

এই foundation ছাড়া পরের step-এ wallet debit/credit করলে ভুল account-এ টাকা চলে যাওয়ার risk থাকে।

## 4. Mobile Number And QR Receiver Selection

SmartKash Send Money দুইভাবে receiver select করবে:

- Registered mobile number দিয়ে
- QR code scan করে

MVP QR payload format:

```text
SMARTKASH_USER:<mobile-number>
```

Example:

```text
SMARTKASH_USER:01712345678
```

এখানে `SMARTKASH_USER:` prefix backend-কে বোঝায় এটি SmartKash user receiver QR। prefix-এর পরের অংশ mobile number, যেটা database-এর `users.mobile_number` দিয়ে lookup করা হয়।

## 5. Why No Money Movement Was Added Yet

এই step শুধু receiver validation। টাকা পাঠানোর actual flow এখনো করা হয়নি, কারণ money movement করতে হলে একসাথে আরও কিছু security rule লাগবে:

- PIN confirmation
- idempotency key
- sender wallet lock
- sender balance check
- sender wallet debit
- receiver wallet credit
- linked debit/credit ledger entries
- user-facing transaction records
- database transaction boundary

এইগুলো পরের dedicated Send Money transfer step-এ করা হবে।

## 6. Files And Folders Created Or Changed

Created:

```text
services/backend/src/main/java/com/smartkash/sendmoney/controller/SendMoneyReceiverController.java
services/backend/src/main/java/com/smartkash/sendmoney/dto/request/ResolveSendMoneyReceiverRequest.java
services/backend/src/main/java/com/smartkash/sendmoney/dto/response/SendMoneyReceiverResponse.java
services/backend/src/main/java/com/smartkash/sendmoney/mapper/SendMoneyReceiverMapper.java
services/backend/src/main/java/com/smartkash/sendmoney/service/SendMoneyReceiverService.java
services/backend/src/main/java/com/smartkash/sendmoney/service/impl/SendMoneyReceiverServiceImpl.java
learning/step-26-send-money-receiver-validation.md
```

Changed:

```text
docs/backend-api-plan.md
docs/security-plan.md
docs/codex-progress.md
```

## 7. Important Code Snippets

### Request DTO

```java
public record ResolveSendMoneyReceiverRequest(
        @Size(max = 32, message = "Mobile number must be 32 characters or fewer.")
        String mobileNumber,

        @Size(max = 255, message = "QR payload must be 255 characters or fewer.")
        String qrPayload
) {
}
```

Block-by-block explanation:

- `public record ResolveSendMoneyReceiverRequest`: API request body-এর data shape define করে।
- `mobileNumber`: user যদি manually receiver mobile number দেয়, সেটা এখানে আসবে।
- `qrPayload`: user যদি QR scan করে, QR থেকে পাওয়া payload এখানে আসবে।
- `@Size(max = 32)`: খুব বড় mobile number input block করে।
- `@Size(max = 255)`: QR payload excessively বড় হলে reject করে।
- এখানে mobile number format service layer-এ validate করা হয়েছে, কারণ request-এ mobile number অথবা QR payload যেকোনো একটি থাকতে পারে।

### Response DTO

```java
public record SendMoneyReceiverResponse(
        Long userId,
        String mobileNumber,
        String displayName,
        UserRole role,
        UserStatus userStatus,
        WalletStatus walletStatus
) {
}
```

Block-by-block explanation:

- `userId`: backend receiver user ID। Flutter UI প্রয়োজন হলে internal reference হিসেবে ব্যবহার করতে পারে।
- `mobileNumber`: resolved receiver mobile number।
- `displayName`: profile থাকলে receiver name দেখানোর জন্য।
- `role`: receiver `CUSTOMER`, `MERCHANT`, অথবা `ADMIN` কিনা।
- `userStatus`: receiver account active কিনা বোঝায়।
- `walletStatus`: receiver wallet active কিনা বোঝায়।

### Controller

```java
@RestController
@RequestMapping("/api/send-money")
public class SendMoneyReceiverController {

    @PostMapping("/resolve-receiver")
    public ResponseEntity<SendMoneyReceiverResponse> resolveReceiver(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody ResolveSendMoneyReceiverRequest request
    ) {
        return ResponseEntity.ok(sendMoneyReceiverService.resolveReceiver(principal, request));
    }
}
```

Block-by-block explanation:

- `@RestController`: এই class REST API response return করে।
- `@RequestMapping("/api/send-money")`: Send Money related endpoint-এর base path।
- `@PostMapping("/resolve-receiver")`: final endpoint হলো `/api/send-money/resolve-receiver`।
- `@AuthenticationPrincipal JwtPrincipal principal`: logged-in sender-এর JWT data নেয়।
- `@Valid @RequestBody`: request DTO validation চালায়।
- Controller নিজে business logic করে না; service method call করে। এটা thin controller rule follow করে।

### Service Validation Flow

```java
User sender = currentUser(principal);
ensureActiveUser(sender, "Only active users can resolve a Send Money receiver.");

String receiverMobileNumber = resolveReceiverMobileNumber(request);
User receiver = userRepository.findByMobileNumber(receiverMobileNumber)
        .orElseThrow(() -> new ResourceNotFoundException("Receiver account was not found."));

ensureNotSelfTransfer(sender, receiver);
ensureActiveUser(receiver, "Receiver account is not active.");

Wallet receiverWallet = walletRepository.findByUserId(receiver.getId())
        .orElseThrow(() -> new ResourceNotFoundException("Receiver wallet was not found."));
ensureActiveWallet(receiverWallet);
```

Block-by-block explanation:

- `currentUser(principal)`: JWT-এর Firebase UID দিয়ে sender user খুঁজে আনে।
- `ensureActiveUser(sender, ...)`: blocked/pending sender Send Money receiver resolve করতে পারবে না।
- `resolveReceiverMobileNumber(request)`: mobile number অথবা QR payload থেকে receiver mobile number বের করে।
- `findByMobileNumber`: receiver registered user কিনা database থেকে check করে।
- `ensureNotSelfTransfer`: নিজের account-এ নিজে Send Money করা block করে।
- `ensureActiveUser(receiver, ...)`: receiver account active না হলে transfer শুরু করা যাবে না।
- `findByUserId`: receiver wallet আছে কিনা check করে।
- `ensureActiveWallet`: receiver wallet blocked হলে transfer শুরু করা যাবে না।

### QR Payload Parsing

```java
private static final String QR_PREFIX = "SMARTKASH_USER:";

private String mobileNumberFromQrPayload(String qrPayload) {
    String trimmedPayload = qrPayload.trim();
    if (!trimmedPayload.startsWith(QR_PREFIX)) {
        throw new IllegalArgumentException("Invalid SmartKash receiver QR payload.");
    }

    String mobileNumber = trimmedPayload.substring(QR_PREFIX.length());
    if (!hasText(mobileNumber)) {
        throw new IllegalArgumentException("Receiver QR payload does not contain a mobile number.");
    }

    return normalizeMobileNumber(mobileNumber);
}
```

Block-by-block explanation:

- `QR_PREFIX`: SmartKash receiver QR চিনতে fixed prefix।
- `trim()`: accidental space থাকলে remove করে।
- `startsWith(QR_PREFIX)`: অন্য app বা invalid QR block করে।
- `substring(QR_PREFIX.length())`: prefix বাদ দিয়ে mobile number বের করে।
- `hasText(mobileNumber)`: empty QR receiver block করে।
- `normalizeMobileNumber`: number format final validate করে।

## 8. How This Fits Into SmartKash Flow

Future Flutter Send Money screen flow হবে:

1. User mobile number লিখবে অথবা QR scan করবে।
2. Flutter backend-এ `/api/send-money/resolve-receiver` call করবে।
3. Backend receiver validate করে receiver info return করবে।
4. Flutter receiver name/mobile/wallet status দেখাবে।
5. User amount লিখে PIN confirm করবে।
6. Future Send Money transfer API wallet debit/credit, ledger, transaction, idempotency handle করবে।

## 9. Expected Manual Outputs

Backend run করার পর Swagger বা API client দিয়ে success request:

```http
POST /api/send-money/resolve-receiver
Authorization: Bearer <backend-jwt>
Content-Type: application/json

{
  "mobileNumber": "01712345678"
}
```

Expected success output:

```json
{
  "userId": 2,
  "mobileNumber": "01712345678",
  "displayName": "Receiver Name",
  "role": "CUSTOMER",
  "userStatus": "ACTIVE",
  "walletStatus": "ACTIVE"
}
```

QR request:

```json
{
  "qrPayload": "SMARTKASH_USER:01712345678"
}
```

Expected output একই receiver info হবে।

Missing both fields:

```json
{}
```

Expected result:

```text
400 Bad Request
Provide either mobileNumber or qrPayload, but not both.
```

Both fields together:

```json
{
  "mobileNumber": "01712345678",
  "qrPayload": "SMARTKASH_USER:01712345678"
}
```

Expected result:

```text
400 Bad Request
Provide either mobileNumber or qrPayload, but not both.
```

Invalid QR:

```json
{
  "qrPayload": "RANDOM:01712345678"
}
```

Expected result:

```text
400 Bad Request
Invalid SmartKash receiver QR payload.
```

Unknown receiver:

```json
{
  "mobileNumber": "01999999999"
}
```

Expected result:

```text
404 Not Found
Receiver account was not found.
```

Self receiver:

```json
{
  "mobileNumber": "<sender-own-mobile-number>"
}
```

Expected result:

```text
400 Bad Request
Sender and receiver cannot be the same account.
```

## 10. Common Mistakes And Cautions

- QR payload থেকে পাওয়া number সরাসরি বিশ্বাস করা যাবে না; database user lookup করতে হবে।
- `mobileNumber` এবং `qrPayload` একসাথে allow করলে ambiguous receiver selection হতে পারে।
- Receiver active হলেও wallet না থাকলে transfer allow করা যাবে না।
- নিজের account-এ নিজে transfer করা block করতে হবে।
- এই endpoint-এ wallet balance show বা mutate করা উচিত না।
- এই endpoint-এ PIN নেওয়া উচিত না, কারণ এটি money-changing endpoint নয়।
- এই endpoint-এ ledger/transaction/idempotency record তৈরি করা উচিত না।

## 11. Manual Verification Commands

Backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Run backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

General git check:

```powershell
cd /d D:\github\my-kash
git status
```

API manual check করতে হলে আগে Firebase login flow দিয়ে backend JWT নিতে হবে, তারপর `Authorization: Bearer <backend-jwt>` header দিয়ে `/api/send-money/resolve-receiver` call করতে হবে।

## 12. Git Commands Used

```powershell
git status --short --branch
git diff --check
git add <step-26-files>
git commit -m "step-26: add send money receiver validation"
git push
git status --short --branch
```

## 13. What I Learned

এই step থেকে শিখলাম Send Money flow শুরু করার আগে receiver validation আলাদা foundation হিসেবে করা ভালো। QR scan করলেই টাকা পাঠানো উচিত না; backend-কে QR payload validate করে registered active receiver এবং active wallet নিশ্চিত করতে হয়। Money movement আলাদা step-এ করলে PIN, idempotency, ledger, transaction, wallet lock সব নিরাপদভাবে একসাথে implement করা যায়।
