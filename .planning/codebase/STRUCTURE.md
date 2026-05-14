# Structure

**Last updated:** 2025-05-14

## Directory Layout

```
ArcaneKey/
├── miniprogram/                 # WeChat Mini Program
│   ├── pages/
│   │   ├── index/               # Main single-page app
│   │   │   ├── index.js         # 690 lines (monolithic)
│   │   │   ├── index.wxml       # 454 lines (all views + modals)
│   │   │   └── index.wxss       # Styles
│   │   ├── membership/          # ¥19.90/year purchase
│   │   └── feedback/            # Feedback submission
│   ├── components/              # 6 reusable components
│   │   ├── bottom-nav/          # Navigation bar
│   │   ├── countdown-ring/      # Canvas countdown
│   │   ├── token-card/          # OTP display
│   │   ├── toast/               # Notification
│   │   └── logo/                # Avatar
│   ├── utils/
│   │   ├── totp.js              # TOTP implementation
│   │   ├── crypto.js            # XOR encryption
│   │   └── storage.js           # Storage wrapper
│   ├── cloudfunctions/
│   │   ├── login/
│   │   └── sendFeedback/
│   ├── app.js                   # Global state + constants
│   ├── app.json                 # Config
│   └── app.wxss                 # Global styles
│
├── harmonyos/                   # HarmonyOS App
│   ├── entry/src/main/ets/
│   │   ├── pages/
│   │   │   └── Index.ets        # Entry page + all modals
│   │   ├── views/               # 4 sub-views
│   │   ├── components/          # 3 components
│   │   ├── utils/               # 3 utilities
│   │   ├── model/
│   │   │   └── Token.ets        # Types + constants
│   │   └── entryability/
│   │   ├── module.json5
│   │   └── oh-package.json5
│
├── docs/
│   └── plans/                   # Planning documents (5 files)
│       ├── 2026-04-26-authenticator-apps.md
│       ├── 2026-04-28-bug-fixes-and-enhancements.md
│       ├── 2026-04-28-ui-fixes-and-features.md
│       ├── 2026-04-29-bug-fixes.md
│       ├── 2026-04-30-membership-and-feedback.md
│
├── .planning/                   # GSD planning (new)
│   └── codebase/                # Codebase maps (this folder)
│
├── CLAUDE.md                    # Project instructions
└── .gitignore                   # (missing, should exist)
```

---

## Key Locations

| What | WeChat Path | HarmonyOS Path |
|------|-------------|----------------|
| TOTP logic | `miniprogram/utils/totp.js` | `harmonyos/.../TOTP.ets` |
| Constants | `miniprogram/app.js` | `harmonyos/.../Token.ets` |
| Main state | `miniprogram/pages/index/index.js` | `harmonyos/.../Index.ets` |
| Navigation | `miniprogram/components/bottom-nav/` | Inline in Index.ets |
| Countdown | `miniprogram/components/countdown-ring/` | `harmonyos/.../CountdownRing.ets` |
| Storage | `miniprogram/utils/storage.js` | `harmonyos/.../StorageUtil.ets` |
| Encryption | `miniprogram/utils/crypto.js` | `harmonyos/.../CryptoUtil.ets` |
| Membership | `miniprogram/pages/membership/` | Inline in Index.ets modal |
| Feedback | `miniprogram/pages/feedback/` | `harmonyos/.../FeedbackView.ets` |
| Cloud env ID | `miniprogram/app.js:44` | N/A |

---

## Naming Conventions

| Platform | Style | Example |
|----------|-------|---------|
| WeChat JS | camelCase | `onCopyTap`, `_updateOtpMap` |
| WeChat WXML | kebab-case | `token-card`, `countdown-ring` |
| WeChat CSS | kebab-case | `.card-bottom`, `.otp-digit` |
| HarmonyOS | PascalCase | `TokenCard`, `CountdownRing`, `HomeView` |

---

## File Sizes

| File | Lines | Notes |
|------|-------|-------|
| `index.js` | 690 | Monolithic — all logic |
| `index.wxml` | 454 | All views + modals inline |
| `totp.js` | 105 | Pure JS implementation |
| `Index.ets` | ~600 | HarmonyOS entry + modals |

---

## Missing Files

- `.gitignore` — Should exclude `.DS_Store`, IDE configs
- `README.md` — No documentation
- Tests — No test files in either platform
- CI/CD — No automation