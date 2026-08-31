import { extractDomain } from '../utils/DomainUtil';

export interface PasswordEntry {
  id: string;
  name: string;
  url: string;
  username: string;
  password: string;
  note: string;
  timestamp: string;
}

export interface PasswordGroup {
  domain: string;
  entries: PasswordEntry[];
}

// 无法解析域名的条目归入此哨兵组；UI 显示「其他」。用哨兵而非空串，
// 这样点击该组能设 openDomain 进入详情、onBackPress 能识别、ForEach key 非空。
export const OTHER_DOMAIN: string = '__other__';

// 按主域名分组。分组顺序：条目多的在前，其次域名字母序。哨兵组排最后。
export function groupByDomain(list: PasswordEntry[]): PasswordGroup[] {
  const map: Record<string, PasswordEntry[]> = {};
  for (const e of list) {
    const d: string = extractDomain(e.url);
    const key: string = d.length > 0 ? d : OTHER_DOMAIN;
    if (!map[key]) map[key] = [];
    map[key].push(e);
  }
  const groups: PasswordGroup[] = [];
  for (const key of Object.keys(map)) {
    const entries: PasswordEntry[] = map[key].slice().sort(
      (a: PasswordEntry, b: PasswordEntry) => (a.name || a.username).localeCompare(b.name || b.username)
    );
    groups.push({ domain: key, entries: entries });
  }
  groups.sort((a: PasswordGroup, b: PasswordGroup) => {
    if (a.domain === OTHER_DOMAIN && b.domain !== OTHER_DOMAIN) return 1;
    if (b.domain === OTHER_DOMAIN && a.domain !== OTHER_DOMAIN) return -1;
    if (b.entries.length !== a.entries.length) return b.entries.length - a.entries.length;
    return a.domain.localeCompare(b.domain);
  });
  return groups;
}

// 某条目是否属于指定分组 key（key 可能是域名或 OTHER_DOMAIN 哨兵）。
export function entryInDomain(e: PasswordEntry, domainKey: string): boolean {
  const d: string = extractDomain(e.url);
  return domainKey === OTHER_DOMAIN ? d === '' : d === domainKey;
}
