# HarmonyOS 锁屏重做 + 安全兜底解锁 + 文案链接改动

日期：2026-07-18
分支：dev-harmonyos

## 目标

1. 重做应用锁屏遮罩（`Index.ets` 的 `securityLockOverlay()`）的视觉设计，用产品 logo 取代当前的 🔒 emoji + 「验证以继续」文案。
2. 在「我的>安全」新增「解锁失败时启用锁屏密码解锁」开关，作为人脸/指纹验证失败后的 PIN 兜底手段，并联动锁屏页底部「解锁」按钮的显隐与可点击状态。
3. 三处文案/链接微调：备份数据、导入备份提示文案，以及关于我们页的官网跳转链接。

## Part A：锁屏遮罩重做

### 涉及文件
- `entry/src/main/ets/pages/Index.ets`（`securityLockOverlay()` builder，约 1715-1748 行；及相关 state）
- `entry/src/main/ets/utils/StorageUtil.ets`（新增 `LOCK_FALLBACK_KEY` 读写函数）
- `entry/src/main/ets/views/SecurityView.ets`（新增开关行）

### 视觉结构（自上而下）
1. 背景层：从 `BRAND_ICONS`（`model/BrandIcons.ets`）中随机抽取 6~10 个图标，以约 8% 透明度、随机位置与随机大小（32~56vp 之间）散布在整个锁屏背景上，作为装饰点缀，不遮挡中心内容。每次锁屏遮罩显示时重新随机一次即可（不需要跨会话持久化）。
2. 中心主体：
   - `Image($r('app.media.logo_img'))`，尺寸约 88x88，圆角 20，带阴影（与 `AboutView.ets` 品牌区风格一致），该图片资源本身在明暗模式下均可正常显示，无需额外适配。
   - 主体下方文字「星枢令已锁定」，字号 20，字重 700。
   - 再下方一行动态状态文字：
     - 默认（验证进行中）：「正在验证…」
     - 若本轮默认方式验证失败：「验证失败，请重试」
   - 状态文字下方一个不起眼的文字链接「重新验证」（字号 13，弱化配色，非按钮样式），任何时候可点击，点击后重新触发默认方式验证（`authenticateSecurity(this.securityMode)`）。
3. 底部固定区域：「解锁」大按钮，距屏幕底部 50vp（`.position({x:0,y:'100%'}).translate({y:-50})`，或等效实现）。
   - 仅当 `lockFallbackEnabled === true` **且** `securityMode` 为 `face` 或 `fingerprint` 时渲染；`securityMode` 为 `lock`（或 `off`，此时锁屏页本就不会出现）时该按钮整体不出现——与 Part B 中 `SecurityView` 开关的显示条件保持一致。
   - 渲染时默认灰态不可点击；当本轮默认方式验证失败后（即状态文字已切换为「验证失败，请重试」的同一时刻）变为可点击的强调色按钮。
   - 点击后直接调用 `authenticateSecurity('lock')`（跳过人脸/指纹，直接走系统 PIN 验证）。

### 状态管理
- `Index.ets` 新增 `@State lockFallbackEnabled: boolean` 和 `@State securityAuthFailed: boolean`（本轮默认方式是否已失败，用于驱动状态文字与底部按钮可点状态；每次开始新一轮验证时重置为 false）。
- `loadData()` 中与 `securityMode` 一起加载 `lockFallbackEnabled = await loadLockFallbackEnabled()`。
- `runSecurityUnlock()` 逻辑调整：验证前 `securityAuthFailed = false`；`authenticateSecurity` 返回 false 时设置 `securityAuthFailed = true`（而不仅仅设置 `securityLocked`）。
- 「重新验证」链接与「解锁」按钮均需保留现有的 `securityUnlocking` 防抖，避免并发触发系统验证弹窗。

## Part B：安全设置新开关

### 涉及文件
- `entry/src/main/ets/views/SecurityView.ets`
- `entry/src/main/ets/utils/StorageUtil.ets`

### 逻辑
- 新增存储函数：
  ```ts
  const LOCK_FALLBACK_KEY = 'ak_lock_fallback_enabled';
  export async function loadLockFallbackEnabled(): Promise<boolean> // 默认 true（无记录时）
  export async function saveLockFallbackEnabled(enabled: boolean): Promise<void>
  ```
- `SecurityView` 新增 `@Prop lockFallbackEnabled: boolean` 和 `onLockFallbackChange` 回调，向上与 `Index.ets` 的新 state 同步（与现有 `mode`/`onModeChange` 模式一致）。
- 显示条件：仅当 `this.mode === 'face' || this.mode === 'fingerprint'` 时，在现有三个互斥开关下方追加一行新开关「解锁失败时启用锁屏密码解锁」。`mode` 为 `off` 或 `lock` 时该行不渲染。
- 可用性：调用 `isSecurityTypeAvailable('lock')` 判断设备是否已设置锁屏密码；不可用时开关置灰（不可点击），并在页面底部现有提示文字区域追加一行「锁屏密码未设置」。
- 默认值：`loadLockFallbackEnabled()` 无历史记录时返回 `true`。
- 交互：切换开关直接调用 `saveLockFallbackEnabled()` 并通过回调通知 `Index.ets` 更新 `lockFallbackEnabled` state（无需二次验证，这是纯偏好开关，不涉及新增认证能力）。

## Part C：文案/链接改动

| 位置 | 修改前 | 修改后 |
|---|---|---|
| `ProfileView.ets:143` | 加密备份到云端 | 加密备份数据到本地存储 |
| `ProfileView.ets:162` | 从云端恢复 | 从本地备份恢复 |
| `Index.ets` `importModal()`，「备份内容」标签下 | （无） | 新增一行小字：支持Proton Authenticator备份文件或格式明文导入 |
| `AboutView.ets:307` `openUrl` 调用参数 | `https://www.xiaoanhome.xyz` | `https://www.xiaoanhome.xyz/arcanekey` |
| `AboutView.ets:174` 静态展示文字「官网：www.xiaoanhome.xyz」 | 不变 | 不变（仅为文字展示，非跳转链接，明确保持原样） |

## 不做的事（YAGNI）

- 不改动 `SecurityUtil.ets` 里系统验证弹窗的 `widgetParam.title`（「验证以继续」），这是系统组件自带弹窗标题，与本次重做的自定义遮罩无关。
- 不做跨平台同步（微信小程序无对应的系统级锁屏能力），本次改动仅限 `harmonyos/`。
- 不持久化背景装饰图标的随机结果，每次锁屏展示重新随机即可。
- 不新增「记住选择」之类的额外偏好，兜底开关就是唯一的持久化状态。

## 测试计划

无自动化测试基础设施（项目无测试框架），按 CLAUDE.md 要求以 DevEco Studio 真机/模拟器手动验证 + `hvigorw assembleApp` 构建通过为准：

- 主方式=人脸，兜底开关开：人脸失败后「解锁」按钮可点，点击后直接拉起 PIN。
- 主方式=人脸，兜底开关关：人脸失败后无「解锁」按钮，仅「重新验证」可用。
- 主方式=锁屏密码：安全页不显示兜底开关；锁屏页无「解锁」按钮（因 `lockFallbackEnabled` 对该 mode 不生效，需在 `Index.ets` 侧也保证仅 face/fingerprint 时渲染该按钮，与 SecurityView 显示条件一致）。
- 设备未设置锁屏密码：安全页兜底开关置灰，底部提示「锁屏密码未设置」。
- 备份数据/导入备份页文案核对；关于我们>网站点击后跳转到 `/arcanekey` 路径。
