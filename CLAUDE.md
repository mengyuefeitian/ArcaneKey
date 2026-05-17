# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the app

The WeChat Mini Program (`miniprogram/`) requires WeChat DevTools. The HarmonyOS app (`harmonyos/`) requires DevEco Studio. There are no shared build commands.

## Permissions

`.claude/settings.json` and `.claude/settings.local.json` auto-allow Bash, Read, Edit, Write, WebSearch, WebFetch, and MCP tools. No permission prompts expected.

## Architecture

This is a TOTP authenticator app (product name: **星枢令**) implemented across two independent platforms (WeChat Mini Program and HarmonyOS). All share the same product logic (30s rotating codes, XOR-encrypted backup, 10 accent themes, login-gated backup/import) but have separate codebases with platform-specific TOTP implementations and persistence.

**Cross-platform constants** (`THEMES`, `BRAND_COLORS`, `INITIAL_TOKENS`, XOR encryption key) are duplicated in:
- `miniprogram/app.js` (WeChat)
- `harmonyos/entry/src/main/ets/model/Token.ets` (HarmonyOS)

When modifying any of these, update both files.

**Membership constants** (`FREE_TOKEN_LIMIT`, `MEMBERSHIP_PRICE`, `APP_NAME`) are defined in:
- `miniprogram/app.js` (WeChat): `FREE_TOKEN_LIMIT = 5`, `MEMBERSHIP_PRICE = 19.90`, `APP_NAME = '星枢令'`
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

<!-- GSD:project-start source:PROJECT.md -->
## Project

**星枢令 (ArcaneKey) — 小程序功能迭代**

**星枢令**是一款跨平台 TOTP 身份验证器，已完成 v1.0 发布（微信小程序 + HarmonyOS）。

本项目跟踪 v1.0 之后的**微信小程序功能迭代**，聚焦于提升用户传播与体验的增量改进。

**核心价值：** 让用户能方便地把星枢令分享给朋友，扩大口碑传播。
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Overview
## WeChat Mini Program (`miniprogram/`)
### Runtime
- **Platform:** WeChat Mini Program
- **Language:** JavaScript (ES5/ES6 compatible)
- **Runtime:** WeChat DevTools
- **Cloud:** WeChat Cloud Development (`wx.cloud`)
### Core Dependencies
- No external npm dependencies
- Pure JavaScript implementations for:
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
## Cross-Platform Constants
| Constant | Value | Files |
|----------|-------|-------|
| `THEMES` | 10 accent colors | `miniprogram/app.js`, `harmonyos/.../Token.ets` |
| `BRAND_COLORS` | ~20 brand hex colors | `harmonyos/.../Token.ets` only (miniprogram inline) |
| `INITIAL_TOKENS` | 6 demo tokens | Both files |
| `FREE_TOKEN_LIMIT` | 5 | Both files |
| `MEMBERSHIP_PRICE` | ¥19.90 | Both files |
| `APP_NAME` | 玄钥 | Both files |
## Security
- XOR encryption for backup (not AES — demo level)
- No secrets in source code
- Cloud environment ID hardcoded in `app.js`
- Privacy agreement pending (errno 112 errors)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Language & UI
- **UI Language:** Chinese (中文)
- **All labels, theme names, button text:** Chinese (e.g. 海洋蓝, 皇室紫, 扫一扫)
- **Code comments:** Mixed Chinese/English
- **Product name:** 玄钥 (ArcaneKey)
## Code Style
### WeChat Mini Program
- **JavaScript:** ES5/ES6, no TypeScript
- **Component pattern:** `Component({ properties, data, methods, observers, lifetimes })`
- **Page pattern:** `Page({ data, onLoad, methods })`
- **Event binding:** `bindtap`, `bindinput`, `bind:custom-event`
- **State updates:** `this.setData({ key: value })`
### HarmonyOS
- **ArkTS:** TypeScript-like with decorators
- **Component pattern:** `@Component struct Name { @State, build() }`
- **Entry pattern:** `@Entry @Component struct Index`
- **Builder pattern:** `@Builder function ModalName()`
- **State updates:** Direct assignment to `@State` vars
## Naming Patterns
| Context | Pattern | Example |
|---------|---------|---------|
| Event handlers | `onXxx` | `onCopyTap`, `onEditToken` |
| Internal methods | `_xxx` | `_updateOtpMap`, `_filterTokens` |
| Data properties | camelCase | `timeLeft`, `accentColor`, `otpMap` |
| WXML classes | kebab-case | `.card-bottom`, `.otp-digit` |
| Components | kebab-case | `token-card`, `bottom-nav` |
## Error Handling
- **Toast notifications:** Custom toast component, not `wx.showToast`
- **Error messages:** Chinese (e.g. "复制失败", "无法解析二维码")
- **Fail callbacks:** Always show user feedback via toast
## Styling Conventions
### Color System
- **Theme colors:** 10 accent colors in `THEMES` array
- **Background:** Dark (`#0d0d12`, `#191920`)
- **Text:** Light (`#eeeef5`, `rgba(238,238,245,0.xx)`)
- **Brand colors:** Hardcoded map for popular brands
### Layout
- **Navigation:** Floating bottom bar, glassmorphism effect
- **Cards:** Rounded corners (18px), dark backgrounds
- **Spacing:** Consistent padding (14px, 16px, 20px)
- **Radius:** Consistent (8px, 12px, 18px)
## Data Patterns
### TOTP Flow
### Storage Keys
| Key | Platform | Purpose |
|-----|----------|---------|
| `ak_tokens` | WeChat | Token array |
| `ak_theme` | WeChat | Theme object |
| `ak_membership` | Both | Membership status |
| `arcankey_cloud` | HarmonyOS | Cloud backup |
## Component Communication
## Magic Numbers
| Value | Context |
|-------|---------|
| 30 | TOTP cycle seconds |
| 5 | Free token limit |
| 19.90 | Membership price (¥) |
| 6 | OTP code digits |
| 3 | Max feedback images |
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern: Single-Page Conditional Rendering
```
```
## WeChat Mini Program Structure
```
```
### Data Flow
```
```
### Timer Architecture
- `setInterval(1000ms)` updates `timeLeft` in `index.js`
- When `timeLeft === 30`: regenerate all OTP codes
- Countdown-ring component receives `timeLeft` as prop
## HarmonyOS Structure
```
```
### Key Differences from WeChat
- Views are `@Component` structs, not pages
- Modals are `@Builder` functions in Index.ets
- Navigation: custom floating capsule (not native)
- State: ArkTS `@State` reactive system
## Membership Architecture
```
```
- WeChat: `wx.getStorageSync('ak_membership')`
- HarmonyOS: Preferences `ak_membership`
## Key Architectural Decisions
| Decision | Rationale |
|----------|-----------|
| Single-page app | Simpler state management, no router complexity |
| No shared code | Platform APIs are incompatible, duplication acceptable |
| XOR encryption | Demo-level simplicity, not production security |
| Canvas countdown | SVG unreliable in WeChat (failed 6 times) |
| Inline modals | WeChat modal API limitations |
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
