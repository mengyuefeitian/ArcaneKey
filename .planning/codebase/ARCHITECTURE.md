<!-- refreshed: 2026-05-19 -->
# Architecture

**Analysis Date:** 2026-05-19

## System Overview

```text
┌─────────────────────────────────────────────────────────────────────┐
│                  ArcaneKey — Dual Platform TOTP App                  │
├──────────────────────────────┬──────────────────────────────────────┤
│   WeChat Mini Program         │   HarmonyOS App                      │
│   `miniprogram/`              │   `harmonyos/entry/src/main/ets/`    │
│                               │                                      │
│  Single-page (index.wxml)     │  Single-page (pages/Index.ets)       │
│  `screen` state drives views  │  `currentTab` + modal flags          │
│  globalData for app state     │  @State on @Entry struct             │
└──────────────┬────────────────┴──────────────┬───────────────────────┘
               │                               │
               ▼                               ▼
┌──────────────────────────────────────────────────────────────────────┐
│                     Shared Logic (duplicated)                         │
│  TOTP (HMAC-SHA1 + base32)  │  XOR+PBKDF2 crypto  │  10 themes       │
│  miniprogram/utils/totp.js  │  utils/crypto.js     │  app.js / Token.ets│
│  harmonyos/.../TOTP.ets     │  utils/CryptoUtil.ets│                  │
└──────────────────────────────────────────────────────────────────────┘
               │                               │
               ▼                               ▼
┌──────────────────────┐     ┌──────────────────────────────────────────┐
│  wx.getStorageSync   │     │  @kit.ArkData preferences                │
│  ak_tokens           │     │  arcankey_prefs (tokens, theme, member)  │
│  ak_theme            │     │  arcankey_cloud (member cloud backup)    │
│  ak_membership       │     │                                          │
└──────────────────────┘     └──────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `Index` (HarmonyOS) | Root `@Entry`: owns ALL state, timers, modals, business logic | `harmonyos/entry/src/main/ets/pages/Index.ets` |
| `App` (WeChat) | Global container, `globalData` store, cloud init, membership persistence | `miniprogram/app.js` |
| `index.js` (WeChat) | Page logic mirror of HarmonyOS Index — all state, event handlers | `miniprogram/pages/index/index.js` |
| `HomeView` | Token list, search bar, scroll-driven nav hide/show | `harmonyos/entry/src/main/ets/views/HomeView.ets` |
| `ScanView` | QR scan (camera/album/manual), otpauth URI parsing | `harmonyos/entry/src/main/ets/views/ScanView.ets` |
| `ProfileView` | Account display, settings menu, membership entry points | `harmonyos/entry/src/main/ets/views/ProfileView.ets` |
| `FeedbackView` | Feedback form, `mailto:` system intent | `harmonyos/entry/src/main/ets/views/FeedbackView.ets` |
| `TokenCard` | Single token card: brand logo, OTP digits with gradient, copy row | `harmonyos/entry/src/main/ets/components/TokenCard.ets` |
| `CountdownRing` | Circular SVG-style progress ring driven by `timeLeft` prop | `harmonyos/entry/src/main/ets/components/CountdownRing.ets` |
| `Logo` | Brand letter-avatar using `BRAND_COLORS` map | `harmonyos/entry/src/main/ets/components/Logo.ets` |
| `Token.ets` | Data model types + all cross-platform constants | `harmonyos/entry/src/main/ets/model/Token.ets` |
| `TOTP.ets` | Pure HMAC-SHA1 + base32 decode + TOTP algorithm | `harmonyos/entry/src/main/ets/utils/TOTP.ets` |
| `StorageUtil.ets` | Async ArkData preferences wrapper (tokens, theme, membership) | `harmonyos/entry/src/main/ets/utils/StorageUtil.ets` |
| `CryptoUtil.ets` | PBKDF2-HMAC-SHA1 key derivation + XOR cipher for file backup | `harmonyos/entry/src/main/ets/utils/CryptoUtil.ets` |
| `EntryAbility.ets` | UIAbility entry; loads `pages/Index`, sets immersive window | `harmonyos/entry/src/main/ets/entryability/EntryAbility.ets` |

## Pattern Overview

**Overall:** Single-page conditional rendering (no router on either platform)

**Key Characteristics:**
- Navigation between Home / Scan / Profile driven entirely by a single integer state value (`currentTab` on HarmonyOS, `screen` string on WeChat)
- All modals are overlaid within the same component tree using `if (flagState) { this.modalBuilder() }` — no navigation stack
- All business logic lives in the root component (Index / index.js); views and components are presentation-only
- No shared code between platforms; logic is independently re-implemented in JS and ArkTS

## Layers

**Model Layer:**
- Purpose: Type definitions and cross-platform constants
- Location: `harmonyos/entry/src/main/ets/model/Token.ets`
- Contains: `Token`, `OtpPair`, `ThemeItem` interfaces; `THEMES`, `BRAND_COLORS`, `INITIAL_TOKENS`, `FREE_TOKEN_LIMIT`, `MEMBERSHIP_PRICE`, `APP_NAME` constants
- Depends on: Nothing
- Used by: All views, components, Index.ets, StorageUtil.ets

**Utility Layer:**
- Purpose: Pure algorithms and I/O adapters with no UI
- Location: `harmonyos/entry/src/main/ets/utils/`
- Contains: `TOTP.ets` (HMAC-SHA1 algorithm), `StorageUtil.ets` (preferences I/O), `CryptoUtil.ets` (PBKDF2 + XOR)
- Depends on: `@kit.ArkData`, `@kit.ArkTS`; model types
- Used by: `Index.ets` only

**Component Layer:**
- Purpose: Reusable presentational UI pieces
- Location: `harmonyos/entry/src/main/ets/components/`
- Contains: `TokenCard.ets`, `CountdownRing.ets`, `Logo.ets`
- Depends on: Model types; receive all data via `@Prop`
- Used by: Views

**View Layer:**
- Purpose: Full-screen tab content panels
- Location: `harmonyos/entry/src/main/ets/views/`
- Contains: `HomeView.ets`, `ScanView.ets`, `ProfileView.ets`, `FeedbackView.ets`
- Depends on: Model types, components
- Used by: `Index.ets` inside `TabContent()` blocks

**Orchestration Layer:**
- Purpose: Root state owner, timer management, cloud sync, modal rendering
- Location: `harmonyos/entry/src/main/ets/pages/Index.ets`
- Contains: All `@State` declarations, `aboutToAppear`/`aboutToDisappear` lifecycle, all business logic methods, all `@Builder` modal functions
- Depends on: All other layers

## Data Flow

### TOTP Update Cycle (Primary)

1. `setInterval(1000ms)` fires in `Index.aboutToAppear()` (`Index.ets:102`)
2. `timeLeft_ = timeLeft()` — reads `Date.now() % 30` (`TOTP.ets:100`)
3. When `timeLeft_ === 30`: calls `refreshOtp()` (`Index.ets:140`)
4. `refreshOtp()` iterates `this.tokens`, calls `totp(t.secret, 0)` and `totp(t.secret, 1)`, writes new `otpMap` object
5. `@State otpMap` change triggers ArkTS re-render
6. `HomeView` receives `otpMap` as `@Prop` → propagates to each `TokenCard`
7. `TokenCard` renders each digit of `otp.current` with gradient color interpolation

### Token Add via QR Scan

1. User taps Scan tab → `currentTab = 1` if `loggedIn`, else `showLogin = true`
2. `ScanView.doScan()` calls `scanBarcode.startScanForResult()` via `@kit.ScanKit`
3. Result URI parsed: `otpauth://totp/<label>?secret=<base32>&issuer=<brand>` → `parseOtpUri()`
4. `ScanView` fires `onAdd(brand, account, secret)` callback to `Index`
5. `Index.addToken()`: checks `FREE_TOKEN_LIMIT`, appends to `tokens`, calls `saveTokens()`, calls `refreshOtp()`
6. If member: also triggers `cloudBackup()`

### Modal Overlay Flow

1. View fires a callback (e.g., `onBackupTap`)
2. `Index` sets a boolean flag (e.g., `showBackup = true`)
3. `build()` evaluates `if (this.showBackup) { this.backupModal() }` — modal rendered as full-screen `Stack` layer with `zIndex(400)`
4. Modal close: sets flag back to `false`

### State Management (HarmonyOS)

All state is `@State` on the `Index` struct. Data flows **downward only** via:
- `@Prop` for read-only data (tokens, otpMap, timeLeft, accentColor, isMember, etc.)
- `@Link` for two-way bindings (searching, searchQ)
- Callback functions (plain TypeScript function references) for child→parent events

Views never mutate shared state directly; they call callbacks that mutate `@State` on Index.

### State Management (WeChat)

- `app.globalData` holds `tokens`, `theme`, `loggedIn`, `userInfo`, `isMember`, `memberExpiry`
- `index.js` copies from `globalData` into `this.data` on `onLoad()`; mutations write back to both `this.data` (via `setData`) and `app.globalData`
- Components receive data via `properties` and fire events via `triggerEvent`

## Membership Architecture

**Client-side demo only — no payment backend.**

```
User taps "开通会员"
       │
       ▼
Index.buyMembership() / membership.js
  • Sets isMember = true
  • Sets expiry = Date.now() + 1 year
  • Calls saveMember(true, expiry.toISOString())
  • Shows "开通成功（演示）" toast
```

**Feature gating at runtime:**
- `tokens.length >= FREE_TOKEN_LIMIT (5)` blocks add if `!isMember`
- Backup/import modals check `isMember` before showing
- `editSecretVisible` toggle blocked if `!isMember`
- Delete confirmation shows "本地+云端" option only if `isMember`

**Persistence:**
- HarmonyOS: `StorageUtil.saveMember()` → `arcankey_prefs` preferences key `ak_membership`
- WeChat: `app.saveMemberData()` → `wx.setStorageSync('ak_membership', ...)`

## Backup / Sync Architecture

### File-based Backup (HarmonyOS)

```
doBackup():
  encryptData(tokens, password)   ← PBKDF2-XOR in CryptoUtil.ets
       │
       ▼
  fs.writeSync() → tmp file in ctx.filesDir
       │
       ▼
  picker.DocumentViewPicker.save()  ← user picks save location
       │
       ▼
  Copy tmp → user-selected URI, delete tmp
```

Encryption format (ENC2): `[0x45,0x4E,0x43,0x32] + 16-byte random salt + PBKDF2(10000 iters)-XOR(plaintext)`, base64-encoded.

### Cloud Backup Proxy (HarmonyOS)

**Not real cloud.** Uses a second preferences store named `arcankey_cloud` as a local cloud proxy:
```
cloudBackup():  preferences('arcankey_cloud').putSync('tokens_backup', JSON.stringify(tokens))
cloudRestore(): preferences('arcankey_cloud').getSync('tokens_backup') → merge non-duplicate tokens
cloudDelete():  filter token from backup, putSync back
startAutoSync(): setInterval(60 * 60 * 1000) → cloudBackup()
```
Auto-sync starts in `aboutToAppear()` with 500ms delay (after `loadData()`) if `isMember`.

### Cloud Backup (WeChat)

Uses real `wx.cloud.database` collection `user_backups`. Cloud init: `wx.cloud.init({ env: 'cloud1-d6gxlvduza77569eb' })` in `app.js:47`.

## Modal Architecture (HarmonyOS)

All modals are `@Builder` methods on the `Index` struct and rendered directly in `build()` using conditional blocks:

```typescript
// In build():
if (this.editToken.id)    { this.editModal() }      // zIndex 300 — full screen
if (this.showLogin)        { this.loginModal() }     // zIndex 400 — full screen
if (this.showBackup)       { this.backupModal() }    // zIndex 400 — full screen
if (this.showImport)       { this.importModal() }    // zIndex 400 — full screen
if (this.showTheme)        { this.themeModal() }     // zIndex 400 — full screen
if (this.showAccountInfo)  { this.accountInfoModal() } // zIndex 400
if (this.showMembership)   { this.membershipModal() }  // zIndex 400
if (this.showFeedback)     { FeedbackView(...) }     // view as modal
if (this.showDeleteConfirm){ this.deleteConfirmDialog() } // zIndex 999 — centered dialog
```

Modals use `.position({ x: 0, y: 0 }).zIndex(400)` to float over the entire Stack. The delete confirm dialog uses a dark overlay Column with `FlexAlign.Center` to center the dialog card.

## Authentication Architecture

**Client-side demo — no backend verification.**

HarmonyOS login flow:
1. User agrees to privacy checkbox (`privacyAgreed = true`)
2. Taps "鸿蒙账号登录" → sets `loggedIn = true`, `harmonyLogin = true`, `userName = '鸿蒙用户'`
3. No actual HarmonyOS account API call (device account integration is UI-only)

Login gates: QR scan tab requires `loggedIn`; backup/import requires both `loggedIn` and `isMember`.

## Navigation Architecture (HarmonyOS)

The native `Tabs` component is used with `.barWidth(0)` to hide the default tab bar. A custom floating capsule `@Builder bottomNav()` provides actual navigation:

```
Stack (root)
├── Tabs (barWidth: 0, index: currentTab)
│   ├── TabContent → HomeView
│   ├── TabContent → ScanView
│   └── TabContent → ProfileView
├── bottomNav() — position absolute, 90% width, translate animates in/out
└── [modals conditionally rendered]
```

Nav hide/show: `HomeView.onScrollFrameBegin` callback compares scroll delta direction, fires `onNavHide()` / `onNavShow()` callbacks → sets `Index.navVisible` → `.translate({ y: navVisible ? -82 : 0 })` with 300ms animation.

## Error Handling

**Strategy:** Silent catch + toast notification. No error propagation to UI error boundaries.

**Patterns:**
- All async storage operations wrapped in `try/catch`, swallow error silently: `catch (_) {}`
- User-facing errors shown via `toast(msg)` — auto-dismisses after 2200ms
- TOTP computation has a deterministic fallback: if `base32Decode` fails, a hash-based pseudo-TOTP is returned (`TOTP.ets:91-97`) — tokens always show a 6-digit code
- Cloud backup failures are silently ignored (best-effort)

## Cross-Cutting Concerns

**Logging:** HarmonyOS uses `hilog.info/error` in `EntryAbility.ets` only; rest of codebase uses `console.error` in StorageUtil.ets. No structured logging.

**Validation:** Input validation is inline within `ScanView.validate()` and scattered `if (!field)` guards in Index methods.

**Authentication:** Login state is `@State loggedIn: boolean` with no session token or expiry. Logout clears name/phone/avatar only.

## Anti-Patterns

### All Business Logic in Root Component

**What happens:** `Index.ets` is ~1090 lines containing all state, timers, TOTP refresh, cloud sync, all modals, and all event handlers.

**Why it's wrong:** Adding any new feature requires editing this single file; the file will grow indefinitely; testing individual behaviors requires instantiating the entire root component.

**Do this instead:** Extract groups of related methods into service objects or dedicated controller files (e.g., a `BackupService`, `TokenManager`), then call them from Index. See the utility layer pattern already used for TOTP and storage as the correct model.

### Cloud Backup Is Local-Only

**What happens:** `cloudBackup()` / `cloudRestore()` in `Index.ets:309-358` write to a second local preferences store named `arcankey_cloud` rather than any real cloud endpoint.

**Why it's wrong:** Data labelled "云端" is not durable across device resets or device changes.

**Do this instead:** Replace with a real Cloud Kit or network-based sync call when integrating production cloud services.

---

*Architecture analysis: 2026-05-19*
