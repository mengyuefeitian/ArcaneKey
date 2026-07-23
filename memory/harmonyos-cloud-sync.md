# HarmonyOS Cloud Sync

## Overview

HarmonyOS 云同步功能通过 AGC (AppGallery Connect) Cloud Functions 实现，而非直接使用云数据库 API。这种架构选择规避了 AGC HTTP 触发器的签名认证问题（详见 [AGC Cloud Function Auth Blocker](agc-cloud-function-auth.md)）。

## Core Files

| File | Responsibility |
|------|----------------|
| `harmonyos/entry/src/main/ets/utils/SyncUtil.ets` | 云同步核心逻辑：初始化、CRUD 操作、自动同步 |
| `harmonyos/entry/src/main/ets/model/Token.ets` | `SyncToken` 接口定义（扩展 `Token`，包含云同步字段） |

## Key API Functions

### Initialization

```typescript
initCloudDB(): Promise<boolean>
```
- AGC SDK 自动初始化，无需额外配置
- 返回 `true` 表示准备就绪

### CRUD Operations

所有 CRUD 操作通过 `cloud.callFunction()` 调用云函数：

```typescript
addToken(token: SyncToken): Promise<void>
```
- 云函数: `sync-add`
- 参数: `{ action: 'add', token }`

```typescript
updateToken(token: SyncToken): Promise<void>
```
- 云函数: `sync-add`
- 参数: `{ action: 'update', token }`

```typescript
softDeleteToken(id: string): Promise<void>
```
- 云函数: `sync-delete`
- 参数: `{ id }`
- 标记 `is_deleted = true`，记录 `deleted_at`

```typescript
restoreToken(id: string): Promise<void>
```
- 云函数: `sync-restore`
- 参数: `{ id }`
- 清除 `is_deleted` 标记

### Sync Operation

```typescript
sync(localTokens: SyncToken[], isMember: boolean): Promise<SyncToken[]>
```
- 云函数: `sync-pull`
- 参数: `{ localTokens }`
- 合并策略: 云端数据优先，同步后返回合并列表
- **会员专享**: 非会员时跳过同步，直接返回本地数据
- 失败时返回本地数据，不影响用户使用

### Auto Sync

```typescript
startAutoSync(syncCallback: () => Promise<void>): void
```
- 定时器间隔: 30 分钟 (`SYNC_INTERVAL_MS = 30 * 60 * 1000`)
- 使用 `setInterval` 实现
- 失败时仅打印日志，不中断定时器

```typescript
stopAutoSync(): void
```
- 清除定时器，重置 `autoSyncTimer = -1`

## Technical Decision: AGC Cloud Functions

### Why Cloud Functions instead of Direct Database API?

1. **Auth Blocker**: AGC HTTP 触发器需要 HDA-SYSTEM 签名，客户端 SDK 无法直接调用云数据库 REST API（详见 [AGC Cloud Function Auth Blocker](agc-cloud-function-auth.md)）
2. **SDK Convenience**: `@hw-agconnect/cloud` 提供简化的 `callFunction()` API，内部处理认证
3. **Server-Side Logic**: 云函数可执行复杂合并逻辑（冲突检测、去重、时间戳比较）

### Cloud Functions Required

| Function Name | Purpose |
|---------------|---------|
| `sync-add` | 添加/更新口令 (action: 'add' or 'update') |
| `sync-delete` | 软删除口令 |
| `sync-restore` | 恢复已删除口令 |
| `sync-pull` | 拉取并合并云端数据 |

## Dependencies

```json5
// oh-package.json5
"dependencies": {
  "@hw-agconnect/cloud": "^1.0.2"
}
```

## Data Model

```typescript
// Token.ets
interface SyncToken extends Token {
  is_deleted?: boolean;      // 软删除标记
  deleted_at?: string;       // 删除时间（ISO 8601）
  _id?: string;              // 云数据库文档 ID
  _openid?: string;          // 用户 OpenID（云端填充）
  timestamp?: string;        // 最后更新时间（ISO 8601）
}
```

## Error Handling Pattern

所有云函数调用统一处理：

```typescript
const result = await cloud.callFunction({
  name: 'sync-xxx',
  version: '$latest',
  params: { ... },
  timeout: 30000
});

const value: CloudSyncResult = result.getValue() as CloudSyncResult;
if (value === null || value === undefined || value.success !== true) {
  const errMsg = (value?.error) ? value.error : '云同步失败';
  throw new Error(errMsg);
}
```

返回值接口：

```typescript
interface CloudSyncResult {
  success: boolean;
  error?: string;
  data?: SyncToken[];
}
```

## How to Apply This Knowledge

1. **会员同步**: 调用 `sync()` 前检查 `isMember` 状态，非会员不执行
2. **自动同步**: 在用户登录且会员状态下调用 `startAutoSync()`，退出时调用 `stopAutoSync()`
3. **CRUD 触发**: 本地修改后立即调用对应云函数（`addToken`, `updateToken`, `softDeleteToken`, `restoreToken`）
4. **错误容忍**: `sync()` 失败时返回本地数据，不阻塞用户操作
5. **云函数部署**: 确保 AGC 后台已部署 `sync-add`, `sync-delete`, `sync-restore`, `sync-pull` 四个云函数

## Related Memory Files

- [AGC Cloud Function Auth Blocker](agc-cloud-function-auth.md) — 背景：AGC HTTP 触发器认证问题
- [HarmonyOS Cloud Function Success](harmonyos-cloud-function-success.md) — 云函数 SDK 调用验证成功