# Step 06c: Manual Verification Workflow

## 1. Step title

Step 06c-এর title: **Codex workflow manual verification mode-এ update করা**।

## 2. কী implement করা হয়েছে

এই step-এ SmartKash project workflow update করা হয়েছে, যাতে Codex future step-এ automatically heavy build/test command না চালায়, যদি user explicitly না বলে।

Updated files:

- `docs/codex-instructions.md`
- `docs/development-roadmap.md`
- `docs/codex-progress.md`
- `learning/README.md`
- `learning/step-06c-manual-verification-workflow.md`

## 3. কেন এই step দরকার

Flutter এবং Spring Boot build/test command অনেক সময় নেয়। যেমন:

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `flutter build web`
- `.\mvnw.cmd test`
- `.\mvnw.cmd -q -DskipTests package`

এগুলো Codex session-এ চালালে token, execution time, এবং tool limit বেশি ব্যবহার হয়। তাই এখন থেকে Codex focused code/config/docs change করবে, commit/push করবে, এবং user-কে local IDE/CMD-তে manual verification command দেবে।

## 4. নতুন workflow summary

নতুন workflow:

1. Codex `git status` check করবে।
2. Relevant planning docs read করবে।
3. Focused change করবে।
4. Bangla learning file update করবে।
5. `docs/codex-progress.md` update করবে।
6. দরকার হলে lightweight check চালাবে।
7. Manual verification commands user-কে দেবে।
8. Commit করবে।
9. GitHub-এ push করবে।
10. User manual verification result দিলে next step বা focused fix step হবে।

## 5. Heavy commands Codex automatically চালাবে না

```text
flutter analyze
flutter test
flutter build apk
flutter build web
mvn test
mvn package
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

User explicitly বললে Codex এগুলো চালাতে পারবে। Otherwise user নিজে local CMD/IDE থেকে run করবে।

## 6. Lightweight checks কী

Codex lightweight check হিসেবে এগুলো চালাতে পারে:

```powershell
git status --short
rg "pattern" docs services apps
Test-Path path\to\file
git diff --stat
git diff --cached --stat
dart format specific_file.dart
```

এসব command সাধারণত দ্রুত চলে এবং heavy build/test নয়।

## 7. Manual verification commands examples

Flutter step হলে Codex user-কে দিতে পারে:

```powershell
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
flutter build web
```

Backend step হলে Codex user-কে দিতে পারে:

```powershell
cd services/backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

## 8. Line-by-line explanation of workflow rule

```text
Make focused code/dependency/config changes.
```

মানে এক step-এ শুধু requested কাজ করা হবে। Unrelated feature mix করা যাবে না।

```text
Update the required Bangla learning file.
```

প্রতিটি implementation/config step-এ Bangla learning note update হবে।

```text
Run only lightweight checks.
```

Codex heavy build/test বাদ দিয়ে দ্রুত check চালাবে।

```text
Provide manual verification commands.
```

User local machine-এ command চালিয়ে result জানাবে।

```text
Commit and push changes.
```

প্রতিটি coding/config/doc step শেষে GitHub-এ commit push থাকবে।

## 9. Common mistakes and cautions

- Codex যেন default ভাবে heavy command না চালায়।
- User explicitly বললে heavy command চালানো যাবে।
- Manual verification command final summary-তে দিতে হবে।
- Verification fail করলে unrelated refactor করা যাবে না।
- Failure fix আলাদা focused fix step হিসেবে করতে হবে।
- Commit/push বাদ দেওয়া যাবে না।

## 10. কীভাবে verify করতে হবে

এই workflow doc update verify করতে:

```powershell
git status --short
rg "Manual Verification Workflow|Do not automatically run|Manual verification commands" docs learning
```

Manual heavy verification এই step-এ দরকার নেই, কারণ এটি workflow documentation update only।

## 11. Git commands used in this step

```powershell
git status --short
git add docs/codex-instructions.md docs/development-roadmap.md docs/codex-progress.md learning/README.md learning/step-06c-manual-verification-workflow.md
git commit -m "step-06c: switch to manual verification workflow"
git push
git status --short
```

## 12. কী শিখলাম

এই step থেকে শিখলাম বড় project-এ সবসময় automated heavy verification চালানো practical নয়। Codex focused implementation করবে, lightweight check করবে, learning docs update করবে, commit/push করবে, তারপর user local environment-এ heavy verification চালাবে। এতে time/token বাঁচে এবং user নিজের machine-এর real toolchain দিয়ে result confirm করতে পারে।
