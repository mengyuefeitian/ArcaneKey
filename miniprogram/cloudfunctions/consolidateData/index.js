const cloud = require('wx-server-sdk');
cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });

const db = cloud.database();

exports.main = async (event, context) => {
  const wxContext = cloud.getWXContext();
  const openid = wxContext.OPENID;

  console.log('[CONSOLIDATE] Starting for openid:', openid);

  try {
    // 1. 查询所有匹配 _openid 的记录
    const allDocs = await db.collection('user_backups')
      .where({ _openid: openid })
      .get();

    if (allDocs.data.length === 0) {
      return { success: true, message: 'No documents found', merged: 0 };
    }

    console.log('[CONSOLIDATE] Found', allDocs.data.length, 'documents');

    // 测试数据过滤规则：id 1-6 或 account 包含 "alice"
    const isTestData = (token) => {
      const testIds = new Set(['1', '2', '3', '4', '5', '6']);
      return testIds.has(token.id) ||
             (token.account && token.account.toLowerCase().includes('alice'));
    };

    // 2. 第一轮合并：按 token id 去重（合并分散文档）
    const tokenMapById = new Map();

    for (const doc of allDocs.data) {
      for (const token of (doc.tokens || [])) {
        // 过滤测试数据
        if (isTestData(token)) {
          continue;
        }

        const existing = tokenMapById.get(token.id);
        if (!existing) {
          tokenMapById.set(token.id, token);
        } else {
          // 取最新版本（按 deleted_at/synced_at/created_at）
          const existingTime = existing.deleted_at || existing.synced_at || existing.created_at || '';
          const tokenTime = token.deleted_at || token.synced_at || token.created_at || '';
          if (tokenTime > existingTime) {
            tokenMapById.set(token.id, token);
          }
        }
      }
    }

    const mergedById = Array.from(tokenMapById.values());
    console.log('[CONSOLIDATE] After id merge:', mergedById.length, 'tokens');

    // 3. 第二轮清理：按 account:secret 去重（清理重复账号）
    const tokenMapBySecret = new Map();

    for (const token of mergedById) {
      // 只处理未删除的 token（活跃数据）
      if (!token.is_deleted) {
        const key = `${token.account || 'unknown'}:${token.secret || 'unknown'}`;
        const existing = tokenMapBySecret.get(key);

        if (!existing) {
          tokenMapBySecret.set(key, token);
        } else {
          // 保留最新时间戳的 token
          const existingTime = new Date(existing.synced_at || existing.created_at || 0);
          const tokenTime = new Date(token.synced_at || token.created_at || 0);
          if (tokenTime > existingTime) {
            // 新的更新，标记旧的为删除
            existing.is_deleted = true;
            existing.deleted_at = new Date().toISOString();
            existing.dedup_reason = `Duplicate of ${token.id}`;
            tokenMapBySecret.set(key, token);
          } else {
            // 旧的更新，标记新的为删除
            token.is_deleted = true;
            token.deleted_at = new Date().toISOString();
            token.dedup_reason = `Duplicate of ${existing.id}`;
          }
        }
      }
    }

    // 4. 第三轮清理：物理删除测试数据和软删除数据
    const finalTokens = [];
    let removedCount = 0;

    for (const token of mergedById) {
      if (isTestData(token) || token.is_deleted) {
        removedCount++;
        console.log('[CONSOLIDATE] Removing:', token.id, token.account,
          isTestData(token) ? '(test data)' : '(deleted/duplicate)');
      } else {
        finalTokens.push(token);
      }
    }

    console.log('[CONSOLIDATE] Final tokens:', finalTokens.length, 'Removed:', removedCount);

    // 5. 更新云端记录
    const sortedDocs = allDocs.data.sort((a, b) =>
      new Date(b.timestamp) - new Date(a.timestamp)
    );
    const mainDoc = sortedDocs[0];

    await db.collection('user_backups').doc(mainDoc._id).update({
      data: {
        tokens: finalTokens,
        timestamp: new Date().toISOString(),
        openid: openid,
      }
    });

    console.log('[CONSOLIDATE] Updated main doc:', mainDoc._id);

    // 删除其他文档
    for (const doc of sortedDocs.slice(1)) {
      await db.collection('user_backups').doc(doc._id).remove();
      console.log('[CONSOLIDATE] Removed doc:', doc._id);
    }

    return {
      success: true,
      message: 'Consolidated and cleaned',
      merged: mergedById.length,
      removed: removedCount,
      remaining: finalTokens.length,
    };

  } catch (err) {
    console.error('[CONSOLIDATE] Error:', err);
    return { success: false, error: err.message };
  }
};