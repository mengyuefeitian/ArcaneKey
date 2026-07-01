# HarmonyOS 云同步跨设备身份修复 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复换设备后云端同步数据丢失的问题——让"谁能看到哪些云端数据"改由真实华为账号 `unionID` 驱动，而不是每次启动都会变化的 AGC 匿名登录 UID。

**Architecture:** 匿名登录（`cloud.auth().signInAnonymously()`）保留，仅作为访问 Cloud DB 的门槛。真正的用户隔离改由 `unionID`（华为账号唯一标识，跨设备/跨重装不变）驱动：登录时获取 `unionID` 并作为 `userId` 存入每条云端记录，所有查询显式按 `userId` 过滤；Cloud DB 权限规则从"仅创建者"放宽为"任意已登录用户"，隔离保证从数据库层转移到 App 查询逻辑层。

**Tech Stack:** HarmonyOS 6.1 (API 23), ArkTS, `@kit.AccountKit`（`authentication.HuaweiIDProvider`）, `@hw-agconnect/cloud@1.0.2`（`DatabaseZoneQuery`）

## Global Constraints

- **平台版本:** HarmonyOS 6.1 (API 23)
- **语言:** ArkTS（TypeScript-like，严格模式，禁止 `any`、匿名对象字面量类型）
- **UI语言:** 中文（所有用户可见文本）
- **不做旧数据迁移:** 已确认——老会员云端记录（`userId` 为空/旧 openID）直接视为孤儿数据丢弃，不写迁移脚本
- **`unionID` 字段大小写:** 华为 SDK 声明为 `unionID`（大写 ID，与既有代码里的 `openID` 命名风格一致），已对照 `@hms.core.authentication.d.ts` 源码验证，不是 `unionId`
- **每个代码任务完成标准:** 必须跑通编译验证命令（见下），编译通过才算任务完成
- **编译验证命令:**
  ```bash
  cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
    /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
    /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
    --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
  ```
- **无自动化测试基础设施:** 项目没有 CI、没有单元测试框架（HarmonyOS 侧），验证方式统一是"编译通过 + 真机手动测试"，不要求编写单测

---

## Task 1: 华为登录改用真实 UnionID

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets:427-444`

**Interfaces:**
- Consumes: `authentication.HuaweiIDProvider`、`authentication.AuthorizationWithHuaweiIDResponse`（`@kit.AccountKit`，已在文件顶部导入，无需改动 import）；`setCloudUserId(userId: string): void`、`saveLogin(loggedIn, userName, userPhone, userAvatar, harmonyLogin, userOpenId?): Promise<void>`（均为既有函数，签名不变）
- Produces: `this.userOpenId`（既有 `@State` 字段，语义从"存 openID"变为"存 unionID"，字段名不变）；`setCloudUserId()` 之后传入的值供 Task 2 的 `SyncUtil.currentUserId` 使用

**Rationale:** 当前 `doHarmonyLogin` 只请求 `scopes = ['profile']`，从未获取 `unionID`，用的是每个应用都不同的 `openID` 存入 `userId` 字段（且从未被查询使用）。改成请求 `['openid', 'profile']` 并读取 `cred.unionID`，是让"同一华为账号跨设备同步"成立的前提条件。

- [ ] **Step 1: 修改 doHarmonyLogin 使用 unionID**

将 `harmonyos/entry/src/main/ets/pages/Index.ets` 第 422-459 行的 `doHarmonyLogin` 方法，把其中第 428、434、437-438、444 行替换为如下完整版本（其余行不变）：

```typescript
  private async doHarmonyLogin(): Promise<void> {
    if (!this.privacyAgreed) { this.toast('请先同意隐私保护协议'); return; }
    const ctx = this.getUIContext().getHostContext();
    if (!ctx) { this.toast('系统错误，请重试'); return; }
    try {
      const request = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
      request.scopes = ['openid', 'profile'];
      request.forceAuthorization = true;
      request.state = util.generateRandomUUID();
      const controller = new authentication.AuthenticationController(ctx);
      const resp = await controller.executeRequest(request);
      const cred = (resp as authentication.AuthorizationWithHuaweiIDResponse).data;
      const unionId = cred?.unionID || '';
      console.info(`[ArcaneKey] HuaweiID auth success: unionID=${unionId ? 'set' : 'empty'}, nickName=${cred?.nickName || 'empty'}, avatarUri=${cred?.avatarUri ? 'set' : 'empty'}`);
      this.loggedIn = true;
      this.userOpenId = unionId;
      setCloudUserId(unionId);
      this.userName = cred?.nickName || '华为用户';
      this.userAvatar = cred?.avatarUri || '';
      this.harmonyLogin = true;
      this.showLogin = false;
      this.privacyAgreed = false;
      await saveLogin(true, this.userName, this.userPhone, this.userAvatar, true, unionId);
      this.toast('登录成功');
      if (this.isMember) {
        await this.cloudRestore();
        this.startAutoSync();
      }
    } catch (e) {
      const code = (e as IapError).code;
      if (code === authentication.AuthenticationErrorCode.USER_CANCELED) {
        this.toast('已取消登录');
      } else {
        console.warn(`[ArcaneKey] HuaweiID auth error: code=${code}`);
        this.toast(`登录失败(${code})，请重试`);
      }
    }
  }
```

- [ ] **Step 2: 编译验证**

Run:
```bash
cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
```
Expected: `BUILD SUCCESSFUL`，无 ArkTS 编译错误

- [ ] **Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "fix(harmonyos): use Huawei unionID instead of openID for cloud sync identity"
```

---

## Task 2: SyncUtil 按 unionID 过滤并放宽权限声明

**Files:**
- Modify: `harmonyos/entry/src/main/ets/utils/SyncUtil.ets`

**Interfaces:**
- Consumes: `currentUserId`（模块级变量，由 Task 1 中 `setCloudUserId(unionId)` 写入）
- Produces: `addToken(token: SyncToken): Promise<void>`、`softDeleteToken(token: SyncToken): Promise<void>`、`restoreToken(token: SyncToken): Promise<void>`、`sync(localTokens: SyncToken[], isMember: boolean): Promise<SyncToken[]>` — 四个函数签名均不变，仅内部行为变化，供 `Index.ets` 现有调用方（`cloudBackup`/`cloudDelete`/`cloudRestore`）直接复用

**Rationale:** 现状是 `userId` 字段写入了但查询时从不过滤，且 Cloud DB 的 `Creator` 权限本来就绑死在匿名 UID 上、和 `unionId` 无关。这一步让查询显式按 `userId` 过滤，并把本地声明的权限角色改为 `Authenticated`，使其与 Task 3 中要在 AGC 控制台做的权限规则修改保持一致（避免本地 schema 声明和服务端配置不一致导致的排查困惑）。同时给三个写操作加上"未识别用户"防护，避免在 `unionId` 为空时误写入。

- [ ] **Step 1: 修改 initCloudDB 的权限声明**

将 `harmonyos/entry/src/main/ets/utils/SyncUtil.ets` 第 75-85 行的 `permissions` 数组，替换为：

```typescript
        permissions: [
          {
            objectTypeName: 'SyncToken',
            permissions: [
              { role: 'World', rights: [] },
              { role: 'Authenticated', rights: ['Read', 'Upsert', 'Delete'] },
              { role: 'Creator', rights: ['Read', 'Upsert', 'Delete'] },
              { role: 'Administrator', rights: ['Read', 'Upsert', 'Delete'] }
            ]
          }
        ]
```

- [ ] **Step 2: addToken 增加空 userId 防护**

将 `addToken` 函数（第 99-111 行）替换为：

```typescript
export async function addToken(token: SyncToken): Promise<void> {
  if (!tokenCollection) {
    throw new Error('Cloud DB not initialized');
  }
  if (!currentUserId) {
    throw new Error('Cloud user not identified');
  }
  try {
    await tokenCollection.upsert(buildRecord(token));
    console.log('[SyncUtil] addToken success:', token.id);
  } catch (e) {
    const err: Error = e as Error;
    console.error('[SyncUtil] addToken failed:', err.message);
    throw new Error(err.message);
  }
}
```

- [ ] **Step 3: softDeleteToken 增加空 userId 防护**

将 `softDeleteToken` 函数（第 117-139 行）开头的检查部分替换为：

```typescript
export async function softDeleteToken(token: SyncToken): Promise<void> {
  if (!tokenCollection) {
    throw new Error('Cloud DB not initialized');
  }
  if (!currentUserId) {
    throw new Error('Cloud user not identified');
  }
  try {
```

（`try` 块内剩余代码不变）

- [ ] **Step 4: restoreToken 增加空 userId 防护**

将 `restoreToken` 函数（第 141-163 行）开头的检查部分替换为：

```typescript
export async function restoreToken(token: SyncToken): Promise<void> {
  if (!tokenCollection) {
    throw new Error('Cloud DB not initialized');
  }
  if (!currentUserId) {
    throw new Error('Cloud user not identified');
  }
  try {
```

（`try` 块内剩余代码不变）

- [ ] **Step 5: sync 查询加上 userId 过滤**

将 `sync` 函数（第 165-207 行）开头部分替换为：

```typescript
export async function sync(localTokens: SyncToken[], isMember: boolean): Promise<SyncToken[]> {
  if (!isMember) {
    return localTokens;
  }
  if (!tokenCollection) {
    console.error('[SyncUtil] sync failed: Cloud DB not initialized');
    return localTokens;
  }
  if (!currentUserId) {
    console.error('[SyncUtil] sync failed: cloud user not identified');
    return localTokens;
  }

  try {
    console.log('[SyncUtil] sync started, local tokens:', localTokens.length);

    const cloudRecords: SyncTokenRecord[] =
      await tokenCollection.query().equalTo('is_deleted', false).equalTo('userId', currentUserId).get();
    const cloudTokens: SyncToken[] = cloudRecords.map((r: SyncTokenRecord): SyncToken => recordToToken(r));
```

（`try` 块内剩余代码——从 `const toUpload` 开始到函数结尾——不变）

- [ ] **Step 6: 编译验证**

Run:
```bash
cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
```
Expected: `BUILD SUCCESSFUL`，无 ArkTS 编译错误

- [ ] **Step 7: Commit**

```bash
git add harmonyos/entry/src/main/ets/utils/SyncUtil.ets
git commit -m "fix(harmonyos): filter cloud sync queries by unionID, relax permission to Authenticated"
```

---

## Task 3: AGC 控制台权限规则修改（人工步骤，无代码）

**Files:** 无（纯控制台操作）

**Interfaces:**
- Consumes: 无
- Produces: AGC 云数据库 `SyncToken` 对象类型的权限规则变更，供 Task 2 提交的代码在真实环境中生效

**Rationale:** `SyncUtil.ets` 里 `initCloudDB()` 声明的 `permissions` 只是客户端本地 schema 描述（用于 SDK 内部版本校验，已在设计阶段对照 SDK 源码 `NaturalBase.ts`/`DefaultNaturalStore.ts` 确认是本地内存注册，不会把权限规则推送到服务端）。真正生效的权限规则是在 AGC 控制台里为 `SyncToken` 对象类型手工配置的，必须单独修改，Task 2 的代码改动才能实际生效。

- [ ] **Step 1: 登录 AGC 控制台，定位对象类型**

1. 打开 https://developer.huawei.com/consumer/cn/service/josp/agc/index.html
2. 选择项目 `101653523864182539`，应用 `com.arcanekey.authenticator`
3. 进入 **云数据库** 服务 → **对象类型** → 找到 `SyncToken`

- [ ] **Step 2: 修改权限规则**

1. 打开 `SyncToken` 的 **权限规则** 配置
2. 将当前"仅创建者可读写"（Creator: Read/Upsert/Delete）修改为"已登录用户可读写"（Authenticated: Read/Upsert/Delete）
3. 保存配置

- [ ] **Step 3: 确认配置生效**

在控制台的对象类型详情页确认权限规则显示为 `Authenticated: Read, Upsert, Delete`（而非 `Creator`）

---

## Task 4: 真机跨设备验证

**Files:** 无（手动测试，无代码改动）

**Interfaces:**
- Consumes: Task 1-3 的全部改动
- Produces: 验证结论——同一华为账号换设备后能否看到之前同步的数据

**Rationale:** 项目没有自动化测试基础设施，HarmonyOS 云同步这类依赖真机华为账号登录 + AGC 后端的行为，历史上只能靠真机手动验证（`docs/superpowers/plans/2026-06-24-harmonyos-cloud-sync.md` 里 Phase 4 也是同样的手动验证模式）。这一步是确认整个修复链路（客户端过滤 + 控制台权限）在真实环境里配合生效。

- [ ] **Step 1: 设备 A 添加口令并同步**

1. 真机 A 上运行 App，登录华为账号（`doHarmonyLogin`），确认是会员（`isMember`）
2. 添加一个新口令
3. 查看控制台日志，确认出现 `[SyncUtil] addToken success:` 且没有 `Cloud user not identified` 报错

- [ ] **Step 2: 设备 B（或同设备卸载重装）登录同一账号并恢复**

1. 换一台真机（或卸载重装同一台设备的 App），登录**同一个华为账号**
2. 确认是会员后，等待自动同步或手动触发"从云端恢复"（`cloudRestore`）
3. 验证 App 界面上出现了设备 A 添加的那个口令
4. 查看控制台日志，确认 `[SyncUtil] sync completed, merged:` 数量包含新口令，且没有 `sync failed: cloud user not identified` 报错

- [ ] **Step 3: 验证软删除与恢复仍正常**

1. 在设备 A 上删除该口令，选择"本地+云端"
2. 在设备 B 上触发同步，确认该口令在设备 B 上也消失（`is_deleted` 生效）

- [ ] **Step 4: 验证非会员/未登录状态不受影响**

1. 退出登录或切换到非会员状态
2. 添加/删除口令，确认不触发任何云端调用（控制台日志中没有 `[SyncUtil]` 相关输出），本地增删改仍正常

- [ ] **Step 5: 记录验证结果**

在本计划文件对应任务的 checkbox 旁边补充验证结论（通过/发现的问题），若发现问题不要直接改这份计划，回到 Task 1/2 对应代码定位修复

---

## Task 5: CryptoUtil 新增云同步专用确定性加密函数

> **追加背景（2026-07-01 最终整体分支 review 后）：** review 指出 Task 2 里权限从 `Creator` 放宽为 `Authenticated` 后，`secret` 字段仍是明文存储，相当于把 TOTP 密钥明文暴露给任何能匿名登录的客户端，是相对改动前的净安全降级。用户确认必须加密，且云同步是后台静默触发（无法每次弹密码框），决定用 `unionID` 派生确定性密钥，全程无需用户输入密码。详见设计文档"密钥加密与复合主键修正"一节。

**Files:**
- Modify: `harmonyos/entry/src/main/ets/utils/CryptoUtil.ets`（在文件末尾追加，第 204 行之后）

**Interfaces:**
- Consumes: 文件内已有的私有函数 `pbkdf2(password: string, salt: number[], iterations: number, keyLen: number): number[]`、`utf8Encode(str: string): number[]`、`utf8Decode(bytes: number[]): string`（均已在本文件顶部定义，无需改动，直接复用）；文件顶部已有的 `import { util } from '@kit.ArkTS';`（无需新增 import）
- Produces: `encryptSecretForCloud(secret: string, unionId: string): string`、`decryptSecretFromCloud(enc: string, unionId: string): string` — 供 Task 6 在 `SyncUtil.ets` 中调用

**Rationale:** 复用本文件已有的 PBKDF2/UTF-8 私有辅助函数，避免重复实现哈希/编码逻辑（DRY）。与 `encryptData`/`decryptData`（备份导出用，随机 salt）不同，这里**故意不用随机 salt**——因为要保证同一账号对同一个 `secret` 每次加密结果一致，否则会破坏 `SyncUtil.ets` 的 `sync()` 里靠 `secret` 字段做本地/云端去重比对的逻辑（该逻辑在 Task 6 里保持不变，比较的是解密后的明文）。

- [ ] **Step 1: 在文件末尾追加加解密函数**

在 `harmonyos/entry/src/main/ets/utils/CryptoUtil.ets` 文件末尾（第 204 行 `decryptData` 函数结束的 `}` 之后）追加：

```typescript

// ── 云同步专用：确定性密钥加密（unionID 派生固定密钥，无随机 salt） ──
// 与 encryptData/decryptData 不同：同一账号对同一 secret 每次加密结果必须一致，
// 供 SyncUtil.sync() 按 secret 做本地/云端去重比对（比对时用解密后的明文）。
export function encryptSecretForCloud(secret: string, unionId: string): string {
  const salt = utf8Encode('ArcaneKey-cloud-sync-v1');
  const key = pbkdf2(unionId, salt, 10000, 32);
  const secretBytes = utf8Encode(secret);
  const xored: number[] = [];
  for (let i = 0; i < secretBytes.length; i++) {
    xored.push(secretBytes[i] ^ key[i % 32]);
  }
  const arr = new Uint8Array(xored);
  const helper = new util.Base64Helper();
  return helper.encodeToStringSync(arr);
}

export function decryptSecretFromCloud(enc: string, unionId: string): string {
  const salt = utf8Encode('ArcaneKey-cloud-sync-v1');
  const key = pbkdf2(unionId, salt, 10000, 32);
  const helper = new util.Base64Helper();
  const decoded: Uint8Array = helper.decodeSync(enc);
  const plain: number[] = [];
  for (let i = 0; i < decoded.length; i++) {
    plain.push(decoded[i] ^ key[i % 32]);
  }
  return utf8Decode(plain);
}
```

- [ ] **Step 2: 编译验证**

Run:
```bash
cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
```
Expected: `BUILD SUCCESSFUL`，无 ArkTS 编译错误

- [ ] **Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/utils/CryptoUtil.ets
git commit -m "feat(harmonyos): add deterministic unionID-derived encryption for cloud-synced secrets"
```

---

## Task 6: SyncUtil 加密 secret 字段并改为复合主键

**Files:**
- Modify: `harmonyos/entry/src/main/ets/utils/SyncUtil.ets`

**Interfaces:**
- Consumes: `encryptSecretForCloud(secret: string, unionId: string): string`、`decryptSecretFromCloud(enc: string, unionId: string): string`（Task 5 产出，从 `./CryptoUtil` 导入）
- Produces: `buildRecord`/`recordToToken`/`initCloudDB` 内部行为变化；`addToken`/`softDeleteToken`/`restoreToken`/`sync` 四个导出函数签名不变

**Rationale:** 把加解密收敛在 `buildRecord`（上传前加密）/`recordToToken`（下载后解密）这两个云端序列化边界函数里，`SyncToken`/`Token` 在 App 内其余逻辑（OTP 生成、`sync()` 内部按 `secret` 去重比对）拿到的始终是明文，改动面最小。同时把 `userId` 字段标记为主键的一部分，组成复合主键 `(userId, secret密文)`，防止不同用户 upsert 相同 `secret` 时互相覆盖对方记录（`Authenticated` 权限放宽后，原先靠 `Creator` 权限间接挡住的跨用户覆盖不再被数据库拦截，必须靠主键设计本身解决）。

- [ ] **Step 1: 导入 Task 5 新增的函数**

在 `harmonyos/entry/src/main/ets/utils/SyncUtil.ets` 文件顶部导入区域（第 1-3 行）追加一行：

```typescript
import cloud from '@hw-agconnect/cloud';
import { DatabaseCollection } from '@hw-agconnect/cloud';
import { SyncToken } from '../model/Token';
import { encryptSecretForCloud, decryptSecretFromCloud } from './CryptoUtil';
```

- [ ] **Step 2: buildRecord 上传前加密 secret**

将 `buildRecord` 函数（第 24-35 行）中的 `r.secret = token.secret;` 一行替换为：

```typescript
  r.secret = encryptSecretForCloud(token.secret, currentUserId);
```

（函数其余行不变）

- [ ] **Step 3: recordToToken 下载后解密 secret**

将 `recordToToken` 函数（第 37-48 行）中的 `secret: r.secret,` 一行替换为：

```typescript
    secret: decryptSecretFromCloud(r.secret, currentUserId),
```

（函数其余行不变）

- [ ] **Step 4: schema 里把 userId 标记为主键的一部分**

将 `initCloudDB` 里 `fields` 数组（第 62-71 行）中 `userId` 那一行：

```typescript
              { fieldName: 'userId', fieldType: 'String', belongPrimaryKey: false, notNull: true, isNeedEncrypt: false, isSensitive: false, defaultValue: '' }
```

替换为：

```typescript
              { fieldName: 'userId', fieldType: 'String', belongPrimaryKey: true, notNull: true, isNeedEncrypt: false, isSensitive: false, defaultValue: '' }
```

（`secret` 字段那一行保留原有的 `belongPrimaryKey: true` 不变，两个字段共同组成复合主键）

- [ ] **Step 5: 编译验证**

Run:
```bash
cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
```
Expected: `BUILD SUCCESSFUL`，无 ArkTS 编译错误

- [ ] **Step 6: Commit**

```bash
git add harmonyos/entry/src/main/ets/utils/SyncUtil.ets
git commit -m "fix(harmonyos): encrypt synced secrets with unionID-derived key, use composite primary key"
```

---

## Task 7: AGC 控制台 schema 更新为复合主键（人工步骤，无代码）

**Files:** 无（纯控制台操作）

**Interfaces:**
- Consumes: Task 6 提交的 schema 声明变化
- Produces: AGC 云数据库 `SyncToken` 对象类型的主键定义变更，供 Task 6 的代码在真实环境中生效

**Rationale:** 和 Task 3 的权限规则一样，`initCloudDB()` 里的 `fields` 声明只是客户端本地 schema 描述，真正的主键约束需要在 AGC 控制台的对象类型定义里同步修改，否则服务端仍然只按 `secret` 单字段去重/去重复。

- [ ] **Step 1: 登录 AGC 控制台，定位对象类型**

同 Task 3 Step 1：项目 `101653523864182539`，应用 `com.arcanekey.authenticator`，云数据库 → 对象类型 → `SyncToken`

- [ ] **Step 2: 修改主键定义**

将 `userId` 字段也勾选为主键的一部分，与现有的 `secret` 字段共同组成复合主键 `(userId, secret)`

- [ ] **Step 3: 确认配置生效**

在控制台对象类型详情页确认主键显示为复合主键（包含 `userId` 和 `secret` 两个字段）

---

## 验收标准

- [ ] Task 1、Task 2、Task 5、Task 6 编译均通过（`BUILD SUCCESSFUL`，无 ArkTS 错误）
- [ ] AGC 控制台 `SyncToken` 权限规则已改为 `Authenticated`（Task 3）
- [ ] AGC 控制台 `SyncToken` 主键已改为复合主键 `(userId, secret)`（Task 7）
- [ ] 真机验证：同一华为账号换设备后，此前同步的口令可见
- [ ] 软删除跨设备同步正常
- [ ] 非会员/未登录状态不触发任何云端调用
- [ ] 云端存储的 `secret` 字段为密文，不是明文 TOTP 密钥
