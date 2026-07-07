# Step 35: Flutter API Client Foundation

## 1. Step title

এই ধাপের নাম: Flutter API Client Foundation.

## 2. What was implemented

এই ধাপে Flutter app-এর backend API communication foundation তৈরি করা হয়েছে।

যা যোগ করা হয়েছে:

- `dio` dependency
- `flutter_secure_storage` dependency
- centralized `ApiClient`
- `ApiException`
- secure backend JWT storage
- Riverpod providers for API client and token storage
- backend auth repository
- backend auth token model
- configurable backend base URL

এই ধাপে কোনো visual UI design, login screen, wallet screen, QR scanner, বা feature screen তৈরি করা হয়নি।

## 3. Why this step is needed

Flutter app backend-এর সাথে কথা বলবে REST API দিয়ে। যদি প্রতিটি screen নিজে নিজে API call করে, তাহলে code duplicate হবে এবং error handling messy হবে।

তাই আমরা একটি centralized network foundation বানালাম:

- UI widget শুধু provider/repository call করবে।
- API call থাকবে repository/service class-এ।
- JWT attach হবে automatically।
- backend error response Flutter exception-এ convert হবে।
- token secure storage-এ থাকবে।

## 4. Files/folders changed

Changed files:

- `apps/mobile/pubspec.yaml`
- `apps/mobile/pubspec.lock`
- `apps/mobile/lib/app/config/app_config.dart`
- `apps/mobile/lib/core/storage/secure_token_storage.dart`
- `apps/mobile/lib/core/errors/api_exception.dart`
- `apps/mobile/lib/core/network/api_client.dart`
- `apps/mobile/lib/core/network/api_providers.dart`
- `apps/mobile/lib/features/auth/data/backend_auth_repository.dart`
- `apps/mobile/lib/features/auth/domain/backend_auth_token.dart`
- `apps/mobile/lib/features/auth/providers/auth_providers.dart`
- `apps/mobile/linux/flutter/generated_plugins.cmake`
- `apps/mobile/windows/flutter/generated_plugin_registrant.cc`
- `apps/mobile/windows/flutter/generated_plugins.cmake`
- `docs/architecture-plan.md`
- `docs/test-checklist.md`
- `docs/codex-progress.md`
- `learning/step-35-flutter-api-client-foundation.md`

## 5. Important dependency snippet

`pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.7.0
  flutter_secure_storage: ^9.2.2
```

ব্যাখ্যা:

- `dio` HTTP request পাঠানোর জন্য।
- `flutter_secure_storage` backend JWT secure ভাবে রাখার জন্য।
- PIN storage-এর জন্য এটি ব্যবহার করা হবে না।
- `flutter pub get` চালালে `pubspec.lock` update হয়।

## 6. Important config snippet

`AppConfig`:

```dart
static const backendBaseUrl = String.fromEnvironment(
  'SMARTKASH_API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);
```

Block-by-block ব্যাখ্যা:

- `String.fromEnvironment` Dart compile-time config পড়ে।
- `SMARTKASH_API_BASE_URL` run command থেকে দেওয়া যায়।
- Android emulator থেকে host machine-এর localhost access করতে `10.0.2.2` লাগে।
- Web/desktop থেকে usually `http://localhost:8080` ব্যবহার করা যাবে।

Example:

```powershell
flutter run --dart-define=SMARTKASH_API_BASE_URL=http://localhost:8080
```

## 7. SecureTokenStorage snippet

```dart
static const _accessTokenKey = 'smartkash.access_token';
static const _tokenTypeKey = 'smartkash.token_type';
```

ব্যাখ্যা:

- `_accessTokenKey` backend JWT রাখার key।
- `_tokenTypeKey` usually `Bearer` রাখে।
- key name project-specific করা হয়েছে যাতে অন্য app data-এর সাথে conflict না হয়।

```dart
Future<void> saveBackendToken({
  required String accessToken,
  String tokenType = 'Bearer',
}) async {
  await _secureStorage.write(key: _accessTokenKey, value: accessToken);
  await _secureStorage.write(key: _tokenTypeKey, value: tokenType);
}
```

ব্যাখ্যা:

- `accessToken` backend JWT।
- `tokenType` default `Bearer`।
- `write` async, কারণ secure storage platform channel ব্যবহার করে।
- raw PIN এখানে store করা হয় না।

## 8. ApiClient snippet

```dart
_dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        final tokenType = await _tokenStorage.readTokenType();
        options.headers['Authorization'] = '$tokenType $token';
      }
      handler.next(options);
    },
  ),
);
```

Block-by-block ব্যাখ্যা:

- `interceptors.add` প্রতিটি request যাওয়ার আগে logic চালায়।
- `readAccessToken()` secure storage থেকে backend JWT পড়ে।
- token থাকলে `Authorization` header add হয়।
- header format: `Bearer <backend-jwt>`।
- token না থাকলে public API call header ছাড়া যাবে।
- `handler.next(options)` request continue করে।

## 9. ApiException snippet

```dart
factory ApiException.fromJson(Map<String, dynamic> json) {
  return ApiException(
    message: json['message'] as String? ?? 'Request failed.',
    statusCode: json['status'] as int?,
    path: json['path'] as String?,
    errors: (json['errors'] as List<dynamic>?)
            ?.map((error) => error.toString())
            .toList() ??
        const [],
  );
}
```

ব্যাখ্যা:

- Backend `ApiErrorResponse` JSON Flutter exception-এ convert হয়।
- `message` user-friendly error text।
- `statusCode` HTTP status।
- `path` কোন endpoint error দিয়েছে।
- `errors` validation field-level messages।
- Flutter UI later এই exception থেকে error message দেখাবে।

## 10. BackendAuthRepository snippet

```dart
final response = await _apiClient.post<Map<String, dynamic>>(
  '/api/auth/firebase-login',
  data: {'firebaseIdToken': firebaseIdToken},
);
```

ব্যাখ্যা:

- Firebase Phone Auth login-এর পর Firebase ID token পাওয়া যায়।
- Flutter সেই token backend-এ পাঠায়।
- Backend endpoint: `POST /api/auth/firebase-login`
- Request body key must be `firebaseIdToken`, কারণ Spring Boot DTO এই field expect করে।

```dart
final token = BackendAuthToken.fromJson(response.data ?? const {});
await _tokenStorage.saveBackendToken(
  accessToken: token.accessToken,
  tokenType: token.tokenType,
);
```

ব্যাখ্যা:

- Backend response থেকে `accessToken` parse হয়।
- backend JWT secure storage-এ save হয়।
- next API request থেকে `ApiClient` automatically Authorization header attach করবে।

## 11. Riverpod provider snippet

```dart
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStorage: ref.watch(secureTokenStorageProvider)),
);
```

ব্যাখ্যা:

- Riverpod `Provider` app-wide dependency provide করে।
- `ApiClient` direct widget-এর ভিতরে create করতে হবে না।
- future repository classes এই provider থেকে API client পাবে।

```dart
final backendAuthRepositoryProvider = Provider<BackendAuthRepository>(
  (ref) => BackendAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
  ),
);
```

ব্যাখ্যা:

- Auth repository API client এবং token storage দুইটাই পায়।
- UI later শুধু repository/provider call করবে।
- Firebase Auth logic এবং backend JWT logic আলাদা রাখা হয়েছে।

## 12. How this connects to SmartKash flow

SmartKash app flow হবে:

1. User Firebase test OTP দিয়ে login করবে।
2. Flutter Firebase ID token পাবে।
3. `BackendAuthRepository.loginWithFirebaseIdToken()` backend-এ token পাঠাবে।
4. Backend Firebase token verify করে backend JWT দেবে।
5. Flutter backend JWT secure storage-এ রাখবে।
6. Future wallet, transaction, send money, payment APIs automatically JWT header পাবে।

## 13. Why PIN is not stored in Flutter

PIN money-changing operation confirm করার জন্য ব্যবহার হবে। PIN must be sent only at transaction confirmation time over secure API.

এই step-এ:

- PIN model তৈরি করা হয়নি।
- PIN local storage নেই।
- PIN cache নেই।
- PIN log নেই।

## 14. Common mistakes and cautions

- Android emulator থেকে backend URL `localhost` দিলে কাজ নাও করতে পারে; use `10.0.2.2`.
- Web/Windows desktop থেকে usually `localhost:8080` কাজ করে।
- Backend DTO field `firebaseIdToken`; ভুল করে `idToken` দিলে `400 Bad Request` হবে।
- `flutter_secure_storage` add করলে generated plugin files update হতে পারে।
- `flutter pub get` না চালালে `pubspec.lock` update হবে না।
- Widget-এর ভিতরে direct `Dio()` create করা যাবে না।
- PIN secure storage-এ রাখা যাবে না।

## 15. Manual verification commands

Flutter dependency and static checks:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter test
```

Android emulator run:

```powershell
flutter run --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

Web/desktop local run:

```powershell
flutter run -d chrome --dart-define=SMARTKASH_API_BASE_URL=http://localhost:8080
```

Expected output:

- `flutter pub get`: finishes with `Got dependencies!`
- `flutter analyze`: no errors
- `flutter test`: default tests pass if present
- app still opens the existing placeholder home screen
- no new feature screen appears yet

## 16. Git commands used

```powershell
git status --short --branch
flutter pub get
dart format <changed dart files>
git diff --check
git add <step-35-files>
git commit -m "step-35: add Flutter API client foundation"
git push
git status --short --branch
```

## 17. What I learned from this step

এই step থেকে শিখলাম:

- API client centralized রাখলে Flutter app maintain করা সহজ হয়।
- secure storage backend JWT রাখার জন্য ভালো, কিন্তু PIN রাখার জন্য নয়।
- backend error response Flutter exception-এ convert করলে UI consistent error দেখাতে পারে।
- Riverpod provider dependency management সহজ করে।
- backend API field name exact match করা খুব গুরুত্বপূর্ণ।
