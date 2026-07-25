# HarmonyOS：应用内点评 + 扫码/锁定生命周期 + 搜索聚焦

**日期：** 2026-07-25  
**分支：** `dev-harmonyos`  
**状态：** 已批准（方案 A）  
**范围：** 仅 HarmonyOS 端；不改微信小程序

---

## 1. 背景与问题

### 1.1 需求清单

1. **应用内评分与点评**：接入华为 AppGallery `commentManager`，支持个人中心入口 + 智能弹窗。
2. **扫码与后台冲突**：解锁后进入扫码 → 退出 App 再打开 → 人脸认证因相机被占用失败；PIN 解锁后仍停在相机页。期望：**App 进入后台时退出扫码并释放相机**。
3. **人脸失败自动备用通道**：相机被占用导致人脸失败时，**不要卡在重试**，应直接进入锁屏密码（PIN）解锁。
4. **搜索自动调起键盘**：点击搜索后搜索框自动获得焦点并弹出键盘。

### 1.2 根因

| 现象 | 根因 |
|------|------|
| 后台再进 → 人脸失败「相机被占用」 | `EntryAbility.onBackground()` 为空；`ScanView` 仅在切 tab 时 `stopEmbeddedCamera`，进后台不释放 `customScan` 相机 |
| PIN 解锁后仍是相机页 | 回前台只重锁，`currentTab` 仍为扫码（1） |
| 失败只能点「重试」 | `authenticateSecurity` 只返回 `boolean`；失败统一 `securityAuthFailed`，不区分 BUSY/取消，不自动走 PIN fallback |

### 1.3 相关现有代码

- `EntryAbility.ets`：`onForeground` 递增 `appForegroundSeq`；`onBackground` 空
- `Index.ets`：`@Watch(onForegroundSeqChanged)` 重锁；`runSecurityUnlock` / `runLockFallbackUnlock`；`securityLockOverlay`
- `SecurityUtil.ets`：`userAuth` FACE / FINGERPRINT / PIN
- `ScanView.ets`：`customScan` 内嵌扫码；`isActive` 控制启停
- `HomeView.ets`：搜索 `TextInput` 无 `defaultFocus` / `requestFocus`
- `ProfileView.ets`：菜单项（反馈、关于等），无评分入口

### 1.4 SDK 依据

- **点评**：`@kit.AppGalleryKit` → `commentManager.showCommentDialog(context)`（API 20+ / 6.0.0；工程 target API 23）
- **认证结果码**：`userAuth.UserAuthResultCode`（`SUCCESS`、`FAIL`、`BUSY`、`CANCELED` 等）

---

## 2. 目标与非目标

### 2.1 目标

- 后台时释放扫码相机，并将主界面切回首页（离开扫码）。
- 人脸/指纹在可恢复失败时自动走锁屏密码 fallback（若用户已开启 fallback）。
- 个人中心可主动点评；满足条件时智能弹一次点评（本版本频控）。
- 进入搜索态时自动弹出键盘。

### 2.2 非目标

- 不改微信小程序。
- 不做服务端点评统计、不做复杂评分算法。
- 不重构 Tabs / 全局导航架构。
- 不引入新的第三方库。

---

## 3. 方案选择

**采用方案 A：生命周期收口 + 认证结果分流。**

- 后台：停相机 + `currentTab = 0`
- 认证：返回结果码；符合条件时自动 PIN
- 评分：`commentManager` + 本地频控
- 搜索：`defaultFocus` / `requestFocus`

否决：仅前台抢相机不重置 tab（方案 B）；独立大状态机（方案 C）。

---

## 4. 详细设计

### 4.1 后台退出扫码

**`EntryAbility.onBackground`**

- 递增 `AppStorage` 键 `appBackgroundSeq`（与 `appForegroundSeq` 对称）。

**`Index.ets`**

- `@StorageLink('appBackgroundSeq')` + `@Watch`。
- 回调中：
  1. 若 `currentTab === 1`，设 `currentTab = 0`（触发 `ScanView.isActive = false` → 已有 `stopEmbeddedCamera`）。
  2. 可选清理：`searching = false`、`searchQ = ''`（推荐，避免后台后脏状态）。
- **不在** background 回调里做生物认证（认证只在 foreground 路径）。

**`ScanView`（双保险，推荐）**

- 监听同一 `appBackgroundSeq`（`@StorageProp` 或父组件传 `isActive` 已足够时可不加）。
- 优先依赖 tab 切换；若实现中发现 `Tabs` 未及时卸载，再在 `ScanView` 内直接 `stopEmbeddedCamera`。

**顺序与前台重锁**

1. 用户后台 → 释放相机 + 回首页  
2. 用户前台 → 现有 `appForegroundSeq` → 上锁 → 人脸/指纹（相机已释放）

### 4.2 人脸失败 → 自动 PIN fallback

**`SecurityUtil.ets`**

```ts
export interface AuthOutcome {
  ok: boolean;
  code: number; // userAuth.UserAuthResultCode 或 -1（本地异常）
}

export function authenticateSecurity(mode: SecurityMode): Promise<AuthOutcome>
```

- `onResult`：`ok = (result.result === SUCCESS)`，`code = result.result`
- `catch`：`{ ok: false, code: -1 }`
- 调用方：`SecurityView` 启用开关前验证需兼容新返回值（`outcome.ok`）

**`Index.runSecurityUnlock`**

1. 主模式认证（face / fingerprint / lock）。
2. 成功 → `securityLocked = false`，清 `securityAuthFailed`。
3. 主模式为 face/fingerprint，且 `lockFallbackEnabled`，且 `isSecurityTypeAvailable('lock')`，且结果码属于 **可自动 fallback**：
   - `BUSY`（12500007）
   - `FAIL`（12500001）
   - `GENERAL_ERROR`（12500002）
   - `TIMEOUT`（12500004）
   - 本地异常 `code === -1`  
   → **立即** `runLockFallbackUnlock()`，不先展示「请重试」卡死态。
4. **不自动 fallback**：
   - `CANCELED` / `CANCELED_FROM_WIDGET`：用户主动取消，保留重试 + 底部「解锁」
   - fallback 关闭或 PIN 不可用：仅失败 UI
5. 自动走 PIN 时：不闪「验证失败」文案（保持「正在验证…」或直接进系统 PIN 控件）。

**`SecurityView`**：仅改 `authenticateSecurity` 消费为 `outcome.ok`，行为不变。

### 4.3 应用内评分与点评

**API**

```ts
import { commentManager } from '@kit.AppGalleryKit';
await commentManager.showCommentDialog(context);
```

**入口 UI**

- `ProfileView` 菜单：「意见与建议」与「关于我们」之间（或紧邻反馈）增加 **「给星枢令评分」**。
- 副标题示例：`在应用市场留下评价`。
- 点击 → 调用统一 `showAppComment()` 工具/Index 方法。

**本地持久化（`StorageUtil`）**

| Key | 含义 |
|-----|------|
| `ak_open_count` | 冷启动累计次数 |
| `ak_comment_prompted_ver` | 本版本是否已自动弹过（存 versionName 或 versionCode） |
| `ak_comment_done_ver` | 本版本是否已成功点评 / 已知已评 |

**打开计数**

- 在 `Index` 数据加载完成路径（或 `aboutToAppear` 一次）对 `ak_open_count` +1。
- 仅冷启动/Ability 创建后的首次 UI 出现计一次，避免每次 foreground +1。

**智能弹窗触发（本版本未 `done` 且未 `prompted`）**

1. `open_count >= 3`（在 +1 后检查）
2. 备份成功
3. 导入成功
4. 开通/恢复会员成功

频控：

- 同版本自动弹窗 **最多 1 次**（设 `ak_comment_prompted_ver`）。
- 菜单入口不受 `prompted` 限制，可随时点。
- `showCommentDialog` 成功 → 写 `ak_comment_done_ver`。
- 错误码友好 toast（中文），不崩溃：
  - 未登录华为账号
  - 已点评当前版本 / 一年内已评 / 达上限
  - 系统/连应用市场失败

**实现注意**

- 延迟弹窗（如成功 toast 后 500–800ms），避免与其他 modal 抢焦点。
- 安全锁开启且 `securityLocked` 时不自动弹点评；解锁后再根据「待弹」标志弹一次（可选简化：锁定期间跳过本次触发，不排队）。

### 4.4 搜索自动键盘

**`HomeView.ets`**

- 搜索 `TextInput`：
  - `.id('home_search_input')`
  - `.defaultFocus(true)`（`searching === true` 时该节点才挂载，适合 defaultFocus）
- 若实机 defaultFocus 不稳：`@Watch('searching')` 在 true 时 `focusControl.requestFocus('home_search_input')`（下一帧/`setTimeout(0)`）。

退出搜索：现有逻辑清空即可；系统会收起键盘。

---

## 5. 文件改动清单

| 文件 | 改动 |
|------|------|
| `harmonyos/.../entryability/EntryAbility.ets` | `onBackground` 递增 `appBackgroundSeq`；`onCreate` 初始化键 |
| `harmonyos/.../pages/Index.ets` | background 回首页；认证 fallback；点评触发与入口回调 |
| `harmonyos/.../utils/SecurityUtil.ets` | `AuthOutcome`；返回结果码 |
| `harmonyos/.../views/SecurityView.ets` | 使用 `outcome.ok` |
| `harmonyos/.../views/ScanView.ets` | （按需）background 停相机双保险 |
| `harmonyos/.../views/HomeView.ets` | 搜索聚焦 |
| `harmonyos/.../views/ProfileView.ets` | 「给星枢令评分」菜单 |
| `harmonyos/.../utils/StorageUtil.ets` | open count / comment 版本键读写 |
| （可选）`harmonyos/.../utils/CommentUtil.ets` | 封装 `showCommentDialog` + 错误映射 |

---

## 6. 错误处理

| 场景 | 行为 |
|------|------|
| 后台时不在扫码 tab | 仅可选清理搜索；不改 tab |
| 人脸 CANCELED | 不自动 PIN；显示重试 + 解锁按钮 |
| fallback 关闭 | 仅失败 UI |
| 点评未登录华为账号 | toast 提示登录华为账号 |
| 点评已评/频控 | toast 简短说明；写 done/prompted 避免死循环弹窗 |
| 点评 API 异常 | toast「暂时无法打开评价」+ 日志 |

---

## 7. 验收标准

1. **扫码 + 后台**：扫码页 → 回桌面 → 再进 App → 人脸可正常（相机不占用）；解锁后在 **首页**，不在相机页。
2. **模拟相机占用**（若仍失败）：人脸失败后 **自动** 出 PIN，无需先点重试。
3. **用户取消人脸**：仍可点「重新验证」或底部「解锁」，不强制 PIN。
4. **个人中心**：点「给星枢令评分」调起系统点评对话框（真机 + 已上架/测试条件以华为文档为准）。
5. **智能弹窗**：打开 ≥3 次 / 备份成功 / 导入成功 / 会员成功 各路径可触发；同版本仅自动 1 次。
6. **搜索**：点底栏搜索后键盘自动弹出，可直接输入。

---

## 8. 测试计划

- 真机：开启人脸 + 锁屏密码 fallback；扫码 → 后台 → 前台完整路径。
- 真机：关闭 fallback，确认失败 UI 仍可用。
- 真机：搜索聚焦；点评入口（需华为账号与 AppGallery 环境）。
- 编译：`hvigorw assembleApp`（API 23）无 ArkTS 错误。

---

## 9. 风险与说明

- `commentManager` 在未上架/非正式环境可能失败；需优雅降级。
- `defaultFocus` 在部分机型行为差异 → 预留 `requestFocus` 兜底。
- 自动 fallback 范围含 `FAIL`：用户人脸真失败也会进 PIN（符合「不要卡在重试」；取消仍不强制）。

---

## 10. 决策记录

| 决策 | 选择 |
|------|------|
| 总体方案 | A：生命周期收口 + 结果码分流 |
| 点评入口 | 个人中心 + 智能弹窗 |
| 智能触发 | 打开≥3 / 备份成功 / 导入成功 / 会员成功 |
| 后台扫码 | 释放相机 + `currentTab = 0` |
| 自动 PIN | face/fingerprint 非取消类失败 + fallback 开启 |
