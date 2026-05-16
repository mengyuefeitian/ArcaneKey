# Testing

**Last updated:** 2025-05-14

## Current State: No Tests

Neither platform has automated tests:

- **WeChat Mini Program:** No test framework, no test files
- **HarmonyOS:** `@ohos/hypium` dependency present but no test files

---

## Testing Approach

Both platforms rely on:

1. **WeChat DevTools:** Manual testing in simulator and real device
2. **DevEco Studio:** Manual testing in emulator and real device
3. **Planning docs:** Bug tracking in `docs/plans/*.md`

---

## Known Test Scenarios (Manual)

| Scenario | Expected | Current Status |
|----------|----------|----------------|
| Add token via QR | Direct add | Working |
| Add token manually | Form validation | Working |
| Copy OTP | Clipboard success | **FAILING** (errno 112) |
| Countdown ring | Visible circle | Working (Canvas) |
| Theme change | Color update | Working |
| Login | User info saved | **FAILING** (errno 112) |
| Membership purchase | Status saved | Demo mode |
| Backup (member) | Cloud sync | Not tested |
| Import (member) | Decrypt restore | Not tested |
| Feedback submit | Email sent | Working |
| Upload images | Cloud upload | **FAILING** (errno 112) |

---

## Platform-Specific Debugging

### WeChat

- `console.log()` in DevTools console
- `wx.showToast()` for visual feedback
- Real device debugging via DevTools

### HarmonyOS

- DevEco Studio debugger
- HiLog for logging
- Real device testing

---

## Recommended Test Frameworks

| Platform | Recommended Framework |
|----------|-----------------------|
| WeChat | miniprogram-simulate (component tests) |
| HarmonyOS | @ohos/hypium (already installed) |

---

## Testing Coverage Gaps

Critical areas lacking tests:

1. **TOTP generation correctness** — No verification against RFC 6238
2. **XOR encryption** — No unit tests for encrypt/decrypt
3. **State persistence** — No storage tests
4. **Timer synchronization** — No tests for 30s cycle
5. **Cloud operations** — No integration tests
6. **UI interactions** — No component tests

---

## Regression History

From `docs/plans/*.md`:

- Countdown ring: Failed 6+ times with SVG, fixed with Canvas
- Copy functionality: Repeated failures due to privacy agreement
- Login: Multiple iterations, still blocked by errno 112
- Search icon: Size complaints, multiple font-size adjustments