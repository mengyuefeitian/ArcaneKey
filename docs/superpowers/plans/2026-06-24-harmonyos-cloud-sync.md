# HarmonyOS 云同步功能实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现会员专享的 TOTP 口令云同步功能，使用华为 AGC 云数据库替代当前的本地 preferences 占位实现。

**Architecture:** Index.ets → SyncUtil.ets → AGC Cloud Database (user_backups collection)。使用软删除机制标记删除的口令，通过 secret 字段唯一性约束防止重复，实现即时同步和 30 分钟定时同步。

**Tech Stack:** HarmonyOS 6.1 (API 23), ArkTS, `@hw-agconnect/cloud@^1.0.2`, AGC Cloud Database

## Global Constraints

- **平台版本:** HarmonyOS 6.1 (API 23)
- **语言:** ArkTS (TypeScript-like with decorators)
- **UI语言:** 中文（所有用户可见文本）
- **云数据库集合:** `user_backups`
- **会员专享:** 非会员不执行任何同步操作
- **软删除:** `is_deleted: true` 标记删除，不物理删除
- **唯一性约束:** `secret` 字段作为口令唯一标识
- **同步间隔:** 30 分钟定时同步
- **数据结构:** SyncToken extends Token，添加 `is_deleted`, `deleted_at` 字段

---

## Phase 1: 数据模型扩展

### Task 1.1: 扩展 Token 模型

**Files:**
- Modify: `harmonyos/entry/src/main/ets/model/Token.ets:1-7`

**Interfaces:**
- Consumes: None
- Produces: `SyncToken` interface

**Rationale:** SyncToken 需要额外的字段来支持软删除和云同步元数据。

- [ ] **Step 1: 扩展 Token.ets 添加 SyncToken 接口**

```typescript
// 在 Token 接口定义之后添加

export interface SyncToken extends Token {
  is_deleted?: boolean;      // 软删除标记
  deleted_at?: string;       // 删除时间（ISO 8601）
  _id?: string;              // 云数据库文档 ID
  _openid?: string;          // 用户 OpenID（云端填充）
  timestamp?: string;        // 最后更新时间（ISO 8601）
}
```

- [ ] **Step 2: 验证编译**

Run: `cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk /Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon`

Expected: Build succeeds with no errors

- [ ] **Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/model/Token.ets
git commit -m "feat: add SyncToken interface for cloud sync"
```

---

## Phase 2: 云同步核心实现

### Task 2.1: 创建 SyncUtil.ets 基础结构

**Files:**
- Create: `harmonyos/entry/src/main/ets/utils/SyncUtil.ets`

**Interfaces:**
- Consumes: `SyncToken` from Task 1.1
- Produces: `initCloudDB()`, `addToken()`, `updateToken()`, `softDeleteToken()`, `restoreToken()`, `sync()`, `startAutoSync()`, `stopAutoSync()`

**Rationale:** SyncUtil 封装所有云同步逻辑，提供清晰的 API 给 Index.ets 调用。

- [ ] **Step 1: 创建 SyncUtil.ets 文件头和导入**

```typescript
import cloud from '@hw-agconnect/cloud';
import { SyncToken } from '../model/Token';

const COLLECTION_NAME = 'user_backups';
const SYNC_INTERVAL_MS = 30 * 60 * 1000; // 30 minutes

let autoSyncTimer: number = -1;

/**
 * 初始化云数据库
 * @returns 是否初始化成功
 */
export async function initCloudDB(): Promise<boolean> {
  try {
    // AGC SDK 会自动使用当前登录用户的凭证
    // 无需手动初始化，返回 true 表示准备就绪
    return true;
  } catch (e) {
    console.error('[SyncUtil] initCloudDB failed:', (e as Error).message);
    return false;
  }
}
```

- [ ] **Step 2: 实现 addToken 函数**

```typescript
/**
 * 添加口令到云端
 * @param token 要添加的口令
 */
export async function addToken(token: SyncToken): Promise<void> {
  try {
    const now = new Date().toISOString();
    const syncToken: SyncToken = {
      ...token,
      is_deleted: false,
      timestamp: now,
    };

    await cloud.database().collection(COLLECTION_NAME).add(syncToken);
    console.log('[SyncUtil] addToken success:', token.id);
  } catch (e) {
    console.error('[SyncUtil] addToken failed:', (e as Error).message);
    throw e;
  }
}
```

- [ ] **Step 3: 实现 updateToken 函数**

```typescript
/**
 * 更新云端口令
 * @param token 更新后的口令
 */
export async function updateToken(token: SyncToken): Promise<void> {
  try {
    if (!token._id) {
      throw new Error('Token _id is required for update');
    }

    const now = new Date().toISOString();
    const updatedToken: SyncToken = {
      ...token,
      timestamp: now,
    };

    await cloud.database()
      .collection(COLLECTION_NAME)
      .doc(token._id)
      .update(updatedToken);
    
    console.log('[SyncUtil] updateToken success:', token.id);
  } catch (e) {
    console.error('[SyncUtil] updateToken failed:', (e as Error).message);
    throw e;
  }
}
```

- [ ] **Step 4: 实现 softDeleteToken 函数**

```typescript
/**
 * 软删除口令（标记为已删除）
 * @param id 口令 ID
 * @param docId 云端文档 ID（可选，如果不提供会先查询）
 */
export async function softDeleteToken(id: string, docId?: string): Promise<void> {
  try {
    let targetDocId = docId;
    
    // 如果没有提供 docId，先查询
    if (!targetDocId) {
      const result = await cloud.database()
        .collection(COLLECTION_NAME)
        .where({ id: id })
        .get();
      
      if (result.data && result.data.length > 0) {
        targetDocId = result.data[0]._id;
      } else {
        console.warn('[SyncUtil] softDeleteToken: token not found in cloud:', id);
        return;
      }
    }

    const now = new Date().toISOString();
    await cloud.database()
      .collection(COLLECTION_NAME)
      .doc(targetDocId)
      .update({
        is_deleted: true,
        deleted_at: now,
        timestamp: now,
      });
    
    console.log('[SyncUtil] softDeleteToken success:', id);
  } catch (e) {
    console.error('[SyncUtil] softDeleteToken failed:', (e as Error).message);
    throw e;
  }
}
```

- [ ] **Step 5: 实现 restoreToken 函数**

```typescript
/**
 * 恢复已删除的口令
 * @param id 口令 ID
 */
export async function restoreToken(id: string): Promise<void> {
  try {
    const result = await cloud.database()
      .collection(COLLECTION_NAME)
      .where({ id: id, is_deleted: true })
      .get();
    
    if (!result.data || result.data.length === 0) {
      console.warn('[SyncUtil] restoreToken: deleted token not found:', id);
      return;
    }

    const docId = result.data[0]._id;
    const now = new Date().toISOString();
    
    await cloud.database()
      .collection(COLLECTION_NAME)
      .doc(docId)
      .update({
        is_deleted: false,
        deleted_at: null,
        timestamp: now,
      });
    
    console.log('[SyncUtil] restoreToken success:', id);
  } catch (e) {
    console.error('[SyncUtil] restoreToken failed:', (e as Error).message);
    throw e;
  }
}
```

- [ ] **Step 6: 实现 sync 函数（核心同步逻辑）**

```typescript
/**
 * 执行云端同步
 * @param localTokens 本地口令列表
 * @returns 同步后的口令列表
 */
export async function sync(localTokens: SyncToken[]): Promise<SyncToken[]> {
  try {
    console.log('[SyncUtil] sync started, local tokens:', localTokens.length);
    
    // 1. 获取云端数据
    const cloudResult = await cloud.database()
      .collection(COLLECTION_NAME)
      .where({ is_deleted: false })  // 只获取未删除的
      .get();
    
    const cloudTokens: SyncToken[] = cloudResult.data || [];
    console.log('[SyncUtil] cloud tokens:', cloudTokens.length);
    
    // 2. 构建本地 secret 集合
    const localSecrets = new Set(localTokens.map(t => t.secret));
    
    // 3. 找出云端新增的口令（本地没有的）
    const newFromCloud = cloudTokens.filter((ct: SyncToken) => !localSecrets.has(ct.secret));
    
    // 4. 构建云端 secret 集合
    const cloudSecrets = new Set(cloudTokens.map(t => t.secret));
    
    // 5. 找出本地新增的口令（云端没有的）
    const newFromLocal = localTokens.filter(lt => !cloudSecrets.has(lt.secret));
    
    // 6. 上传本地新增的口令到云端
    for (const token of newFromLocal) {
      await addToken(token);
    }
    
    // 7. 合并结果
    const merged: SyncToken[] = [...localTokens, ...newFromCloud];
    
    console.log('[SyncUtil] sync completed, merged tokens:', merged.length);
    return merged;
  } catch (e) {
    console.error('[SyncUtil] sync failed:', (e as Error).message);
    // 同步失败时返回本地数据，不影响用户使用
    return localTokens;
  }
}
```

- [ ] **Step 7: 实现 startAutoSync 和 stopAutoSync 函数**

```typescript
/**
 * 启动定时同步
 * @param syncCallback 同步回调函数
 */
export function startAutoSync(syncCallback: () => Promise<void>): void {
  if (autoSyncTimer !== -1) {
    console.warn('[SyncUtil] auto sync already running');
    return;
  }
  
  autoSyncTimer = setInterval(async () => {
    try {
      await syncCallback();
    } catch (e) {
      console.error('[SyncUtil] auto sync error:', (e as Error).message);
    }
  }, SYNC_INTERVAL_MS) as number;
  
  console.log('[SyncUtil] auto sync started, interval:', SYNC_INTERVAL_MS / 1000, 'seconds');
}

/**
 * 停止定时同步
 */
export function stopAutoSync(): void {
  if (autoSyncTimer !== -1) {
    clearInterval(autoSyncTimer);
    autoSyncTimer = -1;
    console.log('[SyncUtil] auto sync stopped');
  }
}
```

- [ ] **Step 8: 验证编译**

Run: `cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk /Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon`

Expected: Build succeeds with no errors

- [ ] **Step 9: Commit**

```bash
git add harmonyos/entry/src/main/ets/utils/SyncUtil.ets
git commit -m "feat: implement SyncUtil for AGC cloud database sync"
```

---

## Phase 3: Index.ets 集成

### Task 3.1: 修改 Index.ets 导入和状态

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets:1-100`

**Interfaces:**
- Consumes: All SyncUtil functions from Task 2.1
- Produces: None

**Rationale:** Index.ets 需要使用真实的云同步替代当前的 preferences 占位实现。

- [ ] **Step 1: 添加 SyncUtil 导入**

在 `Index.ets` 文件顶部导入区域添加：

```typescript
import { initCloudDB, addToken, updateToken, softDeleteToken, restoreToken, sync, startAutoSync, stopAutoSync } from '../utils/SyncUtil';
import { SyncToken } from '../model/Token';
```

- [ ] **Step 2: 修改 tokens 状态类型**

将 `@State tokens: Token[] = [];` 改为：

```typescript
@State tokens: SyncToken[] = [];
```

- [ ] **Step 3: 验证编译**

Run: `cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk /Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon`

Expected: Build succeeds with no errors

- [ ] **Step 4: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "refactor: change tokens state to SyncToken type"
```

### Task 3.2: 替换 cloudBackup 实现

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets:501-511`

**Interfaces:**
- Consumes: `addToken`, `updateToken` from Task 2.1
- Produces: None

**Rationale:** 使用真实的 AGC 云数据库同步替代本地 preferences。

- [ ] **Step 1: 重写 cloudBackup 方法**

替换 `cloudBackup()` 方法实现：

```typescript
private async cloudBackup(): Promise<void> {
  if (!this.isMember) return;
  
  try {
    console.log('[Index] cloudBackup started, tokens:', this.tokens.length);
    
    // 同步所有本地口令到云端
    for (const token of this.tokens) {
      if (token._id) {
        // 已有云端 ID，更新
        await updateToken(token);
      } else {
        // 没有云端 ID，新增
        await addToken(token);
      }
    }
    
    console.log('[Index] cloudBackup completed');
  } catch (e) {
    console.error('[Index] cloudBackup failed:', (e as Error).message);
    this.toast('云端备份失败，请检查网络');
  }
}
```

- [ ] **Step 2: 验证编译**

Run: `cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk /Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon`

Expected: Build succeeds with no errors

- [ ] **Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "refactor: replace cloudBackup with AGC cloud database"
```

### Task 3.3: 替换 cloudRestore 实现

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets:513-533`

**Interfaces:**
- Consumes: `sync` from Task 2.1
- Produces: None

**Rationale:** 使用 SyncUtil.sync() 实现智能双向同步。

- [ ] **Step 1: 重写 cloudRestore 方法**

替换 `cloudRestore()` 方法实现：

```typescript
private async cloudRestore(): Promise<void> {
  if (!this.isMember) return;
  
  try {
    console.log('[Index] cloudRestore started');
    
    // 执行双向同步
    const merged = await sync(this.tokens);
    
    // 检查是否有新数据
    if (merged.length > this.tokens.length) {
      this.tokens = merged;
      await saveTokens(this.tokens);
      this.refreshOtp();
      
      const newCount = merged.length - this.tokens.length;
      this.toast(`从云端同步 ${newCount} 个账号`);
      console.log('[Index] cloudRestore completed, new tokens:', newCount);
    } else {
      console.log('[Index] cloudRestore completed, no new tokens');
    }
  } catch (e) {
    console.error('[Index] cloudRestore failed:', (e as Error).message);
    // 同步失败不提示，不影响用户使用
  }
}
```

- [ ] **Step 2: 验证编译**

Run: `cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk /Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon`

Expected: Build succeeds with no errors

- [ ] **Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "refactor: replace cloudRestore with AGC cloud sync"
```

### Task 3.4: 替换 cloudDelete 实现

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets:535-549`

**Interfaces:**
- Consumes: `softDeleteToken` from Task 2.1
- Produces: None

**Rationale:** 使用软删除替代物理删除。

- [ ] **Step 1: 重写 cloudDelete 方法**

替换 `cloudDelete()` 方法实现：

```typescript
private async cloudDelete(tokenId: string): Promise<void> {
  if (!this.isMember) return;
  
  try {
    console.log('[Index] cloudDelete started, token:', tokenId);
    
    // 软删除云端口令
    await softDeleteToken(tokenId);
    
    console.log('[Index] cloudDelete completed');
  } catch (e) {
    console.error('[Index] cloudDelete failed:', (e as Error).message);
    // 删除失败不提示，本地已删除
  }
}
```

- [ ] **Step 2: 验证编译**

Run: `cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk /Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon`

Expected: Build succeeds with no errors

- [ ] **Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "refactor: replace cloudDelete with soft delete"
```

### Task 3.5: 替换 startAutoSync 实现

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets:552-557`

**Interfaces:**
- Consumes: `startAutoSync`, `stopAutoSync` from Task 2.1
- Produces: None

**Rationale:** 使用 SyncUtil 的定时同步替代简单的 setInterval。

- [ ] **Step 1: 重写 startAutoSync 方法**

替换 `startAutoSync()` 方法实现：

```typescript
private startAutoSync(): void {
  if (!this.isMember) return;
  
  startAutoSync(async () => {
    await this.cloudBackup();
  });
}
```

- [ ] **Step 2: 在 aboutToDisappear 中调用 stopAutoSync**

在 `aboutToDisappear()` 生命周期方法中添加：

```typescript
aboutToDisappear() {
  if (this.autoSyncTimer !== -1) clearInterval(this.autoSyncTimer);
  stopAutoSync();  // 添加这一行
}
```

- [ ] **Step 3: 验证编译**

Run: `cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk /Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon`

Expected: Build succeeds with no errors

- [ ] **Step 4: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "refactor: use SyncUtil auto sync with 30min interval"
```

### Task 3.6: 修改初始化逻辑

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets:208-244`

**Interfaces:**
- Consumes: `initCloudDB` from Task 2.1
- Produces: None

**Rationale:** 在初始化时初始化云数据库并执行首次同步。

- [ ] **Step 1: 在 loadData 中初始化云数据库**

在 `loadData()` 方法中，加载会员状态后添加：

```typescript
// 在加载会员状态之后，cloudRestore 之前
if (this.isMember) {
  await initCloudDB();
  console.log('[Index] cloud DB initialized');
}
```

- [ ] **Step 2: 验证编译**

Run: `cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk /Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon`

Expected: Build succeeds with no errors

- [ ] **Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat: initialize cloud DB on member login"
```

---

## Phase 4: 测试和验证

### Task 4.1: 手动测试云同步功能

**Files:**
- None (manual testing)

**Test Scenarios:**

- [ ] **Step 1: 测试添加口令同步**
  1. 启动应用，登录会员账号
  2. 添加新口令
  3. 检查控制台日志是否有 `[SyncUtil] addToken success`
  4. 在华为 AGC 控制台查看云数据库是否新增记录

- [ ] **Step 2: 测试更新口令同步**
  1. 编辑已有口令
  2. 检查控制台日志是否有 `[SyncUtil] updateToken success`
  3. 在 AGC 控制台查看记录是否更新

- [ ] **Step 3: 测试删除口令同步**
  1. 删除口令（选择"本地+云端"选项）
  2. 检查控制台日志是否有 `[SyncUtil] softDeleteToken success`
  3. 在 AGC 控制台查看记录的 `is_deleted` 是否为 `true`

- [ ] **Step 4: 测试跨设备同步**
  1. 在设备 A 添加口令
  2. 在设备 B 执行"从云端恢复"
  3. 验证设备 B 是否显示新增的口令

- [ ] **Step 5: 测试定时同步**
  1. 保持应用运行 30 分钟
  2. 检查控制台日志是否有定时同步日志
  3. 验证数据是否同步

- [ ] **Step 6: Commit 测试结果**

```bash
git add docs/superpowers/plans/2026-06-24-harmonyos-cloud-sync.md
git commit -m "test: manual testing completed for cloud sync"
```

---

## Phase 5: 文档更新

### Task 5.1: 更新 MEMORY.md

**Files:**
- Modify: `memory/MEMORY.md`

- [ ] **Step 1: 添加云同步实现记录**

在 `MEMORY.md` 添加：

```markdown
- [HarmonyOS Cloud Sync](harmonyos-cloud-sync.md) — 使用 AGC 云数据库实现会员专享口令同步，支持软删除、双向同步、30分钟定时同步
```

- [ ] **Step 2: 创建详细记忆文件**

创建 `memory/harmonyos-cloud-sync.md`：

```markdown
---
name: harmonyos-cloud-sync
description: HarmonyOS 云同步使用 AGC Cloud Database，支持软删除和双向同步
metadata:
  type: project
---

HarmonyOS 云同步功能使用 `@hw-agconnect/cloud` SDK 的 `cloud.database()` API。

**核心实现：**
- `SyncUtil.ets` - 封装所有云同步逻辑
- `SyncToken` 接口 - 扩展 Token 添加软删除字段
- 双向同步 - 合并本地和云端数据
- 软删除 - `is_deleted: true` 标记删除

**API:**
- `addToken(token)` - 添加口令到云端
- `updateToken(token)` - 更新云端口令
- `softDeleteToken(id)` - 软删除口令
- `restoreToken(id)` - 恢复已删除口令
- `sync(localTokens)` - 执行双向同步
- `startAutoSync(callback)` - 启动 30 分钟定时同步
- `stopAutoSync()` - 停止定时同步

**依赖：** `@hw-agconnect/cloud@^1.0.2`

**如何应用：** 会员专享功能，非会员不执行同步。使用 `secret` 字段作为唯一标识防止重复。
```

- [ ] **Step 3: Commit 文档更新**

```bash
git add memory/
git commit -m "docs: update memory with HarmonyOS cloud sync implementation"
```

---

## 验收标准

- [ ] 所有代码编译通过（无 ArkTS 错误）
- [ ] SyncUtil.ets 包含所有必需函数
- [ ] Index.ets 使用 SyncUtil 替代 preferences 占位实现
- [ ] 手动测试场景全部通过
- [ ] 文档已更新

## 风险和注意事项

1. **AGC 权限配置** - 需要在 AGC 控制台配置云数据库权限规则
2. **用户认证** - 确保用户已登录华为账号才能访问云数据库
3. **网络错误处理** - 同步失败不应影响本地使用
4. **冲突解决** - 当前采用"本地优先"策略，未来可考虑更复杂的冲突解决
5. **性能优化** - 大量口令时批量上传可能较慢，未来可优化

## 后续优化方向

- 实现增量同步（只同步变更）
- 添加同步进度显示
- 支持手动触发同步
- 实现更智能的冲突解决策略
- 添加同步历史记录查看
