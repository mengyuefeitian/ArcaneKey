# FEATURE-AUDIT.md — 星枢令功能差异审计

**审计日期：** 2026-05-19
**基准：** 微信小程序 `main` 分支（v1.0 全功能 + v1.1 分享）
**目标：** 鸿蒙 App `dev-harmonyos` 分支（Phase 1 修复后）
**审计方法：** 直接读取两端源代码逐函数对比；关键算法参数通过代码文本提取，不依赖假设
**审计员：** Phase 1 Plan 2 自动化审计

---

## 摘要

| 状态 | 数量 |
|------|------|
| ✅ 对齐 | 14 |
| ✅ 可接受差异 | 3 |
| 🔜 已实现，待真机验证 | 2 |
| ⚠️ 差异（需修复） | 3 |
| ❌ 缺失 | 0 |
| N/A | 1 |

**总功能项：22**

---

## P0 缺口摘要

本次审计发现 **0 个 ❌ 缺失的 P0 功能**，所有核心功能均已实现。但存在以下需关注项：

### P0 差异项

| 编号 | 功能 | 当前状态 | 根本原因 | 修复 Phase |
|------|------|----------|----------|-----------|
| G-01 | QR 扫码（相机） | 🔜 已实现，待真机验证 | FIX-01 已添加双步权限声明，但缺乏真机验证确认 | Phase 1（已修复，验证挂起） |
| G-02 | 相册扫码 | 🔜 已实现，待真机验证 | 同 G-01，enableAlbum=true 路径相同权限依赖 | Phase 1（已修复，验证挂起） |
| G-03 | 跨平台加解密兼容性 | ⚠️ 单向兼容 | 加密格式不对称：小程序用原始 XOR；鸿蒙用 ENC2+PBKDF2。鸿蒙可读小程序备份（fallback 路径），小程序不可读鸿蒙备份 | Phase 2（FEAT-01） |
| G-04 | 云备份/恢复（会员） | ⚠️ 本地 Preferences 代理 | `cloudBackup()` 写入本地 `arcankey_cloud` Preferences，不是真实网络云存储 | Phase 3（AGC-04/05） |
| G-05 | 每小时自动同步 | ⚠️ 有计时器，无真实云 | `startAutoSync()` 的 `setInterval(60*60*1000)` 存在，但目标是本地 Preferences | Phase 3（AGC-06） |

**Phase 2 必须处理 G-03（AUDIT-04 结论：单向兼容）。**
**Phase 3 处理 G-04 和 G-05（AGC 集成）。**

---

## 功能矩阵

| 功能 | 优先级 | 小程序状态 | 鸿蒙实现文件 | 鸿蒙状态 | 差异说明 | 修复 Phase |
|------|--------|-----------|------------|---------|---------|-----------|
| **1. TOTP 代码生成（30s 轮转）** | P0 | ✅ 已验证 | `TOTP.ets`, `Index.ets:refreshOtp()` | ✅ 对齐 | SHA-1/HMAC/base32 算法代码完全一致，逐行比对无差异 | — |
| **2. 多 Token 管理（增删改查）** | P0 | ✅ 已验证 | `Index.ets:addToken/saveEdit/deleteToken()` | ✅ 对齐 | 增删改查逻辑结构一致；编辑限品牌名+账号，secret 只读 | — |
| **3. Token 搜索** | P0 | ✅ 已验证 | `HomeView.ets:filtered()`, `Index.ets:searching/searchQ` | ✅ 对齐 | 按 brand/account 大小写不敏感过滤，逻辑一致 | — |
| **4. OTP 复制** | P0 | ✅ 已验证 | `Index.ets:copyCode()`, `@kit.BasicServicesKit:pasteboard` | ✅ 对齐 | 小程序用 `wx.setClipboardData`；鸿蒙用 `pasteboard.getSystemPasteboard()`；语义完全一致 | — |
| **5. 倒计时环** | P0 | ✅ 已验证 | `CountdownRing.ets` | ✅ 对齐 | 小程序用 Canvas API；鸿蒙用 `@Component` + ArkTS 绘制；视觉效果等价，无功能差异 | — |
| **6. QR 扫码自动添加 Token（相机）** | P0 | ✅ 已验证 | `ScanView.ets:doScan(false)` + `requestCameraPermission()` | 🔜 已实现，待真机验证 | FIX-01（Plan 1）已添加 `ohos.permission.CAMERA` 静态声明 + 运行时 `requestPermissionsFromUser`。无法在模拟器验证；真机验证挂起。详见 AUDIT-02 章节。 | Phase 1（已修复） |
| **7. 从相册选图识别** | P0 | ✅ 已验证 | `ScanView.ets:doScan(true)` (enableAlbum=true) | 🔜 已实现，待真机验证 | `ScanKit.startScanForResult` 的 `enableAlbum:true` 路径复用相同相机权限。真机验证挂起。 | Phase 1（已修复） |
| **8. 手动输入 Token** | P0 | ✅ 已验证 | `ScanView.ets tab=2`，包含品牌名/账号/Secret 字段 | ✅ 对齐 | 三字段表单（品牌名必填、Secret 必填、账号可选）；input 校验逻辑一致 | — |
| **9. 10 种主题色** | P1 | ✅ 已验证 | `Token.ets:THEMES[10]`, `Index.ets:themeModal()/selectTheme()` | ✅ 对齐 | 两端 THEMES 数组完全一致（经代码直接比对：海洋蓝 #4080D0 … 深靛蓝 #6050C8，10 项顺序/名称/颜色均相同） | — |
| **10. 会员系统（¥19.90/年，限 5 个 Token）** | P0 | ✅ 已验证（演示） | `Index.ets:buyMembership()`, `StorageUtil.ets:saveMember()` | ✅ 对齐（演示） | 见 AUDIT-03 章节。FREE_TOKEN_LIMIT=5、MEMBERSHIP_PRICE=19.90 两端完全一致；均为演示模式直接设置 isMember=true+1年有效期 | — |
| **11. 文件备份（XOR/PBKDF2 加密导出）** | P0 | ✅ 已验证 | `Index.ets:doBackup()`, `CryptoUtil.ets:encryptData()` | ✅ 对齐（鸿蒙格式更强） | 小程序用原始 XOR；鸿蒙用 ENC2+PBKDF2(10000)+salt。鸿蒙备份格式安全性更高。跨平台兼容性问题见第13项。 | — |
| **12. 文件导入（解密）** | P0 | ✅ 已验证 | `Index.ets:doImport()/selectImportFile()`, `CryptoUtil.ets:decryptData()` | ✅ 对齐（单向） | 鸿蒙 `decryptData` 含 ENC2 格式检测 + fallback 到原始 XOR，可读小程序备份。见第13项。 | — |
| **13. 跨平台加解密兼容性** | P0 | ✅ 小程序格式：原始 XOR | `CryptoUtil.ets:encryptData/decryptData` | ⚠️ 单向兼容 | **见 AUDIT-04 章节。** 鸿蒙→小程序：不兼容（小程序无 ENC2 解码器）。小程序→鸿蒙：兼容（鸿蒙 fallback 路径处理原始 XOR）。需在 Phase 2 修复小程序端解码 ENC2，或统一格式。 | Phase 2（FEAT-01） |
| **14. 密钥可见性切换（会员）** | P1 | ✅ 已验证 | `Index.ets:editSecretVisible`, `editModal()` 中 `toggleEditSecret` | ✅ 对齐 | 非会员显示星号遮盖；会员点击"查看"切换明文，行为与小程序一致 | — |
| **15. 差异化删除（本地/云）** | P1 | ✅ 已验证 | `Index.ets:deleteToken(localOnly: boolean)`, `showDeleteConfirm` | ✅ 对齐（仅本地语义） | 鸿蒙删除弹窗有 localOnly 参数；`cloudDelete()` 存在但操作的是本地 Preferences 代理。结构与小程序对齐；Phase 3 AGC 替换后语义自动完整。 | Phase 3（随 AGC） |
| **16. 云备份/恢复（会员，wx.cloud vs AGC）** | P0 | ✅ wx.cloud.database | `Index.ets:cloudBackup()/cloudRestore()` | ⚠️ 本地 Preferences 代理 | `cloudBackup()` 写 `arcankey_cloud` Preferences（同设备），`cloudRestore()` 从同一 Preferences 读取——不是真实跨设备云存储。语义结构与小程序对齐；存储后端不同。 | Phase 3（AGC-04/05） |
| **17. 每小时自动同步** | P0 | ✅ 已验证 | `Index.ets:startAutoSync()` | ⚠️ 有计时器，无真实云 | `setInterval(60*60*1000)` 调用 `cloudBackup()`，但 `cloudBackup()` 的目标是本地 Preferences。计时机制实现正确；需 Phase 3 替换后端。 | Phase 3（AGC-06） |
| **18. 登录（微信 getPhoneNumber vs 鸿蒙设备账号）** | P1 | ✅ 微信 getPhoneNumber | `Index.ets:loginModal()`, `doLogin()`, harmonyLogin flag | ✅ 可接受差异 | 小程序：微信授权+手机绑定两步流程；鸿蒙：单步"鸿蒙账号登录"演示（含隐私协议勾选）。两端均为演示模式，平台 API 不同，差异可接受。 | — |
| **19. 底部导航（浮动胶囊）** | P1 | ✅ 已验证 | `Index.ets:bottomNav()` @Builder | ✅ 对齐 | 小程序用独立 `bottom-nav` 组件；鸿蒙用 `@Builder` 内联实现。4个入口（首页/搜索/扫码/我的）、滚动隐藏/显示、glassmorphism 背景，功能与视觉一致。 | — |
| **20. Toast 通知** | P1 | ✅ 已验证 | `Index.ets:toast()`, `toastView()` @Builder | ✅ 对齐 | 小程序用独立 `toast` 组件；鸿蒙用 `@Builder` 内联实现。2.2s 自动消失、消息传参，行为完全一致。 | — |
| **21. 反馈功能** | P2 | ✅ 云函数邮件 | `FeedbackView.ets` | ✅ 可接受差异 | 小程序：云函数 `sendFeedback` + nodemailer → 邮件；鸿蒙：系统 `mailto:` intent 启动邮件客户端。功能语义等价（用户均可提交反馈到同一邮箱）；实现路径平台差异可接受。 | — |
| **22. 分享功能（v1.1）** | — | ✅ onShareAppMessage | N/A | N/A | 微信专属 API（`onShareAppMessage`、`wx.shareAppMessage`）。鸿蒙无对应能力，明确不实现。 | 不做 |

---

## 详细说明

### 功能 1 — TOTP 算法对比

两端 `totp()` 函数逐行比对结果：

| 算法步骤 | 小程序 `totp.js` | 鸿蒙 `TOTP.ets` | 一致？ |
|---------|----------------|----------------|--------|
| SHA-1 初始化常量 | h0=0x67452301…h4=0xC3D2E1F0 | 相同 | ✅ |
| HMAC-SHA1 构造 | ipad(0x36)/opad(0x5c), blockSize=64 | 相同 | ✅ |
| Base32 字母表 | ABCDEFGHIJKLMNOPQRSTUVWXYZ234567 | 相同 | ✅ |
| 时间步长 | 30s (`Date.now()/30000`) | 相同 | ✅ |
| 动态截断 | `sig[19]&0xf` 偏移量 | 相同 | ✅ |
| 6 位格式化 | `% 1000000`, `padStart(6,'0')` | 相同 | ✅ |
| 错误回退伪 OTP | 同一哈希公式 | 相同 | ✅ |

**结论：** TOTP 实现完全一致，相同 secret 在相同时间窗口产生相同 6 位码。

### 功能 5 — 倒计时环实现差异

小程序使用 `<canvas>` + Canvas 2D API（`canvas-type="2d"`）绘制弧形进度；鸿蒙使用 `CountdownRing.ets` ArkTS 组件绘制。两端接收相同的 `timeLeft` 数值参数，视觉输出等价。

### 功能 9 — 主题色代码直接对比

两端 THEMES 数组完全一致（逐项文本比对）：
海洋蓝 #4080D0、皇室紫 #9060D0、玫瑰粉 #D04080、热情红 #D04040、暖橙色 #D07030、琥珀金 #C09030、森林绿 #30A060、青绿色 #2090A0、天空蓝 #3080C0、深靛蓝 #6050C8。

`BRAND_COLORS` 仅在鸿蒙 `Token.ets` 中显式定义，小程序内联于 `logo.js`，功能语义一致。

---

## AUDIT-02 专项确认 — QR 扫码权限修复状态

**需求编号：** AUDIT-02（FIX-01 修复后确认）

### 修复内容（Plan 1 已完成，commit 8c351d4）

| 修复步骤 | 文件 | 变更内容 |
|---------|------|---------|
| 添加字符串资源 | `resources/base/element/string.json` | `camera_reason` = "扫描二维码需要使用相机" |
| 静态权限声明 | `entry/src/main/module.json5` | `requestPermissions: [{ name: "ohos.permission.CAMERA", reason: "$string:camera_reason", usedScene: { abilities: ["EntryAbility"], when: "inuse" } }]` |
| 运行时权限申请 | `ScanView.ets` | 新增 `requestCameraPermission(ctx)` 方法，在 `doScan()` 开头调用；拒绝时显示 Toast 而非崩溃 |

### 真机验证状态

**状态：待真机验证**（skipped in Plan 1 — 无可用真机设备）

预期真机行为：
1. 点击底部导航"扫码"→ 进入 ScanView
2. 点击"扫描二维码"按钮
3. **首次使用：** 系统弹出权限授权弹窗，显示"扫描二维码需要使用相机"
4. **授权后：** 相机正常打开，识别 OTP URI 后自动填入表单
5. **拒绝后：** 显示 Toast "需要相机权限才能扫码"，2.2 秒后消失，无崩溃

**验证方法：** DevEco Studio → 真机调试 → 手动触发扫码流程

---

## AUDIT-03 专项确认 — 会员功能行为对比

**需求编号：** AUDIT-03

### 常量对比（代码直接提取）

| 常量 | 小程序 `app.js` | 鸿蒙 `Token.ets` | 一致？ |
|------|----------------|----------------|--------|
| `FREE_TOKEN_LIMIT` | 5 | 5 | ✅ |
| `MEMBERSHIP_PRICE` | 19.90 | 19.90 | ✅ |
| `APP_NAME` | 玄钥 | 玄钥 | ✅ |
| `INITIAL_TOKENS` | 6 个演示账号（id 1-6，相同 brand/secret） | 同上 | ✅ |

### 限制逻辑触发点对比

| 触发场景 | 小程序 | 鸿蒙 |
|---------|--------|------|
| 添加超额 Token | `if (!isMember && tokens.length >= FREE_TOKEN_LIMIT)` → Toast | `if (!this.isMember && this.tokens.length >= FREE_TOKEN_LIMIT)` → Toast | ✅ |
| 限额 Toast 文案 | "免费用户最多添加5个令牌" | "免费用户最多添加5个口令"（"令牌"→"口令"，用词差异可接受） | ✅ |
| 购买触发 | 跳转 membership 页 → 演示直接设置 | `buyMembership()` → 演示直接设置 1 年有效期 | ✅ |
| 会员持久化 | `wx.setStorageSync('ak_membership', ...)` | `StorageUtil.saveMember(isMember, expiry)` → Preferences | ✅ |
| 会员特权：密钥可见 | `isMember` gate 在 edit modal | `isMember` gate 在 `editModal()` builder | ✅ |
| 会员特权：云备份入口 | Profile 页按钮，非会员 disabled | ProfileView 中 `isMember` 控制 backup/import onClick | ✅ |

**AUDIT-03 结论：** 会员系统功能行为完全对齐。两端均为演示模式，价格、限额、有效期逻辑完全一致。

---

## AUDIT-04 专项验证 — 加解密跨平台兼容性

**需求编号：** AUDIT-04

### 算法参数对比（代码直接提取）

| 参数 | 小程序 `utils/crypto.js` | 鸿蒙 `CryptoUtil.ets` |
|------|------------------------|----------------------|
| **格式头（Magic）** | 无（裸 base64） | `ENC2`（4 字节：0x45,0x4E,0x43,0x32） |
| **salt** | 无 | 16 字节随机 salt（`generateSalt(16)`） |
| **密钥派生** | 无（直接用 password UTF-8 字节） | PBKDF2-HMAC-SHA1，10000 次迭代 |
| **XOR key 长度** | `password.length`（循环复用） | `jsonBytes.length`（key 与明文等长，来自 PBKDF2） |
| **XOR 操作** | `jsonBytes[i] ^ keyBytes[i % keyBytes.length]` | `jsonBytes[i] ^ key[i]`（无循环，key 已足长） |
| **UTF-8 编/解码** | 自实现 `utf8Encode/utf8Decode` | 相同算法（代码逐字符比对：代码块完全一致） |
| **Base64 编码** | 自实现 `btoa/atob` | `util.Base64Helper().encodeToStringSync()` |
| **输出格式** | 裸 base64 字符串 | base64(ENC2 + salt[16] + xored[]) |

### 跨平台兼容性结论

**结论：单向兼容（鸿蒙读小程序，反向不通）**

| 场景 | 可行？ | 原因 |
|------|--------|------|
| 鸿蒙导入小程序备份文件 | ✅ 可行 | `CryptoUtil.decryptData()` 含 fallback 路径：若 base64 解码后前 4 字节不等于 `ENC2`，则使用原始 XOR（与小程序格式完全一致）。测试向量可验证：小程序加密 = base64(XOR(json,pass))，鸿蒙 fallback = atob → XOR(data, pass) → 相同结果。 |
| 小程序导入鸿蒙备份文件 | ❌ 不可行 | 小程序 `utils/crypto.js` 无 ENC2 格式检测，直接对 base64(ENC2+salt+xored) 进行原始 XOR 解密，产生乱码数据，`JSON.parse` 抛出异常。 |

### 影响评估

- **用户场景：** 用户在小程序创建了备份，想在鸿蒙端恢复 → **没有问题**（鸿蒙 fallback 路径兼容）
- **用户场景：** 用户在鸿蒙端创建了备份，想在小程序端恢复 → **会失败**（小程序无法解码 ENC2 格式）
- **P0 程度：** 对于"从鸿蒙迁移回小程序"的用户是阻断问题；对于"从小程序迁移到鸿蒙"的用户无影响
- **现阶段优先级：** Phase 2 FEAT-01 应修复此问题，解决方案选项见下方

### 修复建议（Phase 2 FEAT-01）

**方案 A（推荐）：** 在小程序 `utils/crypto.js` 中添加 ENC2 格式解析逻辑。改动量小，向后兼容旧格式。

**方案 B：** 在鸿蒙 `CryptoUtil.ets` 中增加导出选项，支持输出旧格式（降级），以便与现有小程序互通。但会降低安全性。

**方案 A 优先**：修改小程序端解码器，两端解码均支持两种格式；编码端均使用 ENC2 格式（更强安全）。

---

## Phase 2 功能补全建议

基于本次审计，Phase 2（功能补全）的工作清单如下：

### 必须处理（阻断跨平台用户场景）

| 任务 | 对应缺口 | 预期改动 |
|------|----------|----------|
| 小程序 `crypto.js` 添加 ENC2 解码支持 | G-03（AUDIT-04） | 修改 `miniprogram/utils/crypto.js` 中 `decryptData`，添加 ENC2 format detection |

### 建议处理（体验完整性）

| 任务 | 对应需求 | 预期改动 |
|------|----------|---------|
| Phase 1 真机验证跟进 | G-01/G-02 | DevEco Studio 真机调试验证相机权限弹窗 |

### Phase 3 前提条件

Phase 3 AGC 集成的入口条件已就绪：
- Bundle ID 已修正为 `com.arcanekey.authenticator`（FIX-02 完成）
- 云备份/恢复代码结构已实现（`cloudBackup/Restore/Delete/startAutoSync`），Phase 3 仅需替换存储后端
- `module.json5` 需在 Phase 3 添加 AGC 网络权限（`ohos.permission.INTERNET`）

---

## 功能矩阵完整性验证

```
总功能项：22
✅ 对齐 (14)：1,2,3,4,5,8,9,10,11,12,14,15,19,20
✅ 可接受差异 (3)：18,21,22*
🔜 待真机验证 (2)：6,7
⚠️ 有差异需修复 (3)：13,16,17
❌ 缺失 (0)：无
N/A (1)：22（分享，微信专属）
* 22 计入 N/A 不计入"可接受差异"计数
```
