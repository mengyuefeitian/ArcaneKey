---
phase: 01-fix-audit
plan: 02
subsystem: planning/feature-audit
tags: [audit, feature-matrix, crypto-compatibility, membership, qr-scan]
dependency_graph:
  requires:
    - harmonyos/camera-permission-static-declaration
    - harmonyos/camera-permission-runtime-request
  provides:
    - planning/feature-audit-document
    - audit/crypto-compatibility-finding
    - audit/membership-alignment-confirmed
  affects:
    - .planning/FEATURE-AUDIT.md
tech_stack:
  added: []
  patterns:
    - Direct code extraction for algorithm parameter comparison (no assumptions)
key_files:
  created:
    - .planning/FEATURE-AUDIT.md
  modified: []
decisions:
  - HarmonyOS CryptoUtil uses ENC2+PBKDF2+salt while WeChat crypto.js uses raw XOR — one-way compatibility confirmed, Phase 2 must fix WeChat decoder
  - 0 missing features found — all 22 WeChat baseline features exist in HarmonyOS in some form
  - Cloud backup gaps (features 16/17) deferred to Phase 3 AGC as designed
metrics:
  duration: ~12 minutes
  completed: 2026-05-19
---

# Phase 01 Plan 02: Feature Audit Summary

Produced FEATURE-AUDIT.md with all 22 WeChat Mini Program features audited against the HarmonyOS app. No features are missing outright; key finding is a one-way cipher format incompatibility (AUDIT-04) requiring Phase 2 fix.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 2.1 | Read source code for audit baseline | 47c1503 (data gathering only) | (read-only: crypto.js, CryptoUtil.ets, app.js, Token.ets, TOTP files, Index.ets, views) |
| 2.2 | Generate FEATURE-AUDIT.md | 47c1503 | .planning/FEATURE-AUDIT.md |

## Key Findings

### Feature Alignment Summary

| Status | Count | Notes |
|--------|-------|-------|
| ✅ Aligned | 14 | Full functional equivalence confirmed by code comparison |
| ✅ Acceptable difference | 3 | Login (platform APIs differ), Feedback (mailto vs cloud function), both fine |
| 🔜 Implemented, pending device verify | 2 | Camera scan + album scan (FIX-01 applied in Plan 1) |
| ⚠️ Has differences needing fix | 3 | Crypto compatibility, cloud backup backend, auto-sync backend |
| ❌ Missing | 0 | No features completely absent |
| N/A | 1 | WeChat share (intentionally excluded) |

### AUDIT-02 Conclusion (QR Scan)
FIX-01 (Plan 1, commit 8c351d4) implemented both static `ohos.permission.CAMERA` declaration in `module.json5` and runtime `requestPermissionsFromUser()` in `ScanView.ets`. Status: **implemented, pending real-device verification**. No HarmonyOS device available to verify the permission dialog appears and camera opens correctly.

### AUDIT-03 Conclusion (Membership)
Fully aligned. Both platforms: `FREE_TOKEN_LIMIT = 5`, `MEMBERSHIP_PRICE = 19.90`, `APP_NAME = '玄钥'`, `INITIAL_TOKENS` (6 identical demo accounts). Limit enforcement logic in `addToken()` is structurally identical. Both are demo mode (no real payment integration).

### AUDIT-04 Conclusion (Cross-Platform Cipher Compatibility)
**Critical finding: one-way compatibility.**

- WeChat `crypto.js`: raw XOR, no salt, no PBKDF2, no format header. Output = base64(XOR(json, password)).
- HarmonyOS `CryptoUtil.ets`: ENC2 magic header + 16-byte random salt + PBKDF2-HMAC-SHA1(10000 iter) + XOR with derived key. Output = base64("ENC2" + salt[16] + xored[]).

**HarmonyOS → WeChat import: FAILS.** WeChat decoder has no ENC2 format detection; applies raw XOR to ciphertext, produces garbage.

**WeChat → HarmonyOS import: WORKS.** HarmonyOS `decryptData()` contains a fallback path: if base64-decoded bytes do not start with `ENC2` magic, falls back to raw XOR (identical to WeChat's algorithm).

Fix required in Phase 2: add ENC2 format detection to WeChat `utils/crypto.js::decryptData()`.

## P0 Gaps

Zero features are completely missing. P0 items needing action:

| Gap | Status | Fix Phase |
|-----|--------|-----------|
| QR camera scan (device verify) | 🔜 FIX-01 applied | Phase 1 checkpoint (user verifies on device) |
| Album QR scan (device verify) | 🔜 FIX-01 applied | Phase 1 checkpoint (user verifies on device) |
| Cross-platform cipher (ENC2 → WeChat) | ⚠️ One-way compat | Phase 2 FEAT-01 |
| Cloud backup (real AGC) | ⚠️ Preferences proxy | Phase 3 AGC-04/05 |
| Hourly auto-sync (real AGC) | ⚠️ Timer exists, no real cloud | Phase 3 AGC-06 |

## Phase 2 Scope (Based on Audit)

Phase 2 work is lightweight — no missing features to build from scratch:

1. **FEAT-01 (required):** Fix WeChat `crypto.js` to decode ENC2 format (small change, ~20 lines)
2. **FEAT-03/04 (confirm):** Spot-check bottom nav, toast, theme, login state behaviors in DevEco Simulator
3. **Device verification:** QR camera permission (FIX-01 validation gate)

Estimated Phase 2 effort: 1-2 planning sessions. No new feature development required — only a cipher decoder fix and behavioral verification.

## Phase 3 Entry Conditions

Phase 3 AGC integration prerequisites are met:
- Bundle ID corrected to `com.arcanekey.authenticator` (FIX-02 done)
- `cloudBackup/Restore/Delete/startAutoSync()` code structure already in `Index.ets` — only backend replacement needed
- Still needed before Phase 3: add `ohos.permission.INTERNET` to `module.json5`

## Deviations from Plan

None. Plan executed exactly as written. Both task read targets and write target matched plan specification.

## Self-Check: PASSED

- `.planning/FEATURE-AUDIT.md` exists: confirmed
- Contains all 22 feature items: confirmed (grep count >= 22 status markers)
- P0 gaps section exists: confirmed
- AUDIT-02/03/04 sections exist: confirmed
- Cipher compatibility conclusion is concrete (no "TBD"): confirmed — "single-direction compatibility"
- Commit 47c1503 exists: confirmed
