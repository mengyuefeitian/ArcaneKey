/**
 * SyncUtil.ets - 云同步核心逻辑
 * 使用 AGC 云函数实现云端同步
 */
import cloud from '@hw-agconnect/cloud';
import { SyncToken } from '../model/Token';

const SYNC_INTERVAL_MS = 30 * 60 * 1000; // 30 分钟

let autoSyncTimer: number = -1;

/**
 * 云函数返回值接口
 */
interface CloudSyncResult {
  success: boolean;
  error?: string;
  data?: SyncToken[];
}

/**
 * 初始化云同步
 * AGC SDK 会自动使用当前登录用户的凭证
 * @returns 是否初始化成功
 */
export async function initCloudDB(): Promise<boolean> {
  try {
    // AGC SDK 会自动初始化，无需额外配置
    console.log('[SyncUtil] initCloudDB: ready');
    return true;
  } catch (e) {
    const err: Error = e as Error;
    console.error('[SyncUtil] initCloudDB failed:', err.message);
    return false;
  }
}

/**
 * 添加口令到云端（通过云函数）
 * @param token 要添加的口令
 */
export async function addToken(token: SyncToken): Promise<void> {
  try {
    const result = await cloud.callFunction({
      name: 'sync-add',
      version: '$latest',
      params: { action: 'add', token: token },
      timeout: 30000
    });

    const value: CloudSyncResult = result.getValue() as CloudSyncResult;
    if (value === null || value === undefined || value.success !== true) {
      const errMsg: string = (value !== null && value !== undefined && value.error !== undefined)
        ? value.error : '云同步失败';
      throw new Error(errMsg);
    }

    console.log('[SyncUtil] addToken success:', token.id);
  } catch (e) {
    const err: Error = e as Error;
    console.error('[SyncUtil] addToken failed:', err.message);
    throw new Error(err.message);
  }
}

/**
 * 更新云端口令（通过云函数）
 * @param token 更新后的口令
 */
export async function updateToken(token: SyncToken): Promise<void> {
  try {
    const result = await cloud.callFunction({
      name: 'sync-add',
      version: '$latest',
      params: { action: 'update', token: token },
      timeout: 30000
    });

    const value: CloudSyncResult = result.getValue() as CloudSyncResult;
    if (value === null || value === undefined || value.success !== true) {
      const errMsg: string = (value !== null && value !== undefined && value.error !== undefined)
        ? value.error : '云同步失败';
      throw new Error(errMsg);
    }

    console.log('[SyncUtil] updateToken success:', token.id);
  } catch (e) {
    const err: Error = e as Error;
    console.error('[SyncUtil] updateToken failed:', err.message);
    throw new Error(err.message);
  }
}

/**
 * 软删除口令（通过云函数）
 * @param id 口令 ID
 */
export async function softDeleteToken(id: string): Promise<void> {
  try {
    const result = await cloud.callFunction({
      name: 'sync-delete',
      version: '$latest',
      params: { id: id },
      timeout: 30000
    });

    const value: CloudSyncResult = result.getValue() as CloudSyncResult;
    if (value === null || value === undefined || value.success !== true) {
      const errMsg: string = (value !== null && value !== undefined && value.error !== undefined)
        ? value.error : '云同步失败';
      throw new Error(errMsg);
    }

    console.log('[SyncUtil] softDeleteToken success:', id);
  } catch (e) {
    const err: Error = e as Error;
    console.error('[SyncUtil] softDeleteToken failed:', err.message);
    throw new Error(err.message);
  }
}

/**
 * 恢复已删除的口令（通过云函数）
 * @param id 口令 ID
 */
export async function restoreToken(id: string): Promise<void> {
  try {
    const result = await cloud.callFunction({
      name: 'sync-restore',
      version: '$latest',
      params: { id: id },
      timeout: 30000
    });

    const value: CloudSyncResult = result.getValue() as CloudSyncResult;
    if (value === null || value === undefined || value.success !== true) {
      const errMsg: string = (value !== null && value !== undefined && value.error !== undefined)
        ? value.error : '云同步失败';
      throw new Error(errMsg);
    }

    console.log('[SyncUtil] restoreToken success:', id);
  } catch (e) {
    const err: Error = e as Error;
    console.error('[SyncUtil] restoreToken failed:', err.message);
    throw new Error(err.message);
  }
}

/**
 * 执行云端同步（通过云函数）
 * 拉取云端数据并与本地合并
 * @param localTokens 本地口令列表
 * @param isMember 是否为会员（非会员不执行同步）
 * @returns 同步后的口令列表
 */
export async function sync(localTokens: SyncToken[], isMember: boolean): Promise<SyncToken[]> {
  // 会员专享：非会员不执行任何同步操作
  if (!isMember) {
    console.log('[SyncUtil] sync skipped: not a member');
    return localTokens;
  }

  try {
    console.log('[SyncUtil] sync started, local tokens:', localTokens.length);

    const result = await cloud.callFunction({
      name: 'sync-pull',
      version: '$latest',
      params: { localTokens: localTokens },
      timeout: 30000
    });

    const value: CloudSyncResult = result.getValue() as CloudSyncResult;
    if (value === null || value === undefined || value.success !== true) {
      const errMsg: string = (value !== null && value !== undefined && value.error !== undefined)
        ? value.error : '云同步失败';
      throw new Error(errMsg);
    }

    const merged: SyncToken[] = (value.data !== undefined) ? value.data : localTokens;
    console.log('[SyncUtil] sync completed, merged tokens:', merged.length);
    return merged;
  } catch (e) {
    const err: Error = e as Error;
    console.error('[SyncUtil] sync failed:', err.message);
    // 同步失败时返回本地数据，不影响用户使用
    return localTokens;
  }
}

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
      const err: Error = e as Error;
      console.error('[SyncUtil] auto sync error:', err.message);
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
