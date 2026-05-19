# Technology Stack

**Analysis Date:** 2026-05-19

## Languages

**Primary (HarmonyOS):**
- ArkTS — TypeScript-like language with decorators; used for all HarmonyOS UI and logic
  - All `.ets` files under `harmonyos/entry/src/main/ets/`

**Primary (WeChat Mini Program):**
- JavaScript (ES5/ES6) — used for all WeChat Mini Program logic, pages, and components
  - All `.js` files under `miniprogram/`

**Markup/Style:**
- WXML — WeChat template language for all page/component markup (`miniprogram/**/*.wxml`)
- WXSS — WeChat stylesheet format (`miniprogram/**/*.wxss`)
- JSON — Configuration and component descriptors on both platforms

## Runtime

**HarmonyOS:**
- Platform: HarmonyOS 6.1, API Level 23
- IDE: DevEco Studio (required)
- Compile/Target/Compatible SDK: `6.1.0(23)` (`harmonyos/build-profile.json5`)
- Runtime OS: HarmonyOS (phone, tablet)
- Bundle ID: `com.example.authenticator`

**WeChat Mini Program:**
- Platform: WeChat Mini Program runtime
- IDE: WeChat DevTools (required)
- Base Library: `3.15.2` (`miniprogram/project.config.json`)
- App ID: `wxb3a1fe58a9ad9b87`
- Cloud Environment ID: `cloud1-d6gv0hhga084dbe14`

## Package Manager

**HarmonyOS:**
- Manager: ohpm (HarmonyOS package manager)
- Manifest: `harmonyos/oh-package.json5`
- Model version: `6.1.0`

**WeChat Cloud Functions:**
- Manager: npm
- Manifests: `miniprogram/cloudfunctions/*/package.json`

## Frameworks

**HarmonyOS:**
- ArkUI — Declarative UI framework. Components use `@Component struct`, entry uses `@Entry @Component struct`. State management via `@State`, `@Prop`, `@Link` decorators.
- ArkData (`@kit.ArkData`) — Preferences-based persistence layer
- Entry: `harmonyos/entry/src/main/ets/pages/Index.ets`

**WeChat Mini Program:**
- WeChat MINA Framework — page/component lifecycle via `Page({})` and `Component({})` objects
- State management: `this.setData({})` for reactive updates
- Entry: `miniprogram/pages/index/index.js`

**Testing (HarmonyOS only):**
- `@ohos/hypium` 1.0.18 — HarmonyOS unit test framework (dev dependency only; no test files authored)

## Key Dependencies

**HarmonyOS — Runtime SDKs (all `@kit.*` from HarmonyOS SDK, no external npm):**
- `@kit.ArkData` — Preferences storage (`preferences` API) — `harmonyos/entry/src/main/ets/utils/StorageUtil.ets`
- `@kit.ArkTS` — `util.Base64Helper` for Base64 encode/decode — `harmonyos/entry/src/main/ets/utils/CryptoUtil.ets`
- `@kit.AbilityKit` — `UIAbility`, `Want`, `AbilityConstant`; app lifecycle — `harmonyos/entry/src/main/ets/entryability/EntryAbility.ets`
- `@kit.ArkUI` — `window` API for immersive full-screen setup — `EntryAbility.ets`
- `@kit.PerformanceAnalysisKit` — `hilog` structured logging — `EntryAbility.ets`
- `@kit.ScanKit` — QR/barcode scanning — `harmonyos/entry/src/main/ets/views/ScanView.ets`
- `@kit.BasicServicesKit` — Pasteboard (clipboard copy) — used in token card copy action

**WeChat Cloud Functions:**
- `wx-server-sdk` ~2.6.3 — WeChat server SDK used in both cloud functions
- `nodemailer` ^6.9.0 — SMTP email sending — `miniprogram/cloudfunctions/sendFeedback/index.js`

**WeChat Mini Program — No external npm dependencies.** All crypto, TOTP, and storage are pure-JS implementations.

## Pure-JS / Pure-ArkTS Implementations (no external library)

Both platforms implement the following from scratch to avoid unavailable native APIs:

| Module | WeChat | HarmonyOS |
|--------|--------|-----------|
| HMAC-SHA1 | `miniprogram/utils/totp.js` | `harmonyos/.../utils/TOTP.ets` |
| Base32 decode | `miniprogram/utils/totp.js` | `harmonyos/.../utils/TOTP.ets` |
| TOTP (RFC 6238) | `miniprogram/utils/totp.js` | `harmonyos/.../utils/TOTP.ets` |
| XOR/PBKDF2 encrypt | `miniprogram/utils/crypto.js` | `harmonyos/.../utils/CryptoUtil.ets` |
| SHA-1 | `miniprogram/utils/totp.js` | `harmonyos/.../utils/CryptoUtil.ets` (duplicated) |

Note: HarmonyOS `CryptoUtil.ets` uses PBKDF2-HMAC-SHA1 with 16-byte random salt (ENC2 format) for backup encryption, plus a legacy XOR fallback. WeChat uses a simpler XOR with a fixed key.

## Build / Tooling

**HarmonyOS:**
- Build tool: DevEco Studio (Gradle-based under the hood)
- Build config: `harmonyos/build-profile.json5`
- Module config: `harmonyos/entry/src/main/module.json5`
- Build modes: `debug`, `release`
- No CLI build commands available outside DevEco Studio

**WeChat Mini Program:**
- Build tool: WeChat DevTools (handles WXML/WXSS/JS compilation)
- Project config: `miniprogram/project.config.json`
- Settings: ES6 transpilation enabled (`es6: true`), postcss enabled, minification enabled
- No CLI build commands; DevTools required

## Platform Requirements

**Development:**
- HarmonyOS: DevEco Studio (macOS/Windows)
- WeChat Mini Program: WeChat DevTools (macOS/Windows)
- No shared build system or monorepo tooling

**Production:**
- HarmonyOS: Deploy via Huawei AppGallery Connect (`.hap` package)
- WeChat Mini Program: Deploy via WeChat Mini Program admin console
- Cloud functions deployed to WeChat Cloud Development environment `cloud1-d6gv0hhga084dbe14`

## Configuration

**HarmonyOS:**
- `harmonyos/build-profile.json5` — SDK versions, signing configs, product targets
- `harmonyos/entry/src/main/module.json5` — Ability declarations, device types, permissions
- `harmonyos/oh-package.json5` — Package manifest and dependencies
- No `.env` file; no environment variable system

**WeChat Mini Program:**
- `miniprogram/app.json` — Pages list, window styles, cloud enabled flag
- `miniprogram/project.config.json` — App ID, cloud function root, compiler settings
- Cloud environment ID hardcoded in `miniprogram/app.js` as `globalData`
- SMTP credentials hardcoded in `miniprogram/cloudfunctions/sendFeedback/index.js` (security concern)

---

*Stack analysis: 2026-05-19*
