---
plan: 03-02
phase: 03
subsystem: harmonyos/token-gestures
tags: [harmonyos, gesture, context-menu, swipe-to-delete, tokencard]
completed: 2026-05-20
duration: ~15min
commit: 1252b64
requires: [03-01]
provides: [TokenCard long-press menu, TokenCard swipe-to-delete]
affects: [TokenCard.ets, HomeView.ets, Index.ets]
tech-stack:
  added: [bindContextMenu, PanGesture, Stack dual-layer layout]
  patterns: [callback prop chain, per-card @State swipeOffset, system context menu]
key-files:
  modified:
    - harmonyos/entry/src/main/ets/components/TokenCard.ets
    - harmonyos/entry/src/main/ets/views/HomeView.ets
    - harmonyos/entry/src/main/ets/pages/Index.ets
decisions:
  - "Used bindContextMenu (system API) instead of Index.ets modal overlay for long-press menu — approved deviation from D-4"
  - "swipeOffset reset on cancel is deferred to v2 per RESEARCH open question 2"
  - "MenuItem.onAction() used as primary callback (falls back to onClick if compile error)"
---

# Phase 03 Plan 02: 手势交互 Summary

Added long-press context menu (4 actions via bindContextMenu) and swipe-to-delete (Stack + PanGesture + 72px red button) to TokenCard, wiring both delete paths through the existing requestDeleteToken / deleteConfirmDialog flow in Index.ets.

## Tasks Completed

| Task | Name | Files |
|------|------|-------|
| T1 | TokenCard 新增长按上下文菜单 + onDelete 回调 | TokenCard.ets |
| T2 | TokenCard 左滑删除（Stack 包裹 + PanGesture + swipeOffset） | TokenCard.ets |
| T3 | HomeView 透传 onDelete + Index.ets 接入 requestDeleteToken | HomeView.ets, Index.ets |

## Commits

| Task | Hash | Message |
|------|------|---------|
| T1+T2+T3 | 1252b64 | feat(03-02): Token卡片长按菜单 + 左滑删除手势 |

## Key Changes

**TokenCard.ets:**
- Added `onDelete: (tok: Token) => void = () => {};` callback field
- Added `@State swipeOffset: number = 0;` per-card swipe state
- Added `@Builder contextMenu()` with 4 MenuItem items (复制口令, 复制下一个口令, 编辑, 删除)
- Restructured `build()` from single `Column` to `Stack` dual-layer:
  - Bottom layer: `Row` with red `Button('删除')` (72px wide, #ef4444)
  - Top layer: existing card `Column` with `.offset({ x: this.swipeOffset })` + `.animation()` + `PanGesture`
- `bindContextMenu(this.contextMenu(), ResponseType.LongPress)` on inner card Column
- Snap logic: `swipeOffset < -36 ? -72 : 0` in `onActionEnd`
- `.clip(true)` on both Stack (outer) and Column (inner) — prevents delete button overflow
- `.margin({ bottom: 10 })` moved from inner Column to outer Stack

**HomeView.ets:**
- Added `onDelete: (tok: Token) => void = () => {};` callback field
- Passed `onDelete: (t: Token) => this.onDelete(t)` to TokenCard instances

**Index.ets:**
- Added `onDelete: (tok: Token) => this.requestDeleteToken(tok)` to HomeView instantiation

## Verification

- `grep -c "bindContextMenu" TokenCard.ets` → 1
- `grep -c "ResponseType.LongPress" TokenCard.ets` → 1
- `grep -c "MenuItem(" TokenCard.ets` → 4
- `grep -c "onAction" TokenCard.ets` → 4
- `grep -c "Stack()" TokenCard.ets` → 1
- `grep -c "#ef4444" TokenCard.ets` → 1
- `grep -c "PanGesture(" TokenCard.ets` → 1
- `grep -c "clip(true)" TokenCard.ets` → 2
- `grep -c "onDelete" HomeView.ets` → 2 (field + TokenCard prop)
- `grep -c "deleteConfirmDialog" Index.ets` → 2 (definition + mount, no new dialog added)

## Deviations from Plan

**Approved deviation (D-4 architecture):** The plan originally specified implementing the long-press menu as a modal overlay in Index.ets at zIndex 400. This plan uses `bindContextMenu` (system API, ResponseType.LongPress) instead — system-managed positioning, animation, and dismiss behavior. This was explicitly marked as an approved deviation in the task description ("此为已批准的偏离").

**No other deviations.** All three tasks executed as specified.

## Known Stubs

None — all callbacks are fully wired end-to-end.

## Self-Check: PASSED

- TokenCard.ets exists and contains all required patterns
- HomeView.ets contains onDelete field (×1) and TokenCard prop (×1) = 2 total
- Index.ets HomeView instantiation contains `onDelete: (tok: Token) => this.requestDeleteToken(tok)`
- Commit 1252b64 exists in git log
- No new deleteConfirmDialog builder was added (count remains 2)
