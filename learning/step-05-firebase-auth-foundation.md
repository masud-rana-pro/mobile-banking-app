# Step 05: Firebase Auth Foundation

## 1. Step title

Step 05-এর title: **Firebase Auth foundation setup**.

এই step-এ SmartKash Flutter app এবং Spring Boot backend-এ Firebase Auth foundation যোগ করা হয়েছে। এটি শুধু foundation; full login/register flow, backend JWT issuing, PIN setup, user creation, wallet creation, বা business feature implement করা হয়নি।

## 2. What was implemented

এই step-এ implement করা হয়েছে:

- Flutter app-এ `firebase_core` dependency যোগ করা হয়েছে।
- Flutter app-এ `firebase_auth` dependency যোগ করা হয়েছে।
- Flutter startup-এ safe Firebase initialization যোগ করা হয়েছে।
- Firebase initialization default অবস্থায় disabled রাখা হয়েছে, যাতে real config ছাড়া local analyze/test pass করে।
- Firebase Phone Auth service skeleton তৈরি করা হয়েছে।
- Riverpod provider তৈরি করা হয়েছে, যাতে future UI Firebase auth service access করতে পারে।
- `google-services.json` কোথায় রাখতে হবে তা document করা হয়েছে।
- Backend-এ Firebase Admin environment properties তৈরি করা হয়েছে।
- Backend-এ Firebase Admin SDK initializer foundation তৈরি করা হয়েছে।
- Backend-এ Firebase ID token verifier service skeleton তৈরি করা হয়েছে।
- `.env.example`-এ Firebase client config placeholders যোগ করা হয়েছে।
- `docs/codex-progress.md` update করা হয়েছে।
- এই Bangla learning file তৈরি করা হয়েছে।

## 3. Why Firebase is used in SmartKash

SmartKash MVP-তে Firebase ব্যবহারের কারণ:

- Phone number based authentication শেখা যাবে।
- Test phone number এবং fixed OTP দিয়ে zero-budget learning করা যাবে।
- Flutter app Firebase থেকে ID token নিতে পারবে।
- Spring Boot backend future step-এ সেই Firebase ID token verify করতে পারবে।
- Firebase শুধু auth identity-এর জন্য থাকবে; SmartKash business data PostgreSQL-এ থাকবে।

## 4. Why test OTP/fixed OTP is used instead of real SMS OTP

Real SMS OTP ব্যবহার করলে billing, quota, abuse protection, এবং production compliance-এর বিষয় আসে। SmartKash একটি zero-budget learning MVP, তাই Firebase Phone Auth-এর test phone numbers এবং fixed OTP codes ব্যবহার করা হবে।

এতে শেখা যায়:

- Phone auth flow কেমন কাজ করে।
- Flutter কীভাবে Firebase token পায়।
- Backend কীভাবে Firebase token verify করবে।

কিন্তু real SMS পাঠানো হয় না, তাই billing লাগে না।

## 5. What `google-services.json` does

`google-services.json` হলো Android Firebase client config file। এতে Android app-এর Firebase project সম্পর্কিত client-side identifiers থাকে, যেমন:

- Firebase project id
- Android app id
- API key
- messaging sender id

এটি Firebase Admin service account JSON নয়। Admin service account JSON private credential বহন করে, তাই সেটি কখনো repo-তে commit করা যাবে না।

## 6. Where `google-services.json` should be placed

যদি local Android Firebase run/test করার জন্য দরকার হয়, file path হবে:

```text
apps/mobile/android/app/google-services.json
```

এই step-এ `google-services.json` commit করা হয়নি। `.gitignore` এই file ignore করে। Instruction রাখা হয়েছে:

```text
apps/mobile/android/app/README-google-services.md
```

## 7. Why Firebase Admin service account JSON must never be committed

Firebase Admin service account JSON backend-এর private credential। এটি leak হলে অন্য কেউ Firebase project-এর privileged access পেতে পারে।

তাই SmartKash rule:

- Service account JSON repo-তে রাখা যাবে না।
- Private key source code-এ hardcode করা যাবে না।
- Backend Firebase credentials environment variables থেকে আসবে।

## 8. How Flutter initializes Firebase

Flutter startup এখন এইভাবে কাজ করে:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();

  runApp(const ProviderScope(child: SmartKashApp()));
}
```

Block-by-block explanation:

```dart
Future<void> main() async {
```

`main` async করা হয়েছে, কারণ Firebase initialization একটি asynchronous কাজ।

```dart
  WidgetsFlutterBinding.ensureInitialized();
```

Flutter engine binding ready করে। Firebase initialize করার আগে এটি দরকার।

```dart
  await FirebaseBootstrap.initialize();
```

Firebase foundation bootstrap করে। এই method check করে Firebase enabled কিনা।

```dart
  runApp(const ProviderScope(child: SmartKashApp()));
```

Riverpod `ProviderScope` সহ SmartKash app চালু করে।

Firebase bootstrap:

```dart
class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> initialize() async {
    if (!FirebaseConfig.enabled) {
      return;
    }

    if (Firebase.apps.isNotEmpty) {
      return;
    }

    await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
  }
}
```

Explanation:

- `FirebaseBootstrap._()` private constructor; class instantiate করার দরকার নেই।
- `FirebaseConfig.enabled` false হলে Firebase initialize হবে না।
- `Firebase.apps.isNotEmpty` হলে already initialized, তাই duplicate initialize করা হবে না।
- `Firebase.initializeApp(...)` real Firebase client config দিয়ে app initialize করে।

## 9. How Firebase Auth foundation is separated from UI/business logic

Firebase Auth logic UI widget-এর ভিতরে রাখা হয়নি। Service class তৈরি করা হয়েছে:

```dart
class FirebasePhoneAuthService {
  FirebasePhoneAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<String?> currentIdToken({bool forceRefresh = false}) {
    return _firebaseAuth.currentUser?.getIdToken(forceRefresh);
  }
}
```

Block explanation:

- Constructor optional `FirebaseAuth` নেয়, যাতে future test/mock করা সহজ হয়।
- `_firebaseAuth` private field, direct Firebase dependency service-এর ভিতরে থাকে।
- `authStateChanges()` future UI-কে login/logout state stream দিতে পারবে।
- `currentUser` currently signed-in Firebase user return করে।
- `currentIdToken()` future backend login step-এ Firebase ID token নিতে সাহায্য করবে।

Riverpod provider:

```dart
final firebasePhoneAuthServiceProvider = Provider<FirebasePhoneAuthService>(
  (ref) => FirebasePhoneAuthService(),
);
```

এটি future UI বা controller/provider layer থেকে service access করার clean way। Widget direct `FirebaseAuth.instance` call করবে না।

## 10. How Spring Boot will later verify Firebase ID tokens

Backend token verifier skeleton:

```java
public interface FirebaseTokenVerifier {

    FirebaseToken verifyIdToken(String idToken) throws FirebaseAuthException;
}
```

Explanation:

- Interface রাখা হয়েছে যাতে future auth service implementation এই contract use করে।
- `verifyIdToken` Firebase ID token verify করবে।
- Return type `FirebaseToken`, যেখান থেকে Firebase UID, phone number, claims পাওয়া যাবে।

Implementation:

```java
@Service
public class FirebaseTokenVerifierImpl implements FirebaseTokenVerifier {

    private final FirebaseAdminInitializer firebaseAdminInitializer;

    public FirebaseTokenVerifierImpl(FirebaseAdminInitializer firebaseAdminInitializer) {
        this.firebaseAdminInitializer = firebaseAdminInitializer;
    }

    @Override
    public FirebaseToken verifyIdToken(String idToken) throws FirebaseAuthException {
        FirebaseApp firebaseApp = firebaseAdminInitializer.firebaseApp()
                .orElseThrow(() -> new IllegalStateException("Firebase Admin SDK is not configured."));

        return FirebaseAuth.getInstance(firebaseApp).verifyIdToken(idToken);
    }
}
```

Block explanation:

- `@Service` Spring bean হিসেবে class register করে।
- `FirebaseAdminInitializer` Firebase Admin SDK ready আছে কিনা জানে।
- Admin SDK configured না থাকলে clear error throw করা হয়।
- `FirebaseAuth.getInstance(firebaseApp).verifyIdToken(idToken)` actual Firebase token verify করবে।

## 11. Why JWT issuing is not implemented in this step

এই step শুধু Firebase foundation। Backend JWT issuing করতে হলে দরকার:

- Auth API endpoint
- Firebase token request DTO
- User lookup/create logic
- User role/status model
- JWT signing secret handling
- Response DTO
- Security filter chain
- User profile/wallet bootstrap decision

এগুলো আলাদা auth/security step-এ করা হবে। এই step-এ JWT issuing করলে scope বড় হয়ে যেত।

## 12. Which files/folders were created or changed

Created:

- `apps/mobile/lib/app/config/firebase_config.dart`
- `apps/mobile/lib/app/config/firebase_bootstrap.dart`
- `apps/mobile/lib/features/auth/data/firebase_phone_auth_service.dart`
- `apps/mobile/lib/features/auth/providers/auth_providers.dart`
- `apps/mobile/android/app/README-google-services.md`
- `services/backend/src/main/java/com/smartkash/firebase/FirebaseAdminProperties.java`
- `services/backend/src/main/java/com/smartkash/firebase/FirebaseAdminInitializer.java`
- `services/backend/src/main/java/com/smartkash/firebase/FirebaseTokenVerifier.java`
- `services/backend/src/main/java/com/smartkash/firebase/FirebaseTokenVerifierImpl.java`
- `learning/step-05-firebase-auth-foundation.md`

Changed:

- `.env.example`
- `apps/mobile/pubspec.yaml`
- `apps/mobile/pubspec.lock`
- `apps/mobile/lib/main.dart`
- `services/backend/src/main/java/com/smartkash/SmartKashBackendApplication.java`
- `docs/codex-progress.md`

## 13. Important code/config snippets

Firebase config:

```dart
static const bool enabled = bool.fromEnvironment(
  'FIREBASE_ENABLED',
  defaultValue: false,
);
```

Android options:

```dart
static const FirebaseOptions androidOptions = FirebaseOptions(
  apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
  appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
  messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
  projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
);
```

Backend properties:

```java
@ConfigurationProperties(prefix = "smartkash.firebase")
public record FirebaseAdminProperties(
        String projectId,
        String clientEmail,
        String privateKey
) {
```

Backend app scan:

```java
@SpringBootApplication
@ConfigurationPropertiesScan
public class SmartKashBackendApplication {
```

`.env.example`:

```env
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CLIENT_EMAIL=your-firebase-service-account-email
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nreplace-with-test-key\n-----END PRIVATE KEY-----\n"
FIREBASE_ENABLED=false
FIREBASE_ANDROID_API_KEY=replace-with-firebase-android-api-key
FIREBASE_ANDROID_APP_ID=replace-with-firebase-android-app-id
FIREBASE_MESSAGING_SENDER_ID=replace-with-firebase-messaging-sender-id
```

## 14. Line-by-line or block-by-block Bangla explanation of snippets

### `FirebaseConfig.enabled`

```dart
static const bool enabled = bool.fromEnvironment(
```

Dart compile-time environment variable থেকে boolean value পড়া হয়।

```dart
  'FIREBASE_ENABLED',
```

Variable name `FIREBASE_ENABLED`। Run command-এ `--dart-define=FIREBASE_ENABLED=true` দিলে Firebase চালু হবে।

```dart
  defaultValue: false,
);
```

Default false, তাই real config ছাড়া app test/analyze করা যায়।

### Android `FirebaseOptions`

```dart
apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
```

Firebase Android API key dart-define থেকে আসে।

```dart
appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
```

Firebase Android app id dart-define থেকে আসে।

```dart
messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
```

Firebase project messaging sender id dart-define থেকে আসে।

```dart
projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
```

Firebase project id dart-define থেকে আসে।

### Backend `FirebaseAdminProperties`

```java
@ConfigurationProperties(prefix = "smartkash.firebase")
```

`application-local.yml`-এর `smartkash.firebase.*` values এই record-এ bind হবে।

```java
public record FirebaseAdminProperties(
        String projectId,
        String clientEmail,
        String privateKey
) {
```

Firebase Admin SDK-এর জন্য project id, service account email, এবং private key environment থেকে আসবে।

```java
public boolean isConfigured() {
    return hasText(projectId) && hasText(clientEmail) && hasText(privateKey);
}
```

সব required value আছে কিনা check করে।

```java
public String normalizedPrivateKey() {
    return privateKey == null ? "" : privateKey.replace("\\n", "\n");
}
```

Environment variable-এ private key সাধারণত `\n` text আকারে থাকে। Firebase credential বানাতে actual newline দরকার হয়।

### Backend app scan

```java
@ConfigurationPropertiesScan
```

Spring Boot-কে বলে `@ConfigurationProperties` classes scan করতে।

## 15. Common mistakes and cautions

- Firebase Console-এ real SMS OTP চালু করে billing trigger করা যাবে না।
- MVP-তে only test phone numbers এবং fixed OTP use করতে হবে।
- `google-services.json` ভুল path-এ রাখলে Android Firebase config কাজ করবে না।
- `google-services.json` client config হলেও এই MVP rule অনুযায়ী commit করা হচ্ছে না।
- Firebase Admin service account JSON কখনো commit করা যাবে না।
- `FIREBASE_PRIVATE_KEY` source code-এ hardcode করা যাবে না।
- Flutter app-এ PIN store করা যাবে না।
- Firebase ID token পাওয়া মানেই SmartKash backend JWT পাওয়া নয়; backend verification/JWT future step।
- Backend verifier skeleton আছে, কিন্তু API endpoint নেই; এটিকে full login flow ভাবা যাবে না।
- Firebase initialization enabled করলে সব dart-define না দিলে app startup error দেবে।

## 16. How to verify this step

Flutter verification:

```powershell
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

Backend verification:

```powershell
cd services/backend
$env:DATABASE_URL="jdbc:postgresql://localhost:5432/smartkash_db"
$env:DATABASE_USERNAME="smartkash_admin"
$env:DATABASE_PASSWORD="<your-local-database-password>"
$env:SPRING_PROFILES_ACTIVE="local"
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

General verification:

```powershell
git status --short
```

Expected result:

- Flutter dependencies resolve হবে।
- Flutter analyze pass হবে।
- Flutter widget test pass হবে।
- Backend context load হবে।
- Firebase Admin SDK env vars না থাকলে backend startup fail করবে না; initializer skip করবে।
- কোনো service account JSON commit হবে না।

## 17. Git commands used in this step

```powershell
git status --short
flutter pub add firebase_core firebase_auth
flutter pub get
flutter analyze
flutter test
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
git add .env.example apps/mobile services/backend docs/codex-progress.md learning/step-05-firebase-auth-foundation.md
git commit -m "step-05: add Firebase auth foundation"
git push
git status --short
```

## 18. What I learned from this step

এই step থেকে শিখলাম Firebase Auth foundation কীভাবে app/backend architecture-এ বসে। Flutter side Firebase initialize করে এবং Firebase Auth service আলাদা রাখে। Backend side Firebase Admin SDK environment credentials ছাড়া initialize করে না, কিন্তু future token verification-এর skeleton তৈরি থাকে। Real SMS OTP, backend JWT, user creation, PIN, wallet, বা business feature এই step-এ implement করা হয়নি, কারণ এগুলো আলাদা focused step-এ করা ভালো।
