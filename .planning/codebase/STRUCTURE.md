# Codebase Structure

**Analysis Date:** 2026-05-19

## Directory Layout

```
ArcaneKey/
├── miniprogram/                    # WeChat Mini Program
│   ├── app.js                      # App entry, globalData, cloud init
│   ├── app.json                    # Page routes, window config, cloud enabled
│   ├── app.wxss                    # Global styles
│   ├── pages/
│   │   ├── index/                  # Main page (only real page)
│   │   │   ├── index.js            # All page logic and state (~800+ lines)
│   │   │   ├── index.wxml          # Conditional view template
│   │   │   ├── index.wxss          # Page styles
│   │   │   └── index.json          # Page config (components registered)
│   │   ├── membership/             # Membership purchase page
│   │   │   ├── membership.js
│   │   │   ├── membership.wxml
│   │   │   └── membership.wxss
│   │   └── feedback/               # Feedback page
│   │       ├── feedback.js
│   │       ├── feedback.wxml
│   │       └── feedback.wxss
│   ├── components/
│   │   ├── bottom-nav/             # Floating capsule navigation bar
│   │   ├── countdown-ring/         # Circular countdown drawn on canvas
│   │   ├── logo/                   # Brand letter-avatar component
│   │   ├── toast/                  # Toast notification overlay
│   │   └── token-card/             # Single TOTP token card
│   ├── utils/
│   │   ├── totp.js                 # Pure HMAC-SHA1 TOTP (no SubtleCrypto)
│   │   ├── storage.js              # wx.getStorageSync/setStorageSync wrappers
│   │   └── crypto.js               # XOR encrypt/decrypt for backup
│   └── cloudfunctions/
│       ├── login/
│       │   └── index.js            # Login cloud function (stub)
│       └── sendFeedback/
│           └── index.js            # Feedback email via nodemailer
│
├── harmonyos/                      # HarmonyOS ArkTS App
│   ├── AppScope/
│   │   ├── app.json5               # App-level config (bundle name, version)
│   │   └── resources/base/         # App-level resources (icon, strings)
│   ├── entry/
│   │   ├── build-profile.json5     # Build configuration
│   │   ├── oh-package.json5        # Package manifest + dependencies
│   │   └── src/main/
│   │       ├── module.json5        # Module config, abilities, permissions
│   │       ├── resources/base/     # Module resources (colors, strings, media)
│   │       └── ets/
│   │           ├── entryability/
│   │           │   └── EntryAbility.ets  # UIAbility; loads pages/Index, immersive window
│   │           ├── pages/
│   │           │   └── Index.ets   # @Entry root component — ALL state and modals
│   │           ├── views/
│   │           │   ├── HomeView.ets       # Token list + search bar
│   │           │   ├── ScanView.ets       # QR scan (camera/album/manual)
│   │           │   ├── ProfileView.ets    # Settings menu + account display
│   │           │   └── FeedbackView.ets   # Feedback form (mailto: intent)
│   │           ├── components/
│   │           │   ├── TokenCard.ets      # Single token card with OTP gradient
│   │           │   ├── CountdownRing.ets  # Circular progress ring
│   │           │   └── Logo.ets           # Brand letter-avatar
│   │           ├── model/
│   │           │   └── Token.ets          # Types + all cross-platform constants
│   │           └── utils/
│   │               ├── TOTP.ets           # HMAC-SHA1 + base32 TOTP algorithm
│   │               ├── StorageUtil.ets    # ArkData preferences async wrappers
│   │               └── CryptoUtil.ets     # PBKDF2-XOR file backup encryption
│   └── oh_modules/                 # Package dependencies (do not edit)
│
├── .planning/                      # GSD planning artifacts
│   ├── codebase/                   # Codebase map documents
│   ├── phases/                     # Phase plan documents
│   └── debug/                      # Debug investigation notes
├── docs/
│   └── plans/                      # Historical planning documents
└── CLAUDE.md                       # Project instructions for Claude
```

## Directory Purposes

**`harmonyos/entry/src/main/ets/pages/`:**
- Purpose: ArkTS page entry points. Only one file: `Index.ets`.
- Contains: The `@Entry @Component struct Index` — the root of the entire app UI tree
- Key files: `Index.ets` (1090 lines — owns all state, timers, modals, business logic)
- Note: New pages would go here if the app ever gains a second route; currently intentionally single-page

**`harmonyos/entry/src/main/ets/views/`:**
- Purpose: Full-screen tab content panels. These are `@Component` structs, NOT pages — they cannot be navigated to independently.
- Contains: `HomeView`, `ScanView`, `ProfileView`, `FeedbackView`
- All receive data via `@Prop` and callbacks; they own no shared state
- Note: `FeedbackView` is used both as a tab view and as a modal overlay in Profile

**`harmonyos/entry/src/main/ets/components/`:**
- Purpose: Reusable UI widgets, used within views
- Contains: `TokenCard`, `CountdownRing`, `Logo`
- All are `@Component` structs with `@Prop` inputs and callback functions; no internal shared state

**`harmonyos/entry/src/main/ets/model/`:**
- Purpose: Shared data types and constants — the single source of truth for HarmonyOS
- Contains: `Token.ets` with all interfaces (`Token`, `OtpPair`, `ThemeItem`) and exported constants
- Key files: `Token.ets` — must be kept in sync with `miniprogram/app.js`

**`harmonyos/entry/src/main/ets/utils/`:**
- Purpose: Pure logic and platform-API adapters with no UI dependencies
- Contains: TOTP algorithm, storage I/O, encryption
- `StorageUtil.ets` exports async functions; `CryptoUtil.ets` exports sync `encryptData`/`decryptData`

**`harmonyos/entry/src/main/ets/entryability/`:**
- Purpose: HarmonyOS UIAbility lifecycle — app startup, window configuration
- Contains: `EntryAbility.ets` — loads `pages/Index`, calls `setWindowLayoutFullScreen(true)` and `setWindowBackgroundColor('#00000000')` for immersive edge-to-edge display

**`miniprogram/pages/index/`:**
- Purpose: The only real WeChat page — contains all app screens as conditional blocks
- `index.wxml`: Template with `wx:if="{{screen === 'home'}}"` blocks for home/scan/profile/modals
- `index.js`: Mirror of HarmonyOS Index logic; `screen` string drives view selection (`'home'`, `'scan'`, `'profile'`)

**`miniprogram/components/`:**
- Purpose: WeChat custom components (each has `.js`, `.json`, `.wxml`, `.wxss`)
- Direct functional equivalents of HarmonyOS `components/`
- `bottom-nav`: fires `navigate` custom event with `{screen}` detail to `index.js`
- `countdown-ring`: uses `canvas` API (SVG failed; canvas used instead)

**`miniprogram/utils/`:**
- Purpose: Pure utility functions — algorithm equivalents of HarmonyOS utils
- `totp.js`: Identical algorithm to `TOTP.ets`; exports `totp`, `timeLeft`, `fmtCode`
- `crypto.js`: XOR-only (no PBKDF2); older encryption format than HarmonyOS `CryptoUtil.ets`
- `storage.js`: Thin wrappers over `wx.getStorageSync` / `wx.setStorageSync`

**`miniprogram/cloudfunctions/`:**
- Purpose: WeChat Cloud Functions deployed server-side
- `sendFeedback/index.js`: Uses nodemailer to email `mengyuefeitian@gmail.com`
- `login/index.js`: Login cloud function (stub)

## Key File Locations

**Entry Points:**
- `harmonyos/entry/src/main/ets/entryability/EntryAbility.ets`: HarmonyOS ability; loads `pages/Index`
- `harmonyos/entry/src/main/ets/pages/Index.ets`: HarmonyOS root component
- `miniprogram/app.js`: WeChat App() entry; initializes globalData and cloud
- `miniprogram/pages/index/index.js`: WeChat Page() entry; all page logic

**Configuration:**
- `harmonyos/entry/src/main/module.json5`: Module abilities, permissions (`ohos.permission.SYSTEM_FLOAT_WINDOW`)
- `harmonyos/AppScope/app.json5`: Bundle ID (`com.example.authenticator`), app version
- `miniprogram/app.json`: WeChat page routes, `window` settings, cloud enabled
- `miniprogram/project.config.json`: AppID, cloud environment ID

**Cross-Platform Constants (duplicated — keep in sync):**
- `harmonyos/entry/src/main/ets/model/Token.ets` — `THEMES`, `INITIAL_TOKENS`, `FREE_TOKEN_LIMIT`, `MEMBERSHIP_PRICE`, `APP_NAME`
- `miniprogram/app.js` — same constants defined at top of file

**Core Logic:**
- `harmonyos/entry/src/main/ets/utils/TOTP.ets`: TOTP algorithm
- `harmonyos/entry/src/main/ets/utils/StorageUtil.ets`: Persistence layer
- `harmonyos/entry/src/main/ets/utils/CryptoUtil.ets`: File backup encryption (PBKDF2 + XOR, format `ENC2`)
- `miniprogram/utils/totp.js`: Equivalent TOTP algorithm for WeChat

## Naming Conventions

**Files (HarmonyOS):**
- PascalCase for all `.ets` files: `TokenCard.ets`, `HomeView.ets`, `StorageUtil.ets`
- Views end with `View`, components are standalone names

**Files (WeChat):**
- kebab-case for component directories and their files: `bottom-nav/bottom-nav.js`
- camelCase for utility files: `totp.js`, `crypto.js`, `storage.js`

**Symbols (HarmonyOS):**
- Event callbacks: `onXxx` prefix (e.g., `onEdit`, `onCopy`, `onNavHide`)
- Private methods: no prefix convention — `refreshOtp`, `cloudBackup`, `doLogin`
- State variables: camelCase (e.g., `otpMap`, `accentColor`, `showBackup`)
- Builder methods: descriptive lowercase (e.g., `editModal()`, `bottomNav()`)

**Symbols (WeChat):**
- Event handlers: `onXxx` for wxml event bindings (e.g., `onNavigate`, `onCopyOtp`)
- Internal methods: `_xxx` underscore prefix (e.g., `_updateOtpMap`, `_filterTokens`, `_cloudRestore`)
- WXML classes: kebab-case (`.card-bottom`, `.otp-digit`)

## Component Hierarchy

### HarmonyOS

```
EntryAbility
└── Index (@Entry @Component)
    ├── Tabs
    │   ├── TabContent → HomeView (@Component)
    │   │   └── List
    │   │       └── TokenCard (@Component) × N
    │   │           ├── Logo (@Component)
    │   │           └── CountdownRing (@Component)
    │   ├── TabContent → ScanView (@Component)
    │   │   └── Logo (@Component)
    │   └── TabContent → ProfileView (@Component)
    ├── @Builder bottomNav()              ← custom floating nav
    ├── @Builder editModal()              ← conditionally rendered
    ├── @Builder loginModal()             ← conditionally rendered
    ├── @Builder backupModal()            ← conditionally rendered
    ├── @Builder importModal()            ← conditionally rendered
    ├── @Builder themeModal()             ← conditionally rendered
    ├── @Builder membershipModal()        ← conditionally rendered
    ├── @Builder accountInfoModal()       ← conditionally rendered
    ├── @Builder deleteConfirmDialog()    ← conditionally rendered
    ├── FeedbackView (as modal)           ← conditionally rendered
    └── @Builder toastView()              ← conditionally rendered
```

### WeChat Mini Program

```
App (app.js — globalData)
└── Page: index (index.js + index.wxml)
    ├── [screen==='home'] → home block
    │   └── token-card component × N
    │       └── countdown-ring component
    │       └── logo component
    ├── [screen==='scan'] → scan block
    ├── [screen==='profile'] → profile block
    ├── bottom-nav component
    ├── toast component
    └── [modal conditionals] → overlay blocks
```

## Cross-Platform Shared Constants

These values are **hardcoded duplicates** in both codebases. When changing any, update both files:

| Constant | Value | HarmonyOS | WeChat |
|----------|-------|-----------|--------|
| `THEMES` | 10 color objects | `model/Token.ets:18` | `app.js:16` |
| `INITIAL_TOKENS` | 6 demo tokens | `model/Token.ets:40` | `app.js:7` |
| `FREE_TOKEN_LIMIT` | `5` | `model/Token.ets:49` | `app.js:3` |
| `MEMBERSHIP_PRICE` | `19.90` | `model/Token.ets:50` | `app.js:4` |
| `APP_NAME` | `'玄钥'` | `model/Token.ets:51` | `app.js:5` |
| Cloud env ID | `'cloud1-...'` | N/A | `app.js:47` |

`BRAND_COLORS` is currently only in `harmonyos/entry/src/main/ets/model/Token.ets:31` — the WeChat `logo` component uses a similar hardcoded map inline.

## Where to Add New Code

**New view/screen (HarmonyOS):**
- Create `harmonyos/entry/src/main/ets/views/NewView.ets` as `@Component export struct NewView`
- Add a new `TabContent` in `Index.ets:build()` inside the `Tabs` block
- Add corresponding tab icon case in `Index.tabIcon()` builder
- Add new tab button in `Index.bottomNav()` builder

**New modal (HarmonyOS):**
- Add `@State showNewModal: boolean = false` to `Index`
- Add `@Builder newModal()` method to `Index`
- Add `if (this.showNewModal) { this.newModal() }` in `Index.build()` after existing modal conditionals
- Use `zIndex(400)` and `.position({ x: 0, y: 0 })` on the root Column

**New reusable component (HarmonyOS):**
- Create `harmonyos/entry/src/main/ets/components/NewComponent.ets`
- Use `@Prop` for all inputs; use callback function properties for events (no `@Link` unless bidirectional state is truly needed)

**New utility (HarmonyOS):**
- Create `harmonyos/entry/src/main/ets/utils/NewUtil.ets`
- Export only pure functions; avoid importing from views or pages

**New constant or type:**
- Add to `harmonyos/entry/src/main/ets/model/Token.ets` and mirror in `miniprogram/app.js` if cross-platform

**New WeChat page (separate page, not screen):**
- Create directory `miniprogram/pages/newpage/` with `.js`, `.json`, `.wxml`, `.wxss`
- Register in `miniprogram/app.json` under `"pages"` array

**New WeChat component:**
- Create directory `miniprogram/components/new-component/` with four files
- Register in the consuming page's `.json` under `"usingComponents"`

## Special Directories

**`harmonyos/oh_modules/`:**
- Purpose: HarmonyOS package dependencies (equivalent of `node_modules`)
- Generated: Yes (by ohpm)
- Committed: No (large; should be in `.gitignore`)

**`harmonyos/.hvigor/`:**
- Purpose: Hvigor build system cache and output logs
- Generated: Yes
- Committed: No

**`harmonyos/entry/build/`:**
- Purpose: Compiled build artifacts
- Generated: Yes
- Committed: No

**`.planning/`:**
- Purpose: GSD workflow artifacts — codebase maps, phase plans, debug notes
- Generated: Yes (by GSD commands)
- Committed: Yes

---

*Structure analysis: 2026-05-19*
