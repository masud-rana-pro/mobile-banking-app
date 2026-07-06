# Step 31: FCM Transaction Alert Foundation

## 1. Step Title

Step 31-এ SmartKash backend-এ Firebase Cloud Messaging বা FCM transaction alert foundation যোগ করা হয়েছে।

## 2. What Was Implemented

এই step-এ backend notification foundation তৈরি হয়েছে:

```http
POST /api/devices/fcm-token
```

Request example:

```json
{
  "fcmToken": "demo-fcm-token-from-flutter",
  "deviceType": "ANDROID"
}
```

এই step-এ যোগ হয়েছে:

- `firebase_devices` database table
- FCM device entity/repository
- FCM token registration API
- Device type enum
- Notification type enum
- FCM properties
- `TransactionAlertService` service boundary
- Firebase Messaging sender implementation
- Safe skip behavior when `FCM_ENABLED=false` or Firebase Admin is not configured

## 3. Why This Step Is Needed

SmartKash MVP-তে notification শুধু important transaction alerts-এর জন্য ব্যবহার হবে। যেমন:

- Add Money approved
- Send Money completed
- Merchant Payment completed
- Savings deposit completed
- Mobile Recharge completed
- Loan approved/rejected

FCM alert পাঠাতে হলে backend-কে user-এর device token জানতে হবে। তাই প্রথমে token storage foundation দরকার।

## 4. Files Created Or Changed

Created:

```text
services/backend/src/main/resources/db/migration/V13__create_firebase_devices.sql
services/backend/src/main/java/com/smartkash/notification/config/FcmProperties.java
services/backend/src/main/java/com/smartkash/notification/controller/DeviceTokenController.java
services/backend/src/main/java/com/smartkash/notification/dto/request/RegisterFcmTokenRequest.java
services/backend/src/main/java/com/smartkash/notification/dto/response/FirebaseDeviceResponse.java
services/backend/src/main/java/com/smartkash/notification/entity/FirebaseDevice.java
services/backend/src/main/java/com/smartkash/notification/enums/DeviceType.java
services/backend/src/main/java/com/smartkash/notification/enums/NotificationType.java
services/backend/src/main/java/com/smartkash/notification/mapper/FirebaseDeviceMapper.java
services/backend/src/main/java/com/smartkash/notification/repository/FirebaseDeviceRepository.java
services/backend/src/main/java/com/smartkash/notification/service/DeviceTokenService.java
services/backend/src/main/java/com/smartkash/notification/service/TransactionAlertService.java
services/backend/src/main/java/com/smartkash/notification/service/impl/DeviceTokenServiceImpl.java
services/backend/src/main/java/com/smartkash/notification/service/impl/FcmTransactionAlertService.java
learning/step-31-fcm-transaction-alert-foundation.md
```

Changed:

```text
docs/backend-api-plan.md
docs/database-plan.md
docs/notification-plan.md
docs/codex-progress.md
```

## 5. Important Code Snippets

### Flyway Migration

```sql
CREATE TABLE firebase_devices (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    fcm_token VARCHAR(500) NOT NULL,
    device_type VARCHAR(32) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_firebase_devices_user_id FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT uk_firebase_devices_token UNIQUE (fcm_token),
    CONSTRAINT chk_firebase_devices_device_type CHECK (device_type IN ('ANDROID', 'IOS', 'WEB', 'WINDOWS', 'LINUX', 'MACOS', 'UNKNOWN'))
);
```

Block-by-block explanation:

- `firebase_devices`: user device token রাখার table।
- `user_id`: কোন user-এর device token তা বোঝায়।
- `fcm_token`: Flutter/Firebase থেকে পাওয়া device token।
- `device_type`: Android, iOS, Web ইত্যাদি platform।
- `active`: token active কিনা।
- `created_at`, `updated_at`: audit/timestamp tracking।
- `UNIQUE (fcm_token)`: একই token duplicate row হিসেবে save হবে না।
- `CHECK device_type`: allowed platform values enforce করে।

### RegisterFcmTokenRequest

```java
public record RegisterFcmTokenRequest(
        String fcmToken,
        DeviceType deviceType
) {
}
```

Explanation:

- `fcmToken`: Flutter app Firebase Messaging থেকে token পাবে।
- `deviceType`: কোন platform থেকে token এসেছে তা বোঝায়।
- DTO validation token blank/too large হলে block করে।

### DeviceTokenController

```java
@PostMapping("/fcm-token")
public ResponseEntity<FirebaseDeviceResponse> registerFcmToken(
        @AuthenticationPrincipal JwtPrincipal principal,
        @Valid @RequestBody RegisterFcmTokenRequest request
) {
    return ResponseEntity.ok(deviceTokenService.registerCurrentUserToken(principal, request));
}
```

Explanation:

- Base path `/api/devices`, তাই endpoint `/api/devices/fcm-token`।
- `principal` থেকে authenticated user পাওয়া যায়।
- User ID request body থেকে নেওয়া হয় না, তাই অন্য user-এর নামে token save করা যায় না।
- Controller thin, service layer কাজ করে।

### DeviceTokenService

```java
FirebaseDevice device = firebaseDeviceRepository.findByFcmToken(request.fcmToken().trim())
        .map(existingDevice -> refresh(existingDevice, user, request))
        .orElseGet(() -> new FirebaseDevice(user, request.fcmToken().trim(), request.deviceType()));
```

Explanation:

- Same token আগে থাকলে existing row refresh করা হয়।
- নতুন token হলে new `FirebaseDevice` তৈরি হয়।
- Token current authenticated user-এর সাথে linked হয়।

### FCM Properties

```java
@ConfigurationProperties(prefix = "smartkash.fcm")
public record FcmProperties(boolean enabled) {
}
```

Explanation:

- `smartkash.fcm.enabled` config থেকে FCM on/off জানা যায়।
- Local development-এ default `FCM_ENABLED=false` রাখা যায়।
- FCM disabled হলে send service safe skip করবে।

### TransactionAlertService

```java
public interface TransactionAlertService {

    void sendTransactionAlert(User user, NotificationType type, String title, String body, Map<String, String> data);
}
```

Explanation:

- Business service যেন Firebase Messaging details না জানে।
- Future money-changing services শুধু এই service call করবে।
- `NotificationType` দিয়ে alert category বোঝানো হয়।
- `data` map দিয়ে transaction reference/type পাঠানো যাবে।

### Safe Skip Behavior

```java
if (!fcmProperties.enabled() || firebaseApp.isEmpty()) {
    log.info("Skipping FCM alert because FCM is disabled or Firebase Admin is not configured.");
    return;
}
```

Explanation:

- Local backend-এ Firebase Admin credentials না থাকলে app crash করবে না।
- `FCM_ENABLED=false` হলে notification send attempt হবে না।
- শেখার MVP-তে local testing সহজ থাকে।

## 6. How This Fits Into SmartKash Flow

Future Flutter flow:

1. Flutter app Firebase Messaging token নিবে।
2. User login করার পর app `/api/devices/fcm-token` call করবে।
3. Backend token `firebase_devices` table-এ save করবে।
4. Future transaction success হলে backend `TransactionAlertService` call করবে।
5. FCM enabled/configured থাকলে Firebase user device-এ alert পাঠাবে।

## 7. Expected Manual Outputs

Token registration success response:

```json
{
  "id": 1,
  "deviceType": "ANDROID",
  "active": true,
  "createdAt": "2026-07-05T...",
  "updatedAt": "2026-07-05T..."
}
```

Same token again:

```text
Expected: same token row refreshed, duplicate row created হবে না।
```

Backend startup with `FCM_ENABLED=false`:

```text
Expected: backend starts normally; FCM sending is skipped.
```

Missing Firebase Admin credentials:

```text
Expected: Firebase Admin SDK is not initialized; FCM sending is skipped safely.
```

## 8. Database Expected Output

After registering token:

```sql
SELECT id, user_id, device_type, active, created_at, updated_at
FROM firebase_devices
ORDER BY id DESC;
```

Expected:

- one row for the token
- correct `user_id`
- correct `device_type`
- `active = true`

## 9. Common Mistakes And Cautions

- FCM token user ID request body থেকে নেওয়া যাবে না।
- Firebase Admin service account JSON commit করা যাবে না।
- `google-services.json` backend service account নয়।
- Local `FCM_ENABLED=false` হলে notification না যাওয়া expected।
- Full FCM delivery test backend deployment/Firebase config ছাড়া কঠিন হতে পারে।
- এই step alert service foundation যোগ করেছে, কিন্তু money-changing services-এ alert call wire করা হয়নি।

## 10. Manual Verification Commands

Backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
.\mvnw.cmd spring-boot:run
```

Database:

```powershell
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
\d firebase_devices
SELECT id, user_id, device_type, active, created_at, updated_at FROM firebase_devices ORDER BY id DESC;
SELECT * FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 5;
```

General:

```powershell
cd /d D:\github\my-kash
git status
```

## 11. Git Commands Used

```powershell
git status --short --branch
git diff --check
git add <step-31-files>
git commit -m "step-31: add FCM transaction alert foundation"
git push
git status --short --branch
```

## 12. What I Learned

এই step থেকে শিখলাম notification system সরাসরি business logic-এর মধ্যে না রেখে আলাদা module/service boundary করা ভালো। আগে device token save করতে হয়, তারপর future transaction success event থেকে notification service call করা যায়। Local development-এ FCM disabled থাকলেও backend safely চলতে পারে।
