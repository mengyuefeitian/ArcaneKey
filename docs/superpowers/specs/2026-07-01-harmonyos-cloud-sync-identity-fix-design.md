# HarmonyOS 云同步跨设备身份修复设计

## 背景 / 问题

现有云同步实现（见 `2026-06-24-cloud-sync-design.md`）在真实使用中存在架构性缺陷：**换设备（或卸载重装）后大概率无法访问之前同步到云端的数据**，即使登录的是同一个华为账号。

**根因：** Cloud DB 的 `Creator` 权限判定绑定的是 `EntryAbility.ets` 里每次启动都执行的 `cloud.auth().signInAnonymously()` 产生的匿名 UID，与华为账号登录完全脱钩。华为登录（`doHarmonyLogin`）目前只请求 `scopes = ['profile']`，从未获取 `unionId`；拿到的 `openId` 只存在本地和一个从未被查询过滤使用的 `userId` 字段里（`SyncUtil.ets` 的 `buildRecord`/`sync`）——纯装饰字段，没有任何隔离作用。

换设备后，新的匿名 UID ≠ 旧设备的匿名 UID，AGC 会在 ACL 层面直接拒绝新设备读写旧设备创建的记录，与 `userId` 字段是否匹配无关。

**已排除的方案：**
- 通过 AGC 云函数 HTTP 触发器做服务端 `cloud.getOpenId()` 隔离——此前已实际部署尝试过，被 HDA-SYSTEM 请求签名机制卡住（触发器要求签名，纯 Bearer token 会被拒绝为 404），已放弃。
- 用 `agconnect.auth().signInWithHuaweiId({ idToken })` 把华为账号关联为 AGC Auth 身份，让 Cloud DB 权限做到数据库层强制隔离——已对照项目实际安装的 `@hw-agconnect/cloud@1.0.2` 客户端 SDK 源码（`Auth.ts`）验证，该方法不存在。SDK 的 `signIn()` 仅支持 `PhoneCredentialInfo | EmailCredentialInfo` 两种凭证类型，没有第三方 OAuth/idToken 凭证类型，整个 SDK 源码中也搜不到任何 `HuaweiId`/`idToken`/`OAuthCredential` 相关的声明。这可能是 Android/iOS 版 AGC SDK 的能力，鸿蒙这个 ArkTS 包目前未实现。

## 采用方案：UnionID 客户端过滤 + 放宽 Cloud DB 权限

**核心思路：** 匿名登录依然保留（它是访问 Cloud DB 的门槛要求），但"谁能看到哪些数据"这件事，从 AGC 的 `Creator` ACL 移交给 App 代码用真实的华为 `unionId` 过滤来保证。

```
现状:
doHarmonyLogin (scopes=['profile'])
  → openId ──────────────────┐
                              ↓ (存了但没用于隔离，纯装饰)
EntryAbility.signInAnonymously() → 匿名 UID ← Cloud DB Creator 权限真正绑定在这里

方案实施后:
doHarmonyLogin (scopes=['openid','profile'])
  → unionId ──────────────────┐
                              ↓ (真正用于隔离)
EntryAbility.signInAnonymously() → 匿名 UID (仍需要，满足 AGC Authenticated 权限门槛)
SyncUtil 所有查询 → .equalTo('userId', unionId) 强制过滤
Cloud DB 权限规则 → Creator 改为 Authenticated (Read/Upsert/Delete)
```

## 涉及组件

| 文件 | 改动 |
|---|---|
| `harmonyos/entry/src/main/ets/pages/Index.ets`（`doHarmonyLogin`） | `request.scopes` 由 `['profile']` 改为 `['openid', 'profile']`；改用 `cred?.unionID` 而非 `cred?.openID`，传给 `setCloudUserId()` 和 `saveLogin()` |
| `harmonyos/entry/src/main/ets/utils/SyncUtil.ets` | `sync()` 的云端查询加上 `.equalTo('userId', currentUserId)`；`addToken`/`softDeleteToken`/`restoreToken` 在 `currentUserId` 为空时提前返回并记录错误日志，不静默执行 |
| `harmonyos/entry/src/main/ets/utils/StorageUtil.ets` | `LoginData.userOpenId` 字段语义变为存储 `unionId`（保留字段名以减少改动面，本质是"云端身份标识"） |
| AGC 控制台（`SyncToken` 对象类型权限规则） | `Creator` → `Authenticated`（Read/Upsert/Delete），此项为控制台手工配置，不在代码里 |

## 数据流与时序

**登录时序：**
```
1. App 启动 → EntryAbility.signInAnonymously() → agcAuthReady = true（不变）
2. 用户点击华为登录 → doHarmonyLogin()
   → scopes = ['openid', 'profile']
   → 拿到 unionID + nickName + avatarUri
   → setCloudUserId(unionID)   // 而非 openId
   → saveLogin(..., unionID)   // 本地持久化
3. 若 isMember → initCloudDB() → cloudRestore()
   → SyncUtil.sync() 内部查询改为:
     query().equalTo('is_deleted', false).equalTo('userId', unionID).get()
```

**日常同步（增/删/改）：** 逻辑不变，`buildRecord()` 里塞的 `userId` 现在是真实 `unionID`，查询时用它做过滤。换设备后只要登录同一华为账号 → 同一 `unionID` → 能查到同一批记录。

## 错误处理 / 边界情况

| 场景 | 处理方式 |
|---|---|
| `unionId` 为空（理论上不会发生，代码固定请求 `openid` scope；若华为账号异常返回空值） | `setCloudUserId('')`，所有同步操作在写入/查询前检测到 `currentUserId` 为空则直接跳过并 toast 提示登录异常，不静默失败、不误读写数据 |
| 老会员已同步的云端记录（`userId` 为空或旧 `openId`） | **不做迁移，直接视为孤儿数据。** 本地存储的 token 不受影响，用户下次登录同步时会被当作"本地新增"重新上传一份，携带新的 `unionId` |
| AGC 控制台权限规则改为 `Authenticated` 后，理论上任何匿名登录的客户端都能绕过 App 直接查询到别人的记录 | 已知且明确接受的安全 trade-off：隔离从"数据库强制"降级为"App 代码保证"。**（2026-07-01 修正）** 最初把这个风险类比成"和 XOR 备份加密一个级别的演示级安全"，经代码 review 指出类比不成立——本节原方案里 `secret` 字段是明文存储（`isNeedEncrypt: false`），权限放宽后相当于把 TOTP 密钥明文暴露给任何能匿名登录的客户端，是相对于改动前（`Creator` 权限限定在创建者自己的匿名 session）的净安全降级，不是同级风险。已改为见下方"密钥加密与复合主键修正"一节的方案 |
| `secret` 是 Zone 全局主键、不区分用户，权限放宽为 `Authenticated` 后，不同用户 upsert 相同 `secret`（例如两人都还留着演示用的 `INITIAL_TOKENS`，或真的共享同一个 TOTP 密钥）会互相覆盖对方记录、静默改写 `userId`，导致原用户的记录从此在自己的过滤查询里"消失" | 见下方"密钥加密与复合主键修正"一节，通过复合主键 `(userId, secret密文)` 解决 |
| `initCloudDB` 调用时机 | 沿用现有 `agcAuthReady` 信号机制（`AppStorage` + `@Watch`），不变 |

## 密钥加密与复合主键修正（2026-07-01，最终整体分支 review 后追加）

最终 review 发现方案落地后有两个之前设计遗漏/误判的问题，用户确认都必须修：

1. **`secret` 字段不能明文存云端。** 必须像本地备份导出（`CryptoUtil.ets` 的 `encryptData`/`decryptData`，PBKDF2 派生密钥 + 随机 salt + XOR keystream，"ENC3" 格式）一样做到"加密、可恢复"。但云同步是后台静默触发的（30 分钟定时同步、增删改都不弹窗），不能像备份导出那样每次弹密码框。**用户决定：用 `unionID` 派生一个确定性密钥，全程无需用户输入密码。**
2. **`secret` 作为全局主键会导致跨用户覆盖。** 用户确认这是真实风险，此前"userId 为空、没法用来做主键"的判断已经不成立——Task 1/2 落地后 `currentUserId`（`unionID`）对任何登录成功的会员都是非空真实值（见 Task 2 的空值 guard）。已对照 SDK 源码（`FieldInfo.ts`、`NaturalStoreObjectSchema.ts` 的 `primaryKeyList`/`getPrimaryKeys(): string[]`）确认 `@hw-agconnect/cloud@1.0.2` 支持复合主键（多个字段同时标 `belongPrimaryKey: true`）。

**修正方案：**

- 新增 `CryptoUtil.ets` 导出函数 `encryptSecretForCloud(secret: string, unionId: string): string` / `decryptSecretFromCloud(enc: string, unionId: string): string`：复用文件内已有的 `pbkdf2`/`utf8Encode`/`utf8Decode` 私有辅助函数，用固定字符串盐（如 `'ArcaneKey-cloud-sync-v1'`）+ `unionId` 作为 PBKDF2 口令派生 32 字节密钥，**不使用随机 salt**（因为要保证同一用户对同一 secret 每次加密结果一致，否则会破坏 `sync()` 里靠 `secret` 做去重比对的逻辑）
- `SyncUtil.ets` 的 `buildRecord()` 上传前调用 `encryptSecretForCloud`，`recordToToken()` 下载后调用 `decryptSecretFromCloud`——加解密只发生在云端序列化边界，`SyncToken`/`Token` 在 App 内其余逻辑（OTP 生成、`sync()` 内部按 `secret` 去重比对等）始终拿到的是明文，不受影响
- `initCloudDB()` 的 schema 里，`userId` 字段也标记为 `belongPrimaryKey: true`（`secret` 字段保留原有的 `belongPrimaryKey: true`），组成复合主键 `(userId, secret密文)`——即使不同用户的加密结果碰巧相同（概率极低，且因为密钥本身就包含 `unionId`，同一明文在不同用户下加密结果通常本就不同），`userId` 作为复合主键的一部分也能保证不会跨用户覆盖
- **不做向后兼容/格式迁移**：这个云同步身份修复分支尚未发布给真实用户，此前用明文写入云端的记录（如果有）视为测试数据，无需兼容读取

## 测试方式

项目没有自动化测试基础设施（无 CI、无单测框架），沿用现有 HarmonyOS 手动测试模式：

1. **编译验证**：`cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk .../hvigorw.js --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon`，确认无 ArkTS 错误
2. **真机跨设备测试**：设备 A 登录华为账号 → 添加口令 → 触发同步；设备 B（或同设备卸载重装）登录同一华为账号 → 执行"从云端恢复" → 验证能看到设备 A 添加的口令
3. **权限规则验证**：确认 AGC 控制台 `SyncToken` 权限规则改为 `Authenticated` 后，非会员/未登录状态下不会误触发任何同步调用
4. **回归测试**：验证软删除、恢复、30 分钟定时同步等既有功能在改动后行为不变

## 不在本次范围内

- 不实现老云端数据的迁移脚本（已在"错误处理"一节明确为直接丢弃）
- 不追求数据库层强制隔离（已确认当前 SDK 版本无法实现，见"背景"一节）
- 不改动 WeChat 小程序侧的云同步实现（该侧走的是 `wx.cloud.database`，openid 由微信平台原生保证跨设备一致，不存在此问题）
