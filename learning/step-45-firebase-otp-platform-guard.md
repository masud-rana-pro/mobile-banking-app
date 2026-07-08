# Step 45: Firebase OTP Platform Guard

## 1. Step title

এই step-এ Chrome/Web-এ Firebase OTP চালানোর ভুল flow বন্ধ করে clear message দেখানো হয়েছে।

## 2. What was implemented

- `AuthController` এখন OTP পাঠানোর আগে platform check করে।
- Firebase disabled থাকলে clear message দেখায়।
- Chrome/Web হলে বলে current setup Android-only।
- Android ছাড়া অন্য platform হলে Android emulator ব্যবহার করতে বলে।

## 3. কেন এই step দরকার ছিল

Screenshot-এ URL ছিল:

```text
localhost:56052/#/login
```

মানে app Chrome/Web হিসেবে চলছে। কিন্তু SmartKash-এ এখন Firebase client setup করা হয়েছে Android `google-services.json` দিয়ে। Firebase Phone Auth Web-এ চালাতে আলাদা Firebase Web app config লাগে।

## 4. Important snippet

```dart
final firebaseBlockReason = _firebaseOtpBlockReason();
if (firebaseBlockReason != null) {
  state = state.copyWith(
    status: AuthSessionStatus.failure,
    phoneNumber: phoneNumber,
    clearOtp: true,
    clearInfo: true,
    errorMessage: firebaseBlockReason,
  );
  return;
}
```

Block-by-block ব্যাখ্যা:

- `_firebaseOtpBlockReason()`: current platform/config check করে।
- `firebaseBlockReason != null`: OTP চালানো safe না হলে message পাওয়া যায়।
- `status: failure`: UI error state দেখাবে।
- `errorMessage`: user/developer কী করতে হবে বুঝতে পারবে।
- `return`: Firebase call আর হবে না, তাই raw Web exception আসবে না।

```dart
if (kIsWeb) {
  return 'You are running on Chrome/Web. Current SmartKash OTP setup is Android-only. Run on Android emulator, or add a Firebase Web app config first.';
}
```

ব্যাখ্যা:

- `kIsWeb`: Flutter app Web/Chrome-এ চলছে কিনা বলে।
- Web হলে Firebase Android config ব্যবহার করা যাবে না।
- তাই app Android emulator চালাতে বলে, অথবা Firebase Web app config add করতে বলে।

## 5. Firebase Console-এ কী লাগবে যদি Web OTP চাই

Chrome/Web OTP চালাতে হলে Firebase Console-এ:

1. Project settings খুলতে হবে।
2. Web app add করতে হবে।
3. Firebase config copy করতে হবে:
   - `apiKey`
   - `authDomain`
   - `projectId`
   - `appId`
   - `messagingSenderId`
4. Authentication > Settings > Authorized domains-এ `localhost` থাকতে হবে।
5. তারপর SmartKash Flutter config-এ Web Firebase options যোগ করতে হবে।

## 6. Android OTP test করতে কী করতে হবে

Android emulator/device run:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter run -d <android-device-id> --dart-define=FIREBASE_ENABLED=true --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

Backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

Test:

```text
Phone: 01575634380
OTP: 123456
```

## 7. Expected output

- Chrome/Web-এ raw TypeError দেখাবে না।
- Chrome/Web-এ message দেখাবে যে current OTP setup Android-only।
- Android emulator-এ `Send OTP` Firebase Phone Auth flow চালাবে।
- OTP success হলে backend JWT login হবে।

## 8. Common mistakes

- Chrome-এ Android `google-services.json` দিয়ে Firebase Phone Auth চালানো যাবে না।
- `flutter run` default Chrome select করলে Android OTP test হবে না।
- `--dart-define=FIREBASE_ENABLED=true` না দিলে Firebase initialize হবে না।
- Backend run না থাকলে OTP success হলেও backend login fail করবে।

## 9. Git commands used

```powershell
git status --short --branch
git add ...
git commit -m "step-45: guard unsupported Firebase OTP platforms"
git push
```

## 10. What I learned

এই step থেকে শিখলাম Firebase client config platform-specific। Android app-এর জন্য `google-services.json`, Web app-এর জন্য Firebase Web config লাগে। তাই কোন platform-এ app চলছে সেটা check করে clear instruction দেওয়া জরুরি।
