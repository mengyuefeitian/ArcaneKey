export const MULTI_PART_SUFFIXES: string[] = [
  'com.cn', 'net.cn', 'org.cn', 'gov.cn', 'edu.cn', 'ac.cn',
  'co.uk', 'org.uk', 'gov.uk', 'ac.uk',
  'co.jp', 'or.jp', 'ne.jp',
  'com.hk', 'com.tw', 'com.au', 'com.br', 'co.kr',
  'github.io',
];

const IPV4_RE = new RegExp('^\\d{1,3}(\\.\\d{1,3}){3}$');

export function extractDomain(url: string): string {
  if (!url) return '';
  let s: string = url.trim().toLowerCase();
  const schemeIdx: number = s.indexOf('://');
  if (schemeIdx >= 0) s = s.substring(schemeIdx + 3);
  s = s.split('/')[0].split('?')[0].split('#')[0];
  const atIdx: number = s.lastIndexOf('@');
  if (atIdx >= 0) s = s.substring(atIdx + 1);
  const colonIdx: number = s.indexOf(':');
  if (colonIdx >= 0) s = s.substring(0, colonIdx);
  s = s.trim();
  if (!s) return '';
  if (IPV4_RE.test(s)) return s;
  const labels: string[] = s.split('.').filter((l: string) => l.length > 0);
  if (labels.length <= 1) return s;
  const lastTwo: string = labels.slice(-2).join('.');
  if (MULTI_PART_SUFFIXES.indexOf(lastTwo) >= 0) {
    return labels.slice(-3).join('.');
  }
  return lastTwo;
}
