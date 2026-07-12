# HarmonyOS：会员云同步开关 · 安全锁 · 图标与扫码体验

**Date:** 2026-07-12  
**Branch:** `dev-harmonyos`  
**Scope:** `harmonyos/` only（不改微信小程序）  
**Delivery:** 风险分层三波（Wave 1 → 2 → 3）

## Goal

在鸿蒙端完成六项体验与能力增强：会员页云同步可控、应用级安全锁、验证码复制修正、品牌图标扩充与缩放、扫码在权限通过后自动启动。

## Decisions (from brainstorming)

| Topic | Decision |
|-------|----------|
| Delivery | **A** 三波：打磨 → 云同步开关 → 安全 |
| Security when | **B** 冷启动 + 回前台 |
| Security fail | **A** 全屏锁定 + 点击重试（不杀进程） |
| Cloud sync toggle location | **A** 仅开通会员/会员特权弹窗 |
| Cloud sync off meaning | **A** 仅停自动同步；手动备份/导入仍可用 |
| Security audience | **B** 仅已登录可配置；未登录引导登录 |
| Scan auto-start | 以相机权限是否已授权为准；已授权则每次**重新进入**扫码页自动开；同页关掉系统扫码后需手动再点 |

## Non-goals

- 微信小程序同步改动
- App 内自建 PIN / 密码（仅系统人脸 / 指纹 / 锁屏密码）
- 敏感操作二次验证（本需求仅冷启动与回前台）
- 关闭云同步时禁用手动备份/导入
- 新建 hypium 测试工程（与仓库现状一致，真机/手动验证）

## Architecture overview

```
Wave 1  polish
  TokenCard.ets              下一个区域 → copy next
  BrandIcons.ets             scale + 新品牌
  rawfile/brand-icons/       新 SVG
  ScanView.ets               已授权则进入自动 doScan

Wave 2  cloud sync preference
  StorageUtil                ak_cloud_sync
  Index membershipModal      Toggle + 灰态
  Index / SyncUtil           自动同步门闩

Wave 3  security
  StorageUtil                ak_security_mode
  SecurityView（新）          我的 → 安全
  SecurityUtil（新）          能力检测 + UserAuth
  Index / lifecycle          冷启动 & onForeground 锁遮罩
```

### Persistence keys

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `ak_cloud_sync` | boolean | 会员 `true` / 非会员 `false` | 开通成功瞬间强制写 `true` |
| `ak_security_mode` | `'off' \| 'face' \| 'fingerprint' \| 'lock'` | `'off'` | 三选一或关闭 |

---

## Wave 1 — 打磨

### 1.1 下一个验证码复制

**Problem:** `TokenCard` 下半区整块 `onClick` 复制 `otp.current`，用户点「下一个」区域仍复制当前码。

**Change:**
- 左侧当前码区域 → `onCopy(otp.current, brand)`
- 右侧「下一个 + next 码」区域 → `onCopy(otp.next, brand)`
- 长按菜单「复制口令 / 复制下一个口令」保持现有行为

**Files:** `harmonyos/entry/src/main/ets/components/TokenCard.ets`

### 1.2 图标缩放

- `binance`：`scale: 1.3`
- `netease-mail`：`scale: 1.3`

沿用 `BrandIconConfig.scale` + `Logo.ets` 现有渲染路径。

**Files:** `harmonyos/entry/src/main/ets/model/BrandIcons.ets`

### 1.3 新增品牌图标

源文件（Downloads）→ `harmonyos/entry/src/main/resources/rawfile/brand-icons/`，文件名 id 化：

| id | 源文件 | 建议 keywords（含别名） |
|----|--------|-------------------------|
| meta | Meta.svg | meta |
| figma | Figma.svg | figma |
| linkedin | linkin.svg | linkedin, linkin, 领英 |
| okta | okta.svg | okta |
| nvidia | 英伟达.svg | nvidia, nvdia, 英伟达 |
| discord | discord.svg | discord |
| dropbox | dropbox.svg | dropbox |
| cloudflare | cloudflare.svg | cloudflare |
| snapchat | Snapchat.svg | snapchat |
| coinbase | coinbase.svg | coinbase |
| crypto | Crypto.svg | crypto, crypto.com |
| steam | steam.svg | steam, stream |
| terminal | 终端.svg | terminal, ssh, 终端 |
| tiktok | TIKTOK.svg | 覆盖现有 tiktok.svg（若素材更新）；keywords 保持 tiktok |

**Meta / Facebook 消歧：**
- 新增 `meta` 条目，且排在 `facebook` **之前**（first match wins）
- `facebook` 的 `matchKeywords` **移除** `meta`，仅保留 facebook 相关

**Files:**
- `harmonyos/entry/src/main/resources/rawfile/brand-icons/*.svg`
- `harmonyos/entry/src/main/ets/model/BrandIcons.ets`
- 可选：同步拷贝到仓库根 `logo/` 便于素材归档

### 1.4 扫码自动启动

**状态机：**

| 相机权限 | 进入扫码页（扫二维码子 Tab） |
|----------|------------------------------|
| 已 GRANTED | 自动 `doScan(false)` |
| 未授权 / 曾拒绝 | 走权限申请（当「第一次」）；拒绝则 toast，下次进入仍重新申请 |
| 同一次停留内关掉系统扫码且未成功 | 不连环弹；显示按钮，可手动再扫 |
| 已授权后**再次进入**扫码页 | 再次自动开扫 |

**实现要点：**
- 在 `ScanView.aboutToAppear`（或等价的「进入扫码页」钩子）检查权限后决定是否自动扫
- 使用已有 `scanning` 防重入
- 权限 API：现有 `abilityAccessCtrl` + `ohos.permission.CAMERA`（`module.json5` 已声明）

**Files:** `harmonyos/entry/src/main/ets/views/ScanView.ets`

### Wave 1 验收

- [ ] 点「下一个」区域 toast/剪贴板为下一周期码，点当前码为当前码
- [ ] Binance、网易邮箱图标视觉约 1.3x
- [ ] 新 issuer 字符串能匹配到对应 logo；`Meta` 不落到 Facebook 图
- [ ] 首次扫码申请权限；授权后再次进扫码自动弹扫码；拒绝后再进仍会申请

---

## Wave 2 — 会员云同步开关

### 2.1 UI

- 仅在 `membershipModal` 增加一行：**云同步** + `Toggle`
- 位置：权益列表附近/下方（已开通与未开通两种布局都展示该行，但交互不同）
- 不在「我的」增加第二入口

### 2.2 三态

| 状态 | Toggle | 行为 |
|------|--------|------|
| 未开通会员 | off + disabled（灰） | 不可改；副文案可选「开通后可用」 |
| 开通成功瞬间 | on | 写 `ak_cloud_sync=true`，并 `startAutoSync`（若登录/云就绪） |
| 已是会员 | 可交互 | 开 → startAutoSync；关 → stopAutoSync + 持久化 false |

### 2.3 门闩语义（关 = 停自动，不停手动）

| 拦截（需 `isMember && cloudSyncEnabled`） | 不拦截 |
|------------------------------------------|--------|
| `startAutoSync` / 定时回调 | 用户点击「备份数据」 |
| 增删改触发的自动 `cloudBackup` | 用户点击「导入备份」 |

所有自动上行入口统一：

```ts
if (this.isMember && this.cloudSyncEnabled) { /* auto cloud path */ }
```

### 2.4 存储

`StorageUtil` 增加：

- `loadCloudSyncEnabled(isMember: boolean): Promise<boolean>`
- `saveCloudSyncEnabled(enabled: boolean): Promise<void>`
- key: `ak_cloud_sync`

缺省：无存储记录时，会员 true、非会员 false。

### Wave 2 验收

- [ ] 非会员打开会员页：开关灰且关
- [ ] 开通成功：开关变为开，自动同步启动（登录+会员条件下）
- [ ] 会员关闭开关：定时/增删改不再自动上行；手动备份/导入仍可用
- [ ] 杀进程重开：开关状态与偏好一致

---

## Wave 3 — 安全

### 3.1 入口

- `ProfileView` 菜单增加 **安全**
- 未登录：toast/打开登录弹窗，不进入设置页
- 已登录：打开 `SecurityView`（全屏层，风格对齐现有会员/反馈 modal）

### 3.2 开关规则

- 默认三关，`securityMode = 'off'`
- 开启某一项前：`SecurityUtil` 检测系统是否支持/已录入该类型
  - 不可用 → toast（如「请先在系统设置中录入人脸」），保持关
- **互斥：** 成功开启一种 → 另外两种强制关，mode 写为对应值
- 关闭当前开启项 → mode `'off'`，不再锁屏

三种与系统 UserAuth 类型映射（实现时以 API 23 / 当前 SDK 枚举为准）：

| UI | mode 值 | 系统能力 |
|----|---------|----------|
| 人脸识别 | `face` | FACE |
| 指纹识别 | `fingerprint` | FINGERPRINT |
| 锁屏密码 | `lock` | LOCK_SCREEN / 锁屏凭据 |

### 3.3 锁屏时机与失败 UX

| 事件 | 行为 |
|------|------|
| 冷启动 | `mode !== 'off'` 且已登录 → 鉴权成功后再展示主内容 |
| 回前台（onForeground） | 同上 |
| `mode === 'off'` 或未登录 | 不锁 |
| 用户取消/失败 | 全屏遮罩：「验证以继续」+「点击重试」；**不** `terminateSelf` |
| 成功 | 揭开遮罩；保持解锁直到再次进入后台 |

**实现落点：**
- `SecurityUtil.ets`：`canUse(mode)`、`authenticate(mode): Promise<boolean>`
- `Index.ets`：`@State securityLocked` 全屏遮罩；监听窗口/ability 前台事件
- 若 `EntryAbility.onForeground` 更合适，通过 `AppStorage` 或回调通知 Index 加锁

### 3.4 存储

- `loadSecurityMode()` / `saveSecurityMode(mode)`
- key: `ak_security_mode`

### Wave 3 验收

- [ ] 未登录点安全 → 引导登录
- [ ] 系统未录入时无法开启对应开关
- [ ] 开启人脸后指纹/锁屏自动关；反之亦然
- [ ] 开启后杀进程重开需验证；回前台需验证
- [ ] 取消验证后全屏可重试，不能绕过进主界面
- [ ] 全部关闭后无锁屏

---

## Error handling & UX copy (Chinese)

| 场景 | 文案方向 |
|------|----------|
| 复制成功 | 沿用现有 toast（可区分「已复制」「已复制下一个」若易实现） |
| 相机权限拒绝 | 「需要相机权限才能扫码」 |
| 系统未设置生物特征 | 「请先在系统设置中录入人脸/指纹」或锁屏密码对应文案 |
| 安全未登录 | 「请先登录」并打开登录 |
| 云同步未开通 | Toggle 灰；可选「开通会员后可用」 |

## Testing strategy

- 无新测试框架
- Wave 1：手动/日志验证匹配与复制；`assembleApp` 编译通过
- Wave 2：会员开关切换 + 观察自动同步是否停止
- Wave 3：真机（需录入生物特征/锁屏）验证 UserAuth 与遮罩

## Implementation order

1. Switch git branch to `dev-harmonyos`（实现阶段）
2. Wave 1 commit(s)
3. Wave 2 commit(s)
4. Wave 3 commit(s)
5. 每波结束后真机验收再进入下一波

## Open implementation notes (non-blocking)

- HarmonyOS UserAuth 精确 import 路径与 `userAuthType` 枚举名以实现时 SDK 文档为准（API 23）
- 回前台钩子优先用 Ability/窗口生命周期中已有模式，避免重复加锁抖动（可加短 debounce）
- `facebook` 与 `meta` 并存：issuer 为 `Meta` / `Facebook` 分别命中对应图标

## Success criteria

全部六项需求在 `dev-harmonyos` 上可演示：云同步可关、安全锁可用、下一个码复制正确、图标齐全且缩放正确、扫码授权后自动启动。
