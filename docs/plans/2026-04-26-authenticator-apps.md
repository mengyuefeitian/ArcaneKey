# Authenticator App Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Build a feature-complete TOTP Authenticator as both a WeChat Mini Program and a HarmonyOS App, faithfully replicating the UI/UX of the existing `app.jsx` prototype.

**Architecture:**
- **WeChat Mini Program** — single-page architecture (`pages/index`), all screens (Home/Scan/Profile) as conditional views within one page, custom components for reusable UI, pure-JS HMAC-SHA1 for TOTP, wx.storage for persistence.
- **HarmonyOS App** — ArkTS `Tabs` component for three-tab navigation, pure-TS HMAC-SHA1 for TOTP, `@ohos.data.preferences` for persistence.
- Both share identical product logic: 30s rotating codes, XOR-encrypted backup files (`.atbk`), 10 accent themes, login-gated backup/import.

**Tech Stack:**
- WeChat: WXML / WXSS / JS (ES6+), wx.* APIs
- HarmonyOS: ArkTS 4.x, `@ohos.data.preferences`, `@ohos.pasteboard`, `@kit.ScanKit`

**Color palette (hex, for environments without oklch support):**
```
海洋蓝 #4080D0 | 皇室紫 #9060D0 | 玫瑰粉 #D04080 | 热情红 #D04040
暖橙色 #D07030 | 琥珀金 #C09030 | 森林绿 #30A060 | 青绿色 #2090A0
天空蓝 #3080C0 | 深靛蓝 #6050C8
```

**Brand colors:**
```js
Google:#EA4335  Microsoft:#00A4EF  GitHub:#e6edf3  Apple:#aaaaaa
Twitter:#1DA1F2  Dropbox:#0061FF  Facebook:#1877F2  Amazon:#FF9900
Slack:#4A154B  Discord:#5865F2  Notion:#ffffff  Stripe:#635BFF
Figma:#F24E1E  LinkedIn:#0A66C2  Steam:#c6d4df  Netflix:#E50914
Spotify:#1DB954
```

---

## Phase 1 — WeChat Mini Program

### Task 1: Project scaffolding & global config

**Files:**
- Create: `miniprogram/project.config.json`
- Create: `miniprogram/app.json`
- Create: `miniprogram/app.js`
- Create: `miniprogram/app.wxss`

**app.json** — single page `pages/index/index`, no native tabBar, dark background.

**app.js** — `globalData`: tokens (INITIAL_TOKENS), theme, loggedIn, userInfo.

---

### Task 2: TOTP utility (`utils/totp.js`)

**File:** `miniprogram/utils/totp.js`

Pure-JS SHA-1 + HMAC-SHA1 (no SubtleCrypto dependency).
Exports: `base32Decode(s)`, `hmacSha1(key, data)`, `totp(secret, offset=0)`, `timeLeft()`, `fmtCode(s)`.

TOTP algorithm:
1. base32-decode secret → Uint8Array key
2. t = floor(Date.now()/30000) + offset
3. 8-byte big-endian counter (high 4 bytes = 0, low 4 bytes = t)
4. HMAC-SHA1(key, counter)
5. dynamic truncation → 6-digit code

---

### Task 3: Storage & Crypto utilities

**Files:**
- Create: `miniprogram/utils/storage.js` — `loadTokens()`, `saveTokens(tokens)`, `loadTheme()`, `saveTheme(theme)`
- Create: `miniprogram/utils/crypto.js` — `encryptData(data, pass)`, `decryptData(enc, pass)` (XOR + btoa/atob)

---

### Task 4: Logo component

**Files:** `miniprogram/components/logo/logo.{json,js,wxml,wxss}`

Properties: `brand` (String), `size` (Number, default 40).
Renders a rounded square with brand initial letter, colored by brand color map.

---

### Task 5: CountdownRing component

**Files:** `miniprogram/components/countdown-ring/countdown-ring.{json,js,wxml,wxss}`

Properties: `timeLeft` (Number), `accentColor` (String).
SVG circle with stroke-dasharray countdown. Turns amber when timeLeft ≤ 7.

---

### Task 6: TokenCard component

**Files:** `miniprogram/components/token-card/token-card.{json,js,wxml,wxss}`

Properties: `token` (Object), `otp` (Object {current,next}), `timeLeft` (Number), `accentColor` (String).
Events: `edit` (tap upper row), `copy` (tap lower row).

---

### Task 7: BottomNav component

**Files:** `miniprogram/components/bottom-nav/bottom-nav.{json,js,wxml,wxss}`

Properties: `current` (String), `visible` (Boolean), `accentColor` (String).
Event: `navigate` with detail `{screen}`.
Slide-down animation when `visible` changes (CSS transform).

---

### Task 8: Toast component

**Files:** `miniprogram/components/toast/toast.{json,js,wxml,wxss}`

Properties: `message` (String, '' = hidden).
Centered bottom toast that auto-disappears after 2.2s (parent controls visibility).

---

### Task 9: Main page — Home view

**Files:** `miniprogram/pages/index/index.{json,js,wxml,wxss}` (initial, Home section)

- Header: title "验证码" + search button; switches to search bar mode
- Scroll-view with `bindscroll` → auto-hide/show BottomNav
- Renders filtered TokenCard list
- onLoad: load tokens from storage, start 1s TOTP timer

---

### Task 10: Main page — Scan view

**Modifies:** `pages/index/index.{js,wxml,wxss}`

Three tabs: 扫二维码 / 选相册 / 手动输入.
- Camera tab: `wx.scanCode()` on button tap, parses `otpauth://` URI
- Album tab: `wx.chooseImage()` + `wx.scanCode({onlyFromCamera:false})` 
- Manual tab: form with brand/account/secret fields + logo preview, validates before `addToken()`

---

### Task 11: Main page — Profile view + all Modals

**Modifies:** `pages/index/index.{js,wxml,wxss}`

Profile: avatar, login button / user info, menu items (backup/import/theme).
- **LoginModal**: phone (send-code countdown) + WeChat tabs
- **BackupModal**: password + confirm, `encryptData()`, `wx.saveFile()` or file system write, then share
- **ImportModal**: `wx.chooseMessageFile()`, `decryptData()`, merge tokens
- **EditModal**: edit brand/account, delete with confirm
- **ThemePickerModal**: 5×2 grid of color swatches

---

## Phase 2 — HarmonyOS App

### Task 12: Project scaffolding

**Files:**
- `harmonyos/AppScope/app.json5`
- `harmonyos/AppScope/resources/base/element/string.json`
- `harmonyos/entry/src/main/module.json5`
- `harmonyos/entry/src/main/ets/entryability/EntryAbility.ets`
- `harmonyos/entry/src/main/resources/base/profile/main_pages.json`
- `harmonyos/entry/src/main/resources/base/element/string.json`
- `harmonyos/entry/src/main/resources/base/element/color.json`
- `harmonyos/build-profile.json5`
- `harmonyos/oh-package.json5`
- `harmonyos/entry/oh-package.json5`
- `harmonyos/entry/build-profile.json5`
- `harmonyos/hvigorfile.ts`
- `harmonyos/entry/hvigorfile.ts`

---

### Task 13: Model + TOTP + utils

**Files:**
- `harmonyos/entry/src/main/ets/model/Token.ets` — `Token` interface + `INITIAL_TOKENS` + `THEMES` + `BRAND_COLORS`
- `harmonyos/entry/src/main/ets/utils/TOTP.ets` — pure-TS HMAC-SHA1, same algorithm as WeChat version
- `harmonyos/entry/src/main/ets/utils/StorageUtil.ets` — preferences-based load/save
- `harmonyos/entry/src/main/ets/utils/CryptoUtil.ets` — XOR encrypt/decrypt

---

### Task 14: Logo + CountdownRing components

**Files:**
- `harmonyos/entry/src/main/ets/components/Logo.ets` — `@Component struct Logo`, `@Prop brand: string`, `@Prop size: number`
- `harmonyos/entry/src/main/ets/components/CountdownRing.ets` — Canvas-based SVG ring, `@Prop timeLeft: number`, `@Prop accentColor: string`

---

### Task 15: TokenCard component

**File:** `harmonyos/entry/src/main/ets/components/TokenCard.ets`

`@Component struct TokenCard` with `@Prop token`, `@Prop otp`, `@Prop timeLeft`, `@Prop accentColor`.
`onEdit` and `onCopy` callbacks via `@BuilderParam` or function props.

---

### Task 16: HomeView

**File:** `harmonyos/entry/src/main/ets/views/HomeView.ets`

`@Component struct HomeView`:
- `@Link tokens`, `@Link otpMap`, `@State timeLeft`, `@State searchQ`, `@State searching`
- `List` with `ListItem` → `TokenCard`, scroll detection for nav visibility
- Search bar toggle

---

### Task 17: ScanView

**File:** `harmonyos/entry/src/main/ets/views/ScanView.ets`

Three tabs (Tabs component): Camera (scanCode via `@kit.ScanKit`), Album (chooseImage + scan), Manual form.

---

### Task 18: ProfileView + all modals

**File:** `harmonyos/entry/src/main/ets/views/ProfileView.ets`

Avatar, login/logout, menu (backup/import/theme).
Inline modal dialogs using `@CustomDialog` or conditional `if()` blocks.
- Login: phone verification + WeChat placeholders
- Backup: password input → `CryptoUtil.encrypt()` → write file → share
- Import: pick file → `CryptoUtil.decrypt()` → merge tokens
- Theme: 5×2 grid color picker

---

### Task 19: Main Index page (Tabs navigation)

**File:** `harmonyos/entry/src/main/ets/pages/Index.ets`

Root `@Entry @Component struct Index`:
- `@State` for all shared state (tokens, otpMap, timeLeft, theme, loggedIn, userInfo, navVisible)
- `aboutToAppear()`: load from storage, start 1s `setInterval` TOTP timer
- `aboutToDisappear()`: clear interval
- Custom bottom tab bar that slides off-screen on scroll (transforms via `@State navVisible`)
- `Tabs({ barPosition: BarPosition.End })` with `TabContent` for Home/Scan/Profile

---
