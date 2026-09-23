import { PasswordEntry } from '../model/PasswordEntry';
import { extractDomain } from './DomainUtil';

// 密码 CSV 导入的冲突分类与应用逻辑（纯函数，不涉及 UI / 存储）。
//
// 分组键：主域名 + 用户名（小写、去空格）。与旧版 mergePasswordCsv 保持一致。
export function passwordKeyOf(e: PasswordEntry): string {
  return extractDomain(e.url) + ' ' + e.username.trim().toLowerCase();
}

// 冲突条目的处理方式：'update' 覆盖已有账号的密码，'add' 作为新账号追加。
export type PasswordConflictChoice = string;

export interface PasswordConflict {
  incoming: PasswordEntry;
  targetId: string;
  domain: string;
  username: string;
  choice: PasswordConflictChoice;
}

// 同键且密码相同的一行——合并 name/url/note，密码不变。
export interface PasswordSame {
  incoming: PasswordEntry;
  targetId: string;
}

export interface PasswordClassifyResult {
  news: PasswordEntry[];
  sames: PasswordSame[];
  conflicts: PasswordConflict[];
  // apply() 中「增加」选择继续生成 id 的起点，避免与 news 中已生成的 id 撞车。
  nextIdSeed: number;
}

export interface PasswordApplyResult {
  list: PasswordEntry[];
  added: number;
  updated: number;
  appended: number;
  skipped: number;
}

// 按 CSV 行顺序依次分类。同一批 CSV 中若有多行同键：先出现的一行视为「新增」，
// 并立刻登记为已存在，之后同键的行会与它比较（这样才能感知「批内新增」），
// 保持简单确定：不做跨行去重、不回溯已分类的行。
export function classifyPasswordImport(existing: PasswordEntry[], incoming: PasswordEntry[]): PasswordClassifyResult {
  const byKey: Record<string, PasswordEntry[]> = {};
  for (const e of existing) {
    const k = passwordKeyOf(e);
    if (!byKey[k]) { byKey[k] = []; }
    byKey[k].push(e);
  }

  const news: PasswordEntry[] = [];
  const sames: PasswordSame[] = [];
  const conflicts: PasswordConflict[] = [];
  const baseTs: number = Date.now();
  let counter: number = 0;

  const latestOf = (group: PasswordEntry[]): PasswordEntry => {
    let target: PasswordEntry = group[0];
    for (const g of group) {
      if (g.timestamp > target.timestamp) { target = g; }
    }
    return target;
  };

  for (const inc of incoming) {
    const k: string = passwordKeyOf(inc);
    const group: PasswordEntry[] = byKey[k];

    if (!group || group.length === 0) {
      const fresh: PasswordEntry = {
        id: (baseTs + counter).toString(),
        name: inc.name, url: inc.url, username: inc.username,
        password: inc.password, note: inc.note,
        timestamp: new Date().toISOString(),
      };
      counter++;
      news.push(fresh);
      byKey[k] = [fresh];
      continue;
    }

    // 空密码行：CSV 只提供了账号/网址等信息，不应把已有密码清空，按「相同」处理。
    if (inc.password === '') {
      const target: PasswordEntry = latestOf(group);
      sames.push({ incoming: inc, targetId: target.id });
      continue;
    }

    let sameMatch: PasswordEntry | null = null;
    for (const g of group) {
      if (g.password === inc.password) { sameMatch = g; break; }
    }
    if (sameMatch !== null) {
      sames.push({ incoming: inc, targetId: sameMatch.id });
      continue;
    }

    const target: PasswordEntry = latestOf(group);
    conflicts.push({
      incoming: inc,
      targetId: target.id,
      domain: extractDomain(inc.url),
      username: inc.username,
      choice: 'update',
    });
  }

  return { news: news, sames: sames, conflicts: conflicts, nextIdSeed: baseTs + counter };
}

// 依据 classifyPasswordImport 的结果（冲突项的 choice 可能已被用户修改）写入最终列表。
// 顺序：先加入 news（其 id 在 classify 阶段已生成，conflicts 的 targetId 可能引用它们），
// 再合并 sames，最后处理 conflicts。不修改入参，返回全新数组/对象。
export function applyPasswordImport(
  existing: PasswordEntry[],
  classification: PasswordClassifyResult,
  isMember: boolean,
  limit: number
): PasswordApplyResult {
  const work: PasswordEntry[] = existing.slice();
  let added: number = 0;
  let updated: number = 0;
  let appended: number = 0;
  let skipped: number = 0;
  let nextId: number = classification.nextIdSeed;

  const canAdd = (): boolean => isMember || work.length < limit;

  for (const inc of classification.news) {
    if (!canAdd()) { skipped++; continue; }
    work.push(inc);
    added++;
  }

  for (const s of classification.sames) {
    const idx: number = work.findIndex((x: PasswordEntry): boolean => x.id === s.targetId);
    if (idx < 0) { skipped++; continue; }
    const x: PasswordEntry = work[idx];
    const inc: PasswordEntry = s.incoming;
    const merged: PasswordEntry = {
      id: x.id,
      name: inc.name || x.name,
      url: inc.url || x.url,
      username: x.username,
      password: x.password,
      note: inc.note || x.note,
      timestamp: new Date().toISOString(),
    };
    work[idx] = merged;
    updated++;
  }

  for (const c of classification.conflicts) {
    if (c.choice === 'add') {
      if (!canAdd()) { skipped++; continue; }
      const fresh: PasswordEntry = {
        id: nextId.toString(),
        name: c.incoming.name, url: c.incoming.url, username: c.incoming.username,
        password: c.incoming.password, note: c.incoming.note,
        timestamp: new Date().toISOString(),
      };
      nextId++;
      work.push(fresh);
      appended++;
      continue;
    }
    const idx: number = work.findIndex((x: PasswordEntry): boolean => x.id === c.targetId);
    if (idx < 0) { skipped++; continue; }
    const x: PasswordEntry = work[idx];
    const merged: PasswordEntry = {
      id: x.id,
      name: c.incoming.name || x.name,
      url: c.incoming.url || x.url,
      username: x.username,
      password: c.incoming.password,
      note: c.incoming.note || x.note,
      timestamp: new Date().toISOString(),
    };
    work[idx] = merged;
    updated++;
  }

  return { list: work, added: added, updated: updated, appended: appended, skipped: skipped };
}
