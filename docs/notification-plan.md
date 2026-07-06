# SmartKash Notification Plan

## Purpose

Use Firebase Cloud Messaging for important transaction alerts only.

Notification logic should live in a dedicated backend notification module, not inside controllers. The module should receive event-like service calls after successful transactions and should respect `FCM_ENABLED`.

FCM platform support should be added carefully per Flutter platform. Android remains the primary local notification testing target; full platform-specific notification verification can happen later when each platform is configured.

Step 31 backend foundation:

- `POST /api/devices/fcm-token` stores or refreshes the authenticated user's FCM token.
- `firebase_devices` stores `user_id`, `fcm_token`, `device_type`, `active`, and timestamps.
- `TransactionAlertService` provides a backend service boundary for important transaction alerts.
- `FCM_ENABLED=false` or missing Firebase Admin credentials makes notification sending skip safely.
- Step 31 does not send alerts from every transaction service yet; wiring alerts into each successful money flow can be done in a focused later step.

## MVP Notification Events

- Add Money approved.
- Add Money rejected.
- Send Money completed.
- Merchant Payment completed.
- Savings deposit completed.
- Mobile Recharge completed.
- Loan request approved.
- Loan request rejected.

## Firebase OTP Note

Firebase Phone Auth will use test phone numbers and fixed OTP codes for the MVP. Real SMS OTP will not be used to avoid billing requirements.

## Local Testing Note

If the backend is running locally, FCM notification testing may be limited. Full FCM testing can be done after backend deployment.

## Non-Goals

- Do not send notification for every small user/admin activity in the MVP.
- Do not use paid notification services.
- Do not build a complex notification preference system in MVP Phase 1.
