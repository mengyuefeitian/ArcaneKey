---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: 鸿蒙端功能对齐
status: planning
last_updated: "2026-05-19T10:22:00.000Z"
last_activity: 2026-05-19 -- Phase 1 Plan 2 complete (FEATURE-AUDIT.md)
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 6
  completed_plans: 2
  percent: 33
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-19)

**Core value:** 鸿蒙用户获得与小程序用户完全一致的 TOTP 身份验证体验
**Current focus:** Phase 1 — 缺陷修复 + 功能审计

## Current Position

Phase: 1 (缺陷修复 + 功能审计) — IN PROGRESS
Plan: 2 of 2 complete
Status: Phase 1 complete — awaiting device verification (FIX-01) before Phase 2 planning
Last activity: 2026-05-19 -- Phase 1 Plan 2 complete (FEATURE-AUDIT.md)

Progress: [█████░░░░░] 33%

## Phase Overview

| Phase | Name | Status | Plans |
|-------|------|--------|-------|
| 1 | 缺陷修复 + 功能审计 | 🔜 Ready | 2 |
| 2 | 功能补全 | ⏳ Blocked on Phase 1 | TBD |
| 3 | AGC 云同步 | ⏳ Blocked on Phase 2 | 4 |

## Known Critical Issues

1. **相机权限未声明** — `module.json5` 缺少 `ohos.permission.CAMERA`，真机 QR 扫码静默失败
2. **云备份为本地代理** — `arcankey_cloud` Preferences 不是真实云存储
3. **Bundle ID 错误** — `com.example.authenticator` 无法上架应用市场

## Configuration

- **Mode:** YOLO（自动执行）
- **Granularity:** 粗粒度（3 个阶段）
- **Research:** 每阶段规划前执行
- **Platform:** HarmonyOS 6.1, API 23, ArkTS
- **Branch:** dev-harmonyos

---
# 星枢令 (ArcaneKey) — 鸿蒙端功能对齐

**核心价值：** 让鸿蒙用户获得与微信小程序用户完全一致的 TOTP 身份验证体验

**平台：** HarmonyOS 6.1（API 23），ArkTS
**分支：** `dev-harmonyos`
**参考基准：** 微信小程序 `main` 分支（已验证 v1.0 + v1.1）

## Decisions Made

- **2026-05-19:** HarmonyOS uses ENC2+PBKDF2+salt encryption; WeChat uses raw XOR. One-way compatibility confirmed. Phase 2 must add ENC2 decoder to WeChat crypto.js.
- **2026-05-19:** 0 missing features found in HarmonyOS vs WeChat baseline. Phase 2 scope is small (cipher fix + behavioral verification).
- **2026-05-19:** Camera permission fix (FIX-01) implemented in Plan 1 but requires real-device verification before AUDIT-02 can be closed.

## Next Step

Phase 2: 功能补全 — Requires user to verify camera permission on real HarmonyOS device first (AUDIT-02 gate). Then plan Phase 2 to fix WeChat ENC2 cipher decoder (FEAT-01) and run behavioral spot-checks.
