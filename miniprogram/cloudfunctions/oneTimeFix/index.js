const cloud = require('wx-server-sdk');
cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });

const db = cloud.database();

// Bug 修复 commit 时间戳：2026-06-10 21:38:26
const BUG_FIX_TIME = '2026-06-10T21:38:26+08:00';

exports.main = async (event, context) => {
  const wxContext = cloud.getWXContext();
  const openid = wxContext.OPENID;

  console.log('[ONE_TIME_FIX] Starting for openid:', openid);

  try {
    // 1. 查询所有匹配 _openid 的记录
    const allDocs = await db.collection('user_backups')
      .where({ _openid: openid })
      .get();

    if (allDocs.data.length === 0) {
      return { success: true, message: 'No documents found', recovered: 0, deduplicated: 0 };
    }

    console.log('[ONE_TIME_FIX] Found', allDocs.data.length, 'documents');

    // 测试数据过滤规则：id 1-6 或 account 包含 "alice"
    const isTestData = (token) => {
      const testIds = new Set(['1', '2', '3', '4', '5', '6']);
      return testIds.has(token.id) ||
             (token.account && token.account.toLowerCase().includes('alice'));
    };

    // 合并所有文档的 tokens
    const allTokens = [];
    for (const doc of allDocs.data) {
      for (const token of (doc.tokens || [])) {
        if (!isTestData(token)) {
          allTokens.push(token);
        }
      }
    }

    console.log('[ONE_TIME_FIX] Total tokens (excluding test):', allTokens.length);

    // 2. 恢复误删数据
    // 条件：is_deleted = true 且 deleted_at < BUG_FIX_TIME
    const toRecover = allTokens.filter(token =>
      token.is_deleted === true &&
      token.deleted_at &&
      new Date(token.deleted_at) < new Date(BUG_FIX_TIME)
    );

    console.log('[ONE_TIME_FIX] Tokens to recover:', toRecover.length);
    toRecover.forEach(t => console.log('  -', t.id, t.account, 'deleted_at:', t.deleted_at));

    // 执行恢复
    for (const token of toRecover) {
      token.is_deleted = false;
      token.deleted_at = null;
      token.recovered_at = new Date().toISOString(); // 标记恢复时间
    }

    // 3. 去重清理
    // 按 account:secret 分组
    const groupedBySecret = new Map();
    for (const token of allTokens) {
      // 只对未删除的 token 去重（恢复后的也算）
      if (token.is_deleted !== true) {
        const key = `${token.account || 'unknown'}:${token.secret || 'unknown'}`;
        if (!groupedBySecret.has(key)) {
          groupedBySecret.set(key, []);
        }
        groupedBySecret.get(key).push(token);
      }
    }

    // 找出重复组
    const duplicates = [];
    for (const [key, tokens] of groupedBySecret) {
      if (tokens.length > 1) {
        console.log('[ONE_TIME_FIX] Duplicate group:', key, 'count:', tokens.length);
        // 按时间排序，保留最新的
        const sorted = tokens.sort((a, b) => {
          const timeA = new Date(a.synced_at || a.created_at || 0);
          const timeB = new Date(b.synced_at || b.created_at || 0);
          return timeB - timeA; // 降序，最新的在前
        });
        const keep = sorted[0]; // 保留最新的
        const remove = sorted.slice(1); // 标记其余为删除
        duplicates.push({ key, keep, remove });
      }
    }

    console.log('[ONE_TIME_FIX] Duplicate groups:', duplicates.length);

    // 执行去重：标记旧重复项为删除
    let dedupCount = 0;
    for (const dup of duplicates) {
      for (const token of dup.remove) {
        token.is_deleted = true;
        token.deleted_at = new Date().toISOString();
        token.dedup_reason = `Duplicate of ${dup.keep.id}`;
        dedupCount++;
        console.log('  - Marking duplicate:', token.id, 'keep:', dup.keep.id);
      }
    }

    // 4. 更新所有文档
    // 找到最新的文档作为主记录
    const sortedDocs = allDocs.data.sort((a, b) =>
      new Date(b.timestamp) - new Date(a.timestamp)
    );
    const mainDoc = sortedDocs[0];

    // 构建最终的 token 数组
    const finalTokens = allTokens;

    // 更新主记录
    await db.collection('user_backups').doc(mainDoc._id).update({
      data: {
        tokens: finalTokens,
        timestamp: new Date().toISOString(),
        openid: openid,
      }
    });

    console.log('[ONE_TIME_FIX] Updated main doc:', mainDoc._id);

    // 删除其他文档（已经在 consolidateData 中处理）
    const otherDocs = sortedDocs.slice(1);
    for (const doc of otherDocs) {
      await db.collection('user_backups').doc(doc._id).remove();
      console.log('[ONE_TIME_FIX] Removed doc:', doc._id);
    }

    return {
      success: true,
      message: 'One-time fix completed',
      recovered: toRecover.length,
      deduplicated: dedupCount,
      totalTokens: finalTokens.length,
      activeTokens: finalTokens.filter(t => !t.is_deleted).length,
    };

  } catch (err) {
    console.error('[ONE_TIME_FIX] Error:', err);
    return { success: false, error: err.message };
  }
};