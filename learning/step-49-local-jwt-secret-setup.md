# Step 49: Local JWT Secret Setup

## 1. Step title

এই step-এ backend login-এর জন্য local `.env`-এ valid JWT secret setup করা হয়েছে।

## 2. What was implemented

- `services/backend/.env` file-এ local-only `JWT_SECRET` add করা হয়েছে।
- secret length 64 characters হয়েছে, তাই backend-এর 32-byte minimum rule pass করবে।
- `JWT_EXPIRATION_MINUTES=60` add করা হয়েছে।
- `.env.example`, progress doc, test checklist update করা হয়েছে।

## 3. কেন এই step দরকার ছিল

Login screen-এ backend error দেখাচ্ছিল:

```text
JWT secret must be at least 32 bytes.
```

Firebase OTP pass করেছিল, কিন্তু backend JWT token generate করতে গিয়ে fail করছিল। কারণ `.env`-এ `JWT_SECRET` ছিল না, তাই backend short fallback secret ব্যবহার করছিল।

## 4. Important config snippet

`.env`-এ local-only value থাকে:

```properties
JWT_SECRET=<64-character-random-secret>
JWT_EXPIRATION_MINUTES=60
```

ব্যাখ্যা:

- `JWT_SECRET`: backend JWT sign/verify করার secret।
- এটি কমপক্ষে 32 bytes/characters হতে হবে।
- `JWT_EXPIRATION_MINUTES`: backend token কত মিনিট valid থাকবে।
- actual secret GitHub-এ commit করা যাবে না।

## 5. কেন secret commit করা হয়নি

JWT secret sensitive। কেউ secret পেলে fake JWT বানাতে পারে। তাই:

```text
services/backend/.env
```

Git ignore করা আছে এবং commit করা হয়নি।

## 6. SmartKash login flow-এ এটা কীভাবে কাজ করবে

1. Flutter Firebase OTP verify করে।
2. Flutter Firebase ID token backend-এ পাঠায়।
3. Backend Firebase Admin দিয়ে token verify করে।
4. Backend user create/find করে।
5. Backend JWT generate করে।
6. এই JWT generate করার সময় `JWT_SECRET` লাগে।
7. Secret valid হলে login success হবে।

## 7. Common mistakes

- `.env` change করার পর backend restart না করলে new secret load হবে না।
- Secret 32 bytes-এর কম হলে backend login fail করবে।
- `.env` commit করা যাবে না।
- JWT secret বদলালে পুরোনো logged-in token invalid হতে পারে; app sign out/clean run দরকার হতে পারে।

## 8. Manual verification commands

Backend restart:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

Flutter clean run:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter clean
flutter pub get
flutter run --dart-define=FIREBASE_ENABLED=true --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

Expected:

- Firebase OTP pass হবে।
- Backend login আর `JWT secret must be at least 32 bytes` দেখাবে না।
- Login success হলে PIN setup অথবা Home screen আসবে।

## 9. Git commands used

```powershell
git status --short --branch
git add ...
git commit -m "step-49: document local jwt secret setup"
git push
```

## 10. What I learned

এই step থেকে শিখলাম Firebase OTP success হলেও backend JWT config ভুল থাকলে login শেষ হবে না। Backend JWT secret কমপক্ষে 32 bytes হওয়া জরুরি, এবং secret সবসময় local `.env`-এ রাখা উচিত।
