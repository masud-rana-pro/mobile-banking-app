# Firebase Android Client Config

For the SmartKash MVP, Firebase Phone Auth must use test phone numbers and fixed OTP codes only.

If Android Firebase client config is needed, place the Firebase client config file here:

```text
apps/mobile/android/app/google-services.json
```

Do not commit `google-services.json` in this learning MVP. It is ignored by `.gitignore`.

Firebase Admin SDK service account JSON is different from `google-services.json`. Service account JSON contains private credentials and must stay outside the repository.
