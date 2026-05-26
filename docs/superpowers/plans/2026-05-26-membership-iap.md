# 华为 IAP 会员开通 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将演示版 `buyMembership()` 替换为完整华为 IAP 永久会员流程，包含三态会员弹窗和冷启动自动恢复。

**Architecture:** 新建 `IAPUtil.ets` 封装所有 IAP SDK 调用（queryProductInfo / launchPurchase / restoreOwnedPurchases）；`StorageUtil.ets` 的 `MemberData` 去除到期字段改为 `boundAccount`；`Index.ets` 接入 IAP，完整重写 `membershipModal()` 为三态 UI，添加 `restorePurchase()`，更新 `loadData()` 冷启动恢复逻辑。

**Tech Stack:** HarmonyOS ArkTS API 23 · `@kit.StoreKit`（IAP）· `@kit.AbilityKit`（context）· `@kit.ArkData`（preferences）

> ⚠️ **IAP 包名须在 DevEco Studio 验证**（见 Task 1）。本计划使用 `@kit.StoreKit` + `iap.*` API，如实际包名不同，搜索替换对应 import 即可。

---

## 文件变更清单

| 操作 | 文件 |
|------|------|
| 新增 | `harmonyos/entry/src/main/ets/utils/IAPUtil.ets` |
| 修改 | `harmonyos/entry/src/main/ets/utils/StorageUtil.ets` |
| 修改 | `harmonyos/entry/src/main/ets/pages/Index.ets` |
| 修改 | `harmonyos/entry/src/main/ets/views/ProfileView.ets` |

---

## Task 1: 在 DevEco Studio 验证 IAP SDK 包名

**Files:** 无代码变更，仅确认 API

- [ ] **Step 1: 打开项目**

  在 DevEco Studio 中打开 `harmonyos/` 目录。

- [ ] **Step 2: 验证包名**

  在任意 `.ets` 文件中输入：
  ```typescript
  import { iap } from '@kit.StoreKit';
  ```
  观察 IDE 自动补全是否出现 `iap.ProductType`、`iap.queryProducts`、`iap.createOrder`、`iap.queryPurchases`。

  - 如果出现 → 包名正确，继续
  - 如果不出现 → 依次尝试 `@kit.IAPKit`、`@kit.PurchaseKit`，以能触发补全的为准

- [ ] **Step 3: 记录实际 API 签名**

  补全出现后，确认以下三个函数的实际参数形状：
  - `iap.queryProducts(context, query)` — query 字段名
  - `iap.createOrder(context, order)` — order 字段名，返回值中的 `purchaseToken` 字段路径
  - `iap.queryPurchases(context, query)` — 返回值中的订单列表字段名和 `productId` / `purchaseToken` 字段名

  如实际字段名与本计划中不同，Task 3 中的代码需对应调整。

---

## Task 2: 更新 StorageUtil.ets — 简化 MemberData

**Files:** `harmonyos/entry/src/main/ets/utils/StorageUtil.ets:63-83`

- [ ] **Step 1: 替换 MemberData 接口和相关函数**

  将文件末尾三段（`MemberData` 接口 + `loadMember` + `saveMember`）整体替换为：

  ```typescript
  export interface MemberData {
    isMember: boolean;
    boundAccount: string;
  }

  export async function loadMember(): Promise<MemberData> {
    try {
      if (!pref) return { isMember: false, boundAccount: '' };
      const val = await pref.get(MEMBER_KEY, '');
      if (val && typeof val === 'string' && val !== '') {
        const raw = JSON.parse(val as string) as Record<string, string | boolean>;
        return {
          isMember: !!raw.isMember,
          boundAccount: (raw.boundAccount as string) || '',
        };
      }
    } catch (_) {}
    return { isMember: false, boundAccount: '' };
  }

  export async function saveMember(isMember: boolean, boundAccount: string): Promise<void> {
    try {
      if (!pref) return;
      await pref.put(MEMBER_KEY, JSON.stringify({ isMember, boundAccount }));
      await pref.flush();
    } catch (_) {}
  }
  ```

  > 注：`loadMember` 中的 `raw` 类型转换保证了对旧格式（含 `expiry` 字段）的向后兼容——旧数据读取时 `boundAccount` 会为 `undefined`，fallback 为空字符串。

- [ ] **Step 2: 构建验证**

  在 DevEco Studio 中执行 **Build → Build Module 'entry'**。  
  预期：无编译错误（此时 Index.ets 会因 `saveMember` 签名变化报错，是预期行为，后续 Task 4 修复）。

- [ ] **Step 3: Commit**

  ```bash
  git add harmonyos/entry/src/main/ets/utils/StorageUtil.ets
  git commit -m "feat(storage): simplify MemberData — replace expiry with boundAccount"
  ```

---

## Task 3: 新建 IAPUtil.ets

**Files:** 新建 `harmonyos/entry/src/main/ets/utils/IAPUtil.ets`

- [ ] **Step 1: 创建文件，写入以下内容**

  ```typescript
  import { iap } from '@kit.StoreKit';
  import { common } from '@kit.AbilityKit';

  export const MEMBER_PRODUCT_ID = 'com.arcanekey.authenticator.member_lifetime';

  // 查询商品信息；用于弹窗打开时校验商品可用性并展示 AGC 实际价格
  export async function queryProductInfo(context: common.UIAbilityContext): Promise<iap.Product> {
    const products = await iap.queryProducts(context, {
      productType: iap.ProductType.NONCONSUMABLE,
      productIds: [MEMBER_PRODUCT_ID],
    });
    if (!products || products.length === 0) {
      throw new Error('商品信息查询为空');
    }
    return products[0];
  }

  // 发起购买；成功返回 purchaseToken
  export async function launchPurchase(context: common.UIAbilityContext): Promise<{ purchaseToken: string }> {
    const result = await iap.createOrder(context, {
      productType: iap.ProductType.NONCONSUMABLE,
      productId: MEMBER_PRODUCT_ID,
    });
    return { purchaseToken: result.purchaseToken };
  }

  // 查询已购买的非消耗型商品；找到返回 token，未找到返回 null
  export async function restoreOwnedPurchases(
    context: common.UIAbilityContext
  ): Promise<{ purchaseToken: string } | null> {
    const result = await iap.queryPurchases(context, {
      productType: iap.ProductType.NONCONSUMABLE,
    });
    if (!result.purchaseOrderList || result.purchaseOrderList.length === 0) {
      return null;
    }
    const owned = result.purchaseOrderList.find(o => o.productId === MEMBER_PRODUCT_ID);
    if (!owned) return null;
    return { purchaseToken: owned.purchaseToken };
  }
  ```

  > 如 Task 1 发现实际 API 字段名不同（如 `createOrder` 返回值的 token 字段不叫 `purchaseToken`，或 `queryPurchases` 的列表字段不叫 `purchaseOrderList`），在此文件中修正。

- [ ] **Step 2: 构建验证**

  执行 **Build → Build Module 'entry'**。  
  预期：`IAPUtil.ets` 本身无编译错误（若包名未找到会报 import 错误，回到 Task 1 确认正确包名）。

- [ ] **Step 3: Commit**

  ```bash
  git add harmonyos/entry/src/main/ets/utils/IAPUtil.ets
  git commit -m "feat(iap): add IAPUtil with queryProductInfo/launchPurchase/restoreOwnedPurchases"
  ```

---

## Task 4: 更新 Index.ets — 状态字段 + import + loadData

**Files:** `harmonyos/entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: 更新 import 行**

  在文件顶部第 10 行（`import ... from '../utils/StorageUtil'`）之后新增一行：

  ```typescript
  import { launchPurchase, restoreOwnedPurchases } from '../utils/IAPUtil';
  ```

- [ ] **Step 2: 替换 memberExpiry 状态字段**

  第 75 行：
  ```typescript
  // 旧
  @State memberExpiry: string = '';
  // 改为
  @State boundAccount: string = '';
  ```

- [ ] **Step 3: 更新 loadData() 中的会员加载逻辑**

  定位 `loadData()` 内（约第 155-162 行）的会员加载段：

  ```typescript
  // 旧
  const member: MemberData = await loadMember();
  this.isMember = member.isMember;
  this.memberExpiry = member.expiry || '';
  this.refreshOtp();
  if (this.isMember) {
    this.cloudRestore();
    this.startAutoSync();
  }
  ```

  替换为：

  ```typescript
  const member: MemberData = await loadMember();
  this.isMember = member.isMember;
  this.boundAccount = member.boundAccount;
  this.refreshOtp();
  if (this.isMember) {
    this.cloudRestore();
    this.startAutoSync();
  } else {
    // 冷启动静默恢复：查询华为账号历史购买记录
    try {
      const restored = await restoreOwnedPurchases(ctx);
      if (restored) {
        await saveMember(true, this.userName);
        this.isMember = true;
        this.boundAccount = this.userName;
      }
    } catch (_) {
      // 网络异常或账号未登录时静默忽略，不影响正常启动
    }
  }
  ```

- [ ] **Step 4: 更新 ProfileView 的 prop 传参**

  定位约第 1145 行传给 `ProfileView` 的 `memberExpiry` 参数：

  ```typescript
  // 旧
  memberExpiry: this.memberExpiry,
  // 改为
  boundAccount: this.boundAccount,
  ```

- [ ] **Step 5: 构建验证**

  执行 **Build → Build Module 'entry'**。  
  预期报错：
  - `buyMembership()` 内的 `saveMember` 调用参数不匹配（Task 5 修复）
  - `ProfileView` 的 `memberExpiry` prop 不存在（Task 6 修复）
  - 其余不应有新错误

- [ ] **Step 6: Commit（中间状态，确保每步可回溯）**

  ```bash
  git add harmonyos/entry/src/main/ets/pages/Index.ets
  git commit -m "feat(index): update state/import/loadData for IAP — wip"
  ```

---

## Task 5: 替换 buyMembership() + 新增 restorePurchase()

**Files:** `harmonyos/entry/src/main/ets/pages/Index.ets:413-421`

- [ ] **Step 1: 替换 buyMembership()**

  定位约第 413 行的 `private buyMembership(): void { ... }`，整段替换为：

  ```typescript
  private async buyMembership(): Promise<void> {
    if (!this.loggedIn) {
      this.showLogin = true;
      return;
    }
    const ctx = AppStorage.get<common.UIAbilityContext>('context');
    if (!ctx) { this.toast('系统错误，请重试'); return; }
    try {
      await launchPurchase(ctx);
      await saveMember(true, this.userName);
      this.isMember = true;
      this.boundAccount = this.userName;
      this.toast('开通成功');
      this.showMembership = false;
    } catch (e) {
      const err = e as { code?: number };
      // 以下错误码需在 DevEco Studio 中用 iap.IAPErrorCode.* 或查阅官方文档确认
      if (err.code === 1001770042) {        // ORDER_STATE_CANCEL — 用户主动取消
        this.toast('已取消');
      } else if (err.code === 1001770003) { // ACCOUNT_NOT_LOGIN — 华为账号未登录
        this.toast('请先在系统设置中登录华为账号');
      } else if (err.code === 1001770044) { // NET_ERROR — 网络异常
        this.toast('网络异常，请检查网络后重试');
      } else if (err.code === 1001770001) { // PAY_NOT_SUPPORTED — 设备不支持华为支付
        this.toast('当前设备不支持华为支付');
      } else {
        this.toast(`开通失败（${err.code ?? '未知错误'}），请重试`);
      }
    }
  }
  ```

- [ ] **Step 2: 在 buyMembership() 之后新增 restorePurchase()**

  ```typescript
  private async restorePurchase(): Promise<void> {
    const ctx = AppStorage.get<common.UIAbilityContext>('context');
    if (!ctx) { this.toast('系统错误，请重试'); return; }
    try {
      const result = await restoreOwnedPurchases(ctx);
      if (result) {
        await saveMember(true, this.userName);
        this.isMember = true;
        this.boundAccount = this.userName;
        this.toast('会员已恢复');
      } else {
        this.toast('未找到有效购买记录');
      }
    } catch (_) {
      this.toast('恢复失败，请检查网络后重试');
    }
  }
  ```

- [ ] **Step 3: 构建验证**

  执行 **Build → Build Module 'entry'**。  
  预期：`buyMembership`/`restorePurchase` 相关编译错误消除；`ProfileView` 的 `memberExpiry` prop 错误仍存在（Task 6 修复）。

- [ ] **Step 4: Commit**

  ```bash
  git add harmonyos/entry/src/main/ets/pages/Index.ets
  git commit -m "feat(index): replace buyMembership stub with IAP flow, add restorePurchase"
  ```

---

## Task 6: 重设计 membershipModal() — 三态 UI

**Files:** `harmonyos/entry/src/main/ets/pages/Index.ets:998-1045`

- [ ] **Step 1: 整段替换 membershipModal() builder**

  定位 `@Builder` 之前的 `membershipModal()` 方法（第 998 行开始，到第 1045 行 `}`），替换为：

  ```typescript
  @Builder
  membershipModal() {
    Column() {
      this.modalHeader('开通会员', () => { this.showMembership = false; })
      Scroll() {
        Column({ space: 16 }) {

          if (this.isMember) {
            // ── 状态 3：已开通 ──────────────────────────────────────
            Column({ space: 0 }) {
              Text('✨').fontSize(32).margin({ bottom: 8 })
              Text('您已是会员').fontSize(17).fontWeight(700).fontColor(this.accentColor)
              Text('永久有效').fontSize(12).fontColor('rgba(238,238,245,0.5)').margin({ top: 4 })
            }
            .width('100%').padding(20).alignItems(HorizontalAlign.Center)
            .backgroundColor(this.accentColor + '1e')
            .border({ width: 1, color: this.accentColor + '4d' })
            .borderRadius(14)

            Column({ space: 6 }) {
              Text('绑定账号').fontSize(10).fontColor('rgba(238,238,245,0.4)')
              Row({ space: 10 }) {
                Stack() {
                  Text(this.boundAccount.length > 0 ? this.boundAccount[0].toUpperCase() : '鸿')
                    .fontSize(14).fontColor('#fff').fontWeight(700)
                }
                .width(32).height(32).borderRadius(16)
                .backgroundColor(this.accentColor)
                Column({ space: 2 }) {
                  Text(this.boundAccount || '鸿蒙用户').fontSize(13).fontWeight(600).fontColor('#eeeef5')
                  Text('换设备登录同账号可恢复会员').fontSize(11).fontColor('rgba(238,238,245,0.35)')
                }.alignItems(HorizontalAlign.Start)
              }.width('100%')
            }
            .padding(12).backgroundColor('#191920').borderRadius(12).width('100%')
            .alignItems(HorizontalAlign.Start)

          } else {
            // ── 共用：icon + 价格 ───────────────────────────────────
            Column() {
              Text('👑').fontSize(40)
              Row({ space: 4 }) {
                Text('¥19.90').fontSize(28).fontWeight(800).fontColor('#eeeef5')
                Text('永久会员').fontSize(12).fontColor('rgba(238,238,245,0.4)')
              }
              .alignItems(VerticalAlign.Bottom)
              .margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 24, bottom: 20 })
            .width('100%')

            // ── 共用：权益列表 ──────────────────────────────────────
            Column({ space: 10 }) {
              ForEach(
                ['无限制添加动态口令', '加密备份数据导入导出', '查看 Secret Key', '云端数据自动同步'],
                (item: string) => {
                  Row({ space: 8 }) {
                    Text('✓').fontSize(12).fontWeight(700).fontColor(this.accentColor)
                    Text(item).fontSize(13).fontColor('rgba(238,238,245,0.7)')
                  }.width('100%')
                },
                (item: string) => item
              )
            }
            .padding(14).backgroundColor('#191920').borderRadius(14).width('100%')

            if (!this.loggedIn) {
              // ── 状态 1：未登录 ────────────────────────────────────
              Column({ space: 4 }) {
                Text('购买会员需要先登录').fontSize(12).fontColor('rgba(238,238,245,0.55)')
                Text('会员将绑定至您的鸿蒙账号').fontSize(11).fontColor('rgba(238,238,245,0.35)')
              }
              .width('100%').padding(10).alignItems(HorizontalAlign.Center)
              .backgroundColor(this.accentColor + '1a')
              .border({ width: 1, color: this.accentColor + '40' })
              .borderRadius(10)

              Button('登录后开通')
                .width('100%').height(50).borderRadius(15)
                .backgroundColor(this.accentColor).fontColor('#fff')
                .fontSize(15).fontWeight(650)
                .onClick(() => {
                  this.showMembership = false;
                  this.loginPhone = '';
                  this.loginCode = '';
                  this.loginCodeSent = false;
                  this.loginCodeCd = 0;
                  this.showLogin = true;
                })

            } else {
              // ── 状态 2：已登录 · 未开通 ────────────────────────────
              Row({ space: 8 }) {
                Text('👤').fontSize(16)
                Column({ space: 2 }) {
                  Text('购买后绑定至').fontSize(10).fontColor('rgba(238,238,245,0.5)')
                  Text(this.userName || '鸿蒙用户').fontSize(12).fontWeight(600).fontColor('#eeeef5')
                }.alignItems(HorizontalAlign.Start)
              }
              .width('100%').padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor(this.accentColor + '14')
              .border({ width: 1, color: this.accentColor + '33' })
              .borderRadius(10)

              Column({ space: 8 }) {
                Button('立即开通会员')
                  .width('100%').height(50).borderRadius(15)
                  .backgroundColor(this.accentColor).fontColor('#fff')
                  .fontSize(15).fontWeight(650)
                  .onClick(() => { this.buyMembership(); })

                Row() {
                  Text('换机后可用同一账号 ').fontSize(11).fontColor('rgba(238,238,245,0.3)')
                  Text('恢复购买')
                    .fontSize(11).fontColor(this.accentColor)
                    .onClick(() => { this.restorePurchase(); })
                }
                .justifyContent(FlexAlign.Center).width('100%')
              }
            }
          }

          // ── 已是会员时也展示权益（底部参考） ──────────────────────
          if (this.isMember) {
            Column({ space: 10 }) {
              ForEach(
                ['无限制添加动态口令', '加密备份数据导入导出', '查看 Secret Key', '云端数据自动同步'],
                (item: string) => {
                  Row({ space: 8 }) {
                    Text('✓').fontSize(12).fontWeight(700).fontColor(this.accentColor)
                    Text(item).fontSize(13).fontColor('rgba(238,238,245,0.7)')
                  }.width('100%')
                },
                (item: string) => item
              )
            }
            .padding(14).backgroundColor('#191920').borderRadius(14).width('100%')
          }

        }
        .padding({ left: 20, right: 20, bottom: 40 })
      }
      .scrollBar(BarState.Off).flexGrow(1)
    }
    .width('100%').height('100%').backgroundColor('#0d0d12')
    .padding({ top: 44 })
    .position({ x: 0, y: 0 }).zIndex(400)
  }
  ```

- [ ] **Step 2: 构建验证**

  执行 **Build → Build Module 'entry'**。  
  预期：`membershipModal` 相关错误消除；此时仍有 `ProfileView.memberExpiry` 不存在的报错。

---

## Task 7: 更新 ProfileView.ets — 替换 memberExpiry prop

**Files:** `harmonyos/entry/src/main/ets/views/ProfileView.ets`

- [ ] **Step 1: 替换 prop 声明**

  第 11 行：
  ```typescript
  // 旧
  @Prop memberExpiry: string = '';
  // 改为
  @Prop boundAccount: string = '';
  ```

- [ ] **Step 2: 更新 ProfileView 中的展示文本**

  约第 97 行（会员状态副标题）：
  ```typescript
  // 旧
  Text(this.isMember ? `有效期至 ${this.memberExpiry}` : '¥19.90/年，无限制添加')
  // 改为
  Text(this.isMember ? '永久会员 · 永久有效' : '¥19.90 · 永久会员，无限制添加')
  ```

- [ ] **Step 3: 完整构建验证**

  执行 **Build → Build Module 'entry'**。  
  预期：**零编译错误**。

- [ ] **Step 4: 手动测试清单（在真机或模拟器上）**

  部署 App，按以下路径逐一验证：

  | 测试场景 | 操作步骤 | 预期结果 |
  |----------|----------|---------|
  | 弹窗状态 1 | 未登录时点击「开通会员」 | 弹窗显示登录提示 + "登录后开通"按钮 |
  | 弹窗状态 2 | 登录后点击「开通会员」 | 显示当前账号名 + "立即开通会员"按钮 + "恢复购买"链接 |
  | 恢复购买（无记录） | 状态 2 中点击「恢复购买」 | Toast: "未找到有效购买记录" |
  | 冷启动恢复 | 已购买后重装 App，冷启动 | 自动恢复为会员状态 |
  | 弹窗状态 3 | 已是会员时点击「会员特权」 | 弹窗显示 ✨ 您已是会员 + 永久有效 + 绑定账号 |
  | ProfileView | 已是会员时查看「我的」页 | 显示"永久会员 · 永久有效" |
  | 真实购买 | ⚠️ 需 AGC 商品配置完成后再测 | IAP 收款弹窗 → 成功 → toast "开通成功" → 弹窗关闭 |

- [ ] **Step 5: 最终 Commit**

  ```bash
  git add harmonyos/entry/src/main/ets/views/ProfileView.ets
  git add harmonyos/entry/src/main/ets/pages/Index.ets
  git commit -m "feat(membership): complete Huawei IAP integration — 3-state modal, lifetime membership"
  ```

---

## 注意事项

### IAP 错误码验证

Task 5 中的错误码（`1001770042` 等）需要在 DevEco Studio 中通过以下方式确认：
```typescript
// 在 IDE 中输入以检查可用常量
iap.IAPErrorCode.
```
如果 SDK 提供了枚举，用枚举替换硬编码数字可提升可读性：
```typescript
// 推荐（如 SDK 支持）
if (err.code === iap.IAPErrorCode.ORDER_STATE_CANCEL) { ... }
```

### AppGallery Connect 商品配置

实际购买功能需在 AGC 配置好以下内容后才能测试：
- 商品 ID: `com.arcanekey.authenticator.member_lifetime`
- 商品类型: 非消耗型商品
- 启用应用的 In-App Purchases 能力
- 配置华为支付商户号

开发阶段可使用 AGC 测试账号进行沙箱支付，无需提交审核即可测试完整支付流程。

### 向后兼容

旧格式 `{ isMember: true, expiry: "..." }` 的本地存储读取后会得到 `boundAccount: ''`，不影响 `isMember` 状态，会员功能正常。下次 `saveMember()` 调用后自动迁移到新格式。
