# Roadmap: 星枢令鸿蒙端功能对齐

## Milestones

- ✅ **v1.0 MVP** - 星枢令完整功能（已发布，小程序 + 鸿蒙基础实现）
- ✅ **v1.1 分享功能** - 小程序分享卡片（已发布，鸿蒙不需要）
- 🚧 **v2.0 鸿蒙对齐** - 鸿蒙端与小程序功能完全对齐（本项目）

---

## Phases

<details>
<summary><strong>Phase 1 — 缺陷修复 + 功能审计</strong></summary>

**Goal:** 修复已知关键缺陷，建立完整的功能差异清单。

**Plans:**
1. **Fix: 权限与配置修复** — 添加相机权限、修正 Bundle ID、添加 .gitignore
2. **Audit: 功能差异审计** — 对照小程序功能逐项核查鸿蒙实现，输出 FEATURE-AUDIT.md

**Success Criteria:**
- [ ] `module.json5` 中 `ohos.permission.CAMERA` 已声明
- [ ] Bundle ID 不再是 `com.example.*`
- [ ] `.gitignore` 已添加并提交
- [ ] `FEATURE-AUDIT.md` 存在，包含所有功能的对齐状态
- [ ] 无 P0 功能缺口遗漏

**Dependencies:** None

</details>

<details>
<summary><strong>Phase 2 — 功能补全</strong></summary>

**Goal:** 修复 Phase 1 审计发现的所有功能缺口，实现与小程序的行为一致性。

**Plans:**
1. **Fix: P0 功能缺口修复** — 修复审计中 P0 级别的缺口
2. **Fix: P1 体验差异修复** — 修复审计中 P1 级别的体验差异

> 具体 plans 在 Phase 1 审计结果出来后细化。

**Success Criteria:**
- [ ] FEATURE-AUDIT.md 中所有 P0 项标记为 ✅
- [ ] FEATURE-AUDIT.md 中所有 P1 项标记为 ✅ 或有明确的可接受说明
- [ ] 所有核心用户流程（添加 Token、查看 OTP、备份/导入）在模拟器上可走通

**Dependencies:** Phase 1

</details>

<details>
<summary><strong>Phase 3 — AGC 云同步</strong></summary>

**Goal:** 接入 AppGallery Connect 云数据库，替换本地 Preferences 代理，实现真正的云备份/恢复/自动同步。

**Plans:**
1. **Research: AGC 集成预研** — 研究 AGC Cloud DB SDK 接入方式、鉴权、Schema 设计
2. **Implement: AGC SDK 集成** — 配置 agconnect-services.json、初始化 SDK、定义 Schema
3. **Implement: 云备份/恢复** — 替换 StorageUtil.ets 中的 Preferences 操作为 AGC 操作
4. **Implement: 自动同步** — 实现每小时后台触发的自动同步

**Success Criteria:**
- [ ] AGC SDK 集成到项目，编译通过
- [ ] 会员用户可成功备份 Token 到 AGC
- [ ] 清空本地后可从 AGC 完整恢复
- [ ] 每小时自动同步正常触发
- [ ] 非会员用户云功能被正确拦截

**Dependencies:** Phase 2

</details>

---

## Feature Matrix（小程序 vs 鸿蒙目标）

| 功能 | 小程序 | 鸿蒙目标（本项目完成后） |
|------|--------|------------------------|
| TOTP 生成 | ✅ | ✅ |
| Token CRUD | ✅ | ✅ |
| QR 扫码 | ✅ | ✅（Phase 1 修复） |
| XOR 备份/导入 | ✅ | ✅ |
| 主题系统 | ✅ | ✅ |
| 会员系统 | ✅ | ✅ |
| 云备份/恢复 | ✅ wx.cloud | ✅（Phase 3 AGC） |
| 自动同步 | ✅ | ✅（Phase 3 AGC） |
| 反馈 | ✅ 云函数 | ✅ mailto:（可接受） |
| 分享 | ✅ | ❌ 不需要 |
