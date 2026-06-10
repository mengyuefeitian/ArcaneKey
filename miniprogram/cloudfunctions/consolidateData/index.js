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

    // 2. 合并所有 tokens，按时间戳去重
    const tokenMap = new Map();
    let latestTimestamp = null;

    // 测试数据过滤规则：id 1-6 或 account 包含 "alice"
    const isTestData = (token) => {
      const testIds = new Set(['1', '2', '3', '4', '5', '6']);
      return testIds.has(token.id) ||
             (token.account && token.account.toLowerCase().includes('alice'));
    };

    for (const doc of allDocs.data) {
      // 更新最新时间戳
      if (!latestTimestamp || new Date(doc.timestamp) > new Date(latestTimestamp)) {
        latestTimestamp = doc.timestamp;
      }

      for (const token of (doc.tokens || [])) {
        // 过滤测试数据
        if (isTestData(token)) {
          console.log('[CONSOLIDATE] Skipping test data:', token.id, token.brand);
          continue;
        }

        const existing = tokenMap.get(token.id);
        if (!existing) {
          tokenMap.set(token.id, token);
        } else {
          // 取最新版本（按 deleted_at/synced_at/created_at）
          const existingTime = existing.deleted_at || existing.synced_at || existing.created_at || '';
          const tokenTime = token.deleted_at || token.synced_at || token.created_at || '';
          if (tokenTime > existingTime) {
            tokenMap.set(token.id, token);
          }
        }
      }
    }

    const mergedTokens = Array.from(tokenMap.values());
    const activeTokens = mergedTokens.filter(t => !t.is_deleted);

    console.log('[CONSOLIDATE] Merged tokens:', mergedTokens.length, 'Active:', activeTokens.length);

    // 3. 找到最新的一条记录作为主记录
    const sortedDocs = allDocs.data.sort((a, b) =>
      new Date(b.timestamp) - new Date(a.timestamp)
    );
    const mainDoc = sortedDocs[0];
    const otherDocs = sortedDocs.slice(1);

    // 4. 更新主记录
    await db.collection('user_backups').doc(mainDoc._id).update({
      data: {
        tokens: mergedTokens,
        active_tokens: activeTokens,
        timestamp: new Date().toISOString(),
        openid: openid, // 修正 openid 为真实值
      }
    });

    console.log('[CONSOLIDATE] Updated main doc:', mainDoc._id);

    // 5. 删除其他记录
    let deletedCount = 0;
    for (const doc of otherDocs) {
      await db.collection('user_backups').doc(doc._id).remove();
      deletedCount++;
      console.log('[CONSOLIDATE] Deleted doc:', doc._id);
    }

    return {
      success: true,
      message: `Consolidated ${allDocs.data.length} documents into 1`,
      merged: mergedTokens.length,
      active: activeTokens.length,
      deleted: deletedCount,
    };

  } catch (err) {
    console.error('[CONSOLIDATE] Error:', err);
    return { success: false, error: err.message };
  }
};