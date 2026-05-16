# Architecture

**Last updated:** 2025-05-14

## Pattern: Single-Page Conditional Rendering

Both platforms use the same architectural pattern: **one entry page with conditional view rendering** instead of traditional multi-page routing.

```
┌─────────────────────────────────────────────┐
│  Entry Page (Index)                         │
│  ┌─────────────────────────────────────────┐│
│  │ State: screen = 'home' | 'scan' | ...   ││
│  ├─────────────────────────────────────────┤│
│  │ Conditional Render:                     ││
│  │  if screen == 'home': HomeView          ││
│  │  if screen == 'scan':  ScanView         ││
│  │  if screen == 'profile': ProfileView    ││
│  └─────────────────────────────────────────┘│
│  Bottom Navigation (always visible)         │
│  Modals (inline, triggered by state)        │
└─────────────────────────────────────────────┘
```

---

## WeChat Mini Program Structure

```
miniprogram/
├── app.js                 # Global state + constants + cloud init
├── app.json               # Page routes (3 pages)
├── app.wxss               # Global styles
├── pages/
│   ├── index/             # Main entry (single-page app)
│   │   ├── index.js       # All state, timers, handlers
│   │   ├── index.wxml     # Conditional views + all modals inline
│   │   └── index.wxss     # All styles
│   ├── membership/        # Membership purchase page
│   └── feedback/          # Feedback page
├── components/            # Reusable UI components
│   ├── bottom-nav/        # Floating navigation bar
│   ├── countdown-ring/    # Canvas-based countdown circle
│   ├── token-card/        # OTP display card
│   ├── toast/             # Toast notification
│   └── logo/              # Brand letter-avatar
├── utils/
│   ├── totp.js            # Pure JS HMAC-SHA1 TOTP
│   ├── crypto.js          # XOR encrypt/decrypt
│   └── storage.js         # wx.getStorageSync wrapper
└── cloudfunctions/
    ├── login/             # Login cloud function
    └── sendFeedback/      # Email cloud function
```

### Data Flow

```
app.globalData.tokens
       ↓
index.js: this.data.tokens
       ↓
_updateOtpMap() → otpMap[id] = { current, next }
       ↓
index.wxml: token-card otp="{{otpMap[item.id]}}"
       ↓
token-card: display + copy
```

### Timer Architecture

- `setInterval(1000ms)` updates `timeLeft` in `index.js`
- When `timeLeft === 30`: regenerate all OTP codes
- Countdown-ring component receives `timeLeft` as prop

---

## HarmonyOS Structure

```
harmonyos/entry/src/main/
├── ets/
│   ├── pages/
│   │   └── Index.ets      # Entry page: all @State + all modals inline
│   ├── views/             # Sub-views (not pages)
│   │   ├── HomeView.ets
│   │   ├── ScanView.ets
│   │   ├── ProfileView.ets
│   │   └── FeedbackView.ets
│   ├── components/
│   │   ├── Logo.ets
│   │   ├── CountdownRing.ets
│   │   ├── TokenCard.ets
│   ├── utils/
│   │   ├── TOTP.ets       # Pure ArkTS HMAC-SHA1
│   │   ├── StorageUtil.ets # Preferences wrapper
│   │   ├── CryptoUtil.ets  # XOR encrypt/decrypt
│   ├── model/
│   │   └── Token.ets      # Interfaces + constants
│   └── entryability/
│   │   └── EntryAbility.ets # Immersive window config
└── module.json5           # Abilities + permissions
```

### Key Differences from WeChat

- Views are `@Component` structs, not pages
- Modals are `@Builder` functions in Index.ets
- Navigation: custom floating capsule (not native)
- State: ArkTS `@State` reactive system

---

## Membership Architecture

```
┌──────────────────┐
│ Free User        │
│ • Max 5 tokens   │
│ • No cloud sync  │
│ • Secret hidden  │
└──────────────────┘
        ↓ Payment
┌──────────────────┐
│ Member           │
│ • Unlimited      │
│ • Cloud backup   │
│ • Secret visible │
│ • Auto-sync      │
└──────────────────┘
```

State stored in:
- WeChat: `wx.getStorageSync('ak_membership')`
- HarmonyOS: Preferences `ak_membership`

---

## Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| Single-page app | Simpler state management, no router complexity |
| No shared code | Platform APIs are incompatible, duplication acceptable |
| XOR encryption | Demo-level simplicity, not production security |
| Canvas countdown | SVG unreliable in WeChat (failed 6 times) |
| Inline modals | WeChat modal API limitations |