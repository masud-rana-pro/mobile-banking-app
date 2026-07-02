# SmartKash শেখার নোট

এই `learning/` folder-এর উদ্দেশ্য হলো SmartKash project বানানোর সময় প্রতিটি ধাপ বাংলায় বুঝে শেখা।

প্রতিটি future implementation step-এ অবশ্যই এই folder-এর ভিতরে একটি Bangla learning file তৈরি বা update করতে হবে। Learning file শুধু ছোট summary হলে চলবে না; সেই step-এ তৈরি বা পরিবর্তন করা code, config, folder, class, command, এবং verification ভালোভাবে ব্যাখ্যা করতে হবে।

## File Naming Format

```text
learning/step-XX-topic-name.md
```

## Examples

- `learning/step-00-planning-architecture-review.md`
- `learning/step-01-project-setup.md`
- `learning/step-02-flutter-app-setup.md`
- `learning/step-03-spring-boot-backend-setup.md`
- `learning/step-04-firebase-auth-test-otp.md`
- `learning/step-05-spring-security-jwt.md`
- `learning/step-06-postgresql-database-setup.md`
- `learning/step-07-wallet-ledger-design.md`

## প্রতিটি Learning File-এ যা থাকতে হবে

1. Step title
2. কী implement করা হয়েছে
3. কেন এই step দরকার
4. কোন files/folders/classes/config create বা change হয়েছে
5. Important code snippets
6. Important config snippets, যদি config create/change হয়
7. Code/config-এর Bangla explanation, line-by-line বা block-by-block
8. প্রতিটি গুরুত্বপূর্ণ file/folder/class/config কেন আছে
9. SmartKash app flow-তে এই step কীভাবে connect করে
10. Common mistakes and cautions
11. কীভাবে test বা verify করতে হবে
12. এই step-এ কোন Git commands ব্যবহার করা হয়েছে
13. এই step থেকে কী শিখলাম তার short summary

## Important Rules

- কোনো implementation step learning file ছাড়া করা যাবে না।
- শুধু short summary লেখা যাবে না।
- Important code/config snippets দিতে হবে এবং পরিষ্কারভাবে explain করতে হবে।
- Explanation beginner-friendly কিন্তু technically correct হতে হবে।
- Code implement করার একই step-এ learning file update করতে হবে।
- Folder তৈরি করলে কোন folder কেন দরকার তা explain করতে হবে।
- Class তৈরি করলে class-এর responsibility explain করতে হবে।
- Config change করলে key/value বা important config block explain করতে হবে।
- Verification command চালালে command এবং output-এর অর্থ explain করতে হবে।
- Heavy verification command Codex না চালালে manual verification commands দিতে হবে, যাতে user local IDE/CMD থেকে run করতে পারে।
- Git command ব্যবহার করলে learning file-এ command list দিতে হবে।
- Planning-only step হলেও দরকার হলে learning note তৈরি বা update করা যাবে।

## Manual Verification Workflow

Token এবং execution limit বাঁচানোর জন্য Codex future step-এ automatic heavy build/test command চালাবে না, যদি user explicitly না বলে।

Codex সাধারণত এই heavy commands নিজে চালাবে না:

- `flutter analyze`
- `flutter test`
- `flutter build apk`
- `flutter build web`
- `mvn test`
- `mvn package`
- `.\mvnw.cmd test`
- `.\mvnw.cmd -q -DskipTests package`

Codex code/config/docs change করবে, Bangla learning file update করবে, lightweight check চালাবে, commit/push করবে, তারপর user-এর জন্য exact manual verification commands দেবে।

এই folder project শেখার personal guide হিসেবে কাজ করবে। লক্ষ্য হলো SmartKash project-এর actual code/config/structure ধাপে ধাপে বাংলায় শেখা।

## Current Planning Note

Architecture review-এর learning note: `learning/step-00-planning-architecture-review.md`
