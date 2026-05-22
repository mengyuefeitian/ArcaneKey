# Phase 1: 缺陷修复 + 功能审计 — Research

**Researched:** 2026-05-19
**Domain:** HarmonyOS ArkTS — 权限声明、Bundle ID、构建产物管理、功能差异审计
**Confidence:** HIGH（权限格式、Bundle ID 位置、gitignore 范围均由代码库直接确认；ScanKit 权限格式经多源交叉验证）

---

## 摘要

Phase 1 包含三个独立的配置/文档修复任务，以及一个系统性功能审计产出物。

**权限修复（FIX-01）** 是三个修复中技术风险最高的。`ScanView.ets` 调用 `scanBarcode.startScanForResult()`，但 `module.json5` 中没有 `requestPermissions` 数组——无任何权限声明。ScanKit 需要 `ohos.permission.CAMERA`，且该权限属于 user_grant 类型，必须同时完成静态声明（module.json5）和运行时动态申请（`abilityAccessCtrl.requestPermissionsFromUser()`）两步。当前 `ScanView.doScan()` 没有任何权限检查逻辑，只有一个通用 `try/catch`，导致真机上权限拒绝时用户仅看到通用错误提示"扫码失败，请重试"。

**Bundle ID 修复（FIX-02）** 是纯配置变更，影响面清晰：`harmonyos/AppScope/app.json5` 中的 `bundleName` 是唯一需要修改的权威来源（`vendor` 字段同步修改）。`.hvigor` 缓存文件中也出现了旧 bundle name，但这些文件应被 .gitignore 排除，无需手动更新。

**.gitignore 修复（FIX-03）** 比预期工作量更大。不仅需要新建 `.gitignore` 文件，还需要用 `git rm --cached` 将已跟踪的 177 个构建产物文件从 git 索引中移除（`.hvigor/` 29 个、`entry/build/` 83 个、`oh_modules/` 58 个、`.idea/` 11 个、`.DS_Store` 若干）。这是一次性清理，之后 .gitignore 会自动阻止新产物被跟踪。

**功能审计（AUDIT-01）** 对照已验证的小程序 feature baseline 逐项核查鸿蒙实现。基于代码库分析，已确认大多数功能已实现；主要差距是：相机权限缺失（FIX-01 解决）、云备份是本地代理（Phase 3 解决）、WeChat 专属的两步登录/手机绑定在鸿蒙侧已替换为设备账号登录（可接受差异）。

**首要建议：** 按 FIX-01 → FIX-02 → FIX-03 → AUDIT-01 顺序执行；FIX-01 包含运行时权限申请代码变更，必须在真机上验证。

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| 相机权限声明 | 配置层（module.json5） | 运行时代码（ScanView.ets） | 静态声明在配置，动态申请在视图层 |
| Bundle ID | 配置层（AppScope/app.json5） | — | 唯一权威来源，IDE 缓存跟随变更 |
| .gitignore | 仓库根目录配置 | — | 一次性根目录文件 |
| 功能审计产出 | 文档层（.planning/） | — | 为规划者消费，不影响源代码 |

---

## 详细发现

### FIX-01: 相机权限（ohos.permission.CAMERA）

#### 问题的完整形态

`ScanView.ets` 直接调用 `scanBarcode.startScanForResult(ctx, options)`，无任何权限检查。当前 `module.json5` 没有 `requestPermissions` 数组（代码库直接确认）。

HarmonyOS 权限模型有两种类型：
- `system_grant`：安装时自动授予，无需运行时请求
- `user_grant`：必须在运行时弹窗请求用户授权，`ohos.permission.CAMERA` 属于此类 [CITED: dev.to/caojingcode/permission-application-in-harmonyos-49jf]

`user_grant` 权限要求同时完成：
1. **静态声明**：在 `module.json5` 的 `requestPermissions` 数组中声明
2. **运行时申请**：在使用前调用 `abilityAccessCtrl.requestPermissionsFromUser()`

仅完成静态声明不够——不调用运行时申请，系统不会弹出授权弹窗，权限始终为 DENIED。

#### module.json5 精确格式

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    // ... 现有字段 ...
    "requestPermissions": [
      {
        "name": "ohos.permission.CAMERA",
        "reason": "$string:camera_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

`reason` 字段对 `user_grant` 权限是**必填项**，必须引用 string 资源（不能硬编码字符串）。[CITED: dev.to/caojingcode/permission-application-in-harmonyos-49jf]

#### 对应 string 资源

需在 `harmonyos/entry/src/main/resources/base/element/string.json` 中添加：

```json
{
  "name": "camera_reason",
  "value": "扫描二维码需要使用相机"
}
```

#### ScanView.ets 运行时权限申请代码

`doScan()` 方法需在调用 `startScanForResult` 前加入权限检查：

```typescript
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

private async requestCameraPermission(ctx: common.UIAbilityContext): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager();
  const permission: Permissions = 'ohos.permission.CAMERA';
  try {
    const result = await atManager.requestPermissionsFromUser(ctx, [permission]);
    return result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  } catch (e) {
    return false;
  }
}

private async doScan(enableAlbum: boolean): Promise<void> {
  this.scanning = true;
  try {
    const ctx = getContext(this) as common.UIAbilityContext;
    // 申请相机权限
    const granted = await this.requestCameraPermission(ctx);
    if (!granted) {
      this.scanErrMsg = '需要相机权限才能扫码';
      setTimeout(() => { this.scanErrMsg = ''; }, 2200);
      this.scanning = false;
      return;
    }
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.QR_CODE],
      enableMultiMode: false,
      enableAlbum: enableAlbum
    };
    const result: scanBarcode.ScanResult = await scanBarcode.startScanForResult(ctx, options);
    if (result?.originalValue) this.parseOtpUri(result.originalValue);
    else { this.scanErrMsg = '未识别到二维码'; setTimeout(() => { this.scanErrMsg = ''; }, 2200); }
  } catch (e) {
    this.scanErrMsg = enableAlbum ? '选择图片失败，请重试' : '扫码失败，请重试';
    setTimeout(() => { this.scanErrMsg = ''; }, 2200);
  }
  this.scanning = false;
}
```

**注意：** `when: "inuse"` 表示仅在应用前台时使用相机（推荐），不使用 `"always"`（后台使用需要 system 级别申请）。[ASSUMED: `when: "inuse"` 是扫码场景标准配置，基于鸿蒙权限文档最佳实践，未通过 API 23 官方文档直接确认]

---

### FIX-02: Bundle ID 修正

#### 受影响文件

代码库扫描结果（排除构建缓存）：

| 文件 | 当前值 | 需修改 |
|------|--------|--------|
| `harmonyos/AppScope/app.json5` | `"bundleName": "com.example.arcankey"` | 是 |
| `harmonyos/AppScope/app.json5` | `"vendor": "example"` | 是 |
| `harmonyos/.idea/.deveco/project.cache.json` | `BUNDLE_NAME: com.example.arcankey` | 否（.gitignore 后排除） |
| `harmonyos/.hvigor/cache/project-config.json` | `bundleName: com.example.arcankey` | 否（.gitignore 后排除） |

**唯一需要手动修改的源文件：`harmonyos/AppScope/app.json5`**（2 处：`bundleName` 和 `vendor`）

#### 推荐 Bundle ID

用户尚未指定。基于项目名称推荐：

```
com.arcanekey.authenticator
```

命名逻辑：`com.<product-name>.<app-type>`，符合 HarmonyOS 反域名规范。[ASSUMED: 用户没有注册域名，使用产品名作为组织标识符，需用户确认]

**AppGallery Connect 要求：** `com.example` 前缀为示例占位符，AGC 提交时会被拒绝。生产 Bundle ID 必须在 AGC 控制台创建应用时同步注册（bundle name 与 AGC 应用配置必须完全一致）。[CITED: developer.huawei.com AGC help]

修改后 `app.json5`：

```json5
{
  "app": {
    "bundleName": "com.arcanekey.authenticator",
    "vendor": "arcanekey",
    "versionCode": 1000000,
    "versionName": "1.0.0",
    "icon": "$media:app_icon",
    "label": "$string:app_name"
  }
}
```

---

### FIX-03: .gitignore

#### 已跟踪的构建产物（需 git rm --cached）

当前 git 已跟踪 **177 个构建产物文件**：

| 目录 | 文件数 | 说明 |
|------|--------|------|
| `harmonyos/.hvigor/` | 29 | hvigor 构建缓存、报告、日志 |
| `harmonyos/entry/build/` | 83 | 编译缓存、.msgpack、生成文件 |
| `harmonyos/oh_modules/` | 58 | ohpm 依赖包（等同 node_modules） |
| `harmonyos/.idea/` | 11 | IDE 项目配置（部分可提交，部分不可） |
| `.DS_Store`（根/子目录） | 4 | macOS 目录元数据 |

**必须执行 `git rm --cached` 批量移除**，再添加 .gitignore，否则已跟踪文件不会被忽略。

#### .gitignore 模板

```gitignore
# macOS
.DS_Store
**/.DS_Store

# HarmonyOS 构建缓存 (DevEco Studio / hvigor)
harmonyos/.hvigor/
harmonyos/entry/build/
harmonyos/build/

# ohpm 依赖包 (等同 node_modules，不应提交)
harmonyos/oh_modules/
harmonyos/*/oh_modules/

# IDE 生成文件 (DevEco Studio)
harmonyos/.idea/.deveco/
harmonyos/.idea/workspace.xml
harmonyos/.idea/usage.statistics.xml

# 本地配置（不含 local.properties 如有签名信息）
harmonyos/local.properties

# HarmonyOS 构建产物
*.hap
*.app
*.har

# WeChat 小程序构建产物
miniprogram/miniprogram_npm/

# Node.js（如有）
node_modules/
```

**关于 `.idea/` 的处理方针：**
- `harmonyos/.idea/modules.xml`、`harmonyos/.idea/.gitignore` 等轻量 IDE 配置可选择保留提交
- `harmonyos/.idea/.deveco/` 目录（含 `.cache.json`、`project.cache.json`）属于机器生成的缓存，应排除
- 当前 `harmonyos/.idea/` 下有 11 个被跟踪文件，清理时逐一判断即可

[VERIFIED: codebase grep] — 以上路径均经 `git ls-files` 直接确认存在于跟踪列表中。

---

### AUDIT-01: 功能差异审计方法论

#### 审计维度

FEATURE-AUDIT.md 应包含以下列：

| 列名 | 说明 |
|------|------|
| 功能 | 功能名称 |
| 优先级 | P0（核心功能）/ P1（体验）/ P2（边缘） |
| 小程序状态 | ✅ 已验证 / ⚠️ 已知问题 |
| 鸿蒙实现文件 | 具体到文件和方法 |
| 鸿蒙状态 | ✅ 对齐 / ⚠️ 差异 / ❌ 缺失 |
| 差异说明 | 如有差异，说明原因 |
| Phase | 在哪个 Phase 修复 |

#### 基于代码分析的预填审计表

以下是基于代码库直接分析的审计结果：

| 功能 | 优先级 | 小程序状态 | 鸿蒙实现文件 | 鸿蒙状态 | 差异说明 | Phase |
|------|--------|-----------|------------|---------|---------|-------|
| TOTP 代码生成（30s 轮转） | P0 | ✅ | `TOTP.ets`, `Index.ets:refreshOtp()` | ✅ 对齐 | — | — |
| 多 Token 管理（增删改查） | P0 | ✅ | `Index.ets`, `HomeView.ets` | ✅ 对齐 | — | — |
| Token 搜索 | P0 | ✅ | `Index.ets:searching/searchQ` | ✅ 对齐 | — | — |
| OTP 复制 | P0 | ✅ | `Index.ets:copyCode()` | ✅ 对齐 | — | — |
| 倒计时环 | P0 | ✅ | `CountdownRing.ets` | ✅ 对齐 | Canvas vs SVG 实现不同，视觉效果需对比 | — |
| QR 扫码自动添加 Token | P0 | ✅ | `ScanView.ets:doScan()` | ⚠️ 权限缺失 | 无 CAMERA 权限声明，真机失败 | Phase 1 FIX-01 |
| 从相册选图识别 | P0 | ✅ | `ScanView.ets` `enableAlbum:true` | ⚠️ 同上 | 同 FIX-01 | Phase 1 FIX-01 |
| 手动输入 Token | P0 | ✅ | `ScanView.ets tab=2` | ✅ 对齐 | — | — |
| 10 种主题色 | P1 | ✅ | `Token.ets:THEMES`, `Index.ets:themeModal()` | ✅ 对齐 | — | — |
| 会员系统（¥19.90/年，限5个 Token） | P0 | ✅ | `Index.ets:buyMembership()`, `StorageUtil.ets:saveMember()` | ✅ 对齐（演示） | 均为演示模式，均设1年有效期 | — |
| 文件备份（XOR 加密导出） | P0 | ✅ | `Index.ets:doBackup()`, `CryptoUtil.ets` | ✅ 对齐 | 小程序用 `wx.chooseMedia` → `FileSystemManager`；鸿蒙用 `DocumentViewPicker.save()` | — |
| 文件导入（XOR 解密） | P0 | ✅ | `Index.ets:doImport()`, `CryptoUtil.ets` | ✅ 对齐 | 导入接口不同，加解密算法一致 | — |
| 跨平台加解密兼容性 | P0 | ✅ | `CryptoUtil.ets` vs `utils/crypto.js` | ⚠️ 待验证 | 算法应一致（均 ENC2 + PBKDF2-XOR），但需实际互操测试 | Phase 1 AUDIT-04 |
| 密钥可见性切换（会员） | P1 | ✅ | `Index.ets:editSecretVisible` | ✅ 对齐 | — | — |
| 差异化删除（本地/云） | P1 | ✅ | `Index.ets:deleteConfirmDialog()` | ✅ 对齐（仅本地语义） | 鸿蒙无真实云，但代码逻辑结构一致 | Phase 3 |
| 云备份/恢复（会员） | P0 | ✅ wx.cloud | `Index.ets:cloudBackup/Restore()` | ⚠️ 本地 Preferences 代理 | 语义一致，实现不真实（同设备 Preferences） | Phase 3 |
| 每小时自动同步 | P0 | ✅ | `Index.ets:startAutoSync()` | ⚠️ 有计时器但无真实云 | `setInterval(60*60*1000)` 已实现，但目标是本地 Preferences | Phase 3 |
| 登录（微信 vs 鸿蒙账号） | P1 | ✅ 微信 getPhoneNumber | `Index.ets:loginModal()` | ✅ 可接受差异 | 鸿蒙改为设备账号 demo，无需与小程序对齐 | — |
| 底部导航（浮动胶囊） | P1 | ✅ | `Index.ets:bottomNav()` | ✅ 对齐 | 实现方式不同（小程序自定义组件 vs ArkTS @Builder） | — |
| Toast 通知 | P1 | ✅ 自定义组件 | `Index.ets:toast()` | ✅ 对齐 | 小程序用独立 toast 组件，鸿蒙用 @Builder 内联实现 | — |
| 反馈功能 | P2 | ✅ 云函数邮件 | `FeedbackView.ets` | ✅ 可接受差异 | 鸿蒙用 `mailto:` intent，功能语义一致 | — |
| Logo 品牌色 | P2 | ✅ | `Logo.ets:BRAND_COLORS` | ✅ 对齐 | `BRAND_COLORS` 仅在 HarmonyOS 侧有；小程序内联，功能一致 | — |
| 分享功能（v1.1） | — | ✅ 微信分享 | 不需要 | N/A | 微信专属 API，明确不做 | 不做 |

**P0 缺口摘要：**
1. QR 扫码（相机权限）→ Phase 1 FIX-01
2. 云备份（真实云）→ Phase 3 AGC
3. 加解密跨平台兼容性 → Phase 1 AUDIT-04 验证

---

## 实施风险与缓解措施

### 风险 1：FIX-01 真机验证缺口
- **风险：** 权限修复只能在真实设备上验证；模拟器不触发权限弹窗
- **影响：** 无法在 CI/本地模拟器上自动化验证
- **缓解：** 在 DevEco Studio 真机调试时手动执行 AUDIT-02；FEATURE-AUDIT.md 中明确标记"真机验证必需"

### 风险 2：git rm --cached 误操作
- **风险：** `git rm --cached` 不当使用可能误删源代码文件
- **影响：** 不可逆，若无备份则代码丢失
- **缓解：** 使用精确路径（`git rm -r --cached harmonyos/.hvigor/ harmonyos/entry/build/ harmonyos/oh_modules/`），先 `git status` 确认影响范围，再提交

### 风险 3：Bundle ID 修改后签名失效
- **风险：** Bundle ID 改变后，若有已签名的调试证书，需要重新关联
- **影响：** 当前为开发阶段，尚未提交 AGC，影响极小
- **缓解：** FIX-02 后若 DevEco Studio 弹出证书警告，在 AGC 控制台重新创建应用并更新签名配置

### 风险 4：加解密跨平台兼容性未验证
- **风险：** `CryptoUtil.ets`（鸿蒙）与 `utils/crypto.js`（小程序）的 PBKDF2-XOR 实现可能在 salt 长度、迭代次数或字符编码上存在细微差异
- **影响：** P0 功能——用户可能无法在两个平台间互通备份文件
- **缓解：** AUDIT-04 任务：用小程序加密一段已知数据，用鸿蒙解密；反向验证同理

---

## 不需要研究的项目

以下 CONCERNS.md 中的技术债不在 Phase 1 范围内：
- `Index.ets` 重构（单独议题，Phase 2+ 考虑）
- SHA-1 实现去重（Phase 2 重构期处理）
- 无测试覆盖（不做）
- AES 替换 XOR（明确不做）
- 真实 IAP 支付（明确不做）

---

## 环境可用性

| 依赖 | 必需项 | 可用 | 备注 |
|------|--------|------|------|
| DevEco Studio | FIX-01, FIX-02 编译验证 | — | 用户环境，假设可用 |
| HarmonyOS 真机 | FIX-01 相机权限验证 | — | 仅真机可验证 |
| Git | FIX-03 git rm --cached | ✓ | 已确认为 git 仓库 |
| 文本编辑器 | 所有 FIX + AUDIT 文档 | ✓ | — |

---

## 验证架构

`nyquist_validation: false` — 跳过测试框架章节。

手动验证检查清单：
- FIX-01：DevEco Studio 真机 → 扫码 tab → 点击"扫描二维码" → 系统弹出相机权限授权弹窗
- FIX-02：`AppScope/app.json5` 中 `bundleName` 不含 `com.example`
- FIX-03：`git status` 显示 `.hvigor/`、`entry/build/`、`oh_modules/` 为 untracked（非 staged/tracked）
- AUDIT-01：`.planning/FEATURE-AUDIT.md` 存在，每行有明确状态标记

---

## 来源

### 一级来源（HIGH confidence）
- 代码库直接扫描 — `module.json5`、`ScanView.ets`、`AppScope/app.json5`、`git ls-files`
- `.planning/codebase/CONCERNS.md` — Platform-Specific Risks 章节，相机权限与 Bundle ID 问题均已记录

### 二级来源（MEDIUM confidence）
- [Permission application in HarmonyOS - DEV Community](https://dev.to/caojingcode/permission-application-in-harmonyos-49jf) — `requestPermissions` 格式、`reason` 字段必填性
- [HarmonyOS QR Code Tool: Dev Notes & Pitfalls - DEV Community](https://dev.to/lovehmos/harmonyos-qr-code-tool-dev-notes-pitfalls-430k) — ScanKit 实践陷阱
- [Complete Guide to Creating an App in AppGallery Connect - DEV Community](https://dev.to/xhunmon/complete-guide-to-creating-an-app-in-appgallery-connect-o81) — Bundle ID 命名约定

### 三级来源（ASSUMED）
- `when: "inuse"` 是扫码场景推荐值（未通过 HarmonyOS API 23 官方文档确认，基于训练数据最佳实践）
- 推荐 Bundle ID `com.arcanekey.authenticator`（用户尚未指定，基于反域名规范建议）

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `when: "inuse"` 适用于相机扫码场景 | FIX-01 权限格式 | 若需 `"always"`，权限申请可能被系统拒绝；实际影响极小，`"inuse"` 是更严格的限制 |
| A2 | 推荐 Bundle ID 为 `com.arcanekey.authenticator` | FIX-02 | 用户可能已有注册域名或偏好其他命名，需在执行前确认 |
| A3 | `.idea/modules.xml` 和 `.idea/.gitignore` 可安全保留提交 | FIX-03 .gitignore | 若 IDE 版本差异导致冲突，重新生成即可 |

---

## Open Questions

1. **Bundle ID 最终确认**
   - 已知：当前为 `com.example.arcankey`，需修改
   - 待确认：用户是否已在 AGC 控制台注册应用？若已注册，必须使用 AGC 控制台中的 Bundle ID
   - 建议：执行前询问用户是否有 AGC 账号及已注册的 Bundle ID；若无，使用 `com.arcanekey.authenticator`

2. **AUDIT-04 跨平台加解密验证方式**
   - 已知：两端均实现 ENC2 + PBKDF2(10000) + XOR 格式，算法设计相同
   - 待确认：是否有测试数据可用于验证跨平台解密成功
   - 建议：Phase 1 计划中加入"使用固定测试向量验证加解密往返"任务

---

*Research date: 2026-05-19*
*Valid until: 2026-06-18（HarmonyOS API 文档更新周期约 30 天）*
