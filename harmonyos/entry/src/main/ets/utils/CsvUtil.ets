import { PasswordEntry } from '../model/PasswordEntry';
import { extractDomain } from './DomainUtil';

export function parseCsv(text: string): string[][] {
  let t: string = text;
  if (t.length > 0 && t.charCodeAt(0) === 0xFEFF) t = t.substring(1);
  const rows: string[][] = [];
  let row: string[] = [];
  let field: string = '';
  let inQuotes: boolean = false;
  let i: number = 0;
  const n: number = t.length;
  while (i < n) {
    const ch: string = t[i];
    if (inQuotes) {
      if (ch === '"') {
        if (i + 1 < n && t[i + 1] === '"') { field += '"'; i += 2; continue; }
        inQuotes = false; i++; continue;
      }
      field += ch; i++; continue;
    }
    if (ch === '"') { inQuotes = true; i++; continue; }
    if (ch === ',') { row.push(field); field = ''; i++; continue; }
    if (ch === '\r') { i++; continue; }
    if (ch === '\n') { row.push(field); rows.push(row); row = []; field = ''; i++; continue; }
    field += ch; i++;
  }
  if (field.length > 0 || row.length > 0) { row.push(field); rows.push(row); }
  return rows;
}

const COL_ALIASES: Record<string, string[]> = {
  'name': ['name', 'title'],
  'url': ['url', 'origin', 'login_uri', 'website'],
  'username': ['username', 'login', 'login_username', 'user'],
  'password': ['password', 'login_password', 'pass'],
  'note': ['note', 'notes', 'comment', 'comments', 'extra'],
};

interface HeaderMap {
  name: number;
  url: number;
  username: number;
  password: number;
  note: number;
}

function buildHeaderMap(header: string[]): HeaderMap {
  const map: HeaderMap = { name: -1, url: -1, username: -1, password: -1, note: -1 };
  const fields: string[] = ['name', 'url', 'username', 'password', 'note'];
  for (let idx = 0; idx < header.length; idx++) {
    const key: string = header[idx].trim().toLowerCase();
    for (const field of fields) {
      const aliases: string[] = COL_ALIASES[field];
      if (aliases.indexOf(key) >= 0) {
        if (field === 'name' && map.name < 0) map.name = idx;
        else if (field === 'url' && map.url < 0) map.url = idx;
        else if (field === 'username' && map.username < 0) map.username = idx;
        else if (field === 'password' && map.password < 0) map.password = idx;
        else if (field === 'note' && map.note < 0) map.note = idx;
      }
    }
  }
  return map;
}

export function parsePasswordCsv(text: string): PasswordEntry[] {
  const rows: string[][] = parseCsv(text);
  if (rows.length < 2) return [];
  const h: HeaderMap = buildHeaderMap(rows[0]);
  if (h.password < 0 && h.username < 0 && h.url < 0) return [];
  const out: PasswordEntry[] = [];
  let ts: number = Date.now();
  const cell = (cells: string[], idx: number): string =>
    (idx >= 0 && idx < cells.length ? cells[idx].trim() : '');
  for (let r = 1; r < rows.length; r++) {
    const cells: string[] = rows[r];
    if (cells.length === 1 && cells[0].trim() === '') continue;
    const url: string = cell(cells, h.url);
    const username: string = cell(cells, h.username);
    const password: string = cell(cells, h.password);
    const note: string = cell(cells, h.note);
    if (!url && !username && !password) continue;
    let name: string = cell(cells, h.name);
    if (!name) name = extractDomain(url) || url || username;
    const entry: PasswordEntry = {
      id: (ts++).toString(),
      name: name, url: url, username: username, password: password, note: note,
      timestamp: new Date().toISOString(),
    };
    out.push(entry);
  }
  return out;
}

function csvCell(v: string): string {
  const s: string = v ?? '';
  if (s.indexOf('"') >= 0 || s.indexOf(',') >= 0 || s.indexOf('\n') >= 0 || s.indexOf('\r') >= 0) {
    return '"' + s.split('"').join('""') + '"';
  }
  return s;
}

export function toCsv(entries: PasswordEntry[]): string {
  const lines: string[] = ['name,url,username,password,note'];
  for (const e of entries) {
    lines.push(
      csvCell(e.name) + ',' + csvCell(e.url) + ',' + csvCell(e.username) + ',' +
      csvCell(e.password) + ',' + csvCell(e.note)
    );
  }
  return lines.join('\r\n') + '\r\n';
}
