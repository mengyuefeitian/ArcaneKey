# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the app

The WeChat Mini Program (`miniprogram/`) requires WeChat DevTools. The HarmonyOS app (`harmonyos/`) requires DevEco Studio. There are no shared build commands.

## Permissions

`.claude/settings.json` and `.claude/settings.local.json` auto-allow Bash, Read, Edit, Write, WebSearch, WebFetch, and MCP tools. No permission prompts expected.

## Architecture

This is a TOTP authenticator app (product name: **玄钥**) implemented across two independent platforms (WeChat Mini Program and HarmonyOS). All share the same product logic (30s rotating codes, XOR-encrypted backup, 10 accent themes, login-gated backup/import) but have separate codebases with platform-specific TOTP implementations and persistence.

**Cross-platform constants** (`THEMES`, `BRAND_COLORS`, `INITIAL_TOKENS`, XOR encryption key) are duplicated in:
- `miniprogram/app.js` (WeChat)
- `harmonyos/entry/src/main/ets/model/Token.ets` (HarmonyOS)

When modifying any of these, update both files.

**Membership constants** (`FREE_TOKEN_LIMIT`, `MEMBERSHIP_PRICE`, `APP_NAME`) are defined in:
- `miniprogram/app.js` (WeChat): `FREE_TOKEN_LIMIT = 5`, `MEMBERSHIP_PRICE = 19.90`, `APP_NAME = '玄钥'`
- `harmonyos/entry/src/main/ets/model/Token.ets` (HarmonyOS): same values exported

**Single-page conditional rendering** (both platforms):
Navigation between Home / Scan / Profile is driven by platform-specific state. There is no router — views are conditionally rendered within a single page:
- WeChat: `pages/index/index.wxml` conditional blocks
- HarmonyOS: `Tabs` component in `Index.ets` with `TabContent` per view

### WeChat Mini Program (`miniprogram/`)

Single-page architecture (`pages/index/index` is the only page). All screens are conditional blocks within `index.wxml`.

- **`pages/index/index.js` + `index.wxml`** — monolithic files containing all page logic, state, and conditional view rendering.
- **`pages/membership/membership.js`** — membership purchase page (demo mode, ¥19.90/year).
- **`pages/feedback/feedback.js`** — feedback page (type, content, images, contact → cloud function email).
- **`utils/totp.js`** — pure-JS HMAC-SHA1 + TOTP (no SubtleCrypto; WeChat doesn't expose it). Exports `totp`, `timeLeft`, `fmtCode`.
- **`utils/storage.js`** — `wx.getStorageSync`/`wx.setStorageSync` for tokens and theme persistence.
- **`utils/crypto.js`** — XOR encrypt/decrypt (same algorithm as web, using `btoa`/`atob`).
- **`components/`** — `bottom-nav`, `countdown-ring`, `token-card`, `toast`, `logo` (each with `.js/.json/.wxml/.wxss`).
- **`app.js`** — `globalData` holds `tokens`, `theme`, `loggedIn`, `userInfo`, `isMember`, `memberExpiry`, plus `THEMES` and `INITIAL_TOKENS` constants. `saveMemberData()` method for persistence. Loads from storage on launch.
- **`cloudfunctions/sendFeedback/`** — cloud function using nodemailer to email feedback to developer.

**Membership features**: free users limited to 5 tokens; members get unlimited tokens, cloud backup (wx.cloud.database), hourly auto-sync, secret key visibility toggle, and differentiated delete UX (local vs local+cloud). Backup/import restricted to members only.

**QR scan**: requires login; success directly adds token without manual confirmation step.

### HarmonyOS App (`harmonyos/`)

ArkTS (HarmonyOS 6.1, API 23) app built with DevEco Studio. Bundle name: `com.example.authenticator`.

- **`entry/src/main/ets/pages/Index.ets`** — root `@Entry @Component`. Holds all `@State`, the 1s `setInterval` TOTP timer, and **all modals inline** (LoginModal, EditModal, BackupModal, ImportModal, ThemePicker, MembershipModal — as `@Builder` functions, not separate files). Bottom nav is a custom floating capsule bar.
- **`entry/src/main/ets/views/`** — `HomeView.ets`, `ScanView.ets`, `ProfileView.ets`, `FeedbackView.ets` are `@Component` structs, NOT pages. They are conditionally instantiated inside `Index.ets` based on `currentTab`.
- **`entry/src/main/ets/utils/TOTP.ets`** — pure-TS HMAC-SHA1 TOTP (same algorithm as WeChat).
- **`entry/src/main/ets/utils/StorageUtil.ets`** — `@kit.ArkData` preferences for persistence. Also includes `loadMember()`/`saveMember()` for membership state.
- **`entry/src/main/ets/utils/CryptoUtil.ets`** — XOR encrypt/decrypt.
- **`entry/src/main/ets/model/Token.ets`** — `Token` interface, `OtpPair`, `ThemeItem` types + `INITIAL_TOKENS` + `THEMES` + `BRAND_COLORS` + `FREE_TOKEN_LIMIT` + `MEMBERSHIP_PRICE` + `APP_NAME`.
- **`entry/src/main/ets/components/`** — `Logo.ets`, `CountdownRing.ets`, `TokenCard.ets`.
- **`entry/src/main/ets/entryability/EntryAbility.ets`** — configures immersive window: `setWindowLayoutFullScreen(true)` + `setWindowBackgroundColor('#00000000')`.
- **`entry/src/main/module.json5`** — declares `ohos.permission.SYSTEM_FLOAT_WINDOW`.
- **SDK imports**: `@kit.BasicServicesKit` (pasteboard), `@kit.AbilityKit` (common context), `@kit.ScanKit` (QR scanning), `@kit.ArkData` (preferences).

**Membership features**: same as WeChat — free limit 5 tokens, member unlimited, cloud backup via preferences (local storage as Cloud Kit proxy), hourly auto-sync, secret key visibility toggle, delete confirmation with local/cloud options. Feedback uses `mailto:` system intent.

**Bottom nav**: floating capsule (90% width, 28px border radius) with `.backdropFilter('blur(20px)')` glassmorphism, positioned via `translate({ y: navVisible ? -20 : 80 })`. Content has `.padding({ bottom: 80 })` to avoid overlap. Nav icons are clean SVG paths (not system symbols). `HomeView`'s `onScrollFrameBegin` callback drives `navVisible` to hide/show on scroll direction.

## Key details

- **UI language**: Chinese. All theme names, button labels, and UI text are in Chinese (e.g. 海洋蓝, 皇室紫, 扫一扫). Keep new UI strings in Chinese.
- **Theming**: `THEMES` array drives the `accent` color prop. Web uses oklch colors; miniprogram and HarmonyOS use hex equivalents (e.g. `oklch(0.62 0.20 250)` → `#4080D0`). `BRAND_COLORS` map drives `Logo` letter-avatar colors.
- **Backup encryption**: `encryptData`/`decryptData` use XOR — intentionally simple for this demo, not real AES encryption.
- **QR scanning (miniprogram)**: uses `wx.scanCode()` for camera and album scanning.
- **QR scanning (HarmonyOS)**: uses `@kit.ScanKit`.
- **Login**: entirely client-side demo across both platforms; WeChat login uses `getPhoneNumber`, HarmonyOS uses device account — both are UI-only with no backend.
- **Membership**: demo mode — payment directly sets `isMember = true` with 1-year expiry. Production requires WeChat Pay backend / Huawei IAP.
- **Cloud backup (WeChat)**: uses `wx.cloud.database` collection `user_backups`. Requires cloud development environment.
- **Cloud backup (HarmonyOS)**: uses separate preferences store `arcankey_cloud` as Cloud Kit proxy.
- **Feedback (WeChat)**: cloud function `sendFeedback` with nodemailer → `mengyuefeitian@gmail.com`.
- **Feedback (HarmonyOS)**: uses system `mailto:` intent.

## Git

This repository has a `main` branch with committed history. All source files are currently tracked. The repo root contains a `.DS_Store` file that should be added to `.gitignore`.

## Infrastructure

No tests, no CI/CD, no linter, no formatter, no package manager, no `.gitignore`, no `README.md`. The miniprogram and HarmonyOS apps rely solely on their platform-specific IDEs (WeChat DevTools, DevEco Studio).

**Planning docs** (`docs/plans/`):
- `2026-04-26-authenticator-apps.md` — initial implementation plan
- `2026-04-28-bug-fixes-and-enhancements.md` — bug fixes and feature enhancements
- `2026-04-28-ui-fixes-and-features.md` — UI fixes (input clipping, nav redesign, WeChat/HarmonyOS login, profile branding)
- `2026-04-29-bug-fixes.md` — web app bug fixes (nav clicks, edit modal layout, search box)
- `2026-04-30-membership-and-feedback.md` — membership system, QR auto-add, cloud backup/sync, feedback
