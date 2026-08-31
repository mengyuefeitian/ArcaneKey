# Spec: HarmonyOS 密码管理器（本地密码库）

**日期**: 2026-08-31
**分支**: dev-harmonyos
**范围**: 仅 HarmonyOS App（`harmonyos/`）。微信小程序端本次不实现。

## Objective

在星枢令 HarmonyOS App 中新增一个**本地密码库**功能：用户可存储网站账号密码，按域名分组浏览，
支持浏览器 CSV 格式的本地导入 / 导出。本次**不做云端同步**。

同时按需求调整口令首页：搜索框常驻顶部，移除底部导航的「搜索」项。

### 成功标准

- 底部导航为 `首页 / 密码 / 扫码 / 我的`，`密码` 使用指定图标。
- 口令首页搜索框常驻顶部、即时过滤，无展开/返回交互，无自动聚焦弹键盘。
- 密码库：默认按域名分组展示；点域名进入详情，详情内每条含 `站点URL / 用户名 / 密码`，同一域名可多条。
- 域名从站点 URL 派生（不存储），`accounts.google.com` 与 `mail.google.com` 归入 `google.com`。
- 密码库顶部搜索框常驻，即时跨组关联查找。
- 支持导入浏览器导出的密码 CSV；支持导出为 CSV 保存到本地下载目录。
- 非会员密码条目上限 5，会员无限；CSV 导入/导出仅会员（与现有备份/导入门槛一致）。
- `hvigorw assembleApp` 构建通过，无 ArkTS 错误。

## Tech Stack

ArkTS / HarmonyOS 6.1 (API 23)，DevEco Studio。无新增依赖。
存储：`@kit.ArkData` preferences（复用现有 `arcankey_prefs` 实例）。
文件读写：`@kit.CoreFileKit` `picker.DocumentViewPicker` + `@ohos.file.fs`（复用现有 `doBackup` / `selectImportFile` 模式）。

## Commands

```bash
cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
```

纯函数验证（scratchpad，非入库）：把 `CsvUtil` / `DomainUtil` 逻辑对照 fixture 表用 Node 脚本跑往返/提取用例。

## 布局与导航变更

### 底部胶囊导航

- 由 `首页 / 搜索 / 扫码 / 我的` 改为 `首页 / 密码 / 扫码 / 我的`。
- 删除「搜索」项及其点击逻辑。
- `密码` 图标：拷贝 `/Users/xiaoan/Downloads/密钥.svg` → `entry/src/main/resources/base/media/icon_password.svg`，
  **删除 SVG 内硬编码 `fill="#8A8A8A"`**（否则 `.fillColor()` 不生效）。
  渲染用 `Image($r('app.media.icon_password')).fillColor(active ? accentColor : 灰)`，参照 `HomeView.DeleteAction` 里 `icon_delete.svg` 的用法。
- 资源文件名必须全小写 ASCII——不得命名为 `密钥.svg`。

### TabContent 顺序

- PasswordView 作为**第 4 个 `TabContent`，index = 3**。不得插在 index 1。
- `currentTab` 在多处硬编码比对 0/1/2（`onBackgroundSeqChanged`、`addToken` 的 `this.currentTab = 2`、
  `ScanView({ isActive: this.currentTab === 1 })`、`tabIcon`、`Tabs.onChange`）——保持这些不变，新 tab 用 3。
- 胶囊视觉顺序（首页/密码/扫码/我的）与 TabContent index 解耦：四个按钮 onClick 分别 `set currentTab = 0 / 3 / 1 / 2`。
- `Tabs.onChange`、`tabIcon` 增加对 index 3 的分支。

### 口令首页搜索（HomeView.ets）

- 搜索行改为**常驻**（不再 `if (this.searching)` 条件挂载）。
- **移除返回箭头 `←`**（搜索常驻后无「退出搜索」概念）。
- 保留搜索图标、输入框、以及「有输入内容时」的清除 `×`（仅清空文本，不退出）。
- **移除自动聚焦**：删掉 `.defaultFocus(true)` 和 `onAppear` 里的 `focusControl.requestFocus('home_search_input')`
  （commit 79577f7 的自动聚焦只在条件挂载下合理，常驻后会每次启动/回首页弹键盘）。
- 列表 `padding` 里 `this.searching ? 0 : 8` 的三元改为固定值。

### 删除 `searching` 状态

`searching` 在 6 处承重，需一并清理：

1. Index.ets `@State searching` 字段 → 删除
2. `bottomNav()` 的「搜索」Column → 删除
3. `onBackgroundSeqChanged()` 里 `if (this.searching) { ... }` → 删除该块（`searchQ` 仍在 background 时清空）
4. `Tabs.onChange` 里 `if (this.searching && index !== 0) { ... }` → 删除
5. `build()` 中 `HomeView({ searching: $searching, ... })` → 删除该 prop
6. `HomeView.ets` `@Link searching: boolean` → 删除；条件挂载改常驻

`searchQ` 保留（`@Link searchQ` 仍传给 HomeView，`onBackgroundSeqChanged` 里仍清空）。

## 数据模型

### `model/PasswordEntry.ets`（新）

```ts
export interface PasswordEntry {
  id: string;
  name: string;      // 站点标题 / CSV "name" 列
  url: string;       // 完整站点 URL
  username: string;
  password: string;
  note: string;
  timestamp: string; // ISO 字符串，排序与未来同步预留
}

export interface PasswordGroup {
  domain: string;              // extractDomain(url) 结果；'' → 归「其他」
  entries: PasswordEntry[];
}
```

- **域名不存储**（需求4：从 url 派生，单一数据源）。分组在加载 / 变更时计算。

### `model/Token.ets`（修改）

```ts
export const FREE_PASSWORD_LIMIT: number = 5;
```

HarmonyOS 侧新增。小程序端本次不涉及（feature 未移植，无漂移风险）。

## `utils/DomainUtil.ets`（新）

纯函数 `extractDomain(url: string): string`：

1. 去 scheme（`https://` 等）、`userinfo@`、`:port`、`/path`、`?query`、`#frag`
2. 转小写、trim
3. 空 → 返回 `''`
4. 纯 IP（`1.2.3.4`）或单标签（`localhost`）→ 原样返回
5. 按 `.` 分段；若末两段命中 `MULTI_PART_SUFFIXES` → 取末三段，否则取末两段

```ts
export const MULTI_PART_SUFFIXES: string[] = [
  'com.cn', 'net.cn', 'org.cn', 'gov.cn', 'edu.cn', 'ac.cn',
  'co.uk', 'org.uk', 'gov.uk', 'ac.uk',
  'co.jp', 'or.jp', 'ne.jp',
  'com.hk', 'com.tw', 'com.au', 'com.br', 'co.kr',
  'github.io',
];
```

- `foo.com.cn` → `foo.com.cn`；`a.b.google.com` → `google.com`
- 常量风格对齐现有 `BRAND_COLORS` / `BRAND_ICONS`。
- 非公共后缀清单，够用即可；后续可补。

## `utils/CsvUtil.ets`（新）

### `parseCsv(text: string): string[][]`

字符级 tokenizer（约 40 行），必须处理：

- 引号字段内含逗号（密码常见）
- `""` 转义为字面引号
- CRLF / LF 行尾（Windows 导出每行末尾 `\r` 必须吞掉）
- 文件头 BOM（Excel 碰过的文件）—— 解析前 strip
- 引号字段内的换行（因此不能先按行 split）

**不得**用 `split(',')` / `split('\n')`。

### `parsePasswordCsv(text: string): PasswordEntry[]`

- 先 `parseCsv`，第一行作表头
- **按表头名映射列**（大小写不敏感），一套代码兼容：
  - Chrome / Edge / Brave：`name, url, username, password, note`
  - Firefox：`url, username, password, httpRealm, formActionOrigin, guid, timeCreated, ...`
- 列别名：`name`←`name|title`；`url`←`url|origin|login_uri`；`username`←`username|login|login_username`；
  `password`←`password|login_password`；`note`←`note|notes|comment`
- 缺 `name` → 用 `extractDomain(url)` 兜底
- 跳过 url+username+password 全空的行
- `id` = 生成；`timestamp` = 当前 ISO

### `toCsv(entries: PasswordEntry[]): string`

- 表头固定 `name,url,username,password,note`（Chrome 兼容）
- 字段含 `,` / `"` / 换行 → 加双引号包裹，内部 `"` → `""`
- 行尾 `\r\n`

### 不变式

`parseCsv(toCsv(x))` 的数据格与 `x` 往返一致（忽略 id/timestamp）。

## `utils/StorageUtil.ets`（修改）

复用已初始化的模块级 `pref` 单例，新增：

```ts
const PASSWORDS_KEY = 'ak_passwords';

export async function loadPasswords(): Promise<PasswordEntry[]> { /* JSON.parse，失败返回 [] */ }
export async function savePasswords(list: PasswordEntry[]): Promise<void> { /* JSON.stringify + flush */ }
```

明文存储（用户已确认）。

## `views/PasswordView.ets`（新 `@Component struct PasswordView`）

参照 `HomeView` / `ProfileView`：是 `@Component` 而非 page，在 Index.ets 的 `TabContent` 内条件实例化。

### Props

```
@Prop accentColor: string
@Prop isDark: boolean
@Prop isMember: boolean
@Prop loggedIn: boolean
@Link passwords: PasswordEntry[]
@Link openDomain: string          // 提升到 Index，供 onBackPress 判断
onChange: (list: PasswordEntry[]) => void = () => {}
onImport: () => void = () => {}
onExport: () => void = () => {}
onNavHide / onNavShow: () => void
```

### 内部状态

```
@State query: string = ''         // 常驻顶部搜索框，无自动聚焦
@State editEntry: PasswordEntry | null = null   // null=关闭；{} 空对象=新增
@State revealId: string = ''      // 当前显示明文密码的条目 id
@State confirmDeleteId: string = ''
```

增/改/删表单为内建 `@Builder` overlay（不放 Index.ets），提交后调 `onChange(newList)` 持久化。

### 两级导航

- **Level 0**（`openDomain === '' && query === ''`）：
  - 顶部常驻搜索框 + `+` 新增按钮 + 导入/导出入口（溢出菜单或底部按钮，实现时定）
  - 分组列表：每行 = `Logo({ brand: domain })` + 域名文本 + `N 个账号` 徽标
  - 点击行 → `openDomain = domain`
  - 空态引导文案
- **Level 1**（`openDomain !== ''`）：
  - 返回箭头（→ `openDomain = ''`）+ 域名标题 + 常驻搜索框（组内过滤）
  - 条目卡片：`name` / `url` 行；`username`（点击复制）；`password`（掩码，眼睛切换 `revealId`，点击复制）；`note`（有则显示）
  - 左滑删除（`.swipeAction`，参照 HomeView）；编辑按钮 → 打开表单
  - `+` 新增时预填当前域名
- **query 非空**（任意层级）：跨全部域名的扁平匹配结果列表，匹配 `name / url / username / domain`（即需求5「即时关联查找」）

### 复制 / toast

复制走 `pasteboard`（同 Index.ets `copyCode`）。toast 由 Index 提供回调或 PasswordView 自带轻提示（实现时对齐现有风格）。

## `pages/Index.ets`（集成）

### 新增 State

```
@State passwords: PasswordEntry[] = [];
@State pwOpenDomain: string = '';          // @Link 传给 PasswordView
@State passwordTabUnlocked: boolean = false;
```

`loadData()` 里 `this.passwords = await loadPasswords();`

### 应用锁复用

点击 `密码` tab（或 `Tabs.onChange` 到 index 3）时：

```
if (this.securityMode !== 'off' && this.loggedIn && !this.passwordTabUnlocked) {
  const outcome = await authenticateSecurity(this.securityMode);
  if (!outcome.ok) { this.toast('验证失败'); return; }  // 不切 tab
  this.passwordTabUnlocked = true;
}
this.currentTab = 3;
```

- `securityMode === 'off'` → 不拦截（没设锁就没锁可复用）。
- `onBackgroundSeqChanged()`：`this.passwordTabUnlocked = false`；若 `currentTab === 3` → 弹回 0。

### `onBackPress()`

在 zIndex 顺序链里、EditModal 分支**之前或之后**（详情非 modal，放在 `this.editToken.id` 检查前即可）加：

```
if (this.pwOpenDomain !== '') { this.pwOpenDomain = ''; return true; }
```

否则密码详情页按返回手势会直接退出 App。

### CSV 导入 / 导出（放 Index.ets，镜像 `doBackup` 位置）

```
private async exportPasswordsCsv(): Promise<void>   // toCsv → filesDir 临时文件 → DocumentViewPicker.save → 字节拷贝 → toast
private importPasswordsCsv(): void                  // docPicker.select → TextDecoder（1MB 上限）→ parsePasswordCsv → 合并
```

- 会员门槛：`if (!this.isMember) { this.toast('CSV 导入/导出需要开通会员'); this.showMembership = true; return; }`（同 `onBackupTap`）
- 合并去重键：`extractDomain(url) + ' ' + username.toLowerCase()`；命中则更新 `password` / `note` / `name`，否则新增
- 非会员：合并后总数受 `FREE_PASSWORD_LIMIT` 限制，超出部分丢弃并在 toast 说明
- 统计新增 / 更新 / 跳过数，toast 反馈
- 成功后 `savePasswords` + `maybeSmartCommentAfterSuccess()`

### build() 接线

```
TabContent() {
  PasswordView({
    accentColor: this.accentColor, isDark: this.isDark,
    isMember: this.isMember, loggedIn: this.loggedIn,
    passwords: $passwords,
    openDomain: $pwOpenDomain,
    onChange: (list) => { this.passwords = list; savePasswords(list); },
    onImport: () => { /* 会员判断 + importPasswordsCsv */ },
    onExport: () => { /* 会员判断 + exportPasswordsCsv */ },
    onNavHide: () => { this.navVisible = false; },
    onNavShow: () => { this.navVisible = true; },
  })
}
.tabBar(this.tabIcon('password', 3))
```

## 会员门槛汇总

| 能力 | 非会员 | 会员 |
|---|---|---|
| 查看 / 新增 / 编辑 / 删除密码 | ✅（≤ 5 条） | ✅ 无限 |
| CSV 导入 | ❌（引导开通） | ✅ |
| CSV 导出 | ❌（引导开通） | ✅ |

（与现有口令备份/导入门槛一致；如需放开可在实现前调整。）

## 安全

- **明文存储**于 preferences（用户已确认）。
- **不走 XOR**：CLAUDE.md 已声明 XOR 是 demo 级、非真加密，UI 标「已加密」是虚假安全声明。
- **不做至存储加密**：repo 有 PBKDF2 迭代卡主线程崩溃的已记录教训。
- 密码 tab 进入前复用现有 `authenticateSecurity(securityMode)` 应用锁（`securityMode === 'off'` 时无锁）。
- CSV 明文导出（与 Chrome / Firefox 行为一致）。

## Boundaries

- **Always**: 每次 `.ets` 改动后跑 `hvigorw assembleApp`，构建不过 = 未完成；`@State/@Link/@Prop` 全部带类型 + 初值；
  import 路径从现有文件拷贝；`@Builder` 值参数不可响应 → builder 内直接读 `this.xxx`。
- **Ask first**: 放宽会员门槛；改动去重策略；新增第三方依赖。
- **Never**: 把密码走 XOR 并在 UI 标「已加密」；把新 tab 插在 TabContent index 1；用 `split(',')` 解析 CSV；
  资源文件用非 ASCII 文件名；在 `onBackPress` 链外新增全屏视图。

## Project Structure

**新增**
- `harmonyos/entry/src/main/ets/model/PasswordEntry.ets`
- `harmonyos/entry/src/main/ets/utils/DomainUtil.ets`
- `harmonyos/entry/src/main/ets/utils/CsvUtil.ets`
- `harmonyos/entry/src/main/ets/views/PasswordView.ets`
- `harmonyos/entry/src/main/resources/base/media/icon_password.svg`

**修改**
- `harmonyos/entry/src/main/ets/pages/Index.ets`
- `harmonyos/entry/src/main/ets/views/HomeView.ets`
- `harmonyos/entry/src/main/ets/utils/StorageUtil.ets`
- `harmonyos/entry/src/main/ets/model/Token.ets`

## Testing Strategy

项目无测试设施（platform-IDE only）。

1. **纯函数**（`CsvUtil`、`DomainUtil`）：scratchpad 里 Node 脚本对照 fixture 表：
   - `extractDomain`：`https://accounts.google.com/x` → `google.com`；`http://a.foo.com.cn` → `foo.com.cn`；
     `192.168.1.1` → `192.168.1.1`；`` → ``；`https://user:pw@sub.example.co.uk:8443/p` → `example.co.uk`
   - CSV 往返：含逗号/引号/换行/CRLF/BOM 的样本 → `parseCsv(toCsv(parsePasswordCsv(x)))` 数据一致
   - Chrome 样本 + Firefox 样本各一，均能解析出正确字段
2. **UI 真机手动清单**：
   - 底部导航 4 项、图标正确、点击切换
   - 口令首页搜索框常驻、即时过滤、无键盘自动弹出、无返回箭头
   - 密码 Level 0 分组、点击进详情、Level 1 多条、返回箭头 / 系统返回手势正常（不退出 App）
   - 密码显隐切换、点击复制 username / password
   - 新增 / 编辑 / 删除条目并持久化（杀进程重进仍在）
   - 非会员加到第 6 条被拦、非会员点导入/导出被引导开通
   - 会员导入 Chrome CSV、导出 CSV 到下载目录、导出文件再导入往返一致
   - 设了应用锁时进密码 tab 需验证；未设锁时直接进
3. **构建**：`hvigorw assembleApp` 通过，无 ArkTS 错误。

## Open Questions

无（布局、会员门槛、存储安全、域名粒度、返回按钮均已确认）。
