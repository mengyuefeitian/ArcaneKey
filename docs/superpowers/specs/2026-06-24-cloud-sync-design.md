# HarmonyOS 云同步设计

## 概述

会员专享的 TOTP 口令云同步功能，使用华为 AGC 云数据库。

## 架构

```
Index.ets → SyncUtil.ets → AGC Database (user_backups)
```

## 核心规则

| 规则 | 说明 |
|------|------|
| 会员专享 | 非会员不执行同步 |
| secret 唯一 | 防止重复口令 |
| 软删除 | `is_deleted: true` 标记 |
| 即时同步 | 操作后立即推送 |
| 定时同步 | 30分钟间隔拉取 |

## 数据结构

```typescript
interface SyncToken extends Token {
  is_deleted?: boolean;
  deleted_at?: string;
}

interface CloudBackup {
  openid: string;
  tokens: SyncToken[];
  timestamp: string;
}
```

## 文件清单

| 文件 | 说明 |
|------|------|
| `utils/SyncUtil.ets` | 同步核心逻辑 |
| `model/Token.ets` | 扩展 SyncToken 类型 |

## API 设计

```typescript
// SyncUtil.ets
export function addToken(token: SyncToken): Promise<void>
export function updateToken(token: SyncToken): Promise<void>
export function softDeleteToken(id: string): Promise<void>
export function restoreToken(id: string): Promise<void>
export function sync(): Promise<void>
export function startAutoSync(): void
```
