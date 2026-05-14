# Concerns

**Last updated:** 2025-05-14

## Privacy Agreement Issues (errno 112)

**Severity:** HIGH — Blocks core functionality

| API | Error | Impact |
|-----|-------|--------|
| `wx.setClipboardData` | errno 112 | Cannot copy OTP codes |
| `wx.chooseMedia` | errno 112 | Cannot upload feedback images |
| `getPhoneNumber` | errno 112 | Cannot complete login |

**Root Cause:** Mini program not submitted for review → Privacy agreement not available in backend

**Resolution Path:**
1. Submit mini program for review
2. After approval: Configure privacy in 微信小程序后台 → 设置 → 基本设置 → 服务内容声明 → 用户隐私保护指引
3. Declare: Clipboard write, Album access, Phone number

---

## Security Concerns

### XOR Encryption

- **Issue:** Backup uses XOR, not AES
- **Impact:** Demo-level encryption only
- **Recommendation:** For production, implement AES-256

### Hardcoded Secrets

- **Issue:** Cloud environment ID in source code
- **Location:** `miniprogram/app.js:44`
- **Impact:** Acceptable for demo, should use env vars in production

### Demo Tokens

- **Issue:** `INITIAL_TOKENS` contains demo secrets
- **Impact:** Hardcoded test data visible in source
- **Recommendation:** Remove or use placeholder values

---

## Technical Debt

### Monolithic Files

| File | Lines | Issue |
|------|-------|-------|
| `index.js` | 690 | All page logic in one file |
| `index.wxml` | 454 | All views + modals inline |
| `Index.ets` | ~600 | Entry + all modals in one file |

**Impact:** Hard to maintain, hard to test

**Recommendation:** Split into:
- Separate modal components
- Extract business logic to services

### Code Duplication

- **Issue:** `THEMES`, `INITIAL_TOKENS`, constants duplicated across platforms
- **Impact:** Maintenance burden, sync errors possible
- **Recommendation:** Create shared config file if multi-platform build system added

### Missing Infrastructure

- **Missing:** `.gitignore`, `README.md`, tests, CI/CD, linter, formatter
- **Impact:** Code quality uncontrolled, onboarding difficult

---

## Performance Concerns

### Timer Efficiency

- **Current:** `setInterval(1000ms)` always running
- **Alternative:** Could pause when app backgrounded
- **Impact:** Minor battery drain

### Canvas Rendering

- **Issue:** Countdown ring redraws every second
- **Alternative:** Could use CSS animation with `@keyframes`
- **Impact:** Acceptable for 34px canvas

---

## Fragile Areas

### Canvas Countdown Ring

- **History:** Failed 6+ times with SVG before Canvas worked
- **Risk:** Canvas may have platform-specific issues
- **Location:** `miniprogram/components/countdown-ring/`

### Login Flow

- **History:** Multiple redesigns
- **Current:** Blocked by privacy agreement
- **Risk:** Further changes may break existing demo users

### Cloud Functions

- **Risk:** `sendFeedback` depends on nodemailer
- **Location:** `miniprogram/cloudfunctions/sendFeedback/index.js`
- **Issue:** No error handling for email failures

---

## Platform Compatibility

| Concern | Platform | Notes |
|---------|----------|-------|
| WeChat version compatibility | WeChat | Older clients may lack APIs |
| HarmonyOS version | HarmonyOS | API 23 (6.1) minimum |
| Different screen sizes | Both | Not explicitly handled |

---

## Missing Documentation

- No API documentation for TOTP implementation
- No user guide
- No deployment guide
- Planning docs in `docs/plans/` but outdated (last updated April 30)