# Memory Index

- [AGC Cloud Function Auth Blocker](agc-cloud-function-auth.md) — AGC HTTP triggers require HDA-SYSTEM signing; Bearer token alone always 404s; workaround is direct SMTP
- [HarmonyOS Feedback Implementation](harmonyos-feedback-smtp.md) — FeedbackView uses direct 163 SMTP (SmtpSession class) to bypass AGC auth issues
- [HarmonyOS Cloud Function Success](harmonyos-cloud-function-success.md) — ✅ 云函数 SDK 调用已成功，使用 cloud.callFunction() 通过内部 AGC API 发送反馈
- [HarmonyOS Cloud Sync](harmonyos-cloud-sync.md) — 云同步使用 AGC Cloud Functions (sync-add, sync-delete, sync-restore, sync-pull) 实现 CRUD 和自动同步