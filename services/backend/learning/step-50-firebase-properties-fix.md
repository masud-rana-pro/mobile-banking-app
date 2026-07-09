# ধাপ ৫০: Firebase Admin SDK প্রপার্টি ফিক্স (Bangla Learning)

## সমস্যা

ব্যাকএন্ড Firebase Admin SDK আরম্ভ হচ্ছিল না, কারণ `application.yml`-এ শুধুমাত্র ২টি Firebase প্রপার্টি ম্যাপ করা ছিল:

- `private-key-id`
- `client-id`

কিন্তু `FirebaseAdminProperties` ক্লাস ৫টি প্রপার্টি আশা করে:

- `project-id` (projectId)
- `client-email` (clientEmail)
- `private-key` (privateKey)
- `private-key-id` (privateKeyId)
- `client-id` (clientId)

যেহেতু `isConfigured()` মেথড চেক করে:

```java
return hasText(projectId) && hasText(clientEmail) && hasText(privateKey);
```

এবং `projectId`, `clientEmail`, `privateKey` সবগুলো null/empty ছিল, তাই Firebase Admin SDK কখনোই আরম্ভ হতো না। ফলে প্রতিটি লগইন চেষ্টায় `FirebaseTokenVerifierImpl` `IllegalStateException("Firebase Admin SDK is not configured.")` থ্রো করত।

## সমাধান

`application.yml`-এ সব ৫টি Firebase প্রপার্টি যোগ করা হয়েছে:

```yaml
smartkash:
  firebase:
    project-id: ${FIREBASE_PROJECT_ID:}
    client-email: ${FIREBASE_CLIENT_EMAIL:}
    private-key: ${FIREBASE_PRIVATE_KEY:}
    private-key-id: ${FIREBASE_PRIVATE_KEY_ID:}
    client-id: ${FIREBASE_CLIENT_ID:}
```

## কীভাবে কাজ করে

1. Spring Boot `@ConfigurationProperties(prefix = "smartkash.firebase")` ব্যবহার করে `application.yml` থেকে প্রপার্টি পড়ে
2. `.env` ফাইল থেকে `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` ইত্যাদি ভেরিয়েবল লোড হয়
3. `FirebaseAdminInitializer.initialize()` মেথড চেক করে `isConfigured()` — এখন সব প্রপার্টি উপস্থিত থাকায় এটি `true` রিটার্ন করে
4. Firebase Admin SDK আরম্ভ হয় এবং Firebase ID Token ভেরিফিকেশন কাজ করে

## পরীক্ষা

- ব্যাকএন্ড রান করুন: `.\mvnw.cmd spring-boot:run`
- Firebase OTP দিয়ে লগইন করুন
- ব্যাকএন্ড টার্মিনালে দেখুন: "Firebase Admin SDK initialized for project smartkash-f478e."
- লগইন সফল হলে JWT টোকেন ফেরত আসবে

## ফাইল পরিবর্তন

- `services/backend/src/main/resources/application.yml` — ৩টি নতুন Firebase প্রপার্টি যোগ করা হয়েছে
