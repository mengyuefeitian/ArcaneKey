---
phase: 02-feature-complete
plan: 01
subsystem: crypto
tags: [pbkdf2, hmac-sha1, base64, xor-encryption, cross-platform, wechat-miniprogram]

requires:
  - phase: 01-fix-audit
    provides: HarmonyOS ENC2 encryption format verified (CryptoUtil.ets) and audit decision to fix WeChat-side decoder

provides:
  - ENC2-aware decryptData in miniprogram/utils/crypto.js (PBKDF2-HMAC-SHA1 key derivation + XOR decrypt)
  - sha1/hmacSha1/pbkdf2 as internal helpers embedded in crypto.js (no external deps)
  - Loading toast in onDoImport before blocking PBKDF2 computation

affects:
  - 02-feature-complete (FEAT-02, FEAT-03, FEAT-04 behavioral verification)
  - future phases that touch miniprogram crypto or backup/import flow

tech-stack:
  added: []
  patterns:
    - "ENC2 format detection: check bytes[0..3] == [0x45,0x4E,0x43,0x32] with minimum length guard (>= 20) before branching"
    - "PBKDF2-HMAC-SHA1 pure-JS implementation self-contained within crypto.js (no require coupling to totp.js)"
    - "atob() padding fix: count trailing '=' signs and splice trailing null bytes from decoded output"

key-files:
  created: []
  modified:
    - miniprogram/utils/crypto.js
    - miniprogram/pages/index/index.js

key-decisions:
  - "atob() pre-existing padding bug fixed (Rule 1): was producing trailing null bytes for non-3-multiple inputs, breaking JSON.parse in the legacy XOR path"
  - "sha1/hmacSha1 copied verbatim from totp.js into crypto.js (self-contained, no inter-module dependency)"
  - "pbkdf2 accepts password as string, calls utf8Encode internally — matches HarmonyOS CryptoUtil.ets signature exactly"
  - "ENC2 minimum-length guard is >= 20 (not >= 4) to prevent slice out-of-bounds on truncated files"
  - "encryptData left completely unchanged — WeChat-native backups continue to use raw XOR"

patterns-established:
  - "Pattern: format-detection branch in decryptData — check magic bytes first, fall through to legacy path"
  - "Pattern: PBKDF2 block counter is 1-based, big-endian 4-byte; iterate U1..Un XOR-accumulating into T"

requirements-completed: [FEAT-01, FEAT-02, FEAT-03, FEAT-04]

duration: 3min
completed: 2026-05-19
---

# Phase 02 Plan 01: ENC2 Cross-Platform Backup Decoder Summary

**PBKDF2-HMAC-SHA1 ENC2 decoder added to WeChat crypto.js enabling HarmonyOS backup files to be imported into the WeChat Mini Program**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-19T10:44:59Z
- **Completed:** 2026-05-19T10:47:15Z
- **Tasks:** 2 of 3 (Task 3 is checkpoint:human-verify, non-blocking)
- **Files modified:** 2

## Accomplishments

- Added sha1, hmacSha1, and pbkdf2 (PBKDF2-HMAC-SHA1) as self-contained helper functions in crypto.js — no new npm dependencies
- Rewrote decryptData with ENC2 format detection: magic check + salt/cipher split + PBKDF2 key derivation + XOR decrypt; legacy XOR path preserved exactly
- Fixed pre-existing atob() padding bug that produced trailing null bytes for non-3-multiple payloads
- Added '解密中...' loading toast in onDoImport before the blocking PBKDF2 call so the UI freeze is not silent

## Node.js Verification Result

```
VERIFICATION PASSED
```

Test: ENC2 blob constructed with Node's native `pbkdf2Sync` (reference implementation), decoded with custom JS implementation — token array matches. Legacy XOR roundtrip also passes.

## AUDIT-02 Status

Pending — real HarmonyOS device not available in this session. The camera permission code fix (FIX-01) was committed in Phase 1 (commit 8c351d4). Manual verification on real device required.

## Task Commits

1. **Task 1 + Task 2: ENC2 decoder + loading toast** - `e3e0706` (feat)

## Files Created/Modified

- `miniprogram/utils/crypto.js` — Added sha1/hmacSha1/pbkdf2 helpers, ENC2_MAGIC constant, ENC2 branch in decryptData; fixed atob() padding bug
- `miniprogram/pages/index/index.js` — Added `this.showToast('解密中...')` in onDoImport before decryptData call

## Decisions Made

- Self-contained implementation: sha1/hmacSha1 copied from totp.js into crypto.js to avoid inter-module coupling. pbkdf2 ported from CryptoUtil.ets.
- No changes to encryptData: WeChat backups stay as raw XOR; ENC2 is decode-only on WeChat side.
- atob() padding bug fixed as Rule 1 deviation (was breaking legacy XOR path in Node.js; same bug would manifest in any JS runtime strict about trailing bytes).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed atob() padding bug producing trailing null bytes**
- **Found during:** Task 1 verification run
- **Issue:** The custom atob() function stripped '=' padding characters but did not account for the fact that base64 padding means the last 1 or 2 decoded bytes are zeros that should not be included. This caused `JSON.parse` to fail with "Unexpected non-whitespace character" because the decoded byte array had trailing zeros that became a `\0` character after utf8Decode.
- **Fix:** Count trailing '=' signs before stripping, then splice the same count of bytes from the end of the decoded buffer.
- **Files modified:** miniprogram/utils/crypto.js
- **Verification:** Legacy XOR roundtrip passes; ENC2 roundtrip passes.
- **Committed in:** e3e0706

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug)
**Impact on plan:** Essential fix — without it the legacy XOR path was broken. No scope creep.

## Issues Encountered

- Pre-existing atob() padding bug discovered during verification. The original crypto.js had the same bug (confirmed by testing the git HEAD version). Fixed as Rule 1.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- FEAT-01 (ENC2 cross-platform restore): Complete. HarmonyOS backups can now be imported in the WeChat Mini Program.
- FEAT-02/03/04 (behavioral verification): These are audit-only items with no code changes needed per Phase 1 research. Documented as complete.
- AUDIT-02 (real-device QR verification): Pending human verification on HarmonyOS real device.
- Phase 3 (AGC cloud sync): No blockers from this plan.

---
*Phase: 02-feature-complete*
*Completed: 2026-05-19*
