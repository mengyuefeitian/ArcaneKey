---
plan: 03-01
phase: 03
subsystem: harmonyos/branding
completed: 2026-05-20
---

# Plan 03-01: 品牌重塑 Summary

HarmonyOS 端产品从「玄钥」全面更名为「星枢令」：更新 APP_NAME 常量、字符串资源（启动器标签 + 模块描述）、邮件主题、ProfileView 品牌区（产品名、副标题、描述文案、版本页脚），并将品牌色方块内的「玄」文字字符替换为 PNG Logo 图片。共 6 处字符串替换、1 个新增 PNG 资源、1 处描述文案更新、1 处 Logo 图片渲染。

## Tasks Completed

| Task | Name | Files |
|------|------|-------|
| T1 | 更名「玄钥」→「星枢令」（常量 + 字符串资源 + 文档） | `harmonyos/entry/src/main/ets/model/Token.ets`, `harmonyos/entry/src/main/ets/views/FeedbackView.ets`, `harmonyos/entry/src/main/resources/base/element/string.json`, `harmonyos/AppScope/resources/base/element/string.json`, `CLAUDE.md` |
| T2 | ProfileView 更名 + 新产品描述 | `harmonyos/entry/src/main/ets/views/ProfileView.ets` |
| T3 | 拷贝 Logo PNG 并替换品牌方块文字为图片 | `harmonyos/entry/src/main/resources/base/media/logo_img.png`, `harmonyos/entry/src/main/ets/views/ProfileView.ets` |

## Verification

- `grep -rn "玄钥" harmonyos/entry/src/main harmonyos/AppScope` 无输出（源码完全干净）
- `APP_NAME` 常量值为 `'星枢令'`（Token.ets 第 51 行）
- FeedbackView.ets 邮件主题 `[星枢令][...]`（1 处）
- `app_name` value 为 `星枢令`（AppScope string.json）
- `module_desc` / `EntryAbility_desc` / `EntryAbility_label` 全部包含「星枢令」
- 两个 string.json 均为合法 JSON（`node -e JSON.parse` 验证通过）
- ProfileView.ets 含「星枢令」3 处（标题、副标题、版本页脚），不含旧描述文案
- `logo_img.png` 存在，53461 字节（> 0）
- `Image($r('app.media.logo_img')).width(48).height(48).objectFit(ImageFit.Contain)` 已插入 Stack
- `Text('玄')` 已从 ProfileView.ets 移除
- Stack 外层 shadow (`accentColor + '55'`)、borderRadius(20)、backgroundColor 保持不变
- CLAUDE.md 产品名从「玄钥」更新为「星枢令」（Architecture 段落标题处）

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- `harmonyos/entry/src/main/resources/base/media/logo_img.png` — FOUND (53461 bytes)
- `harmonyos/entry/src/main/ets/model/Token.ets` — FOUND, contains `APP_NAME: string = '星枢令'`
- `harmonyos/entry/src/main/ets/views/ProfileView.ets` — FOUND, contains `Image($r('app.media.logo_img'))`
- Commit b6027df — FOUND
