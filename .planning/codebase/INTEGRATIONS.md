# Integrations

**Last updated:** 2025-05-14

## External Services

### WeChat Cloud Development

- **Environment:** `cloud1-d6gv0hhga084dbe14`
- **Database Collections:**
  - `user_memberships` — Membership status with openid + expiry
  - `user_backups` — Token backups with openid + tokens + timestamp
- **Cloud Functions:**
  - `login` — User authentication
  - `sendFeedback` — Email feedback via nodemailer → `mengyuefeitian@gmail.com`

### WeChat Platform APIs

| API | Purpose | Status |
|-----|---------|--------|
| `wx.scanCode()` | QR scanning | Working |
| `wx.setClipboardData()` | Copy OTP | **errno 112** (privacy agreement) |
| `wx.chooseMedia()` | Image upload | **errno 112** (privacy agreement) |
| `getPhoneNumber` | Login | **errno 112** (privacy agreement) |
| `chooseAvatar` | Avatar selection | Working |
| `nickname` input | Nickname | Working |

### Email Integration

- **Provider:** nodemailer (in cloud function)
- **Recipient:** `mengyuefeitian@gmail.com`
- **Content:** Feedback type, content, images (cloud URLs), contact info

---

## HarmonyOS Integrations

### System APIs

| Kit | Purpose |
|-----|---------|
| `@kit.BasicServicesKit` | Clipboard pasteboard |
| `@kit.ScanKit` | QR code scanning |
| `@kit.ArkData` | Preferences storage |
| `@kit.AbilityKit` | App context |

### Email

- Uses system `mailto:` intent for feedback (no backend)

---

## Authentication

Both platforms use **demo-only client-side login**:

- WeChat: `getPhoneNumber` button (fails due to privacy agreement)
- HarmonyOS: Device account (UI-only)

No real backend authentication. Production would require:
- WeChat Pay backend for membership
- Huawei IAP for HarmonyOS membership

---

## Backup/Sync

- **Free users:** No backup (local storage only)
- **Members:**
  - WeChat: Cloud database (`user_backups` collection)
  - HarmonyOS: Separate preferences store (`arcankey_cloud`)
  - Hourly auto-sync
  - XOR encrypted export/import