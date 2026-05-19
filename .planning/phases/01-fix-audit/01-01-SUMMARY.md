---
phase: 01-fix-audit
plan: 01
subsystem: harmonyos/permissions,harmonyos/config,repo/gitignore
tags: [permissions, bundle-id, gitignore, camera, harmonyos]
dependency_graph:
  requires: []
  provides:
    - harmonyos/camera-permission-static-declaration
    - harmonyos/camera-permission-runtime-request
    - harmonyos/production-bundle-id
    - repo/gitignore
  affects:
    - harmonyos/entry/src/main/ets/views/ScanView.ets
    - harmonyos/entry/src/main/module.json5
    - harmonyos/AppScope/app.json5
tech_stack:
  added: []
  patterns:
    - abilityAccessCtrl.requestPermissionsFromUser for user_grant camera permission
key_files:
  created:
    - .gitignore
  modified:
    - harmonyos/entry/src/main/resources/base/element/string.json
    - harmonyos/entry/src/main/module.json5
    - harmonyos/entry/src/main/ets/views/ScanView.ets
    - harmonyos/AppScope/app.json5
decisions:
  - Combined source-file fixes and git-index cleanup into single commit (all staging preceded the commit)
  - Added private.wx*.key glob to .gitignore as security measure (CLAUDE.md requirement)
  - requestCameraPermission() implemented as private method before doScan() for clean separation
metrics:
  duration: ~8 minutes
  completed: 2026-05-19
---

# Phase 01 Plan 01: HarmonyOS Config Fixes (Camera Permission, Bundle ID, Gitignore) Summary

Fixed three critical configuration defects in the HarmonyOS app: dual-step camera permission (static manifest + runtime request with graceful denial handling), bundle ID renamed from `com.example.arcankey` to `com.arcanekey.authenticator`, and 174 tracked build artifacts removed from git index via new `.gitignore`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1.1 | Add camera_reason string resource | 8c351d4 | string.json |
| 1.2 | Static camera permission in module.json5 | 8c351d4 | module.json5 |
| 1.3 | Runtime permission request in ScanView.ets | 8c351d4 | ScanView.ets |
| 1.4 | Fix Bundle ID in app.json5 | 8c351d4 | app.json5 |
| 1.5 | Create .gitignore, remove tracked build artifacts | 8c351d4 | .gitignore + 170 deletions |

## Fix Status

### FIX-01: Camera Permission (Dual-step)
**Status: IMPLEMENTED — device verification pending**

- `string.json`: Added `camera_reason` = "扫描二维码需要使用相机"
- `module.json5`: Added `requestPermissions` array with `ohos.permission.CAMERA`, `reason: "$string:camera_reason"`, `usedScene: { abilities: ["EntryAbility"], when: "inuse" }`
- `ScanView.ets`: Added `requestCameraPermission(ctx)` private method using `abilityAccessCtrl.createAtManager()` + `requestPermissionsFromUser`. Modified `doScan()` to call permission check before `startScanForResult`; on denial shows "需要相机权限才能扫码" toast and returns early without crash.

### FIX-02: Bundle ID
**Status: COMPLETE**

- `app.json5`: `bundleName` changed from `com.example.arcankey` to `com.arcanekey.authenticator`
- `app.json5`: `vendor` changed from `example` to `arcanekey`
- No `example` residue remains in app.json5

### FIX-03: Gitignore + Build Artifact Cleanup
**Status: COMPLETE**

- Created root `.gitignore` covering: `.DS_Store`, `.hvigor/`, `entry/build/`, `oh_modules/`, `.idea/.deveco/`, `workspace.xml`, `usage.statistics.xml`, `local.properties`, `*.hap`, `*.app`, `*.har`, `miniprogram_npm/`, `private.wx*.key`
- Removed 170 previously-tracked build artifact files from git index (`git rm --cached`)
- `git ls-files harmonyos/.hvigor/ harmonyos/entry/build/ harmonyos/oh_modules/` returns 0 lines

## Deviations from Plan

### Auto-added: private.wx*.key to .gitignore

**Rule 2 - Missing Critical Functionality**
- **Found during:** Task 1.5
- **Issue:** CLAUDE.md explicitly states the `private.wx5327dd9b28d32e7a.key` file must be excluded from all commits; the plan's gitignore template did not include a rule for it
- **Fix:** Added `private.wx*.key` glob pattern to `.gitignore` to permanently prevent accidental commit of WeChat private keys
- **Files modified:** `.gitignore`
- **Commit:** 8c351d4

### Auto-fixed: Typo in ScanView.ets write

**Rule 1 - Bug**
- **Found during:** Task 1.3
- **Issue:** Initial Write of ScanView.ets contained `self.secret = v` (typo) instead of `this.secret = v` in the Secret Key TextInput onChange handler
- **Fix:** Corrected to `this.secret = v` via Edit before verifying or committing
- **Files modified:** `ScanView.ets`
- **Commit:** 8c351d4 (correction applied before commit, no separate commit needed)

## Device Verification Status

Task 1.6 (human checkpoint) — FIX-01 device verification: **SKIPPED (no device available)**

Real-device verification of the camera permission dialog requires DevEco Studio build + HarmonyOS physical device. This cannot be automated. When verified, the expected behavior is:
- User taps "扫描二维码" button in ScanView
- System permission dialog appears with text "扫描二维码需要使用相机"
- After grant: camera opens normally
- After denial: in-app toast "需要相机权限才能扫码" appears for 2.2 seconds, scan session ends cleanly

This item should be tracked in FEATURE-AUDIT.md as: `FIX-01 camera permission dialog — pending real-device verification`.

## Self-Check: PASSED

- `.gitignore` exists: confirmed
- `harmonyos/entry/src/main/module.json5` contains `ohos.permission.CAMERA`: confirmed
- `harmonyos/entry/src/main/resources/base/element/string.json` contains `camera_reason`: confirmed
- `harmonyos/entry/src/main/ets/views/ScanView.ets` contains `requestPermissionsFromUser`: confirmed
- `harmonyos/AppScope/app.json5` contains `com.arcanekey.authenticator`: confirmed
- `harmonyos/AppScope/app.json5` has no `example` residue: confirmed
- `git ls-files harmonyos/.hvigor/ harmonyos/entry/build/ harmonyos/oh_modules/` returns 0: confirmed
- Commit 8c351d4 exists: confirmed
