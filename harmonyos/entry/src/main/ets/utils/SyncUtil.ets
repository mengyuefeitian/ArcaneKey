import cloud from '@hw-agconnect/cloud';
import { DatabaseCollection } from '@hw-agconnect/cloud';
import { SyncToken } from '../model/Token';

const ZONE_NAME = 'ArcaneKey';
const SYNC_INTERVAL_MS = 30 * 60 * 1000;

let autoSyncTimer: number = -1;
let currentUserId: string = '';
let tokenCollection: DatabaseCollection<SyncTokenRecord> | null = null;

class SyncTokenRecord {
  static readonly className: string = 'SyncToken';
  id: string = '';
  brand: string = '';
  account: string = '';
  secret: string = '';
  is_deleted: boolean = false;
  deleted_at: string = '';
  timestamp: string = '';
  userId: string = '';
}

function buildRecord(token: SyncToken): SyncTokenRecord {
  const r = new SyncTokenRecord();
  r.id = token.id;
  r.brand = token.brand;
  r.account = token.account;
  r.secret = token.secret;
  r.is_deleted = token.is_deleted ?? false;
  r.deleted_at = token.deleted_at ?? '';
  r.timestamp = new Date().toISOString();
  r.userId = currentUserId;
  return r;
}

function recordToToken(r: SyncTokenRecord): SyncToken {
  return {
    id: r.id,
    brand: r.brand,
    account: r.account,
    secret: r.secret,
    is_deleted: r.is_deleted,
    deleted_at: r.deleted_at,
    timestamp: r.timestamp,
    userId: r.userId
  };
}

export function setCloudUserId(userId: string): void {
  currentUserId = userId;
}

export async function initCloudDB(): Promise<boolean> {
  try {
    const db = cloud.database({
      objectTypeInfo: {
        schemaVersion: 2,
        objectTypes: [
          {
            objectTypeName: 'SyncToken',
            fields: [
              { fieldName: 'id', fieldType: 'String', belongPrimaryKey: false, notNull: true, isNeedEncrypt: false, isSensitive: false, defaultValue: '' },
              { fieldName: 'brand', fieldType: 'String', belongPrimaryKey: false, notNull: true, isNeedEncrypt: false, isSensitive: false, defaultValue: '' },
              { fieldName: 'account', fieldType: 'String', belongPrimaryKey: false, notNull: true, isNeedEncrypt: false, isSensitive: false, defaultValue: '' },
              { fieldName: 'secret', fieldType: 'String', belongPrimaryKey: true, notNull: true, isNeedEncrypt: false, isSensitive: false },
              { fieldName: 'deleted_at', fieldType: 'String', belongPrimaryKey: false, notNull: false, isNeedEncrypt: false, isSensitive: false, defaultValue: '' },
              { fieldName: 'timestamp', fieldType: 'String', belongPrimaryKey: false, notNull: false, isNeedEncrypt: false, isSensitive: false },
              { fieldName: 'is_deleted', fieldType: 'Boolean', belongPrimaryKey: false, notNull: false, isNeedEncrypt: false, isSensitive: false },
              { fieldName: 'userId', fieldType: 'String', belongPrimaryKey: false, notNull: true, isNeedEncrypt: false, isSensitive: false, defaultValue: '' }
            ],
            indexes: []
          }
        ],
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
      },
      zoneName: ZONE_NAME
    });
    tokenCollection = db.collection(SyncTokenRecord);
    console.log('[SyncUtil] initCloudDB ready, zone:', ZONE_NAME);
    return true;
  } catch (e) {
    const err: Error = e as Error;
    console.error('[SyncUtil] initCloudDB failed:', err.message);
    return false;
  }
}

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

export async function updateToken(token: SyncToken): Promise<void> {
  await addToken(token);
}

export async function softDeleteToken(token: SyncToken): Promise<void> {
  if (!tokenCollection) {
    throw new Error('Cloud DB not initialized');
  }
  if (!currentUserId) {
    throw new Error('Cloud user not identified');
  }
  try {
    const deleted: SyncToken = {
      id: token.id,
      brand: token.brand,
      account: token.account,
      secret: token.secret,
      is_deleted: true,
      deleted_at: new Date().toISOString(),
      timestamp: token.timestamp,
      userId: token.userId
    };
    await tokenCollection.upsert(buildRecord(deleted));
    console.log('[SyncUtil] softDeleteToken success:', token.id);
  } catch (e) {
    const err: Error = e as Error;
    console.error('[SyncUtil] softDeleteToken failed:', err.message);
    throw new Error(err.message);
  }
}

export async function restoreToken(token: SyncToken): Promise<void> {
  if (!tokenCollection) {
    throw new Error('Cloud DB not initialized');
  }
  if (!currentUserId) {
    throw new Error('Cloud user not identified');
  }
  try {
    const restored: SyncToken = {
      id: token.id,
      brand: token.brand,
      account: token.account,
      secret: token.secret,
      is_deleted: false,
      deleted_at: '',
      timestamp: token.timestamp,
      userId: token.userId
    };
    await tokenCollection.upsert(buildRecord(restored));
    console.log('[SyncUtil] restoreToken success:', token.id);
  } catch (e) {
    const err: Error = e as Error;
    console.error('[SyncUtil] restoreToken failed:', err.message);
    throw new Error(err.message);
  }
}

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

    const toUpload: SyncTokenRecord[] = [];
    for (const local of localTokens) {
      const inCloud = cloudTokens.find((c: SyncToken): boolean => c.secret === local.secret);
      if (!inCloud) {
        toUpload.push(buildRecord(local));
      }
    }
    if (toUpload.length > 0) {
      await tokenCollection.upsert(toUpload);
    }

    const merged: SyncToken[] = localTokens.slice();
    for (const cloudToken of cloudTokens) {
      const inLocal = localTokens.find((l: SyncToken): boolean => l.secret === cloudToken.secret);
      if (!inLocal) {
        merged.push(cloudToken);
      }
    }

    console.log('[SyncUtil] sync completed, merged:', merged.length);
    return merged;
  } catch (e) {
    const err: Error = e as Error;
    console.error('[SyncUtil] sync failed:', err.message);
    return localTokens;
  }
}

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
  console.log('[SyncUtil] auto sync started');
}

export function stopAutoSync(): void {
  if (autoSyncTimer !== -1) {
    clearInterval(autoSyncTimer);
    autoSyncTimer = -1;
  }
}
