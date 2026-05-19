# Testing Patterns

**Analysis Date:** 2026-05-19

## Current Test Coverage

**Zero.** There are no test files anywhere in the project source. Neither the WeChat Mini Program nor the HarmonyOS app has any written tests. No test runner is configured or runnable.

Confirmed by filesystem search — no `*.test.*` or `*.spec.*` files exist under the project root (outside of vendor/dependency directories).

---

## Test Infrastructure Present

### HarmonyOS — Hypium Framework (Declared, Unused)

`@ohos/hypium` version `1.0.18` is declared as a `devDependency` in `harmonyos/oh-package.json5`:

```json
{
  "devDependencies": {
    "@ohos/hypium": "1.0.18"
  }
}
```

The package is installed in `harmonyos/oh_modules/.ohpm/@ohos+hypium@1.0.18/`. The framework's test runner exists at:
- `harmonyos/oh_modules/.ohpm/@ohos+hypium@1.0.18/oh_modules/@ohos/hypium/src/main/testrunner/OpenHarmonyTestRunner.ts`

No application test files, test suites, or test abilities have been created. The `ohosTest/` source set that DevEco Studio generates for unit tests does not exist.

### WeChat Mini Program — No Test Infrastructure

No test framework, no test config, no test scripts. The `miniprogram/` directory has no `package.json` and no test tooling of any kind. Pure client-side JavaScript with no module system means Jest/Vitest would require additional setup to run.

### Run Commands

None are currently configured. To run tests once created:

```bash
# HarmonyOS — run via DevEco Studio
# "Run > Run ohosTest" or hvigorw test

# WeChat — no runner configured; would require setup
```

---

## Testable Pure Logic (Priority Candidates)

These modules contain pure algorithmic logic with no platform dependencies and are the highest-value test targets:

### 1. TOTP Generation (`harmonyos/.../utils/TOTP.ets`, `miniprogram/utils/totp.js`)

Both files implement identical algorithms. The HarmonyOS version exports three functions:
- `totp(secret: string, offset: number): string` — generates a 6-digit TOTP code
- `timeLeft(): number` — seconds remaining in current 30s window (1–30)
- `fmtCode(s: string): string` — formats `"123456"` → `"123 456"`

These are pure functions with no I/O. Deterministic for a given input and time offset.

**Test cases needed:**
```
totp("JBSWY3DPEHPK3PXP", 0) → known 6-digit code (RFC 6238 test vector)
totp("JBSWY3DPEHPK3PXP", 1) → next code (offset +1 window)
totp("", 0) → falls back to deterministic hash, returns 6-digit string
totp("INVALIDBASE32!!!", 0) → falls back, returns 6-digit string
fmtCode("123456") → "123 456"
fmtCode("12345") → "12345" (too short, pass-through)
fmtCode("") → "------"
fmtCode(undefined/null) → "------"
timeLeft() → integer 1–30
```

**RFC 6238 test vectors** (base32 key `JBSWY3DPEHPK3PXP` = `Hello!` in base32):
- These allow verifying the HMAC-SHA1-TOTP implementation is correct against the standard.

### 2. Crypto Encryption/Decryption (`harmonyos/.../utils/CryptoUtil.ets`)

`encryptData(data: object[], pass: string): string` and `decryptData(enc: string, pass: string): object[]`

Pure functions over strings and arrays (the `util.Base64Helper` from `@kit.ArkTS` is the only platform dependency).

**Test cases needed:**
```
round-trip: decryptData(encryptData(tokens, "pass"), "pass") deepEquals tokens
wrong password: decryptData(encryptData(tokens, "pass"), "wrong") throws or returns garbage
empty array: encryptData([], "pass") → valid base64 string; round-trips to []
unicode password: encryptData(tokens, "密码123") round-trips correctly
legacy format: decryptData(legacy_xor_encoded, pass) → correct tokens (backward compat)
ENC2 magic bytes present in output: output starts with "ENC2" after base64 decode
```

### 3. Base32 Decode (internal to `TOTP.ets`)

`base32Decode` is not exported but is the most likely source of subtle bugs. Worth testing via the `totp()` wrapper using known test vectors.

### 4. OTP Code Formatting (`fmtCode`)

Both platforms implement the same `fmtCode`/`fmt` logic. Simple pure function. Already identified above.

---

## Test Coverage Gaps (By Risk)

### Critical — No Tests

| Area | File(s) | Risk |
|------|---------|------|
| TOTP algorithm correctness | `TOTP.ets`, `totp.js` | Silent wrong codes — user locked out of accounts |
| PBKDF2-XOR encryption | `CryptoUtil.ets` | Backup files unrecoverable after any change |
| Backup round-trip | `CryptoUtil.ets` | Data loss on import |
| Base32 decode edge cases | `TOTP.ets` | Secrets with padding/spaces produce wrong codes |
| Storage key correctness | `StorageUtil.ets` | Tokens or theme lost across app restart |

### High — No Tests

| Area | File(s) | Risk |
|------|---------|------|
| `timeLeft()` boundary (t=0, t=30) | `TOTP.ets` | Countdown display shows wrong value |
| Legacy crypto fallback path | `CryptoUtil.ets` | Old backups fail silently |
| `INITIAL_TOKENS` constant consistency | `Token.ets`, `app.js` | Demo tokens show wrong codes |
| Token limit enforcement | `Index.ets`, `index.js` | Free users bypass 5-token cap |

### Medium — Integration Behavior

| Area | Risk |
|------|------|
| OTP refresh on 30s boundary | New window codes not generated at correct moment |
| Auto-sync timer (hourly) | Double-sync or no-sync on state transitions |
| Toast auto-dismiss timing | Toast never dismisses or dismisses too fast |

---

## Recommended Test Setup

### HarmonyOS (Hypium)

DevEco Studio supports Hypium unit tests via the `ohosTest` source set. To enable:

1. Create `harmonyos/entry/src/ohosTest/ets/` directory structure
2. Create an `EntryAbility` test ability in `ohosTest`
3. Write test suites using Hypium `describe`/`it`/`expect` API

**Example Hypium test structure:**
```typescript
// harmonyos/entry/src/ohosTest/ets/test/TotpTest.ets
import { describe, it, expect } from '@ohos/hypium';
import { totp, fmtCode, timeLeft } from '../../../main/ets/utils/TOTP';

export default function totpTest() {
  describe('TOTP', () => {
    it('formats 6-digit code with space', 0, () => {
      expect(fmtCode('123456')).assertEqual('123 456');
    });
    it('returns fallback for empty secret', 0, () => {
      const code = totp('', 0);
      expect(code.length).assertEqual(6);
    });
  });
}
```

### WeChat Mini Program (No Recommended Framework Yet)

The WeChat Mini Program JS files (`utils/totp.js`, `utils/crypto.js`) use CommonJS `module.exports`. They can be tested with Jest in a Node.js environment without any WeChat runtime:

```bash
# Hypothetical setup
cd miniprogram
npm init -y
npm install --save-dev jest
```

```javascript
// utils/totp.test.js
const { totp, fmtCode, timeLeft } = require('./totp');

test('fmtCode formats 6 digits', () => {
  expect(fmtCode('123456')).toBe('123 456');
});
test('timeLeft returns 1-30', () => {
  const t = timeLeft();
  expect(t).toBeGreaterThanOrEqual(1);
  expect(t).toBeLessThanOrEqual(30);
});
```

---

## Testing Anti-Patterns to Avoid

- **Do not mock `Date.now()`** unless testing time-boundary behavior — use the `offset` parameter of `totp()` to test next/previous windows instead.
- **Do not test OTP values against hardcoded expected strings without pinning `Date.now()`** — codes change every 30 seconds.
- **Do not test `Index.ets` UI logic directly** — the 1000+ line monolith mixes state and UI; extract logic into utilities first, then test the utilities.
- **Prefer testing `CryptoUtil.ets` through `encryptData`/`decryptData`** rather than internal functions (`pbkdf2`, `sha1`) which are implementation details.

---

## Priority Order for Writing First Tests

1. `fmtCode` (WeChat + HarmonyOS) — trivial pure function, zero dependencies, proves test setup works
2. `totp()` with RFC 6238 test vectors — validates the core security-critical algorithm
3. `encryptData` / `decryptData` round-trip — validates no data loss on backup
4. `base32Decode` via `totp()` — validates secret key parsing (spaces, padding, lowercase)
5. `timeLeft()` — validates countdown math at epoch boundaries

---

*Testing analysis: 2026-05-19*
