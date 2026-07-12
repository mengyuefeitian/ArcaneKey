# HarmonyOS 会员云同步 · 安全锁 · 图标与扫码 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `dev-harmonyos` 上交付六项能力：下一个验证码复制、品牌图标缩放与新增、扫码授权后自动启动、会员页云同步开关、应用级安全锁（人脸/指纹/锁屏密码互斥）。

**Architecture:** 三波增量：Wave1 局部 UI/资源 → Wave2 偏好门闩自动同步 → Wave3 UserAuth + 全屏锁。持久化走现有 `StorageUtil` preferences；自动同步门闩包在 `Index.startAutoSync` / 增删改触发的 `cloudBackup`；安全封装 `SecurityUtil` + `SecurityView`，冷启动/回前台由 `EntryAbility`/`Index` 协作加锁。

**Tech Stack:** ArkTS (HarmonyOS API 23)、ArkUI、`@kit.ScanKit`、`@kit.AbilityKit`（相机权限）、`@kit.UserAuthenticationKit` / `userAuth`、`@kit.ArkData` preferences。无单元测试框架——以手动验收 + `assembleApp` 编译为准。

**Spec:** `docs/superpowers/specs/2026-07-12-harmonyos-member-security-icons-design.md`

---

## File map

| File | Role |
|------|------|
| `harmonyos/entry/src/main/ets/components/TokenCard.ets` | 当前/下一个分区复制 |
| `harmonyos/entry/src/main/ets/model/BrandIcons.ets` | scale + 新品牌 + meta/facebook 消歧 |
| `harmonyos/entry/src/main/resources/rawfile/brand-icons/*.svg` | 图标资源 |
| `harmonyos/entry/src/main/ets/views/ScanView.ets` | 已授权自动扫码 |
| `harmonyos/entry/src/main/ets/utils/StorageUtil.ets` | `ak_cloud_sync`、`ak_security_mode` |
| `harmonyos/entry/src/main/ets/pages/Index.ets` | 会员 Toggle、自动同步门闩、安全遮罩、安全页挂载 |
| `harmonyos/entry/src/main/ets/views/ProfileView.ets` | 「安全」入口 |
| `harmonyos/entry/src/main/ets/utils/SecurityUtil.ets` | **新建** UserAuth 能力检测 + 鉴权 |
| `harmonyos/entry/src/main/ets/views/SecurityView.ets` | **新建** 三开关 UI（或 Index 内 `@Builder`，二选一；推荐独立 View） |
| `harmonyos/entry/src/main/ets/entryability/EntryAbility.ets` | `onForeground` 发信号触发重新加锁 |
| `harmonyos/entry/src/main/module.json5` | `ohos.permission.ACCESS_BIOMETRIC` |

**Build command (every `.ets` task end):**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey/harmonyos && \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
```

Expected: exit 0, no compile errors.

---

### Task 0: Switch to `dev-harmonyos`

**Files:** none (git only)

- [ ] **Step 1: Check working tree**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git status -sb
git branch --show-current
```

If dirty unrelated files block checkout, stash only what is necessary or leave them untracked; do **not** discard user work.

- [ ] **Step 2: Checkout branch**

```bash
git checkout dev-harmonyos
git pull --ff-only origin dev-harmonyos 2>/dev/null || true
git status -sb
```

Expected: on `dev-harmonyos`, clean enough to edit harmonyos sources.

- [ ] **Step 3: Confirm key files exist**

```bash
test -f harmonyos/entry/src/main/ets/model/BrandIcons.ets && \
test -f harmonyos/entry/src/main/ets/views/ScanView.ets && \
test -f harmonyos/entry/src/main/ets/utils/SyncUtil.ets && echo OK
```

---

## Wave 1 — 打磨

### Task 1: TokenCard — copy next OTP on next-area tap

**Files:**
- Modify: `harmonyos/entry/src/main/ets/components/TokenCard.ets`

- [ ] **Step 1: Split lower-row click targets**

In `TokenCard.ets` `build()`, the lower `Row()` currently has a single:

```typescript
.onClick(() => this.onCopy(this.otp.current, this.token.brand))
```

Change structure so:

1. Left digit `Row` gets `.onClick(() => this.onCopy(this.otp.current, this.token.brand))`
2. Right `Column` (「下一个」+ next code) gets `.onClick(() => this.onCopy(this.otp.next, this.token.brand))`
3. Remove the outer lower-row `.onClick` that always copies current
4. Keep long-press menu as-is

Illustrative structure (match existing styles/colors exactly when editing):

```typescript
// Lower row — copy (split hit targets)
Row() {
  Row({ space: 1 }) {
    // ... existing current digit Texts ...
  }
  .onClick(() => this.onCopy(this.otp.current, this.token.brand))

  Blank()

  Column({ space: 2 }) {
    Row({ space: 3 }) {
      Text('📋').fontSize(10).fontColor(this.c('rgba(238,238,245,0.60)', 'rgba(44,24,16,0.70)'))
      Text('点击复制').fontSize(10).fontColor(this.c('rgba(238,238,245,0.60)', 'rgba(44,24,16,0.70)'))
    }
    Row({ space: 5 }) {
      Text('下一个').fontSize(10).fontColor(this.c('rgba(238,238,245,0.60)', 'rgba(44,24,16,0.70)'))
      Text(fmt(this.otp.next))
        .fontSize(13).fontWeight(600)
        .fontColor(this.c('rgba(238,238,245,0.65)', 'rgba(44,24,16,0.75)'))
        .fontFamily('monospace').letterSpacing(2)
    }
  }
  .alignItems(HorizontalAlign.End)
  .onClick(() => this.onCopy(this.otp.next, this.token.brand))
}
.width('100%')
.padding({ left: 16, right: 16, top: 11, bottom: 14 })
// no row-level onClick
```

- [ ] **Step 2: Build**

Run assembleApp command above. Expected: success.

- [ ] **Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/components/TokenCard.ets
git commit -m "fix(harmonyos): copy next OTP when tapping next-code area"
```

---

### Task 2: Brand icons — scale + 14 new brands

**Files:**
- Modify: `harmonyos/entry/src/main/ets/model/BrandIcons.ets`
- Create/overwrite: `harmonyos/entry/src/main/resources/rawfile/brand-icons/{meta,figma,linkedin,okta,nvidia,discord,dropbox,cloudflare,snapchat,coinbase,crypto,steam,terminal,tiktok}.svg`
- Optional archive copy to repo root `logo/`

- [ ] **Step 1: Copy SVG assets with id filenames**

```bash
SRC=/Users/xiaoan/Downloads
DST=/Users/xiaoan/Documents/code/ArcaneKey/harmonyos/entry/src/main/resources/rawfile/brand-icons
mkdir -p "$DST"
cp "$SRC/Meta.svg" "$DST/meta.svg"
cp "$SRC/Figma.svg" "$DST/figma.svg"
cp "$SRC/linkin.svg" "$DST/linkedin.svg"
cp "$SRC/okta.svg" "$DST/okta.svg"
cp "$SRC/英伟达.svg" "$DST/nvidia.svg"
cp "$SRC/discord.svg" "$DST/discord.svg"
cp "$SRC/dropbox.svg" "$DST/dropbox.svg"
cp "$SRC/cloudflare.svg" "$DST/cloudflare.svg"
cp "$SRC/Snapchat.svg" "$DST/snapchat.svg"
cp "$SRC/coinbase.svg" "$DST/coinbase.svg"
cp "$SRC/Crypto.svg" "$DST/crypto.svg"
cp "$SRC/steam.svg" "$DST/steam.svg"
cp "$SRC/终端.svg" "$DST/terminal.svg"
cp "$SRC/TIKTOK.svg" "$DST/tiktok.svg"
ls "$DST" | sort
```

- [ ] **Step 2: Update BrandIcons.ets scales**

Set on existing entries:

```typescript
{ id: 'binance', officialName: 'Binance', iconFile: 'binance.svg', matchKeywords: ['binance', '币安'], scale: 1.3 },
// netease-mail — add scale: 1.3 to existing object
```

- [ ] **Step 3: Insert new brand rows + fix facebook/meta**

Insert **before** facebook (order = priority). Example entries:

```typescript
{ id: 'meta', officialName: 'Meta', iconFile: 'meta.svg', matchKeywords: ['meta'] },
{ id: 'figma', officialName: 'Figma', iconFile: 'figma.svg', matchKeywords: ['figma'] },
{ id: 'linkedin', officialName: 'LinkedIn', iconFile: 'linkedin.svg', matchKeywords: ['linkedin', 'linkin', '领英'] },
{ id: 'okta', officialName: 'Okta', iconFile: 'okta.svg', matchKeywords: ['okta'] },
{ id: 'nvidia', officialName: 'NVIDIA', iconFile: 'nvidia.svg', matchKeywords: ['nvidia', 'nvdia', '英伟达'] },
{ id: 'discord', officialName: 'Discord', iconFile: 'discord.svg', matchKeywords: ['discord'] },
{ id: 'dropbox', officialName: 'Dropbox', iconFile: 'dropbox.svg', matchKeywords: ['dropbox'] },
{ id: 'cloudflare', officialName: 'Cloudflare', iconFile: 'cloudflare.svg', matchKeywords: ['cloudflare'] },
{ id: 'snapchat', officialName: 'Snapchat', iconFile: 'snapchat.svg', matchKeywords: ['snapchat'] },
{ id: 'coinbase', officialName: 'Coinbase', iconFile: 'coinbase.svg', matchKeywords: ['coinbase'] },
{ id: 'crypto', officialName: 'Crypto', iconFile: 'crypto.svg', matchKeywords: ['crypto', 'crypto.com'] },
{ id: 'steam', officialName: 'Steam', iconFile: 'steam.svg', matchKeywords: ['steam', 'stream'] },
{ id: 'terminal', officialName: '终端', iconFile: 'terminal.svg', matchKeywords: ['terminal', 'ssh', '终端'] },
```

Change facebook to **remove** `meta` from keywords:

```typescript
{ id: 'facebook', officialName: 'Facebook', iconFile: 'facebook.svg', matchKeywords: ['facebook'] },
```

`tiktok` entry already exists — keep keywords; file overwritten in Step 1.

- [ ] **Step 4: Quick match sanity (Node mirror, uncommitted ok)**

```bash
node -e "
const icons = require('fs').readFileSync('harmonyos/entry/src/main/ets/model/BrandIcons.ets','utf8');
console.log(/id: 'meta'/.test(icons) ? 'meta ok' : 'meta MISSING');
console.log(/facebook.*meta/.test(icons) ? 'WARN facebook still has meta nearby' : 'facebook line check manually');
"
```

Or manually confirm: `matchBrandIcon('Meta')` path → meta.svg via reading keywords order.

- [ ] **Step 5: Build + commit**

```bash
# assembleApp
git add harmonyos/entry/src/main/ets/model/BrandIcons.ets \
  harmonyos/entry/src/main/resources/rawfile/brand-icons/
git commit -m "feat(harmonyos): expand brand icons and scale binance/netease-mail"
```

---

### Task 3: ScanView — auto-start scan when camera granted

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/ScanView.ets`

- [ ] **Step 1: Add silent permission check helper**

Add methods (do not replace `requestCameraPermission` used inside `doScan`):

```typescript
private async isCameraGranted(ctx: common.UIAbilityContext): Promise<boolean> {
  try {
    const atManager = abilityAccessCtrl.createAtManager();
    // checkAccessTokenSync or checkAccessToken — use API available on project SDK
    const status = atManager.checkAccessTokenSync(
      ctx.applicationInfo.accessTokenId,
      'ohos.permission.CAMERA'
    );
    return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  } catch (_) {
    return false;
  }
}
```

If `checkAccessTokenSync` / `accessTokenId` types fail compile, fall back to documented `checkAccessToken` async API from AbilityKit for this SDK version — adjust to compile.

- [ ] **Step 2: Auto-scan on appear when already granted**

At end of `aboutToAppear()` (after state reset):

```typescript
aboutToAppear(): void {
  this.brand = '';
  this.account = '';
  this.secret = '';
  this.brandErr = '';
  this.secretErr = '';
  this.scanned = false;
  this.tab = 0;
  this.scanErrMsg = '';
  this.scanning = false;

  // Auto-open system scanner only if camera already authorized
  const ctx = AppStorage.get<common.UIAbilityContext>('context');
  if (ctx) {
    this.isCameraGranted(ctx).then((granted: boolean) => {
      if (granted && this.tab === 0 && !this.scanning) {
        this.doScan(false);
      }
    });
  }
}
```

Notes:
- First launch: `granted === false` → do **not** auto-call here; user taps「扫描二维码」→ `doScan` → `requestCameraPermission` (existing path). After grant, next enter auto-starts.
- `doScan` already guards with `scanning` and requests permission if needed when user taps.

- [ ] **Step 3: Build + commit**

```bash
git add harmonyos/entry/src/main/ets/views/ScanView.ets
git commit -m "feat(harmonyos): auto-start QR scan when camera permission granted"
```

**Wave 1 manual UAT (before Wave 2):**
- [ ] Next-area copies next code
- [ ] Binance / 网易邮箱 larger; Meta ≠ Facebook icon
- [ ] Grant camera once → re-enter scan auto-opens; deny → re-enter still prompts

---

## Wave 2 — 云同步开关

### Task 4: StorageUtil — cloud sync preference

**Files:**
- Modify: `harmonyos/entry/src/main/ets/utils/StorageUtil.ets`

- [ ] **Step 1: Add key + load/save**

```typescript
const CLOUD_SYNC_KEY = 'ak_cloud_sync';

export async function loadCloudSyncEnabled(isMember: boolean): Promise<boolean> {
  try {
    if (!pref) return isMember;
    const val = await pref.get(CLOUD_SYNC_KEY, '');
    if (val === '' || val === null || val === undefined) {
      return isMember; // default: member on, non-member off
    }
    if (typeof val === 'boolean') return val as boolean;
    if (typeof val === 'string') return val === 'true' || val === '1';
    return isMember;
  } catch (_) {
    return isMember;
  }
}

export async function saveCloudSyncEnabled(enabled: boolean): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(CLOUD_SYNC_KEY, enabled);
    await pref.flush();
  } catch (_) {}
}
```

- [ ] **Step 2: Commit**

```bash
git add harmonyos/entry/src/main/ets/utils/StorageUtil.ets
git commit -m "feat(harmonyos): persist cloud sync preference"
```

---

### Task 5: Membership modal toggle + auto-sync gate

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Import + state**

```typescript
import { loadCloudSyncEnabled, saveCloudSyncEnabled, /* existing imports */ } from '../utils/StorageUtil';

@State cloudSyncEnabled: boolean = false;
```

In `loadData()` after member load:

```typescript
this.cloudSyncEnabled = await loadCloudSyncEnabled(this.isMember);
```

- [ ] **Step 2: Gate `startAutoSync` and auto `cloudBackup`**

Replace private `startAutoSync`:

```typescript
private startAutoSync(): void {
  if (!this.isMember || !this.cloudSyncEnabled) return;
  startAutoSync(async () => {
    await this.cloudBackup();
  });
}
```

At every fire-and-forget auto path (add token, import, etc.) that currently does:

```typescript
if (this.isMember) { this.cloudBackup(); }
// or
if (this.isMember && this.loggedIn) { this.cloudBackup(); }
```

Change auto paths to:

```typescript
if (this.isMember && this.cloudSyncEnabled) { this.cloudBackup(); }
// keep loggedIn checks where they already exist:
if (this.isMember && this.loggedIn && this.cloudSyncEnabled) { this.cloudBackup(); }
```

**Do not** gate the user-driven backup/import button handlers (Profile → 备份/导入) — those stay member-only without `cloudSyncEnabled`.

Also gate `updateToken` / soft-delete auto cloud ops if they run without user explicitly choosing cloud delete — match spec: 增删改触发的自动上行. For explicit「同时删除云端」keep as-is (user intent). For silent `cloudBackup` after add/edit/import — require `cloudSyncEnabled`.

When toggling off:

```typescript
private async onCloudSyncToggle(on: boolean): Promise<void> {
  if (!this.isMember) return;
  this.cloudSyncEnabled = on;
  await saveCloudSyncEnabled(on);
  if (on) {
    this.startAutoSync();
  } else {
    stopAutoSync();
  }
}
```

- [ ] **Step 3: UI row in `membershipModal`**

Inside both member and non-member columns (shared after benefits or inside each branch), add:

```typescript
Row() {
  Column({ space: 2 }) {
    Text('云同步').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
    Text(this.isMember ? '关闭后仅保留本地，仍可手动备份' : '开通会员后可用')
      .fontSize(11).fontColor(this.c('rgba(238,238,245,0.55)', '#5C4F43'))
  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
  Toggle({ type: ToggleType.Switch, isOn: this.isMember ? this.cloudSyncEnabled : false })
    .selectedColor(this.accentColor)
    .enabled(this.isMember)
    .opacity(this.isMember ? 1 : 0.4)
    .onChange((isOn: boolean) => {
      if (!this.isMember) return;
      this.onCloudSyncToggle(isOn);
    })
}
.width('100%')
.padding(12)
.backgroundColor(this.c('#191920', '#FFFFFF'))
.borderRadius(12)
```

- [ ] **Step 4: On purchase success default ON**

In `buyMembership` success and `restorePurchase` success paths, after `this.isMember = true`:

```typescript
this.cloudSyncEnabled = true;
await saveCloudSyncEnabled(true);
// isMember @Watch still starts cloud; startAutoSync already checks flag
```

- [ ] **Step 5: Build + commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets harmonyos/entry/src/main/ets/utils/StorageUtil.ets
git commit -m "feat(harmonyos): membership cloud sync toggle gates auto-sync"
```

**Wave 2 UAT:**
- [ ] Non-member: toggle gray off
- [ ] After purchase: toggle on; auto sync runs
- [ ] Toggle off: auto stops; manual backup still works

---

## Wave 3 — 安全

### Task 6: SecurityUtil + security mode storage

**Files:**
- Create: `harmonyos/entry/src/main/ets/utils/SecurityUtil.ets`
- Modify: `harmonyos/entry/src/main/ets/utils/StorageUtil.ets`
- Modify: `harmonyos/entry/src/main/module.json5`

- [ ] **Step 1: Storage modes**

```typescript
export type SecurityMode = 'off' | 'face' | 'fingerprint' | 'lock';

const SECURITY_MODE_KEY = 'ak_security_mode';

export async function loadSecurityMode(): Promise<SecurityMode> {
  try {
    if (!pref) return 'off';
    const val = await pref.get(SECURITY_MODE_KEY, 'off');
    const s = String(val);
    if (s === 'face' || s === 'fingerprint' || s === 'lock') return s;
    return 'off';
  } catch (_) {
    return 'off';
  }
}

export async function saveSecurityMode(mode: SecurityMode): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(SECURITY_MODE_KEY, mode);
    await pref.flush();
  } catch (_) {}
}
```

- [ ] **Step 2: module.json5 permission**

Add to `requestPermissions`:

```json
{
  "name": "ohos.permission.ACCESS_BIOMETRIC",
  "reason": "$string:biometric_reason",
  "usedScene": {
    "abilities": ["EntryAbility"],
    "when": "inuse"
  }
}
```

Add string resource `biometric_reason` in `resources/base/element/string.json` (e.g. 「用于应用解锁的人脸、指纹或锁屏密码验证」). If project uses different string file layout, follow existing `camera_reason` pattern.

- [ ] **Step 3: SecurityUtil.ets**

```typescript
import { userAuth } from '@kit.UserAuthenticationKit';

export type SecurityMode = 'off' | 'face' | 'fingerprint' | 'lock';

function toAuthType(mode: SecurityMode): userAuth.UserAuthType | null {
  if (mode === 'face') return userAuth.UserAuthType.FACE;
  if (mode === 'fingerprint') return userAuth.UserAuthType.FINGERPRINT;
  if (mode === 'lock') return userAuth.UserAuthType.PIN;
  return null;
}

/** true if system has enrolled credential for this mode */
export function isSecurityTypeAvailable(mode: SecurityMode): boolean {
  const authType = toAuthType(mode);
  if (authType === null) return false;
  try {
    // Throws BusinessError if unsupported / not enrolled (e.g. 12500010)
    userAuth.getAvailableStatus(authType, userAuth.AuthTrustLevel.ATL1);
    return true;
  } catch (_) {
    return false;
  }
}

export function authenticateSecurity(mode: SecurityMode): Promise<boolean> {
  return new Promise<boolean>((resolve) => {
    const authType = toAuthType(mode);
    if (authType === null) {
      resolve(true);
      return;
    }
    try {
      const authParam: userAuth.AuthParam = {
        challenge: new Uint8Array(0),
        authType: [authType],
        authTrustLevel: userAuth.AuthTrustLevel.ATL1
      };
      const widgetParam: userAuth.WidgetParam = {
        title: '验证以继续'
      };
      const instance = userAuth.getUserAuthInstance(authParam, widgetParam);
      instance.on('result', (result: userAuth.AuthResult) => {
        // SUCCESS result code — verify against UserAuthResultCode.SUCCESS in SDK
        resolve(result.result === userAuth.UserAuthResultCode.SUCCESS);
      });
      instance.start();
    } catch (_) {
      resolve(false);
    }
  });
}
```

**Implementation note:** Exact property names on `AuthResult` / success code must match the project's `userAuth.d.ts` at build time — adjust field names until `assembleApp` passes. Prefer `UserAuthResultCode.SUCCESS`.

- [ ] **Step 4: Build + commit**

```bash
git add harmonyos/entry/src/main/ets/utils/SecurityUtil.ets \
  harmonyos/entry/src/main/ets/utils/StorageUtil.ets \
  harmonyos/entry/src/main/module.json5 \
  harmonyos/entry/src/main/resources/base/element/string.json
git commit -m "feat(harmonyos): SecurityUtil and security mode persistence"
```

---

### Task 7: SecurityView + Profile entry

**Files:**
- Create: `harmonyos/entry/src/main/ets/views/SecurityView.ets`
- Modify: `harmonyos/entry/src/main/ets/views/ProfileView.ets`
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets` (show flag + callbacks)

- [ ] **Step 1: SecurityView**

Full-screen page (same padding/header pattern as membership modal content):

```typescript
import { isSecurityTypeAvailable, authenticateSecurity } from '../utils/SecurityUtil';
import { SecurityMode, saveSecurityMode } from '../utils/StorageUtil';

@Component
export struct SecurityView {
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  @Prop mode: SecurityMode = 'off';
  onModeChange: (mode: SecurityMode) => void = () => {};
  onClose: () => void = () => {};

  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  private tipFor(mode: SecurityMode): string {
    if (mode === 'face') return '请先在系统设置中录入人脸';
    if (mode === 'fingerprint') return '请先在系统设置中录入指纹';
    return '请先在系统设置中设置锁屏密码';
  }

  private async tryEnable(target: SecurityMode): Promise<void> {
    if (this.mode === target) {
      // turn off
      this.onModeChange('off');
      await saveSecurityMode('off');
      return;
    }
    if (!isSecurityTypeAvailable(target)) {
      // parent toast via callback or local — Index passes toast
      this.onModeChange(this.mode); // no-op notify
      // Use onUnavailable callback preferred:
      return;
    }
    // Optional: require one successful auth before enabling
    const ok = await authenticateSecurity(target);
    if (!ok) return;
    this.onModeChange(target);
    await saveSecurityMode(target);
  }

  build() {
    Column() {
      // header with × → onClose
      // three rows: 人脸识别 / 指纹识别 / 锁屏密码
      // each: label + Toggle isOn: mode===that, onChange tryEnable
      // footer tip: 三种互斥，仅可开启一种
    }
    .width('100%').height('100%')
    .backgroundColor(this.c('#0d0d12', '#FAF7F2'))
  }
}
```

Wire toggles with mutual exclusion in `tryEnable` only (single mode value).

Add `onUnavailable: (msg: string) => void` for toast.

- [ ] **Step 2: ProfileView menu item「安全」**

Add `onSecurityTap: () => void = () => {}` prop.

Insert menu block before 意见与建议 (mirror Feedback row styling):

```typescript
// Security
Column() {
  Row({ space: 0 }) {
    Stack() { Text('🔒').fontSize(16) }
      .width(34).height(34).borderRadius(10)
      .backgroundColor(this.accentColor + '28')
      .margin({ right: 14 })
    Column({ space: 2 }) {
      Text('安全').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
      Text('人脸 / 指纹 / 锁屏密码').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
    }.alignItems(HorizontalAlign.Start).flexGrow(1)
    Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
  }
  .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
  .onClick(() => this.onSecurityTap())
  Divider()...
}
```

- [ ] **Step 3: Index wiring**

```typescript
@State showSecurity: boolean = false;
@State securityMode: SecurityMode = 'off';
@State securityLocked: boolean = false;

// loadData:
this.securityMode = await loadSecurityMode();

// ProfileView:
onSecurityTap: () => {
  if (!this.loggedIn) {
    this.toast('请先登录');
    this.showLogin = true;
    return;
  }
  this.showSecurity = true;
}

// overlay:
if (this.showSecurity) {
  SecurityView({
    accentColor: this.accentColor,
    isDark: this.isDark,
    mode: this.securityMode,
    onModeChange: (m: SecurityMode) => { this.securityMode = m; },
    onClose: () => { this.showSecurity = false; },
    onUnavailable: (msg: string) => { this.toast(msg); }
  })
}
```

- [ ] **Step 4: Build + commit**

```bash
git add harmonyos/entry/src/main/ets/views/SecurityView.ets \
  harmonyos/entry/src/main/ets/views/ProfileView.ets \
  harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat(harmonyos): security settings page with exclusive toggles"
```

---

### Task 8: App lock overlay + cold start / foreground

**Files:**
- Modify: `harmonyos/entry/src/main/ets/entryability/EntryAbility.ets`
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: EntryAbility foreground signal**

```typescript
onForeground(): void {
  AppStorage.setOrCreate('appForegroundSeq', (AppStorage.get<number>('appForegroundSeq') ?? 0) + 1);
}

onBackground(): void {
  // optional: AppStorage.setOrCreate('appNeedsRelock', true);
}
```

- [ ] **Step 2: Index lock flow**

After loadData when `securityMode !== 'off' && loggedIn`:

```typescript
this.securityLocked = true;
this.runSecurityUnlock();
```

```typescript
@Watch('onForegroundSeq') @StorageLink('appForegroundSeq') foregroundSeq: number = 0;

onForegroundSeq(): void {
  if (this.securityMode !== 'off' && this.loggedIn) {
    this.securityLocked = true;
    this.runSecurityUnlock();
  }
}

private async runSecurityUnlock(): Promise<void> {
  if (this.securityMode === 'off' || !this.loggedIn) {
    this.securityLocked = false;
    return;
  }
  const ok = await authenticateSecurity(this.securityMode);
  if (ok) {
    this.securityLocked = false;
  } else {
    this.securityLocked = true; // keep overlay; user taps retry
  }
}
```

**Lock overlay `@Builder`** (zIndex above everything except system auth widget):

```typescript
@Builder
securityLockOverlay() {
  Column({ space: 16 }) {
    Text('🔒').fontSize(40)
    Text('验证以继续').fontSize(18).fontWeight(700).fontColor(this.c('#eeeef5', '#2C1810'))
    Text('已开启应用锁，请验证身份').fontSize(13).fontColor(this.c('rgba(238,238,245,0.55)', '#5C4F43'))
    Button('点击重试')
      .width('80%').height(48).borderRadius(14)
      .backgroundColor(this.accentColor).fontColor('#fff')
      .onClick(() => { this.runSecurityUnlock(); })
  }
  .width('100%').height('100%')
  .justifyContent(FlexAlign.Center)
  .backgroundColor(this.c('#0d0d12', '#FAF7F2'))
  .position({ x: 0, y: 0 })
  .zIndex(900)
}
```

In root `build()`: `if (this.securityLocked) { this.securityLockOverlay() }`

**Debounce:** ignore foregroundSeq fires within ~300ms of successful unlock if spurious double-fire observed.

**Logout:** set `securityLocked = false` (mode may remain saved; lock only when loggedIn).

- [ ] **Step 3: Build + commit**

```bash
git add harmonyos/entry/src/main/ets/entryability/EntryAbility.ets \
  harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat(harmonyos): app lock on cold start and return to foreground"
```

**Wave 3 UAT:**
- [ ] Not logged in → 安全引导登录
- [ ] System without face → cannot enable face
- [ ] Mutual exclusion works
- [ ] Kill app / background → re-auth; cancel → overlay + retry; success → enter

---

## Spec coverage checklist

| Spec item | Task |
|-----------|------|
| Next OTP copy | Task 1 |
| binance / netease-mail 1.3x | Task 2 |
| New icons + meta/facebook | Task 2 |
| Scan auto after permission | Task 3 |
| Cloud sync toggle UI + gray | Task 5 |
| Cloud sync default on purchase | Task 5 |
| Auto-sync only gated | Task 5 |
| Manual backup not gated | Task 5 |
| Security entry + login gate | Task 7 |
| Three exclusive toggles | Task 7 |
| System capability check | Task 6–7 |
| Cold start + foreground lock | Task 8 |
| Fail → full-screen retry | Task 8 |
| `dev-harmonyos` only | Task 0 |

## Placeholder / consistency notes

- `SecurityMode` type defined in StorageUtil; SecurityUtil may re-export or import the same union — **one definition only** (prefer StorageUtil export, SecurityUtil imports it).
- `cloudSyncEnabled` default and `loadCloudSyncEnabled(isMember)` must stay consistent with membership restore paths.
- UserAuth result field names adjusted at compile time to match SDK — not left as TBD in code comments beyond one-line SDK note.

---

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-12-harmonyos-member-security-icons.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
2. **Inline Execution** — this session with executing-plans, batch + checkpoints  

Which approach?
