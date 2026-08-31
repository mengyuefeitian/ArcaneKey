# HarmonyOS 本地密码管理器 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给星枢令 HarmonyOS App 新增一个本地密码库（按域名分组、CSV 本地导入导出），并把口令首页搜索框改为常驻顶部、移除底部导航「搜索」项。

**Architecture:** 三个新纯函数/数据文件（`DomainUtil` / `CsvUtil` / `PasswordEntry`），一个新全屏视图 `PasswordView`（在 `Index.ets` 的 `Tabs` 里作第 4 个 `TabContent`，index=3），密码明文存 `preferences`（复用 `StorageUtil` 的 `pref` 单例）。进入密码 tab 前复用现有 `authenticateSecurity` 应用锁。CSV 导入导出复用现有 `doBackup` / `selectImportFile` 的文件读写模式，仅会员可用。

**Tech Stack:** ArkTS / HarmonyOS 6.1 (API 23)，DevEco Studio，`@kit.ArkData` preferences，`@kit.CoreFileKit` DocumentViewPicker，`@ohos.file.fs`。无新增依赖。

**Spec:** `docs/superpowers/specs/2026-08-31-harmonyos-password-manager-design.md`

## Global Constraints

- 目标平台：HarmonyOS 6.1 / API 23。仅 `harmonyos/` 目录；微信小程序端本次不动。
- 每次 `.ets` 改动后必须跑构建（下方 Build 命令），**构建不通过 = 任务未完成**。
- 所有 `@State` / `@Link` / `@Prop` 字段必须有类型注解 **且** 有初值。
- 禁止匿名对象字面量类型作装饰器字段类型 —— 用命名 `interface`。
- `@Builder` 值参数不可响应 —— builder 内部必须直接读 `this.xxx`，不能依赖传入的值参数刷新。
- import 路径从现有工作文件拷贝，不凭记忆写。
- 资源文件名必须全小写 ASCII。禁止 `密钥.svg` 之类文件名。
- 禁止把密码走 XOR 加密并在 UI 标「已加密」。密码明文存储（已与用户确认）。
- 禁止用 `split(',')` / `split('\n')` 解析 CSV。
- 新的 `TabContent` 必须是第 4 个，index=3。禁止插在 index 0/1/2 之间。
- UI 文案全部中文。
- 非会员密码条目上限 `FREE_PASSWORD_LIMIT = 5`；CSV 导入/导出仅会员。
- Git 提交信息格式 `<type>: <描述>`，中文描述可。开发完成后**不要**自行 merge / push。

## Build 命令

```bash
cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
```

预期：`BUILD SUCCESSFUL`，无 ArkTS / 编译 / import / 资源错误。

## 纯函数验证约定

项目无测试框架。`DomainUtil` / `CsvUtil` 的纯逻辑先在 scratchpad 里用 Node 写好并跑通断言，再逐字移植进 `.ets`（补 ArkTS 类型注解 + `export`）。scratchpad 文件不入库。

scratchpad 目录：`/private/tmp/claude-501/-Users-xiaoan-Documents-code-ArcaneKey/573087f4-a63c-4a3f-96db-e4f75574b44c/scratchpad`

---

## 文件结构

**新增**
| 文件 | 职责 |
|---|---|
| `harmonyos/entry/src/main/ets/utils/DomainUtil.ets` | `extractDomain(url)` 纯函数 + `MULTI_PART_SUFFIXES` 常量 |
| `harmonyos/entry/src/main/ets/model/PasswordEntry.ets` | `PasswordEntry` / `PasswordGroup` 接口 + `groupByDomain()` |
| `harmonyos/entry/src/main/ets/utils/CsvUtil.ets` | `parseCsv` / `parsePasswordCsv` / `toCsv` |
| `harmonyos/entry/src/main/ets/views/PasswordView.ets` | 密码库全屏视图（两级导航 + 增改删 + 搜索） |
| `harmonyos/entry/src/main/resources/base/media/icon_password.svg` | 底部导航「密码」图标 |

**修改**
| 文件 | 改动 |
|---|---|
| `harmonyos/entry/src/main/ets/model/Token.ets` | 加 `FREE_PASSWORD_LIMIT` |
| `harmonyos/entry/src/main/ets/utils/StorageUtil.ets` | 加 `loadPasswords` / `savePasswords` |
| `harmonyos/entry/src/main/ets/views/HomeView.ets` | 搜索行常驻、去返回箭头、去自动聚焦、去 `@Link searching` |
| `harmonyos/entry/src/main/ets/pages/Index.ets` | 删 `searching` 状态、底部导航「搜索」→「密码」、新 `TabContent` index=3、密码相关 state、应用锁门禁、`onBackPress`、CSV 导入导出 |

---

## Task 1: DomainUtil —— 域名提取纯函数

**Files:**
- Create: `harmonyos/entry/src/main/ets/utils/DomainUtil.ets`
- Test (scratchpad, 不入库): `scratchpad/domainutil.mjs` + `scratchpad/test-domainutil.mjs`

**Interfaces:**
- Consumes: 无
- Produces:
  - `export const MULTI_PART_SUFFIXES: string[]`
  - `export function extractDomain(url: string): string` —— 返回主域名（如 `google.com`）；无法解析返回 `''`

- [ ] **Step 1: scratchpad 里写实现 + 断言**

`scratchpad/domainutil.mjs`:

```js
export const MULTI_PART_SUFFIXES = [
  'com.cn', 'net.cn', 'org.cn', 'gov.cn', 'edu.cn', 'ac.cn',
  'co.uk', 'org.uk', 'gov.uk', 'ac.uk',
  'co.jp', 'or.jp', 'ne.jp',
  'com.hk', 'com.tw', 'com.au', 'com.br', 'co.kr',
  'github.io',
];

export function extractDomain(url) {
  if (!url) return '';
  let s = url.trim().toLowerCase();
  // 去 scheme
  const schemeIdx = s.indexOf('://');
  if (schemeIdx >= 0) s = s.substring(schemeIdx + 3);
  // 去 path / query / frag
  s = s.split('/')[0].split('?')[0].split('#')[0];
  // 去 userinfo
  const atIdx = s.lastIndexOf('@');
  if (atIdx >= 0) s = s.substring(atIdx + 1);
  // 去 port
  const colonIdx = s.indexOf(':');
  if (colonIdx >= 0) s = s.substring(0, colonIdx);
  s = s.trim();
  if (!s) return '';
  // IPv4
  if (/^\d{1,3}(\.\d{1,3}){3}$/.test(s)) return s;
  const labels = s.split('.').filter(l => l.length > 0);
  if (labels.length <= 1) return s;
  const lastTwo = labels.slice(-2).join('.');
  if (MULTI_PART_SUFFIXES.indexOf(lastTwo) >= 0) {
    return labels.slice(-3).join('.');
  }
  return lastTwo;
}
```

`scratchpad/test-domainutil.mjs`:

```js
import { extractDomain } from './domainutil.mjs';
import assert from 'node:assert';

const cases = [
  ['https://accounts.google.com/signin', 'google.com'],
  ['http://mail.google.com', 'google.com'],
  ['https://user:pw@sub.example.co.uk:8443/path?q=1', 'example.co.uk'],
  ['http://a.b.foo.com.cn/x', 'foo.com.cn'],
  ['foo.com.cn', 'foo.com.cn'],
  ['192.168.1.1', '192.168.1.1'],
  ['localhost', 'localhost'],
  ['', ''],
  ['   ', ''],
  ['https://GitHub.com', 'github.com'],
  ['myuser.github.io', 'myuser.github.io'],
  ['https://www.baidu.com/', 'baidu.com'],
];
for (const [input, expected] of cases) {
  assert.strictEqual(extractDomain(input), expected, `extractDomain(${JSON.stringify(input)})`);
}
console.log('DomainUtil: all', cases.length, 'cases passed');
```

- [ ] **Step 2: 跑测试，确认全绿**

Run: `node scratchpad/test-domainutil.mjs`
Expected: `DomainUtil: all 12 cases passed`

- [ ] **Step 3: 移植进 `.ets`**

`harmonyos/entry/src/main/ets/utils/DomainUtil.ets` —— 与 mjs 逻辑逐字一致，补类型：

```ts
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
```

- [ ] **Step 4: 构建验证**

Run: Build 命令
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 5: 提交**

```bash
git add harmonyos/entry/src/main/ets/utils/DomainUtil.ets
git commit -m "feat(harmonyos): 域名提取工具 DomainUtil"
```

---

## Task 2: PasswordEntry 模型 + 存储 + 常量

**Files:**
- Create: `harmonyos/entry/src/main/ets/model/PasswordEntry.ets`
- Modify: `harmonyos/entry/src/main/ets/model/Token.ets`（文件末尾追加）
- Modify: `harmonyos/entry/src/main/ets/utils/StorageUtil.ets`（文件末尾追加 + import）

**Interfaces:**
- Consumes: `extractDomain` from `../utils/DomainUtil`（Task 1）
- Produces:
  - `export interface PasswordEntry { id: string; name: string; url: string; username: string; password: string; note: string; timestamp: string }`
  - `export interface PasswordGroup { domain: string; entries: PasswordEntry[] }`
  - `export function groupByDomain(list: PasswordEntry[]): PasswordGroup[]`
  - `export const OTHER_DOMAIN: string`（`'__other__'` 哨兵，无法解析域名的分组 key）
  - `export function entryInDomain(e: PasswordEntry, domainKey: string): boolean`
  - `export const FREE_PASSWORD_LIMIT: number`（在 `model/Token.ets`）
  - `export async function loadPasswords(): Promise<PasswordEntry[]>`（在 `StorageUtil.ets`）
  - `export async function savePasswords(list: PasswordEntry[]): Promise<void>`（在 `StorageUtil.ets`）

- [ ] **Step 1: 创建 `model/PasswordEntry.ets`**

```ts
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
```

- [ ] **Step 2: 在 `model/Token.ets` 末尾追加常量**

现有末尾是：
```ts
export const FREE_TOKEN_LIMIT: number = 5;
export const MEMBERSHIP_PRICE: number = 19.90;
export const APP_NAME: string = '星枢令';
```
在其后追加：
```ts
export const FREE_PASSWORD_LIMIT: number = 5;
```

- [ ] **Step 3: 在 `StorageUtil.ets` 加密码读写**

顶部 import 改为（追加 `PasswordEntry`）：
```ts
import { Token, ThemeItem } from '../model/Token';
import { PasswordEntry } from '../model/PasswordEntry';
```

文件末尾追加：
```ts
const PASSWORDS_KEY = 'ak_passwords';

export async function loadPasswords(): Promise<PasswordEntry[]> {
  try {
    if (!pref) return [];
    const val = await pref.get(PASSWORDS_KEY, '');
    if (!val || typeof val !== 'string' || val === '') return [];
    const parsed = JSON.parse(val as string) as PasswordEntry[];
    return Array.isArray(parsed) ? parsed : [];
  } catch (e) {
    return [];
  }
}

export async function savePasswords(list: PasswordEntry[]): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(PASSWORDS_KEY, JSON.stringify(list));
    await pref.flush();
  } catch (e) {
    console.error('savePasswords failed: ' + (e as Error).message);
  }
}
```

- [ ] **Step 4: 构建验证**

Run: Build 命令
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 5: 提交**

```bash
git add harmonyos/entry/src/main/ets/model/PasswordEntry.ets harmonyos/entry/src/main/ets/model/Token.ets harmonyos/entry/src/main/ets/utils/StorageUtil.ets
git commit -m "feat(harmonyos): 密码条目模型、分组、本地存储"
```

---

## Task 3: CsvUtil —— CSV 解析与生成

**Files:**
- Create: `harmonyos/entry/src/main/ets/utils/CsvUtil.ets`
- Test (scratchpad): `scratchpad/csvutil.mjs` + `scratchpad/test-csvutil.mjs`

**Interfaces:**
- Consumes: `PasswordEntry`（Task 2）、`extractDomain`（Task 1）
- Produces:
  - `export function parseCsv(text: string): string[][]`
  - `export function parsePasswordCsv(text: string): PasswordEntry[]`
  - `export function toCsv(entries: PasswordEntry[]): string`

- [ ] **Step 1: scratchpad 实现**

`scratchpad/csvutil.mjs`（`extractDomain` 从 Task 1 的 `domainutil.mjs` import）:

```js
import { extractDomain } from './domainutil.mjs';

// 字符级 CSV tokenizer：处理引号字段内逗号/换行、"" 转义、CRLF、BOM。
export function parseCsv(text) {
  if (text && text.charCodeAt(0) === 0xFEFF) text = text.slice(1); // 去 BOM
  const rows = [];
  let row = [];
  let field = '';
  let inQuotes = false;
  let i = 0;
  const n = text.length;
  while (i < n) {
    const ch = text[i];
    if (inQuotes) {
      if (ch === '"') {
        if (i + 1 < n && text[i + 1] === '"') { field += '"'; i += 2; continue; }
        inQuotes = false; i++; continue;
      }
      field += ch; i++; continue;
    }
    if (ch === '"') { inQuotes = true; i++; continue; }
    if (ch === ',') { row.push(field); field = ''; i++; continue; }
    if (ch === '\r') { i++; continue; } // CRLF 里的 \r 直接吞
    if (ch === '\n') { row.push(field); rows.push(row); row = []; field = ''; i++; continue; }
    field += ch; i++;
  }
  // 收尾
  if (field.length > 0 || row.length > 0) { row.push(field); rows.push(row); }
  return rows;
}

const COL_ALIASES = {
  name: ['name', 'title'],
  url: ['url', 'origin', 'login_uri', 'website'],
  username: ['username', 'login', 'login_username', 'user'],
  password: ['password', 'login_password', 'pass'],
  note: ['note', 'notes', 'comment', 'comments', 'extra'],
};

function buildHeaderMap(header) {
  const map = {};
  header.forEach((h, idx) => {
    const key = h.trim().toLowerCase();
    for (const field of Object.keys(COL_ALIASES)) {
      if (COL_ALIASES[field].indexOf(key) >= 0 && map[field] === undefined) {
        map[field] = idx;
      }
    }
  });
  return map;
}

export function parsePasswordCsv(text) {
  const rows = parseCsv(text);
  if (rows.length < 2) return [];
  const hmap = buildHeaderMap(rows[0]);
  if (hmap.password === undefined && hmap.username === undefined && hmap.url === undefined) return [];
  const out = [];
  let ts = Date.now();
  for (let r = 1; r < rows.length; r++) {
    const cells = rows[r];
    if (cells.length === 1 && cells[0].trim() === '') continue;
    const get = (f) => (hmap[f] !== undefined && cells[hmap[f]] !== undefined ? cells[hmap[f]].trim() : '');
    const url = get('url');
    const username = get('username');
    const password = get('password');
    const note = get('note');
    if (!url && !username && !password) continue;
    let name = get('name');
    if (!name) name = extractDomain(url) || url || username;
    out.push({
      id: (ts++).toString(),
      name, url, username, password, note,
      timestamp: new Date().toISOString(),
    });
  }
  return out;
}

function csvCell(v) {
  const s = v === undefined || v === null ? '' : String(v);
  if (s.indexOf('"') >= 0 || s.indexOf(',') >= 0 || s.indexOf('\n') >= 0 || s.indexOf('\r') >= 0) {
    return '"' + s.replace(/"/g, '""') + '"';
  }
  return s;
}

export function toCsv(entries) {
  const lines = ['name,url,username,password,note'];
  for (const e of entries) {
    lines.push([e.name, e.url, e.username, e.password, e.note].map(csvCell).join(','));
  }
  return lines.join('\r\n') + '\r\n';
}
```

`scratchpad/test-csvutil.mjs`:

```js
import { parseCsv, parsePasswordCsv, toCsv } from './csvutil.mjs';
import assert from 'node:assert';

// 1. 引号字段内逗号 + "" 转义 + CRLF
const raw1 = 'name,url,username,password,note\r\n' +
  'Test,"https://a.com","u1","p,a""ss","line1\nline2"\r\n';
const rows1 = parseCsv(raw1);
assert.strictEqual(rows1.length, 2);
assert.deepStrictEqual(rows1[1], ['Test', 'https://a.com', 'u1', 'p,a"ss', 'line1\nline2']);

// 2. BOM
const raw2 = '﻿name,url,username,password,note\nX,https://x.com,ux,px,\n';
assert.strictEqual(parseCsv(raw2)[0][0], 'name');

// 3. Chrome 格式解析
const chrome = 'name,url,username,password,note\nGitHub,https://github.com/login,octocat,s3cr,\n';
const p = parsePasswordCsv(chrome);
assert.strictEqual(p.length, 1);
assert.strictEqual(p[0].username, 'octocat');
assert.strictEqual(p[0].url, 'https://github.com/login');

// 4. Firefox 格式（列序不同 + 多余列）
const ff = 'url,username,password,httpRealm,formActionOrigin,guid,timeCreated\n' +
  'https://mail.google.com,me@g.com,pw12,,,{abc},1700000000\n';
const pf = parsePasswordCsv(ff);
assert.strictEqual(pf.length, 1);
assert.strictEqual(pf[0].username, 'me@g.com');
assert.strictEqual(pf[0].password, 'pw12');
assert.strictEqual(pf[0].name, 'google.com'); // name 缺失 → 域名兜底

// 5. 往返一致（忽略 id/timestamp）
const entries = parsePasswordCsv(chrome);
const round = parsePasswordCsv(toCsv(entries));
const strip = (e) => ({ name: e.name, url: e.url, username: e.username, password: e.password, note: e.note });
assert.deepStrictEqual(round.map(strip), entries.map(strip));

// 6. 含特殊字符往返
const tricky = [{ name: 'a,b', url: 'https://t.com', username: 'u"x', password: 'p\nq', note: '' }];
const round2 = parsePasswordCsv(toCsv(tricky.map((e, i) => ({ ...e, id: String(i), timestamp: '' }))));
assert.strictEqual(round2[0].username, 'u"x');
assert.strictEqual(round2[0].password, 'p\nq');
assert.strictEqual(round2[0].name, 'a,b');

console.log('CsvUtil: all 6 groups passed');
```

- [ ] **Step 2: 跑测试**

Run: `node scratchpad/test-csvutil.mjs`
Expected: `CsvUtil: all 6 groups passed`

- [ ] **Step 3: 移植进 `.ets`**

`harmonyos/entry/src/main/ets/utils/CsvUtil.ets` —— 逻辑逐字一致，补 ArkTS 类型。注意点：
- ArkTS 无对象展开 `...`，无箭头简写返回对象字面量需命名 interface。用显式构造。
- `Record<string, string[]>` 代替 mjs 里的裸对象。
- 正则用 `new RegExp('"', 'g')` 或 `replaceAll`。

```ts
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
  for (let idx = 0; idx < header.length; idx++) {
    const key: string = header[idx].trim().toLowerCase();
    for (const field of Object.keys(COL_ALIASES)) {
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
```

- [ ] **Step 4: 构建验证**

Run: Build 命令
Expected: `BUILD SUCCESSFUL`。若 ArkTS 报 `Object.keys` 迭代或索引签名问题，把 `COL_ALIASES` 的遍历改为对固定 5 个字段名的显式数组 `['name','url','username','password','note']` 遍历。

- [ ] **Step 5: 提交**

```bash
git add harmonyos/entry/src/main/ets/utils/CsvUtil.ets
git commit -m "feat(harmonyos): CSV 解析与生成工具 CsvUtil"
```

---

## Task 4: 口令首页搜索常驻 + 删除 `searching` 状态

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/HomeView.ets`
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets`

**Interfaces:**
- Consumes: 无（纯重构）
- Produces: `HomeView` 不再有 `@Link searching`；`Index` 不再有 `searching` state

- [ ] **Step 1: 改 `HomeView.ets`**

删除 `@Link searching: boolean;`（第 13 行）。保留 `@Link searchQ: string;`。

`build()` 里：把 `if (this.searching) { Row(){...搜索行...} }` 改为**无条件**渲染的搜索行，并：
- 删掉行内的返回箭头 `Text('←')...onClick(...)` 整块
- `TextInput` 删掉 `.defaultFocus(true)` 和整个 `.onAppear(() => { ... requestFocus ... })`
- 保留搜索图标、输入框、`if (this.searchQ.length > 0) { Text('×')... }` 清除按钮（仅清空文本）

改造后的搜索行（放在 `Column()` 内、`List` 之前，无 `if` 包裹）：

```ts
Row({ space: 6 }) {
  SymbolGlyph($r('sys.symbol.magnifyingglass'))
    .fontColor([this.c('rgba(238,238,245,0.55)', '#5C4F43')])
    .fontSize(18)
  TextInput({ text: this.searchQ, placeholder: '搜索品牌或账号' })
    .id('home_search_input')
    .flexGrow(1)
    .backgroundColor(Color.Transparent)
    .fontColor(this.c('#eeeef5', '#2C1810'))
    .placeholderColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
    .fontSize(13)
    .height(28)
    .padding(0)
    .onChange((v: string) => { this.searchQ = v; })
  if (this.searchQ.length > 0) {
    Text('×')
      .fontSize(16).fontWeight(500).fontColor(this.c('rgba(238,238,245,0.5)', '#5C4F43'))
      .width(20).height(20)
      .textAlign(TextAlign.Center)
      .onClick(() => { this.searchQ = ''; })
  }
}
.height(36)
.padding({ left: 16, right: 16, top: 6, bottom: 6 })
.margin({ left: 16, right: 16, top: 8, bottom: 8 })
.backgroundColor(this.c('#191920', '#FFFFFF'))
.borderRadius(10)
.border({ width: 1, color: this.accentColor + '55' })
.alignItems(VerticalAlign.Center)
```

`List` 的 `.padding({ left: 16, right: 16, top: this.searching ? 0 : 8 })` 改为 `.padding({ left: 16, right: 16, top: 0 })`。

- [ ] **Step 2: 改 `Index.ets` —— 删 `searching`**

1. 删字段 `@State searching: boolean = false;`（约第 142 行）。保留 `@State searchQ: string = '';`。
2. `onBackgroundSeqChanged()` 里删除：
   ```ts
   if (this.searching) {
     this.searching = false;
     this.searchQ = '';
   }
   ```
   改为：
   ```ts
   if (this.searchQ) {
     this.searchQ = '';
   }
   ```
3. `bottomNav()` 里删除整个「搜索」Column（`// 搜索 (紧跟首页)` 那一块，含其 `.onClick`）。**先删，Task 5 再在原位加「密码」。**
   - 删除后 `Row` 里剩 3 项，`.width(222)` 暂时保留，Task 5 加回第 4 项。
4. `build()` 里 `HomeView({ ... })` 删除 `searching: $searching,` 这一行。
5. `Tabs(...).onChange((index: number) => { ... })` 里删除：
   ```ts
   if (this.searching && index !== 0) { this.searching = false; this.searchQ = ''; }
   ```
   改为：
   ```ts
   if (index !== 0 && this.searchQ) { this.searchQ = ''; }
   ```
6. `tabIcon` builder 里的 `scan` 分支上方原本没有 search 分支（search 在 bottomNav 内联，不在 tabIcon）——无需改 tabIcon。

- [ ] **Step 3: 构建验证**

Run: Build 命令
Expected: `BUILD SUCCESSFUL`。grep 确认无残留：`grep -rn "searching" harmonyos/entry/src/main/ets/` 应无结果。

- [ ] **Step 4: 提交**

```bash
git add harmonyos/entry/src/main/ets/views/HomeView.ets harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "refactor(harmonyos): 口令首页搜索框常驻顶部，移除 searching 展开态"
```

---

## Task 5: 密码图标资源 + PasswordView 骨架 + 导航接线

**Files:**
- Create: `harmonyos/entry/src/main/resources/base/media/icon_password.svg`
- Create: `harmonyos/entry/src/main/ets/views/PasswordView.ets`
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets`

**Interfaces:**
- Consumes: `PasswordEntry`、`PasswordGroup`、`groupByDomain`（Task 2）；`extractDomain`（Task 1）；`loadPasswords`、`savePasswords`（Task 2）；现有 `authenticateSecurity`、`AuthOutcome`（`../utils/SecurityUtil`）
- Produces: `PasswordView` 组件，属性签名：
  ```ts
  @Prop accentColor: string
  @Prop isDark: boolean
  @Prop isMember: boolean
  @Prop loggedIn: boolean
  @Link passwords: PasswordEntry[]
  @Link openDomain: string
  onChange: (list: PasswordEntry[]) => void
  onImport: () => void
  onExport: () => void
  onNavHide: () => void
  onNavShow: () => void
  ```

- [ ] **Step 1: 生成图标资源**

用户提供的 `/Users/xiaoan/Downloads/密钥.svg` 拷到 `harmonyos/entry/src/main/resources/base/media/icon_password.svg`，并把三处 `fill="#8A8A8A"` **删除**（让 `.fillColor()` 生效）。最终文件内容：

```xml
<?xml version="1.0" standalone="no"?><!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"><svg t="1788156884473" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="200" height="200"><path d="M814.8992 312.32c0 171.0592-139.4176 304.128-304.128 304.128-171.0592 0-304.128-139.4176-304.128-304.128 0-164.7616 133.0688-304.128 304.128-304.128s304.128 139.3664 304.128 304.128zM510.9248 79.0016c-131.6864 0-233.5232 107.776-233.5232 233.5232 0 125.696 101.7856 239.5136 233.5232 239.5136 131.6864 0 239.5136-107.776 239.5136-233.5232s-107.776-239.5136-239.5136-239.5136z m0 0"></path><path d="M479.0784 597.4528h63.3344v392.8576c0 17.4592-14.1824 31.6928-31.6928 31.6928-17.5104 0-31.6928-14.1824-31.6928-31.6928v-392.8576z m0 0"></path><path d="M510.7712 705.1264h158.4128c17.4592 0 31.6928 14.1824 31.6928 31.6928 0 17.4592-14.1824 31.6928-31.6928 31.6928H510.7712v-63.3856z m0 126.7712h158.4128c17.4592 0 31.6928 14.1824 31.6928 31.6928 0 17.5104-14.1824 31.6928-31.6928 31.6928H510.7712v-63.3856z m0 0"></path></svg>
```

- [ ] **Step 2: 创建 `PasswordView.ets` 骨架**

先只做 Level 0 的空壳（列表在 Task 6 填充），确保能编译并显示：

```ts
import { PasswordEntry, PasswordGroup, groupByDomain } from '../model/PasswordEntry';

@Component
export struct PasswordView {
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  @Prop isMember: boolean = false;
  @Prop loggedIn: boolean = false;
  @Link passwords: PasswordEntry[];
  @Link openDomain: string;
  onChange: (list: PasswordEntry[]) => void = () => {};
  onImport: () => void = () => {};
  onExport: () => void = () => {};
  onNavHide: () => void = () => {};
  onNavShow: () => void = () => {};

  @State query: string = '';

  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  build() {
    Column() {
      // 顶部常驻搜索框
      Row({ space: 6 }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontColor([this.c('rgba(238,238,245,0.55)', '#5C4F43')]).fontSize(18)
        TextInput({ text: this.query, placeholder: '搜索域名、站点或用户名' })
          .flexGrow(1).backgroundColor(Color.Transparent)
          .fontColor(this.c('#eeeef5', '#2C1810'))
          .placeholderColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
          .fontSize(13).height(28).padding(0)
          .onChange((v: string) => { this.query = v; })
        if (this.query.length > 0) {
          Text('×').fontSize(16).fontColor(this.c('rgba(238,238,245,0.5)', '#5C4F43'))
            .width(20).height(20).textAlign(TextAlign.Center)
            .onClick(() => { this.query = ''; })
        }
      }
      .height(36).padding({ left: 16, right: 16, top: 6, bottom: 6 })
      .margin({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(10)
      .border({ width: 1, color: this.accentColor + '55' })
      .alignItems(VerticalAlign.Center)

      // 占位内容（Task 6 替换）
      Column() {
        Text('密码库').fontSize(14).fontColor(this.c('rgba(238,238,245,0.6)', '#6B5B50'))
      }
      .width('100%').flexGrow(1).justifyContent(FlexAlign.Center)
    }
    .width('100%').height('100%')
    .backgroundColor(this.c('#0d0d12', '#FAF7F2'))
  }
}
```

- [ ] **Step 3: `Index.ets` —— import 与 state**

顶部 import 追加：
```ts
import { PasswordEntry } from '../model/PasswordEntry';
import { PasswordView } from '../views/PasswordView';
```
（`loadPasswords` / `savePasswords` 追加到已有的 `StorageUtil` import 列表里。`extractDomain` 追加 `import { extractDomain } from '../utils/DomainUtil';`。）

State 区（`// ── Search ──` 附近）追加：
```ts
// ── Password Manager ───────────────────────────────────────────
@State passwords: PasswordEntry[] = [];
@State pwOpenDomain: string = '';
@State passwordTabUnlocked: boolean = false;
```

- [ ] **Step 4: `Index.ets` —— `loadData()` 加载密码**

在 `loadData()` 的 `try` 块里、`this.tokens = ...` 之后追加：
```ts
this.passwords = await loadPasswords();
```

- [ ] **Step 5: `Index.ets` —— 应用锁门禁方法**

在类里（`copyCode` 附近）新增：
```ts
private async goPasswordTab(): Promise<void> {
  if (this.securityMode !== 'off' && this.loggedIn && !this.passwordTabUnlocked) {
    try {
      const outcome: AuthOutcome = await authenticateSecurity(this.securityMode);
      if (!outcome.ok) { this.toast('验证失败'); return; }
    } catch (_) { this.toast('验证失败'); return; }
    this.passwordTabUnlocked = true;
  }
  this.currentTab = 3;
  this.navVisible = true;
}
```

- [ ] **Step 6: `Index.ets` —— 底部导航加「密码」**

在 `bottomNav()` 的 `Row` 里、「首页」Column 之后（即 Task 4 删掉「搜索」的原位）插入：
```ts
// 密码
Column({ space: 2 }) {
  Image($r('app.media.icon_password'))
    .width(18).height(18)
    .fillColor(this.currentTab === 3 ? this.accentColor : this.c('#d0d0dd', '#8888A0'))
  Text('密码')
    .fontSize(9)
    .fontWeight(this.currentTab === 3 ? 600 : 500)
    .fontColor(this.currentTab === 3 ? this.accentColor : this.c('#d0d0dd', '#8888A0'))
}
.layoutWeight(1)
.width('100%').height('100%')
.alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
.onClick(() => { this.goPasswordTab(); })
```
`Row` 的 `.width(222)` 保持（4 项，与原先一致）。

- [ ] **Step 7: `Index.ets` —— 新增 TabContent（第 4 个）**

在 `build()` 里 `Tabs` 的第 3 个 `TabContent`（ProfileView，`.tabBar(this.tabIcon('profile', 2))`）**之后**追加：
```ts
TabContent() {
  PasswordView({
    accentColor: this.accentColor,
    isDark: this.isDark,
    isMember: this.isMember,
    loggedIn: this.loggedIn,
    passwords: $passwords,
    openDomain: $pwOpenDomain,
    // 仅持久化。PasswordView 通过 $passwords（@Link）已就地写回，单一写路径。
    onChange: (list: PasswordEntry[]) => { savePasswords(list); },
    onImport: () => { this.importPasswordsCsv(); },
    onExport: () => { this.exportPasswordsCsv(); },
    onNavHide: () => { this.navVisible = false; },
    onNavShow: () => { this.navVisible = true; },
  })
}
.tabBar(this.tabIcon('password', 3))
```

`tabIcon` builder 追加分支：
```ts
} else if (type === 'password') {
  Image($r('app.media.icon_password'))
    .width(18).height(18)
    .fillColor(this.currentTab === 3 ? this.accentColor : this.c('#d0d0dd', '#8888A0'))
}
```
（`tabIcon` 现有分支用 `SymbolGlyph`；新增 `Image` 分支即可。tab bar 因 `.barWidth(0).barHeight(0)` 不可见，内容仅需合法。）

- [ ] **Step 8: `Index.ets` —— `onBackPress` 处理详情返回**

在 `onBackPress()` 里、`if (this.editToken.id) {` 判断**之前**插入：
```ts
// 密码详情下钻：返回分组列表，不退出 App
if (this.pwOpenDomain !== '') {
  this.pwOpenDomain = '';
  return true;
}
```

- [ ] **Step 9: `Index.ets` —— 后台回收密码 tab**

`onBackgroundSeqChanged()` 里追加：
```ts
this.passwordTabUnlocked = false;
this.pwOpenDomain = '';
if (this.currentTab === 3) {
  this.currentTab = 0;
}
```

- [ ] **Step 10: `Index.ets` —— 禁用 Tabs 滑动切换（有意的行为变更）**

`Tabs` 链式调用里加 `.scrollable(false)`（放在 `.barMode(BarMode.Fixed)` 之后）。这样只有底部胶囊能切 tab，密码 tab 的锁门禁不会被内容横滑绕过。

**这是对现有手感的有意改动**：此前 tab 内容可横滑切换，改后只能点胶囊。完成报告里需明确写出。若用户反馈想保留横滑，退路是移除本行、改在 `Tabs.onChange` 里对 `index === 3 && !this.passwordTabUnlocked && 需锁` 做 `this.currentTab = <上一个>` 回退（但异步鉴权回退会有一帧闪烁）。

- [ ] **Step 11: `Index.ets` —— 占位 CSV 方法（Task 10 实现）**

为让本任务能编译，先加空实现（Task 10 替换）：
```ts
private importPasswordsCsv(): void { this.toast('即将支持'); }
private async exportPasswordsCsv(): Promise<void> { this.toast('即将支持'); }
```

- [ ] **Step 12: 构建验证**

Run: Build 命令
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 13: 提交**

```bash
git add harmonyos/entry/src/main/resources/base/media/icon_password.svg harmonyos/entry/src/main/ets/views/PasswordView.ets harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat(harmonyos): 密码 Tab 骨架、底部导航与应用锁门禁"
```

---

## Task 6: PasswordView Level 0 —— 域名分组列表

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/PasswordView.ets`

**Interfaces:**
- Consumes: `groupByDomain`（Task 2）、`Logo` 组件（`../components/Logo`）
- Produces: 分组列表 UI；点击组 → `this.openDomain = 组域名`

- [ ] **Step 1: import Logo + 域名标签辅助**

顶部追加：
```ts
import { Logo } from '../components/Logo';
```
`PasswordEntry` import 改为 `import { PasswordEntry, PasswordGroup, groupByDomain, OTHER_DOMAIN, entryInDomain } from '../model/PasswordEntry';`

类里加：
```ts
private domainLabel(key: string): string { return key === OTHER_DOMAIN ? '其他' : key; }
```

- [ ] **Step 2: 分组过滤方法**

类里新增：
```ts
private visibleGroups(): PasswordGroup[] {
  const groups: PasswordGroup[] = groupByDomain(this.passwords);
  const q: string = this.query.trim().toLowerCase();
  if (!q) return groups;
  const out: PasswordGroup[] = [];
  for (const g of groups) {
    if (g.domain.toLowerCase().indexOf(q) >= 0) { out.push(g); continue; }
    const matched: PasswordEntry[] = g.entries.filter((e: PasswordEntry) =>
      e.name.toLowerCase().indexOf(q) >= 0 ||
      e.url.toLowerCase().indexOf(q) >= 0 ||
      e.username.toLowerCase().indexOf(q) >= 0
    );
    if (matched.length > 0) out.push({ domain: g.domain, entries: matched });
  }
  return out;
}
```

- [ ] **Step 3: 替换 build() 里的占位内容**

把 Step 2 (Task 5) 的「占位内容」`Column` 换成：
```ts
List({ space: 0 }) {
  if (this.visibleGroups().length === 0) {
    ListItem() {
      Column({ space: 12 }) {
        Text('🔐').fontSize(36)
        Text(this.query ? '未找到匹配的密码' : '暂无密码\n点右上角 + 添加，或导入 CSV')
          .fontSize(14).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50')).textAlign(TextAlign.Center)
      }
      .width('100%').padding({ top: 70, bottom: 70 }).justifyContent(FlexAlign.Center)
    }
  }
  ForEach(this.visibleGroups(), (g: PasswordGroup) => {
    ListItem() {
      Row({ space: 12 }) {
        Logo({ brand: this.domainLabel(g.domain), account: '', logoSize: 40, isDark: this.isDark, accentColor: this.accentColor })
        Column({ space: 3 }) {
          Text(this.domainLabel(g.domain))
            .fontSize(15).fontWeight(600).fontColor(this.c('#eeeef5', '#2C1810'))
          Text(`${g.entries.length} 个账号`)
            .fontSize(12).fontColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
        }.alignItems(HorizontalAlign.Start).flexGrow(1)
        Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.4)', '#9B8B80'))
      }
      .width('100%').padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(14)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.openDomain = g.domain; })
    }
    .padding({ bottom: 10 })
  }, (g: PasswordGroup) => g.domain)
  ListItem() { Column().height(96) }
}
.width('100%').flexGrow(1).padding({ left: 16, right: 16 }).scrollBar(BarState.Off)
```

- [ ] **Step 4: 构建验证**

Run: Build 命令
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 5: 手动烟雾测试（可选，若有设备）**

DevEco 预览或真机：进「密码」tab，无数据显示空态。（数据需 Task 8 或 Task 10 才能造。）

- [ ] **Step 6: 提交**

```bash
git add harmonyos/entry/src/main/ets/views/PasswordView.ets
git commit -m "feat(harmonyos): 密码库域名分组列表"
```

---

## Task 7: PasswordView Level 1 —— 详情列表 + 显隐 + 复制

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/PasswordView.ets`

**Interfaces:**
- Consumes: `pasteboard` from `@kit.BasicServicesKit`
- Produces: 详情视图；`revealId` 控制单条明文显隐

- [ ] **Step 1: import pasteboard + 新增 state**

```ts
import { pasteboard } from '@kit.BasicServicesKit';
```
类里追加：
```ts
@State private revealId: string = '';
@State private toastMsg: string = '';
@State private toastShow: boolean = false;
private toastTimer: number = -1;
```

- [ ] **Step 2: toast + copy 辅助方法**

```ts
private tip(msg: string): void {
  clearTimeout(this.toastTimer);
  this.toastMsg = msg;
  this.toastShow = true;
  this.toastTimer = setTimeout(() => { this.toastShow = false; }, 1800) as number;
}

private copy(text: string, label: string): void {
  try {
    const d = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    pasteboard.getSystemPasteboard().setData(d);
    this.tip(`已复制${label}`);
  } catch (_) { this.tip('复制失败'); }
}

private currentEntries(): PasswordEntry[] {
  return this.passwords.filter((e: PasswordEntry) => entryInDomain(e, this.openDomain));
}
```
顶部追加 `import { extractDomain } from '../utils/DomainUtil';`（`entryInDomain` 已在 Task 6 的 PasswordEntry import 里）

- [ ] **Step 3: build() 顶层按 openDomain 分叉**

`build()` 的 `Column` 里，搜索框之后：**若 `this.openDomain !== ''` 显示详情，否则显示分组列表（Task 6 的 List）**。用 `if / else`：

```ts
if (this.openDomain !== '') {
  // 详情头
  Row({ space: 8 }) {
    Text('‹ 返回').fontSize(14).fontColor(this.accentColor)
      .onClick(() => { this.openDomain = ''; this.revealId = ''; })
    Text(this.domainLabel(this.openDomain))
      .fontSize(16).fontWeight(700).fontColor(this.c('#eeeef5', '#2C1810')).flexGrow(1)
      .textAlign(TextAlign.Center)
    Text('').width(44)
  }
  .width('100%').padding({ left: 16, right: 16, top: 4, bottom: 8 }).alignItems(VerticalAlign.Center)

  List({ space: 10 }) {
    ForEach(this.currentEntries(), (e: PasswordEntry) => {
      ListItem() { this.entryCard(e) }
      .swipeAction({ end: () => { this.deleteAction(e) } })
    }, (e: PasswordEntry) => e.id)
    ListItem() { Column().height(96) }
  }
  .width('100%').flexGrow(1).padding({ left: 16, right: 16 }).scrollBar(BarState.Off)
} else {
  // Task 6 的分组 List
}
```

- [ ] **Step 4: entryCard 与 deleteAction builder**

```ts
@Builder
entryCard(e: PasswordEntry) {
  Column({ space: 8 }) {
    Text(e.name || e.url || '(未命名)')
      .fontSize(14).fontWeight(600).fontColor(this.c('#eeeef5', '#2C1810')).width('100%')
    if (e.url) {
      Text(e.url).fontSize(11).fontColor(this.c('rgba(238,238,245,0.5)', '#9B8B80'))
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
    }
    Row({ space: 6 }) {
      Text('账号').fontSize(11).fontColor(this.c('rgba(238,238,245,0.45)', '#9B8B80')).width(40)
      Text(e.username || '—').fontSize(13).fontColor(this.c('#eeeef5', '#2C1810')).flexGrow(1)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text('复制').fontSize(12).fontColor(this.accentColor)
        .onClick(() => { this.copy(e.username, '账号'); })
    }.width('100%').alignItems(VerticalAlign.Center)
    Row({ space: 6 }) {
      Text('密码').fontSize(11).fontColor(this.c('rgba(238,238,245,0.45)', '#9B8B80')).width(40)
      Text(this.revealId === e.id ? (e.password || '—') : '••••••••')
        .fontSize(13).fontFamily('monospace').fontColor(this.c('#eeeef5', '#2C1810')).flexGrow(1)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.revealId === e.id ? '隐藏' : '显示').fontSize(12).fontColor(this.accentColor)
        .onClick(() => { this.revealId = this.revealId === e.id ? '' : e.id; })
      Text('复制').fontSize(12).fontColor(this.accentColor)
        .onClick(() => { this.copy(e.password, '密码'); })
    }.width('100%').alignItems(VerticalAlign.Center)
    if (e.note) {
      Text(e.note).fontSize(11).fontColor(this.c('rgba(238,238,245,0.5)', '#6B5B50')).width('100%')
    }
    Row() {
      Text('编辑').fontSize(12).fontColor(this.c('rgba(238,238,245,0.6)', '#6B5B50'))
        .onClick(() => { this.beginEdit(e); })
    }.width('100%').justifyContent(FlexAlign.End)
  }
  .width('100%').padding(14)
  .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(14)
  .border({ width: 1, color: this.c('rgba(255,255,255,0.05)', '#E8E2D9') })
}

@Builder
deleteAction(e: PasswordEntry) {
  Column() {
    Text('删除').fontSize(13).fontColor('#ff5a5a')
  }
  .width(64).height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  .onClick(() => { this.removeEntry(e); })
}
```

`beginEdit` / `removeEntry` 在 Task 8 定义 —— 本任务先加占位以便编译：
```ts
private beginEdit(e: PasswordEntry): void {}
private removeEntry(e: PasswordEntry): void {
  const next: PasswordEntry[] = this.passwords.filter((x: PasswordEntry) => x.id !== e.id);
  this.passwords = next;
  this.onChange(next);
  this.tip('已删除');
}
```

- [ ] **Step 5: toast 视图**

`build()` 最外层用 `Stack` 包裹（原 `Column` 作为第一个子节点），追加：
```ts
if (this.toastShow) {
  Text(this.toastMsg)
    .fontSize(13).fontColor('#f0f0f5')
    .padding({ left: 18, right: 18, top: 8, bottom: 8 })
    .backgroundColor('rgba(22,22,30,0.96)').borderRadius(20)
    .position({ x: '50%', y: '90%' }).translate({ x: '-50%', y: 0 })
}
```
`PasswordView` 无 `aboutToDisappear` —— 新增一个：
```ts
aboutToDisappear(): void { clearTimeout(this.toastTimer); }
```

- [ ] **Step 6: 构建验证**

Run: Build 命令
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 7: 提交**

```bash
git add harmonyos/entry/src/main/ets/views/PasswordView.ets
git commit -m "feat(harmonyos): 密码详情列表、显隐切换、复制、删除"
```

---

## Task 8: PasswordView —— 新增 / 编辑条目表单

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/PasswordView.ets`

**Interfaces:**
- Consumes: `FREE_PASSWORD_LIMIT` from `../model/Token`
- Produces: `editEntry` 表单 overlay；提交回调 `onChange`

- [ ] **Step 1: import 常量 + state**

```ts
import { FREE_PASSWORD_LIMIT } from '../model/Token';
```
类里追加：
```ts
@State private formOpen: boolean = false;
@State private formId: string = '';        // '' = 新增
@State private fName: string = '';
@State private fUrl: string = '';
@State private fUser: string = '';
@State private fPass: string = '';
@State private fNote: string = '';
```

- [ ] **Step 2: 替换 Task 7 的占位 `beginEdit`，加 `beginAdd` / `submitForm`**

```ts
private beginAdd(): void {
  this.formId = '';
  this.fName = '';
  this.fUrl = this.openDomain ? 'https://' + this.openDomain : '';
  this.fUser = '';
  this.fPass = '';
  this.fNote = '';
  this.formOpen = true;
}

private beginEdit(e: PasswordEntry): void {
  this.formId = e.id;
  this.fName = e.name;
  this.fUrl = e.url;
  this.fUser = e.username;
  this.fPass = e.password;
  this.fNote = e.note;
  this.formOpen = true;
}

private submitForm(): void {
  const url: string = this.fUrl.trim();
  const user: string = this.fUser.trim();
  const pass: string = this.fPass;
  if (!url && !user && !pass) { this.tip('请至少填写一项'); return; }
  if (this.formId === '') {
    if (!this.isMember && this.passwords.length >= FREE_PASSWORD_LIMIT) {
      this.tip(`免费用户最多保存 ${FREE_PASSWORD_LIMIT} 条密码`);
      return;
    }
    const entry: PasswordEntry = {
      id: Date.now().toString(),
      name: this.fName.trim() || extractDomain(url) || url || user,
      url: url, username: user, password: pass, note: this.fNote.trim(),
      timestamp: new Date().toISOString(),
    };
    const next: PasswordEntry[] = this.passwords.concat([entry]);
    this.passwords = next;
    this.onChange(next);
    this.tip('已保存');
  } else {
    const id: string = this.formId;
    const next: PasswordEntry[] = this.passwords.map((x: PasswordEntry): PasswordEntry => {
      if (x.id !== id) return x;
      return {
        id: x.id,
        name: this.fName.trim() || extractDomain(url) || url || user,
        url: url, username: user, password: pass, note: this.fNote.trim(),
        timestamp: new Date().toISOString(),
      };
    });
    this.passwords = next;
    this.onChange(next);
    this.tip('已更新');
  }
  this.formOpen = false;
  // 若编辑后域名变了，回退到分组列表避免停留在空详情
  if (this.openDomain !== '' && extractDomain(url) !== this.openDomain) {
    this.openDomain = '';
  }
}
```

- [ ] **Step 3: `+` 入口**

分组列表（`openDomain === ''`、`query === ''`）和详情视图的头部各加一个 `+`。详情头部的 `Text('').width(44)` 换成：
```ts
Text('+ 添加').fontSize(14).fontColor(this.accentColor)
  .onClick(() => { this.beginAdd(); })
```
分组模式：在搜索框那一 `Row` 后、`List` 前加一行操作条：
```ts
if (this.openDomain === '') {
  Row({ space: 16 }) {
    Text('+ 添加').fontSize(13).fontColor(this.accentColor)
      .onClick(() => { this.beginAdd(); })
    Text('导入 CSV').fontSize(13).fontColor(this.accentColor)
      .onClick(() => { this.onImport(); })
    Text('导出 CSV').fontSize(13).fontColor(this.accentColor)
      .onClick(() => { this.onExport(); })
  }
  .width('100%').padding({ left: 20, right: 20, bottom: 6 }).justifyContent(FlexAlign.Start)
}
```

- [ ] **Step 4: 表单 overlay builder**

```ts
@Builder
formField(label: string, value: string, onCh: (v: string) => void, isPass: boolean) {
  Column({ space: 6 }) {
    Text(label).fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
    TextInput({ text: value, placeholder: '' })
      .type(isPass ? InputType.Password : InputType.Normal)
      .onChange(onCh)
      .backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
      .border({ width: 1, color: this.c('rgba(255,255,255,0.08)', '#E8E2D9') }).borderRadius(12)
      .height(44).padding({ left: 14, right: 14 })
  }.alignItems(HorizontalAlign.Start).width('100%')
}

@Builder
formOverlay() {
  Column() {
    Row() {
      Button({ type: ButtonType.Normal }) {
        Text('×').fontSize(20).fontColor(this.c('rgba(238,238,245,0.75)', '#5C4F43'))
      }
      .backgroundColor(this.c('rgba(255,255,255,0.08)', 'rgba(0,0,0,0.06)')).borderRadius(11).width(36).height(36)
      .onClick(() => { this.formOpen = false; })
      Text(this.formId === '' ? '新增密码' : '编辑密码')
        .fontSize(17).fontWeight(650).fontColor(this.c('#eeeef5', '#2C1810'))
      Text('').width(36).height(36)
    }
    .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 8 })
    .justifyContent(FlexAlign.SpaceBetween).alignItems(VerticalAlign.Center)

    Scroll() {
      Column({ space: 14 }) {
        this.formField('名称', this.fName, (v: string) => { this.fName = v; }, false)
        this.formField('站点 URL', this.fUrl, (v: string) => { this.fUrl = v; }, false)
        this.formField('用户名', this.fUser, (v: string) => { this.fUser = v; }, false)
        this.formField('密码', this.fPass, (v: string) => { this.fPass = v; }, true)
        this.formField('备注', this.fNote, (v: string) => { this.fNote = v; }, false)
        Button('保存')
          .width('100%').height(50).borderRadius(15)
          .backgroundColor(this.accentColor).fontColor('#fff').fontSize(15).fontWeight(650)
          .onClick(() => { this.submitForm(); })
      }
      .padding({ left: 20, right: 20, top: 8, bottom: 40 })
    }.scrollBar(BarState.Off).layoutWeight(1)
  }
  .width('100%').height('100%').backgroundColor(this.c('#0d0d12', '#FAF7F2'))
  .padding({ top: 44 })
  .position({ x: 0, y: 0 }).zIndex(500)
}
```

- [ ] **Step 5: 挂载 overlay**

`build()` 最外层 `Stack` 里，toast 之前追加：
```ts
if (this.formOpen) { this.formOverlay() }
```

**注意**：`formOverlay` 内所有动态值直接读 `this.fName` 等（不是值参数）—— 符合「`@Builder` 值参数不可响应」约束。`formField` 的 `value` 是值参数但只作 `TextInput` 初始 `text`，配合 `@State` 双向足够；若发现输入不刷新，改为在 `formOverlay` 里内联 5 个 `TextInput` 不用 `formField`。

- [ ] **Step 6: 构建验证**

Run: Build 命令
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 7: 真机功能验证（Task 6–8 首个可造数据的节点）**

DevEco 真机/模拟器：
- [ ] 新增 3 条：`https://accounts.google.com` / `https://mail.google.com`（同组 `google.com`）+ 1 条 URL 留空或填 `not a url`（进「其他」组）
- [ ] Level 0 显示 2 组：`google.com`（2 个账号）、`其他`（1 个账号）
- [ ] 点 `其他` 组能进入详情（验证哨兵组可达），点 `google.com` 进详情看到 2 条
- [ ] 详情内显示/隐藏密码切换正常；点击复制账号、复制密码有 toast
- [ ] 左滑删除一条，列表即时更新
- [ ] 编辑一条改动用户名并保存，详情反映改动
- [ ] 杀进程重进 App → 密码 tab 数据仍在（`@Link` 写回 + `onChange` 持久化验证）

- [ ] **Step 8: 提交**

```bash
git add harmonyos/entry/src/main/ets/views/PasswordView.ets
git commit -m "feat(harmonyos): 密码条目新增与编辑表单"
```

---

## Task 9: PasswordView —— 全局扁平搜索结果

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/PasswordView.ets`

**Interfaces:**
- Consumes: 无新增
- Produces: `query` 非空时跨域名扁平结果列表

- [ ] **Step 1: flatMatches 方法**

```ts
private flatMatches(): PasswordEntry[] {
  const q: string = this.query.trim().toLowerCase();
  if (!q) return [];
  return this.passwords.filter((e: PasswordEntry) =>
    e.name.toLowerCase().indexOf(q) >= 0 ||
    e.url.toLowerCase().indexOf(q) >= 0 ||
    e.username.toLowerCase().indexOf(q) >= 0 ||
    extractDomain(e.url).indexOf(q) >= 0
  );
}
```

- [ ] **Step 2: build() 三态分叉**

把 Task 7 的 `if (this.openDomain !== '') { 详情 } else { 分组 }` 改为：
```ts
if (this.query.trim() !== '') {
  // 扁平搜索结果
  List({ space: 10 }) {
    if (this.flatMatches().length === 0) {
      ListItem() {
        Column({ space: 12 }) {
          Text('🔍').fontSize(36)
          Text('未找到匹配的密码').fontSize(14)
            .fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
        }.width('100%').padding({ top: 70, bottom: 70 }).justifyContent(FlexAlign.Center)
      }
    }
    ForEach(this.flatMatches(), (e: PasswordEntry) => {
      ListItem() { this.entryCard(e) }
      .swipeAction({ end: () => { this.deleteAction(e) } })
    }, (e: PasswordEntry) => e.id)
    ListItem() { Column().height(96) }
  }
  .width('100%').flexGrow(1).padding({ left: 16, right: 16 }).scrollBar(BarState.Off)
} else if (this.openDomain !== '') {
  // Task 7 详情（此时 currentEntries 的 q 分支永不触发，因为 query 为空）
} else {
  // Task 6 分组列表 + Task 8 操作条
}
```

- [ ] **Step 3: 清理**

`visibleGroups()` 里的 `q` 过滤分支现在是死代码（搜索走 `flatMatches`）。删除 `const q = ...` 之后的过滤逻辑，直接 `return groups`，保留方法签名。（`currentEntries()` 已在 Task 7 简化过，无需再动。）

- [ ] **Step 4: 构建验证**

Run: Build 命令
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 5: 提交**

```bash
git add harmonyos/entry/src/main/ets/views/PasswordView.ets
git commit -m "feat(harmonyos): 密码库全局即时搜索"
```

---

## Task 10: CSV 导入 / 导出（Index.ets）

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets`

**Interfaces:**
- Consumes: `parsePasswordCsv`、`toCsv`（Task 3）；`extractDomain`（Task 1）；`FREE_PASSWORD_LIMIT`（Task 2）；现有 `picker`、`fs`、`util`、`SaveOptions` interface
- Produces: `importPasswordsCsv()`、`exportPasswordsCsv()` 真实实现

- [ ] **Step 1: import**

顶部追加：
```ts
import { parsePasswordCsv, toCsv } from '../utils/CsvUtil';
```
把 `FREE_PASSWORD_LIMIT` 加到 `Index.ets:9` **现有的** Token import 列表里（不要新写一行 `from '../model/Token'`）。`extractDomain` 已在 Task 5 import。

- [ ] **Step 2: 替换 Task 5 的占位 `exportPasswordsCsv`**

参照现有 `doBackup()` 的文件写入模式：
```ts
private async exportPasswordsCsv(): Promise<void> {
  if (!this.isMember) {
    this.toast('导出功能需要开通会员');
    this.showMembership = true;
    return;
  }
  if (this.passwords.length === 0) { this.toast('暂无密码可导出'); return; }
  const ctx = AppStorage.get<common.UIAbilityContext>('context');
  if (!ctx) { this.toast('上下文错误，请重启应用'); return; }
  const fileName = `passwords_${Date.now()}.csv`;
  const tmpPath = `${ctx.filesDir}/${fileName}`;
  try {
    const csv = toCsv(this.passwords);
    const tmpFile: fs.File = fs.openSync(tmpPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    fs.writeSync(tmpFile.fd, csv);
    fs.closeSync(tmpFile.fd);
    const savePicker = new picker.DocumentViewPicker(ctx);
    const opts: SaveOptions = { newFileNames: [fileName] };
    savePicker.save(opts).then((saveResult: string[]) => {
      if (saveResult && saveResult.length > 0) {
        const destUri = saveResult[0];
        const srcF: fs.File = fs.openSync(tmpPath, fs.OpenMode.READ_ONLY);
        const st: fs.Stat = fs.statSync(tmpPath);
        const buf: ArrayBuffer = new ArrayBuffer(st.size);
        fs.readSync(srcF.fd, buf);
        fs.closeSync(srcF);
        const destF: fs.File = fs.openSync(destUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        fs.writeSync(destF.fd, buf);
        fs.closeSync(destF);
        this.toast(`已导出 ${this.passwords.length} 条密码`);
        this.maybeSmartCommentAfterSuccess();
      } else {
        this.toast('保存取消');
      }
      try { fs.unlink(tmpPath); } catch (_) {}
    }).catch(() => {
      this.toast(`已导出 ${this.passwords.length} 条密码`);
      try { fs.unlink(tmpPath); } catch (_) {}
    });
  } catch (_) { this.toast('导出失败'); }
}
```

- [ ] **Step 3: 替换占位 `importPasswordsCsv`**

参照现有 `selectImportFile()` 的读取模式 + 合并逻辑：
```ts
private importPasswordsCsv(): void {
  if (!this.isMember) {
    this.toast('导入功能需要开通会员');
    this.showMembership = true;
    return;
  }
  const ctx = AppStorage.get<common.UIAbilityContext>('context');
  if (!ctx) { this.toast('上下文错误，请重启应用'); return; }
  const docPicker = new picker.DocumentViewPicker(ctx);
  docPicker.select({ maxSelectNumber: 1 }).then((result: string[]) => {
    if (!result || result.length === 0) { this.toast('选择文件取消'); return; }
    const uri = result[0];
    const file: fs.File = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    const stat: fs.Stat = fs.statSync(uri);
    if (stat.size > 1024 * 1024) {
      fs.closeSync(file.fd);
      this.toast('文件过大，请选择小于 1MB 的 CSV');
      return;
    }
    const buf: ArrayBuffer = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buf);
    const decoder = new util.TextDecoder('utf-8');
    const text = decoder.decodeToString(new Uint8Array(buf));
    fs.closeSync(file.fd);
    this.mergePasswordCsv(text);
  }).catch(() => { this.toast('选择文件取消'); });
}

private mergePasswordCsv(text: string): void {
  const incoming: PasswordEntry[] = parsePasswordCsv(text);
  if (incoming.length === 0) { this.toast('未识别到有效的密码数据'); return; }
  const keyOf = (e: PasswordEntry): string =>
    extractDomain(e.url) + ' ' + e.username.trim().toLowerCase();
  const byKey: Record<string, PasswordEntry> = {};
  for (const e of this.passwords) { byKey[keyOf(e)] = e; }

  let added = 0;
  let updated = 0;
  let next: PasswordEntry[] = this.passwords.slice();
  for (const inc of incoming) {
    const k = keyOf(inc);
    const existing = byKey[k];
    if (existing) {
      next = next.map((x: PasswordEntry): PasswordEntry => {
        if (x.id !== existing.id) return x;
        return {
          id: x.id,
          name: inc.name || x.name,
          url: inc.url || x.url,
          username: x.username,
          password: inc.password || x.password,
          note: inc.note || x.note,
          timestamp: new Date().toISOString(),
        };
      });
      updated++;
    } else {
      if (!this.isMember && next.length >= FREE_PASSWORD_LIMIT) { continue; }
      const fresh: PasswordEntry = {
        id: (Date.now() + added).toString(),
        name: inc.name, url: inc.url, username: inc.username,
        password: inc.password, note: inc.note,
        timestamp: new Date().toISOString(),
      };
      next = next.concat([fresh]);
      byKey[k] = fresh;
      added++;
    }
  }
  const skipped = incoming.length - added - updated;
  this.passwords = next;
  savePasswords(next);
  if (skipped > 0) {
    this.toast(`新增 ${added}，更新 ${updated}，${skipped} 条超出免费上限`);
  } else {
    this.toast(`新增 ${added}，更新 ${updated}`);
  }
  this.maybeSmartCommentAfterSuccess();
}
```

- [ ] **Step 4: 构建验证**

Run: Build 命令
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 5: 真机手动验证清单**

- [ ] 底部导航为 `首页 / 密码 / 扫码 / 我的`，密码图标随主题色高亮
- [ ] 口令首页：搜索框常驻顶部、输入即时过滤、进 App 不自动弹键盘、无返回箭头
- [ ] 未设应用锁：直接进密码 tab；已设应用锁 + 已登录：进密码 tab 弹生物/锁屏验证，取消则不进入
- [ ] 密码 Level 0：按域名分组，`accounts.google.com` 与 `mail.google.com` 同组 `google.com`
- [ ] 点组进详情，同域名多条并列；返回箭头 + 系统返回手势都回到分组（不退出 App）
- [ ] 密码显示/隐藏切换；点击复制账号 / 复制密码
- [ ] 新增条目（在详情内预填域名）、编辑、左滑删除，杀进程重进数据仍在
- [ ] 非会员加到第 6 条被拦；非会员点导入/导出被引导开通会员
- [ ] 会员：导入 Chrome 导出的 `Chrome 密码.csv`（含表头 `name,url,username,password,note`），分组正确
- [ ] 会员：导出 CSV 到下载目录，用文件管理器确认文件存在
- [ ] 导出的 CSV 再次导入，条目数不增加（全部识别为"更新"）—— 往返一致
- [ ] 切到后台再回前台：密码 tab 弹回首页，再次进入需重新验证

- [ ] **Step 6: 提交**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat(harmonyos): 密码库 CSV 本地导入导出"
```

---

## Self-Review 结论

**Spec 覆盖：**
- 需求1（顶部/密码菜单 + 图标）→ Task 5（用户已确认放底部导航「搜索」原位）
- 需求2（字段 域名/站点/用户名/密码）→ Task 2 模型 + Task 7 详情卡片
- 需求3（默认仅展示域名，点进看多组）→ Task 6 + Task 7
- 需求4（域名从 URL 提取，不存储）→ Task 1 + Task 2 `groupByDomain`（计算态）
- 需求5（顶部固定搜索 + 即时关联）→ Task 5 搜索框 + Task 9 `flatMatches`
- 需求6（本地 CSV 导入导出，浏览器格式，不上云）→ Task 3 + Task 10
- 需求7（OTP 首页搜索常驻顶部 + 移除底部搜索菜单）→ Task 4
- 会员门槛 / 应用锁 / 明文存储 / 不走 XOR → Task 2 / Task 5 / Task 8 / Task 10

**Placeholder 扫描：** Task 5/7 有显式"占位实现，Task N 替换"，均在后续任务落地，非计划缺口。

**类型一致性：** `PasswordEntry` 7 字段全程一致；`groupByDomain` / `extractDomain` / `parsePasswordCsv` / `toCsv` 签名跨任务一致；`onChange` / `openDomain` / `passwords` 在 Index 与 PasswordView 间签名一致。

**已在评审中解决：**
- 哨兵组 `OTHER_DOMAIN`：无法解析域名的条目此前 `domain: ''` 与「显示分组列表」状态撞车、不可点开、ForEach key 为空 → 改用 `'__other__'` 哨兵 + `entryInDomain()` + `domainLabel()`（Task 2/6/7）。
- Task 6–8 缺功能验证 → Task 8 Step 7 加真机清单（含哨兵组可达性）。
- 单一写路径：`onChange` 只做 `savePasswords`，不再回写 `this.passwords`（Task 5 Step 7）。
- Level 1 搜索行为：spec 与 plan 统一为「query 非空 → 全局扁平，不做组内过滤」（spec 已改，待用户一句话确认）。

**风险点（执行时注意）：**
1. ArkTS 对 `Object.keys` + 索引签名遍历可能报错 → Task 3 Step 4 已给退路。
2. `@Builder` `formField` 值参数响应性 → Task 8 Step 5 已给内联退路。
3. `Image($r('app.media.icon_password')).fillColor()` 对含 `<!DOCTYPE>` 的 svg 可能不识别 → 若图标不显示/不染色，改用 `sys.symbol` 或把 svg 精简为纯 `<svg viewBox><path/></svg>`（去掉 DOCTYPE/xml 声明）。
4. `.scrollable(false)` 是有意的行为变更（见 Task 5 Step 10），完成报告需写明；退路是 `Tabs.onChange` 里回退。
