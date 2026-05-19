# External Integrations

**Analysis Date:** 2026-05-19

## WeChat Platform APIs

**Used in `miniprogram/pages/index/index.js` and `miniprogram/app.js`:**

| API | Purpose |
|-----|---------|
| `wx.cloud.init()` | Initialize cloud development environment at app launch |
| `wx.cloud.database()` | Access cloud Firestore-like database (backup, feedback, login collections) |
| `wx.cloud.uploadFile()` | Upload feedback images to cloud storage |
| `wx.cloud.callFunction()` | Invoke `login` and `sendFeedback` cloud functions |
| `wx.cloud.getTempFileURL()` | Convert cloud fileIDs to temporary download URLs (used in `sendFeedback`) |
| `wx.scanCode()` | Camera and album QR code scanning to add TOTP tokens |
| `wx.getStorageSync()` / `wx.setStorageSync()` | Synchronous local key-value storage for tokens, theme, membership |
| `wx.setClipboardData()` | Copy OTP code to system clipboard |
| `wx.chooseMedia()` | Select up to 3 images for feedback attachments |
| `wx.getUserProfile()` | Fetch user avatar and nickname for profile display |
| `wx.login()` | Obtain WeChat auth code for cloud function calls |
| `wx.getPhoneNumber` (open-type button) | Trigger phone number authorization flow |
| `wx.showToast()` | Not used — replaced by custom `toast` component |
| `wx.navigateTo()` | Navigate to `pages/membership/membership` and `pages/feedback/feedback` |
| `wx.onShareAppMessage()` | Mini Program share card customization (title, path, imageUrl) |

**Cloud Environment:**
- Environment ID: `cloud1-d6gv0hhga084dbe14` (hardcoded in `miniprogram/app.js`)
- Configured via `miniprogram/app.json` (`"cloud": true`)

## HarmonyOS SDK Kits

**Used across `harmonyos/entry/src/main/ets/`:**

| Kit | Import | Purpose | File |
|-----|--------|---------|------|
| `@kit.ArkData` | `preferences` | Key-value persistent storage for tokens, theme, membership | `utils/StorageUtil.ets` |
| `@kit.ArkTS` | `util` (Base64Helper) | Base64 encode/decode for backup encryption | `utils/CryptoUtil.ets` |
| `@kit.AbilityKit` | `UIAbility`, `Want`, `AbilityConstant` | App lifecycle (onCreate, onWindowStageCreate) | `entryability/EntryAbility.ets` |
| `@kit.ArkUI` | `window` | Immersive full-screen setup (transparent status/nav bar) | `entryability/EntryAbility.ets` |
| `@kit.PerformanceAnalysisKit` | `hilog` | Structured logging with domain tags | `entryability/EntryAbility.ets` |
| `@kit.ScanKit` | (QR scanner) | Camera-based QR/barcode scanning for token import | `views/ScanView.ets` |
| `@kit.BasicServicesKit` | `pasteboard` | Clipboard copy of OTP codes | Used in token card copy action |

**Declared Permissions (`harmonyos/entry/src/main/module.json5`):**
- `ohos.permission.SYSTEM_FLOAT_WINDOW` — Required for floating window capability

## Cloud Functions (WeChat)

Located in `miniprogram/cloudfunctions/`:

### `login/`
- **File:** `miniprogram/cloudfunctions/login/index.js`
- **Runtime:** Node.js on WeChat Cloud
- **Dependencies:** `wx-server-sdk ~2.6.3`
- **Actions:**
  - `getPhoneNumber`: Exchanges WeChat auth code for user phone number via `cloud.openapi.phonenumber.getPhoneNumber()`, stores `{openid, phoneNumber, createdAt}` in `login` collection
  - Default: Checks if user (by openid) already exists in `login` collection; returns existing phone number or signals new user
- **Database collection:** `login`

### `sendFeedback/`
- **File:** `miniprogram/cloudfunctions/sendFeedback/index.js`
- **Runtime:** Node.js on WeChat Cloud
- **Dependencies:** `wx-server-sdk ~2.6.3`, `nodemailer ^6.9.0`
- **Actions:**
  - Converts cloud storage fileIDs to temporary download URLs via `cloud.getTempFileURL()`
  - Sends HTML email via SMTP to `mengyuefeitian@gmail.com`
  - Stores feedback record in `feedbacks` collection with `{feedbackId, type, content, contactInfo, nickName, imageUrls, createdAt}`
- **SMTP config:** `smtp.163.com:465` (TLS); credentials hardcoded in source (security issue — see CONCERNS.md)
- **Database collection:** `feedbacks`

## Data Storage

### WeChat Mini Program — Local Storage

Uses `wx.getStorageSync` / `wx.setStorageSync` (synchronous key-value):

| Key | Type | Purpose | File |
|-----|------|---------|------|
| `ak_tokens` | JSON string | Array of TOTP token objects | `utils/storage.js` |
| `ak_theme` | JSON string | Selected theme object | `utils/storage.js` |
| `ak_membership` | JSON string | `{isMember, expiry}` | `app.js` `saveMemberData()` |

Storage utility: `miniprogram/utils/storage.js`

### WeChat Mini Program — Cloud Database

Collection: `user_backups` — stores encrypted backup blobs for member users
Collection: `feedbacks` — stores feedback submissions
Collection: `login` — stores user openid and phone number records

### HarmonyOS — Local Preferences

Uses `@kit.ArkData` preferences API (async, file-backed key-value store):

| Preferences File | Key | Type | Purpose |
|-----------------|-----|------|---------|
| `arcankey_prefs` | `auth_tokens` | JSON string | Array of Token objects |
| `arcankey_prefs` | `auth_theme` | JSON string | Selected ThemeItem object |
| `arcankey_prefs` | `ak_membership` | JSON string | `{isMember, expiry}` |

"Cloud" backup on HarmonyOS uses a **separate preferences store** (`arcankey_cloud`) as a Cloud Kit proxy — there is no actual remote cloud storage on HarmonyOS.

Storage utility: `harmonyos/entry/src/main/ets/utils/StorageUtil.ets`

## Authentication & Identity

### WeChat Mini Program
- **Method:** WeChat OAuth via `wx.login()` + `getPhoneNumber` open-type button
- **Backend:** `login` cloud function retrieves openid and phone number
- **State:** `app.globalData.loggedIn`, `app.globalData.userInfo`
- **Persistence:** Membership state stored in `ak_membership` local storage key
- **Nature:** Client-side demo — no session tokens, no JWT, no server session management

### HarmonyOS
- **Method:** Device account (UI-only demo, no actual account SDK calls in current source)
- **State:** `@State` variables in `Index.ets`
- **Nature:** Client-side demo — login is UI state only, no actual authentication

## Email / Notifications

**Outbound email:**
- Triggered by `sendFeedback` cloud function
- SMTP via `nodemailer` → `smtp.163.com:465`
- Destination: `mengyuefeitian@gmail.com`
- Sender address: `17817560527@163.com`
- Credentials: hardcoded in `miniprogram/cloudfunctions/sendFeedback/index.js`

**HarmonyOS feedback:**
- Uses system `mailto:` intent (no cloud function; opens device email client)

## File / Media Storage

### WeChat
- `wx.cloud.uploadFile()` — Feedback images uploaded to WeChat Cloud Storage
- Files referenced by cloud fileID (`cloud://...`); converted to temp URLs for email via `getTempFileURL()`

### HarmonyOS
- No remote file storage; local preferences only

## Monitoring & Observability

**HarmonyOS:**
- `hilog` from `@kit.PerformanceAnalysisKit` — structured logging with domain `0x0000`, tag `ArcaneKey`
- Log calls in `EntryAbility.ets` for lifecycle and error events

**WeChat:**
- `console.log` / `console.error` in cloud functions
- No external error tracking service (Sentry, etc.) detected

## CI/CD & Deployment

**CI Pipeline:** None detected — no GitHub Actions, no CI config files.

**HarmonyOS deployment:**
- Manual build via DevEco Studio
- Distribute via Huawei AppGallery Connect

**WeChat deployment:**
- Manual upload via WeChat DevTools
- Cloud functions deployed independently via WeChat DevTools cloud function panel

## Webhooks & Callbacks

**Incoming:** None (no server, no webhook endpoints).

**Outgoing:** None beyond SMTP email from `sendFeedback`.

---

*Integration audit: 2026-05-19*
