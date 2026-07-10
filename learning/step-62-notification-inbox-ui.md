# Step 62: Notification Inbox UI

## 1. Step title

এই step-এর নাম: **Step 62: Notification Inbox UI**।

## 2. কী implement করা হয়েছে

এই step-এ SmartKash Flutter app-এ bottom navigation-এর `Inbox` button কাজ করানো হয়েছে।

- নতুন `NotificationInboxScreen` তৈরি হয়েছে।
- Home bottom navigation থেকে Inbox screen-এ route করা হয়েছে।
- App router-এ `/notifications` route যোগ হয়েছে।
- Screen-এ important transaction alert categories দেখানো হয়েছে।
- Local FCM limitation এবং notification history future scope হিসেবে clearly দেখানো হয়েছে।

## 3. কেন এই step দরকার

SmartKash backend already important transaction alerts-এর জন্য FCM foundation এবং wiring রাখে। কিন্তু Flutter app-এ user-এর জন্য কোনো Inbox screen ছিল না। ফলে bottom nav-এর `Inbox` button কাজ করছিল না।

এই step user experience improve করে:

- bottom nav-এর Inbox আর dead button নয়,
- user বুঝতে পারে কোন ধরনের alert আসবে,
- MVP limitation পরিষ্কার থাকে,
- future notification history API-এর জায়গা তৈরি হয়।

## 4. কোন files/folders/classes change হয়েছে

- `apps/mobile/lib/features/notification/presentation/notification_inbox_screen.dart`
- `apps/mobile/lib/app/router/app_router.dart`
- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `docs/codex-progress.md`
- `docs/test-checklist.md`
- `learning/step-62-notification-inbox-ui.md`

## 5. Important code snippets

### Notification route constants

```dart
static const routeName = 'notification-inbox';
static const routePath = '/notifications';
```

### App router entry

```dart
GoRoute(
  path: NotificationInboxScreen.routePath,
  name: NotificationInboxScreen.routeName,
  builder: (context, state) => const NotificationInboxScreen(),
),
```

### Bottom nav click handling

```dart
if (index == 3) {
  context.pushNamed(NotificationInboxScreen.routeName);
}
```

### MVP scope note

```dart
'This screen is the MVP inbox placeholder. Backend already sends important FCM alerts when enabled, but notification history storage is future scope.'
```

## 6. Code explanation

### Route constants

`routeName` route identify করতে use হয়।

`routePath` browser/app navigation path হিসেবে use হয়।

এই constants রাখলে route name typo হওয়ার chance কমে।

### App router

`GoRoute` app-কে বলে `/notifications` path hit করলে কোন screen show করতে হবে।

`builder` নতুন `NotificationInboxScreen` return করে।

এটা auth-protected router-এর ভিতরে আছে, তাই login ছাড়া user Inbox screen দেখতে পারবে না।

### Bottom navigation

`NavigationBar` index দিয়ে destination চিনে।

`index == 3` হলো Inbox tab।

`context.pushNamed(...)` current Home screen-এর উপর Inbox screen push করে, তাই back button দিলে Home-এ ফেরা যায়।

### MVP scope note

এই text user-কে honest limitation জানায়। Backend FCM alert পাঠাতে পারে, কিন্তু persisted notification history এখনো database/API হিসেবে build করা হয়নি।

## 7. SmartKash flow-তে কীভাবে কাজ করে

1. User login করে Home screen-এ যায়।
2. Bottom nav থেকে `Inbox` tap করে।
3. App `/notifications` route open করে।
4. User দেখতে পায় SmartKash কোন important alerts support করবে।
5. Future-এ notification history API হলে এই screen real list দেখাতে পারবে।

## 8. কেন backend API যোগ করা হয়নি

এই step শুধুই Flutter UI polish step।

Notification history table/API এখনো planning scope-এ নেই। Backend currently FCM important alerts send করে, কিন্তু historical notification inbox store করে না।

তাই এই step-এ database schema, backend API, FCM permission prompt, বা local notification rendering যোগ করা হয়নি।

## 9. Common mistakes and cautions

- UI placeholder মানে fake backend history নয়।
- User-কে এমনভাবে দেখানো যাবে না যেন real persisted notification list already আছে।
- Bottom nav route missing থাকলে tap করলে কিছু হবে না।
- Route name typo হলে navigation fail করবে।
- Heavy verification Codex automatic চালাবে না; user manual run করবে।

## 10. Manual verification commands

Flutter:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter run --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

Backend normally does not need to change for this UI-only step. If you want full app run:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

## 11. Expected output

- Login/Home flow আগের মতো কাজ করবে।
- Home bottom nav-এ `Inbox` tap করলে Inbox screen open হবে।
- Screen title হবে `Inbox`।
- Screen-এ `Transaction alerts only` summary card দেখা যাবে।
- Add Money, Send Money, Merchant payments, Recharge/Savings, Loan status alert category দেখা যাবে।
- নিচে local testing/future scope note দেখা যাবে।

## 12. Git commands used

```powershell
git status
git add <step-62-files>
git commit -m "step-62: add notification inbox UI"
git push
```

## 13. কী শিখলাম

এই step থেকে শিখলাম কীভাবে existing Flutter route system-এ নতুন screen add করতে হয়, bottom navigation থেকে route open করতে হয়, এবং MVP limitation honest UI copy দিয়ে user-এর কাছে পরিষ্কার রাখতে হয়।
