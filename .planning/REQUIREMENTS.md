# Requirements — 星枢令鸿蒙端功能对齐

## Phase 1 Requirements — 缺陷修复 + 功能审计

### FIX — 关键缺陷修复

- [ ] **FIX-01**: `module.json5` 中声明 `ohos.permission.CAMERA` 权限，确保真机 QR 扫码可用
- [ ] **FIX-02**: 修正 Bundle ID（从 `com.example.authenticator` 改为生产值）
- [ ] **FIX-03**: 添加 `.gitignore`（排除 `.DS_Store`、IDE 缓存、构建产物）

### AUDIT — 功能差异审计

- [ ] **AUDIT-01**: 对照小程序功能清单，逐项验证鸿蒙端实现状态，输出差异文档
- [ ] **AUDIT-02**: 确认 QR 扫码修复后在真机上正常工作
- [ ] **AUDIT-03**: 确认会员功能（限制 5 个 Token、会员无限）行为与小程序一致
- [ ] **AUDIT-04**: 确认备份/导入的 XOR 加解密结果与小程序跨平台互通

---

## Phase 2 Requirements — 功能补全（审计后定义）

> 此阶段的详细需求在 Phase 1 审计完成后补充。预期包含：

### FEAT — 功能补全（基于审计结果）

- [ ] **FEAT-01**: 修复审计中发现的所有 P0 功能缺口
- [ ] **FEAT-02**: 修复审计中发现的所有 P1 体验差异
- [ ] **FEAT-03**: 确认底部导航、Toast 通知、主题切换行为与小程序一致
- [ ] **FEAT-04**: 确认登录态管理（本地 demo）行为与小程序一致

---

## Phase 3 Requirements — AGC 云同步

### AGC — AppGallery Connect 云数据库集成

- [ ] **AGC-01**: 在 AGC 控制台创建应用 + 开启云数据库服务
- [ ] **AGC-02**: 配置 `agconnect-services.json` 并集成 AGC SDK
- [ ] **AGC-03**: 定义云数据库 Schema（与小程序 `user_backups` 结构对齐）
- [ ] **AGC-04**: 实现云备份功能（加密数据写入 AGC 云数据库）
- [ ] **AGC-05**: 实现云恢复功能（从 AGC 读取并解密还原 Token 列表）
- [ ] **AGC-06**: 实现每小时自动同步（与小程序 hourly auto-sync 逻辑一致）
- [ ] **AGC-07**: 更新 `StorageUtil.ets`——将 `arcankey_cloud` Preferences 代理替换为 AGC 操作
- [ ] **AGC-08**: 更新 `module.json5`——声明 AGC 所需网络权限

### VALIDATE — 验证

- [ ] **VALIDATE-01**: 会员用户可将 Token 备份到 AGC
- [ ] **VALIDATE-02**: 清空本地后可从 AGC 完整恢复 Token 列表
- [ ] **VALIDATE-03**: 自动同步在后台正常触发
- [ ] **VALIDATE-04**: 非会员用户无法使用云功能（与小程序行为一致）

---

## Out of Scope（明确不做）

- 分享/转发功能（微信专属 API，鸿蒙无对应能力）
- 华为 IAP 真实支付
- AES 替换 XOR 加密
- Index.ets 重构（单独议题）
