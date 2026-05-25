# 会员开通功能设计 — 华为 IAP

**日期：** 2026-05-25  
**平台：** HarmonyOS（ArkTS，API 23，compatibleSdk 5.0.0(12)）  
**范围：** 替换现有演示占位逻辑，接入华为 In-App Purchase（IAP）实现真实支付

---

## 目标

将 `buyMembership()` 从演示代码升级为完整的华为 IAP 支付流程，支持：
- 购买会员（¥19.90/年，消耗型商品）
- 冷启动自动恢复历史购买
- 手动触发恢复购买
- 会员绑定鸿蒙账号，可跨设备恢复

---

## 决策记录

| 决策项 | 选择 | 原因 |
|--------|------|------|
| 支付渠道 | 仅华为 IAP | AppGallery 政策要求数字商品必须走 IAP，添加支付宝会导致应用被下架 |
| 服务端核验 | 不做，客户端直信 IAP 结果 | 无后端，¥19.90 低单价风险可接受，后续可升级 |
| 商品类型 | consumable（消耗型） | 支持每年重新购买；购买后延迟消耗，保留凭证以支持跨设备恢复 |
| 账号绑定 | 显示绑定账号 + 购买前强制登录 | IAP 底层已绑定华为账号，UI 层需明确告知用户 |
| 恢复方式 | 冷启动自动 + 手动链接兜底 | 自动处理 95% 场景，手动链接覆盖网络异常等边缘情况 |

---

## AppGallery Connect 配置步骤

在开始编码前，需在 AppGallery Connect 完成以下配置：

1. 登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)
2. 进入应用 → **盈利** → **商品管理** → 新增商品
3. 商品配置：
   - **商品 ID：** `com.arcanekey.authenticator.member_yearly`（与代码保持一致）
   - **商品类型：** 消耗型商品
   - **商品名称：** 星枢令会员年费
   - **价格：** ¥19.90
4. 在应用配置页启用 **In-App Purchases** 能力
5. 确保应用已完成华为支付商户号绑定

---

## 架构

### 新增文件：`entry/src/main/ets/utils/IAPUtil.ets`

封装所有华为 IAP SDK 调用，对外暴露四个函数。

> **注意：** 实现前在 DevEco Studio 中确认正确的 import 包名（`@kit.IAPKit` 或 `@kit.PurchaseKit`）及可用 API，以实际 SDK 文档为准。

```typescript
// 查询商品信息（价格、名称）；在 membershipModal 打开时调用，
// 用于校验商品有效性并展示 AppGallery 实际价格（替代硬编码 ¥19.90）
queryProductInfo(context: common.UIAbilityContext): Promise<iap.Product>

// 发起购买，返回 { purchaseToken, purchaseTime }
launchPurchase(context: common.UIAbilityContext): Promise<{ purchaseToken: string; purchaseTime: number }>

// 查询未消耗的历史购买，用于恢复会员状态
restoreOwnedPurchases(context: common.UIAbilityContext): Promise<{ purchaseToken: string; purchaseTime: number } | null>

// 消耗购买凭证（会员到期时调用，释放商品供重新购买）
consumePurchase(context: common.UIAbilityContext, purchaseToken: string): Promise<void>
```

**商品 ID 常量：** `MEMBER_PRODUCT_ID = 'com.arcanekey.authenticator.member_yearly'`

### 修改 `Index.ets`

**`aboutToAppear()`** — 现有 `loadMember()` 之后追加：
- 若会员已过期：调用 `consumePurchase()` 释放旧凭证（重试机制：本地记录 `pendingConsume` 标记）
- 若未开通或已过期：调用 `restoreOwnedPurchases()` 尝试静默恢复

**`buyMembership()`** — 替换为：
1. 检查 `loggedIn`，未登录则触发登录弹窗并返回
2. 调用 `IAPUtil.launchPurchase(context)`
3. 成功：计算 `expiry = purchaseTime + 365天`，调用 `saveMember(true, expiry, userName, purchaseToken)`
4. 失败/取消：展示对应 toast

**新增 `restorePurchase()`** — 手动恢复入口：
1. 调用 `IAPUtil.restoreOwnedPurchases(context)`
2. 找到：更新会员状态，toast "会员已恢复"
3. 未找到：toast "未找到有效购买记录"

### 修改 `StorageUtil.ets`

`saveMember()` / `loadMember()` 增加 `purchaseToken` 和 `boundAccount` 字段：

```typescript
interface MemberData {
  isMember: boolean;
  memberExpiry: string;
  purchaseToken: string;   // 新增，用于延迟消耗
  boundAccount: string;    // 新增，绑定的鸿蒙账号名
  pendingConsume: boolean; // 新增，消耗失败重试标记
}
```

### 修改 `membershipModal()` builder

三种状态（见 UI 设计）：

**状态 1 — 未登录：**
- 展示权益列表 + 价格（¥19.90/年 同行）
- 提示框：「购买会员需要先登录 · 会员将绑定至您的鸿蒙账号」
- 按钮：「登录后开通」→ 触发登录弹窗

**状态 2 — 已登录 · 未开通：**
- 展示权益列表 + 价格
- 账号绑定提示框：显示当前登录的鸿蒙账号名
- 主按钮：「立即开通会员」→ 调用 `buyMembership()`
- 底部文字链接：「换机后可用同一账号 恢复购买」→ 调用 `restorePurchase()`

**状态 3 — 已开通：**
- 会员状态卡片：✨ 您已是会员 + 到期日期
- 绑定账号卡片：头像 + 账号名 + 「换设备登录同账号可恢复会员」
- 权益列表

---

## 购买流程

```
用户点击"立即开通会员"
  ├─ 未登录 → 触发登录弹窗 → 登录后重新打开会员弹窗
  └─ 已登录 → IAPUtil.launchPurchase()
               ├─ 成功 → saveMember() → toast "开通成功" → 关闭弹窗
               ├─ 取消 → toast "已取消"
               └─ 失败 → toast 对应错误信息
```

## 恢复流程

```
冷启动（自动）
  loadMember()
  ├─ 会员有效 → 结束（不请求网络）
  ├─ 已过期 → consumePurchase(token) → restoreOwnedPurchases()
  │             ├─ 找到新购买 → saveMember() → 静默恢复
  │             └─ 未找到 → 保持非会员（静默）
  └─ 未开通 → restoreOwnedPurchases()
               ├─ 找到未消耗购买 → saveMember() → 静默恢复
               └─ 未找到 → 保持非会员（静默）

手动恢复（用户点击"恢复购买"）
  restoreOwnedPurchases()
  ├─ 找到 → saveMember() → toast "会员已恢复"
  └─ 未找到 → toast "未找到有效购买记录"
```

---

## 错误处理

| 场景 | Toast 提示 |
|------|-----------|
| 设备不支持华为支付 | 当前设备不支持华为支付 |
| 网络异常 | 网络异常，请检查网络后重试 |
| 华为系统账号未登录 | 请先在系统设置中登录华为账号 |
| purchaseToken 消耗失败 | 静默，写入 `pendingConsume = true`，下次启动重试 |
| 重复购买（已有未消耗凭证） | 不会发生（IAP 层拦截），走恢复流程即可 |

---

## 文件变更清单

| 操作 | 文件 |
|------|------|
| 新增 | `entry/src/main/ets/utils/IAPUtil.ets` |
| 修改 | `entry/src/main/ets/pages/Index.ets` |
| 修改 | `entry/src/main/ets/utils/StorageUtil.ets` |

---

## 不在本次范围内

- 服务端购买凭证核验（后续可升级）
- 会员到期自动提醒推送
- 家庭共享 / 多设备同步（依赖华为云服务）
- 订阅型商品（自动续费）
