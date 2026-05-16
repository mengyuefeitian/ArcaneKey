# Technology Stack

**Last updated:** 2025-05-14

## Overview

Two independent platform implementations sharing the same product logic (TOTP authenticator). No shared code — each platform has its own codebase with platform-specific implementations.

---

## WeChat Mini Program (`miniprogram/`)

### Runtime
- **Platform:** WeChat Mini Program
- **Language:** JavaScript (ES5/ES6 compatible)
- **Runtime:** WeChat DevTools
- **Cloud:** WeChat Cloud Development (`wx.cloud`)

### Core Dependencies
- No external npm dependencies
- Pure JavaScript implementations for:
  - TOTP/HMAC-SHA1: `miniprogram/utils/totp.js`
  - XOR Encryption: `miniprogram/utils/crypto.js`
  - Storage: `miniprogram/utils/storage.js` (wraps `wx.getStorageSync`/`wx.setStorageSync`)

### Configuration
- `miniprogram/app.json` — Pages, window settings, cloud enabled
- `miniprogram/project.config.json` — AppID, cloud environment ID
- Cloud Environment ID: `cloud1-d6gv0hhga084dbe14`

### Cloud Functions
- `miniprogram/cloudfunctions/login/` — Login cloud function
- `miniprogram/cloudfunctions/sendFeedback/` — Feedback email via nodemailer

### WeChat APIs Used
- `wx.cloud.init()` — Cloud initialization
- `wx.cloud.database()` — Cloud database for backup
- `wx.cloud.uploadFile()` — File upload
- `wx.cloud.callFunction()` — Cloud function invocation
- `wx.scanCode()` — QR code scanning
- `wx.setClipboardData()` — Clipboard copy
- `wx.getStorageSync()`/`wx.setStorageSync()` — Local storage
- `wx.chooseMedia()` — Media selection

---

## HarmonyOS App (`harmonyos/`)

### Runtime
- **Platform:** HarmonyOS 6.1 (API 23)
- **Language:** ArkTS (TypeScript-like)
- **IDE:** DevEco Studio
- **Bundle ID:** `com.example.authenticator`

### Core Dependencies
- `@kit.BasicServicesKit` — Pasteboard (clipboard)
- `@kit.AbilityKit` — Common context
- `@kit.ScanKit` — QR scanning
- `@kit.ArkData` — Preferences (storage)
- Dev dependency: `@ohos/hypium` 1.0.18 (testing framework)

### Configuration
- `harmonyos/entry/src/main/module.json5` — Module config, abilities
- `harmonyos/build-profile.json5` — Build configuration
- `harmonyos/oh-package.json5` — Package manifest

### Permissions Declared
- `ohos.permission.SYSTEM_FLOAT_WINDOW` — Floating window

---

## Cross-Platform Constants

Both platforms duplicate identical constants:

| Constant | Value | Files |
|----------|-------|-------|
| `THEMES` | 10 accent colors | `miniprogram/app.js`, `harmonyos/.../Token.ets` |
| `BRAND_COLORS` | ~20 brand hex colors | `harmonyos/.../Token.ets` only (miniprogram inline) |
| `INITIAL_TOKENS` | 6 demo tokens | Both files |
| `FREE_TOKEN_LIMIT` | 5 | Both files |
| `MEMBERSHIP_PRICE` | ¥19.90 | Both files |
| `APP_NAME` | 玄钥 | Both files |

---

## Security

- XOR encryption for backup (not AES — demo level)
- No secrets in source code
- Cloud environment ID hardcoded in `app.js`
- Privacy agreement pending (errno 112 errors)