# Step 41: Flutter PIN Setup Flow

## 1. Step title

এই ধাপে SmartKash Flutter app-এ PIN setup screen এবং backend PIN setup API integration যোগ করা হয়েছে।

## 2. কী implement করা হয়েছে

- Backend `GET /api/users/me` response-এ safe PIN metadata যোগ করা হয়েছে: `pinSet`, `pinUpdatedAt`।
- Flutter current user model যোগ করা হয়েছে।
- Flutter PIN setup result model যোগ করা হয়েছে।
- `BackendAuthRepository` এখন `/api/users/me` এবং `/api/auth/set-pin` call করতে পারে।
- `AuthController` PIN setup action handle করে।
- Auth route guard এখন `pinSet=false` হলে `/pin-setup` route-এ পাঠায়।
- PIN setup screen যোগ করা হয়েছে যেখানে 5 digit PIN set এবং confirm করা যায়।

## 3. কেন এই step দরকার

SmartKash app-এ login করার পর money-changing feature ব্যবহার করার আগে user-এর PIN থাকা দরকার। Backend already PIN hash করে store করে, কিন্তু Flutter-এ PIN setup UI না থাকলে user নিজের PIN set করতে পারে না। তাই login flow-এর পর PIN setup flow দরকার।

## 4. কোন files changed হয়েছে

- `services/backend/src/main/java/com/smartkash/user/dto/response/UserResponse.java`
- `services/backend/src/main/java/com/smartkash/user/mapper/UserMapper.java`
- `apps/mobile/lib/app/router/app_router.dart`
- `apps/mobile/lib/features/auth/data/backend_auth_repository.dart`
- `apps/mobile/lib/features/auth/domain/auth_session_state.dart`
- `apps/mobile/lib/features/auth/domain/current_user_summary.dart`
- `apps/mobile/lib/features/auth/domain/pin_setup_result.dart`
- `apps/mobile/lib/features/auth/providers/auth_controller.dart`
- `apps/mobile/lib/features/auth/presentation/pin_setup_screen.dart`
- `docs/codex-progress.md`
- `docs/test-checklist.md`
- `learning/step-41-flutter-pin-setup-flow.md`

## 5. Important backend snippets

### UserResponse PIN metadata

```java
public record UserResponse(
        Long id,
        String firebaseUid,
        String mobileNumber,
        UserRole role,
        UserStatus status,
        boolean pinSet,
        Instant pinUpdatedAt,
        UserProfileResponse profile,
        Instant createdAt,
        Instant updatedAt
) {
}
```

### Bangla explanation

- `pinSet`: user PIN setup করেছে কি না, শুধু boolean status।
- `pinUpdatedAt`: PIN last কবে update হয়েছে।
- Raw PIN return করা হয়নি।
- `pin_hash` return করা হয়নি।
- Flutter এই metadata দিয়ে decide করবে user-কে PIN setup screen দেখাবে কি না।

### UserMapper

```java
return new UserResponse(
        user.getId(),
        user.getFirebaseUid(),
        user.getMobileNumber(),
        user.getRole(),
        user.getStatus(),
        user.isPinSet(),
        user.getPinUpdatedAt(),
        toProfileResponse(profile),
        user.getCreatedAt(),
        user.getUpdatedAt()
);
```

### Bangla explanation

- `user.isPinSet()` entity থেকে safe PIN status নেয়।
- `user.getPinUpdatedAt()` timestamp নেয়।
- Mapper Entity থেকে DTO বানায়, তাই Entity direct API response হয় না।

## 6. Important Flutter snippets

### CurrentUserSummary

```dart
class CurrentUserSummary {
  const CurrentUserSummary({
    required this.id,
    required this.mobileNumber,
    required this.role,
    required this.pinSet,
    this.pinUpdatedAt,
  });

  final int id;
  final String mobileNumber;
  final String role;
  final bool pinSet;
  final DateTime? pinUpdatedAt;
}
```

### Bangla explanation

- `CurrentUserSummary` হলো `/api/users/me` response-এর Flutter model।
- `pinSet` route guard-এর জন্য দরকার।
- `pinUpdatedAt` future profile/security UI-তে দেখানো যেতে পারে।
- এখানে raw PIN নেই, কারণ Flutter PIN save করে না।

### BackendAuthRepository PIN calls

```dart
Future<CurrentUserSummary> getCurrentUser() async {
  final response = await _apiClient.get<Map<String, dynamic>>(
    '/api/users/me',
  );

  return CurrentUserSummary.fromJson(response.data ?? const {});
}

Future<PinSetupResult> setPin({
  required String pin,
  required String confirmPin,
}) async {
  final response = await _apiClient.post<Map<String, dynamic>>(
    '/api/auth/set-pin',
    data: {
      'pin': pin,
      'confirmPin': confirmPin,
    },
  );

  return PinSetupResult.fromJson(response.data ?? const {});
}
```

### Bangla explanation

- API call widget থেকে নয়, repository থেকে করা হয়েছে।
- `getCurrentUser()` backend JWT দিয়ে current user metadata আনে।
- `setPin()` PIN শুধু request payload হিসেবে backend-এ পাঠায়।
- Flutter local storage-এ PIN save করে না।
- Backend PIN hash করে database-এ রাখে।

### AuthSessionState PIN state

```dart
final bool? pinSet;
final DateTime? pinUpdatedAt;

bool get isAuthenticated =>
    status == AuthSessionStatus.authenticated || backendToken != null;
bool get needsPinSetup => isAuthenticated && pinSet != true;
```

### Bangla explanation

- `pinSet` null হলে এখনো জানা যায়নি।
- `pinSet=false` হলে PIN setup দরকার।
- `backendToken != null` থাকলে loading/error state-এও user authenticated থাকে।
- এতে PIN save করার সময় route হঠাৎ Login screen-এ চলে যায় না।

### AuthController setPin

```dart
Future<void> setPin({
  required String pin,
  required String confirmPin,
}) async {
  if (!_isFiveDigitPin(pin) || !_isFiveDigitPin(confirmPin)) {
    state = state.copyWith(
      status: AuthSessionStatus.failure,
      errorMessage: 'PIN must be exactly 5 digits.',
    );
    return;
  }

  if (pin != confirmPin) {
    state = state.copyWith(
      status: AuthSessionStatus.failure,
      errorMessage: 'PIN and confirm PIN do not match.',
    );
    return;
  }

  final result = await _backendAuthRepository.setPin(
    pin: pin,
    confirmPin: confirmPin,
  );
}
```

### Bangla explanation

- প্রথমে frontend basic validation করে।
- PIN অবশ্যই 5 digit হতে হবে।
- PIN এবং confirm PIN match করতে হবে।
- তারপর repository backend API call করে।
- Backend আবার validation করে এবং hash করে।

### Router PIN setup redirect

```dart
if (authState.isAuthenticated) {
  if (authState.needsPinSetup) {
    return isPinSetupRoute ? null : PinSetupScreen.routePath;
  }

  if (isPinSetupRoute) {
    return HomeScreen.routePath;
  }

  return isLoginRoute ? HomeScreen.routePath : null;
}
```

### Bangla explanation

- User authenticated হলে PIN status check হয়।
- `needsPinSetup=true` হলে Home না দেখিয়ে PIN setup screen দেখানো হয়।
- PIN already set থাকলে PIN setup route থেকে Home-এ পাঠানো হয়।
- Unauthenticated user Login screen-এ থাকে।

## 7. PIN setup screen flow

1. User login করে backend JWT পায়।
2. Flutter `/api/users/me` call করে।
3. যদি `pinSet=false`, router `/pin-setup` দেখায়।
4. User 5 digit PIN দেয়।
5. User আবার confirm PIN দেয়।
6. Flutter `POST /api/auth/set-pin` call করে।
7. Backend PIN hash করে save করে।
8. Flutter `pinSet=true` state update করে।
9. Router Home screen দেখায়।

## 8. কেন PIN Flutter-এ store করা হয়নি

PIN sensitive security data। Flutter app compromise হলে local PIN leak হতে পারে। তাই SmartKash rule:

- PIN local storage-এ save করা যাবে না।
- PIN শুধু backend confirmation request payload হিসেবে যাবে।
- Backend raw PIN store করবে না।
- Backend only BCrypt hash store করবে।

## 9. Common mistakes and cautions

- PIN hash কখনো API response-এ return করা যাবে না।
- Flutter secure storage-এ PIN রাখা যাবে না।
- PIN setup screen থেকে direct database/API client call করা যাবে না; repository/controller ব্যবহার করতে হবে।
- PIN mismatch হলে backend call করার আগেই user-friendly error দেখানো ভালো।
- Backend Firebase Admin env ready না থাকলে login success হবে না, তাই PIN setup screen-এ পৌঁছানো যাবে না।

## 10. Manual verification commands

Backend:

```bat
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
.\mvnw.cmd spring-boot:run
```

Flutter:

```bat
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter run --dart-define=FIREBASE_ENABLED=true --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

General:

```bat
cd /d D:\github\my-kash
git status
```

## 11. Expected output

- Login success হলে যদি user-এর PIN না থাকে, PIN setup screen দেখাবে।
- PIN setup screen-এ 5 dot input দেখা যাবে।
- প্রথম 5 digit দিলে `Next` confirm step-এ যাবে।
- confirm PIN mismatch হলে error দেখাবে।
- matching 5 digit PIN দিলে `POST /api/auth/set-pin` success হবে।
- Success হলে Home screen দেখা যাবে।
- Flutter app কোথাও PIN save করবে না।

## 12. Git commands used

```bat
git status --short --branch
git add <step-41-files>
git commit -m "step-41: add Flutter PIN setup flow"
git push
```

## 13. এই step থেকে কী শিখলাম

এই step-এ শিখলাম কীভাবে backend safe metadata expose করে frontend route decision নিতে সাহায্য করে, আর sensitive raw PIN frontend storage-এ না রেখে শুধু backend API request দিয়ে secure setup flow তৈরি করা যায়।
