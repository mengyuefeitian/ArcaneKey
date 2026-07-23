# 锁屏重做 + 安全兜底解锁 + 文案链接改动 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the HarmonyOS app-lock overlay with a product-logo-centric design and a bottom PIN-fallback button, add a new "解锁失败时启用锁屏密码解锁" toggle in 我的>安全, and fix three copy/link items across Profile, Import, and About views.

**Architecture:** All changes live in `harmonyos/entry/src/main/ets/`. `StorageUtil.ets` gains a new boolean preference. `SecurityView.ets` gains a conditional fourth toggle row. `Index.ets` gains two new `@State` fields and a rewritten `securityLockOverlay()` builder. Three unrelated text/link edits round out the plan.

**Tech Stack:** ArkTS (HarmonyOS 6.1 / API 23), `@kit.ArkData` preferences, `@kit.UserAuthenticationKit`.

## Global Constraints

- No `any` type, no implicit conversion, no anonymous object literal types on `@State`/`@Prop` fields (per CLAUDE.md ArkTS strict mode).
- No test framework exists in this repo — verification is `hvigorw assembleApp` build success plus manual DevEco Studio checks, not automated tests (per CLAUDE.md HarmonyOS rules, overriding generic TDD skill defaults).
- New toggle default value: `true` when no stored preference exists.
- New fallback button ("解锁") renders only when `lockFallbackEnabled === true` AND `securityMode` is `'face'` or `'fingerprint'`.
- Existing three-way exclusive security toggle behavior (`SecurityMode`) is unchanged.
- Background decoration icons: 6–10 icons from `BRAND_ICONS`, ~8% opacity, random position/size (32–56vp), re-randomized every time the overlay mounts (no persistence).
- Build command (run from `harmonyos/`):
  ```bash
  DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
    /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
    /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
    --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
  ```

---

### Task 1: Add `lockFallbackEnabled` preference to StorageUtil

**Files:**
- Modify: `harmonyos/entry/src/main/ets/utils/StorageUtil.ets:176-198` (append after existing `SecurityMode` section)

**Interfaces:**
- Produces: `loadLockFallbackEnabled(): Promise<boolean>` (default `true`), `saveLockFallbackEnabled(enabled: boolean): Promise<void>`

- [ ] **Step 1: Add the preference key and functions**

Append at the end of `harmonyos/entry/src/main/ets/utils/StorageUtil.ets` (after the existing `saveSecurityMode` function, currently ending at line 198):

```ts

const LOCK_FALLBACK_KEY = 'ak_lock_fallback_enabled';

export async function loadLockFallbackEnabled(): Promise<boolean> {
  try {
    if (!pref) return true;
    const val = await pref.get(LOCK_FALLBACK_KEY, true);
    if (typeof val === 'boolean') return val as boolean;
    if (typeof val === 'string') return val === 'true' || val === '1';
    return true;
  } catch (_) {
    return true;
  }
}

export async function saveLockFallbackEnabled(enabled: boolean): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(LOCK_FALLBACK_KEY, enabled);
    await pref.flush();
  } catch (_) {}
}
```

This mirrors the existing `loadCloudSyncEnabled`/`saveCloudSyncEnabled` pattern already in the same file (lines 150-174) for boolean prefs with a sensible default.

- [ ] **Step 2: Verify no syntax errors by checking the file compiles in isolation**

Run: `cd harmonyos && grep -c "^export" entry/src/main/ets/utils/StorageUtil.ets`
Expected: a number greater than the pre-change count (new exports added), command exits 0.

- [ ] **Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/utils/StorageUtil.ets
git commit -m "feat(harmonyos): add lock-fallback preference storage"
```

---

### Task 2: Add the fallback toggle to SecurityView

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/SecurityView.ets`

**Interfaces:**
- Consumes: `isSecurityTypeAvailable(mode: SecurityMode): boolean` from `../utils/SecurityUtil` (already imported), `SecurityMode` from `../utils/StorageUtil` (already imported)
- Produces: new `@Prop lockFallbackEnabled: boolean` and `onLockFallbackChange: (enabled: boolean) => void` callback, consumed by `Index.ets` in Task 3.

- [ ] **Step 1: Add the new prop and local toggle state**

In `harmonyos/entry/src/main/ets/views/SecurityView.ets`, after line 15 (`@State private lockOn: boolean = false;`), add:

```ts
  @Prop lockFallbackEnabled: boolean = true;
  @State private fallbackOn: boolean = true;
  onLockFallbackChange: (enabled: boolean) => void = (_e: boolean) => {};
```

- [ ] **Step 2: Sync `fallbackOn` from the prop on appear**

Modify `aboutToAppear()` (currently line 24-26):

```ts
  aboutToAppear(): void {
    this.applyModeVisual(this.mode);
    this.fallbackOn = this.lockFallbackEnabled;
  }
```

- [ ] **Step 3: Add the toggle-change handler**

After the existing `onToggleChange` method (currently ending at line 100), add:

```ts

  private onFallbackToggleChange(on: boolean): void {
    this.fallbackOn = on;
    this.onLockFallbackChange(on);
  }
```

- [ ] **Step 4: Render the new row conditionally, inside the same card as the three existing toggles**

In the `build()` method, the 锁屏密码 row is the last child of the `ForEach` callback's inner `Column`, currently:

```ts
            // 锁屏密码
            Column() {
              Row() {
                Text('锁屏密码')
                  .fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                  .layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.lockOn })
                  .selectedColor(this.accentColor)
                  .onChange((on: boolean) => {
                    this.onToggleChange('lock', on);
                  })
              }
              .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .alignItems(VerticalAlign.Center)
            }
```

Replace it with (adds a trailing `Divider` to the 锁屏密码 row so it's no longer the last child when the new row appears, plus the new conditional row):

```ts
            // 锁屏密码
            Column() {
              Row() {
                Text('锁屏密码')
                  .fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                  .layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.lockOn })
                  .selectedColor(this.accentColor)
                  .onChange((on: boolean) => {
                    this.onToggleChange('lock', on);
                  })
              }
              .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .alignItems(VerticalAlign.Center)
              if (this.mode === 'face' || this.mode === 'fingerprint') {
                Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1)
                  .margin({ left: 16, right: 16 })
              }
            }
            // 解锁失败时启用锁屏密码解锁 (only when primary mode is face/fingerprint)
            if (this.mode === 'face' || this.mode === 'fingerprint') {
              Column() {
                Row() {
                  Text('解锁失败时启用锁屏密码解锁')
                    .fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                    .layoutWeight(1)
                  Toggle({ type: ToggleType.Switch, isOn: this.fallbackOn })
                    .selectedColor(this.accentColor)
                    .enabled(isSecurityTypeAvailable('lock'))
                    .onChange((on: boolean) => {
                      this.onFallbackToggleChange(on);
                    })
                }
                .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .alignItems(VerticalAlign.Center)
                .opacity(isSecurityTypeAvailable('lock') ? 1 : 0.5)
              }
            }
```

- [ ] **Step 5: Add the "锁屏密码未设置" hint to the footer tip when applicable**

Replace the footer tip (currently lines 175-181):

```ts
        // Footer tip
        Text('三种互斥，仅可开启一种。依赖系统设置；未录入则无法开启。')
          .fontSize(12)
          .fontColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
          .width('100%')
          .padding({ left: 4, right: 4 })
          .lineHeight(18)
```

with:

```ts
        // Footer tip
        Text('三种互斥，仅可开启一种。依赖系统设置；未录入则无法开启。')
          .fontSize(12)
          .fontColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
          .width('100%')
          .padding({ left: 4, right: 4 })
          .lineHeight(18)
        if ((this.mode === 'face' || this.mode === 'fingerprint') && !isSecurityTypeAvailable('lock')) {
          Text('锁屏密码未设置')
            .fontSize(12)
            .fontColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
            .width('100%')
            .padding({ left: 4, right: 4 })
            .lineHeight(18)
        }
```

- [ ] **Step 6: Commit**

```bash
git add harmonyos/entry/src/main/ets/views/SecurityView.ets
git commit -m "feat(harmonyos): add lock-fallback toggle to security settings"
```

---

### Task 3: Wire `lockFallbackEnabled` and `securityAuthFailed` state through Index.ets

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets`

**Interfaces:**
- Consumes: `loadLockFallbackEnabled`, `saveLockFallbackEnabled` from `../utils/StorageUtil` (Task 1); `SecurityView`'s new `lockFallbackEnabled` prop and `onLockFallbackChange` callback (Task 2)
- Produces: `@State lockFallbackEnabled: boolean`, `@State securityAuthFailed: boolean` — consumed by Task 4's rewritten `securityLockOverlay()`

- [ ] **Step 1: Import the new StorageUtil functions**

Modify line 11:

```ts
import { initPreferences, loadTokens, saveTokens, loadTheme, saveTheme, loadMember, saveMember, MemberData, loadLogin, saveLogin, LoginData, loadThemeMode, saveThemeMode, loadCloudSyncEnabled, saveCloudSyncEnabled, SecurityMode, loadSecurityMode, loadLockFallbackEnabled, saveLockFallbackEnabled } from '../utils/StorageUtil';
```

- [ ] **Step 2: Add the new `@State` fields**

Modify the Security Settings block (currently lines 109-114):

```ts
  // ── Security Settings ───────────────────────────────────────────
  @State showSecurity: boolean = false;
  @State securityMode: SecurityMode = 'off';
  @State securityLocked: boolean = false;
  @State lockFallbackEnabled: boolean = true;
  @State securityAuthFailed: boolean = false;
  // EntryAbility.onForeground bumps this; @Watch re-locks when security is on
  @StorageLink('appForegroundSeq') @Watch('onForegroundSeqChanged') foregroundSeq: number = 0;
```

- [ ] **Step 3: Reset and track failure state in the unlock flow**

Modify `runSecurityUnlock()` (currently lines 171-187):

```ts
  private async runSecurityUnlock(): Promise<void> {
    if (this.securityMode === 'off' || !this.loggedIn) {
      this.securityLocked = false;
      this.securityAuthFailed = false;
      return;
    }
    // Debounce: cold start can fire loadData unlock + onForeground seq together
    if (this.securityUnlocking) {
      return;
    }
    this.securityUnlocking = true;
    this.securityAuthFailed = false;
    try {
      const ok = await authenticateSecurity(this.securityMode);
      this.securityLocked = !ok;
      this.securityAuthFailed = !ok;
    } finally {
      this.securityUnlocking = false;
    }
  }
```

- [ ] **Step 4: Add a fallback-unlock method for the bottom "解锁" button**

After `runSecurityUnlock()` (after the closing brace that now ends around line 189), add:

```ts

  private async runLockFallbackUnlock(): Promise<void> {
    if (this.securityUnlocking) {
      return;
    }
    this.securityUnlocking = true;
    try {
      const ok = await authenticateSecurity('lock');
      this.securityLocked = !ok;
      if (ok) {
        this.securityAuthFailed = false;
      }
    } finally {
      this.securityUnlocking = false;
    }
  }
```

- [ ] **Step 5: Load the new preference in `loadData()`**

Modify line 346 area — after `this.securityMode = await loadSecurityMode();`, add:

```ts
      this.securityMode = await loadSecurityMode();
      this.lockFallbackEnabled = await loadLockFallbackEnabled();
```

- [ ] **Step 6: Reset `securityAuthFailed` on logout (two call sites)**

At line 1699 (inside `accountInfoModal`'s 退出登录 button) and line 1826 (inside `ProfileView`'s `onLogout` callback), both currently set `this.securityLocked = false;`. Change each to:

```ts
            this.securityLocked = false;
            this.securityAuthFailed = false;
```

(Apply this same two-line change at both locations — they are structurally identical single-line statements in different callbacks.)

- [ ] **Step 7: Pass the new prop/callback to `SecurityView`**

Modify the `SecurityView` invocation (currently lines 1888-1898):

```ts
      if (this.showSecurity) {
        SecurityView({
          accentColor: this.accentColor,
          isDark: this.isDark,
          mode: this.securityMode,
          onModeChange: (m: SecurityMode) => { this.securityMode = m; },
          lockFallbackEnabled: this.lockFallbackEnabled,
          onLockFallbackChange: (enabled: boolean) => {
            this.lockFallbackEnabled = enabled;
            saveLockFallbackEnabled(enabled);
          },
          onClose: () => { this.showSecurity = false; },
          onUnavailable: (msg: string) => { this.toast(msg); }
        })
          .position({ x: 0, y: 0 })
          .zIndex(400)
      }
```

- [ ] **Step 8: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat(harmonyos): wire lock-fallback state through Index"
```

---

### Task 4: Rewrite the lock overlay UI

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets:1-23` (imports), `:1715-1748` (the `securityLockOverlay()` builder)

**Interfaces:**
- Consumes: `BRAND_ICONS: BrandIconConfig[]` and `BrandIconConfig` from `../model/BrandIcons`; `this.lockFallbackEnabled`, `this.securityAuthFailed`, `this.securityMode`, `this.securityUnlocking`, `this.accentColor`, `this.isDark`, `this.c()`, `runSecurityUnlock()`, `runLockFallbackUnlock()` (all from Task 3)
- Produces: rewritten `securityLockOverlay()` builder, unchanged external call site (`Index.ets:1930-1932` — no change needed there, it already calls `this.securityLockOverlay()`)

- [ ] **Step 1: Import `BRAND_ICONS` and its type**

Modify line 9, adding the new import on its own line right after it:

```ts
import { Token, SyncToken, OtpPair, ThemeItem, THEMES, INITIAL_TOKENS, FREE_TOKEN_LIMIT, MEMBERSHIP_PRICE, APP_NAME } from '../model/Token';
import { BRAND_ICONS, BrandIconConfig } from '../model/BrandIcons';
```

- [ ] **Step 2: Add a typed helper interface and a random-icon picker above the class**

After the existing `interface IapError { ... }` block (search for it near the top of the file, right after the `SaveOptions` interface), add a new interface and module-level function. These must sit outside the `@Entry @Component struct Index` body since ArkTS structs can't host free functions with `Math.random`-based array shuffling logic as instance methods only — but a plain instance method works fine too, so instead we add it as a private method inside the struct in Step 3, keeping this step to just the type:

```ts
interface DecorativeIcon {
  iconFile: string;
  leftPercent: number;
  topPercent: number;
  size: number;
}
```

Place this interface definition directly below `interface IapError { ... }` (top of file, alongside the other interfaces).

- [ ] **Step 3: Add `@State decorativeIcons` and a randomizer method**

In the Security Settings block (right after `@State securityAuthFailed: boolean = false;` from Task 3 Step 2), add:

```ts
  @State decorativeIcons: DecorativeIcon[] = [];
```

Add a new private method near `runLockFallbackUnlock()` (Task 3 Step 4), after it:

```ts

  private randomizeDecorativeIcons(): void {
    const count = 6 + Math.floor(Math.random() * 5); // 6–10 inclusive
    const pool = BRAND_ICONS.slice();
    const picked: DecorativeIcon[] = [];
    for (let i = 0; i < count && pool.length > 0; i++) {
      const idx = Math.floor(Math.random() * pool.length);
      const cfg: BrandIconConfig = pool.splice(idx, 1)[0];
      picked.push({
        iconFile: cfg.iconFile,
        leftPercent: Math.round(Math.random() * 85),
        topPercent: Math.round(Math.random() * 85),
        size: 32 + Math.round(Math.random() * 24)
      });
    }
    this.decorativeIcons = picked;
  }
```

- [ ] **Step 4: Trigger randomization when the overlay is about to show**

Modify `onForegroundSeqChanged()` (Task 3 area, currently around line 164-169):

```ts
  private onForegroundSeqChanged(): void {
    if (this.securityMode !== 'off' && this.loggedIn) {
      this.securityLocked = true;
      this.randomizeDecorativeIcons();
      this.runSecurityUnlock();
    }
  }
```

Also modify the cold-start lock-setting site in `loadData()` (currently lines 371-375):

```ts
      // Cold start: lock until biometric / lock-screen auth succeeds
      if (this.securityMode !== 'off' && this.loggedIn) {
        this.securityLocked = true;
        this.randomizeDecorativeIcons();
        this.runSecurityUnlock();
      }
```

- [ ] **Step 5: Rewrite the `securityLockOverlay()` builder**

Replace the entire builder (currently lines 1715-1748):

```ts
  // ── Builder: Security lock overlay ──────────────────────────────
  @Builder
  securityLockOverlay() {
    Stack() {
      // Decorative brand-icon backdrop
      ForEach(this.decorativeIcons, (icon: DecorativeIcon, index: number) => {
        Image($rawfile('brand-icons/' + icon.iconFile))
          .width(icon.size)
          .height(icon.size)
          .opacity(0.08)
          .position({ x: `${icon.leftPercent}%`, y: `${icon.topPercent}%` })
      }, (icon: DecorativeIcon, index: number) => `decor-${index}-${icon.iconFile}`)

      // Center content
      Column({ space: 16 }) {
        Image($r('app.media.logo_img'))
          .width(88).height(88).borderRadius(20)
          .shadow({ radius: 24, color: this.accentColor + '55', offsetX: 0, offsetY: 6 })
        Text('星枢令已锁定')
          .fontSize(20)
          .fontWeight(700)
          .fontColor(this.c('#eeeef5', '#2C1810'))
        Text(this.securityAuthFailed ? '验证失败，请重试' : '正在验证…')
          .fontSize(13)
          .fontColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
        Text('重新验证')
          .fontSize(13)
          .fontColor(this.accentColor)
          .onClick(() => {
            this.runSecurityUnlock();
          })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // Bottom fallback "解锁" button
      if (this.lockFallbackEnabled && (this.securityMode === 'face' || this.securityMode === 'fingerprint')) {
        Button('解锁')
          .width('100%')
          .height(50)
          .borderRadius(15)
          .backgroundColor(this.securityAuthFailed ? this.accentColor : this.c('#191920', '#F5F0EA'))
          .fontColor(this.securityAuthFailed ? '#fff' : this.c('rgba(238,238,245,0.60)', '#6B5B50'))
          .fontSize(15)
          .fontWeight(650)
          .enabled(this.securityAuthFailed)
          .position({ x: 0, y: '100%' })
          .markAnchor({ x: 0, y: '100%' })
          .translate({ y: -50 })
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.runLockFallbackUnlock();
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.c('#0d0d12', '#FAF7F2'))
    .position({ x: 0, y: 0 })
    .zIndex(900)
  }
```

Note: `position({x:0,y:'100%'})` combined with `markAnchor({x:0,y:'100%'})` anchors the button's own bottom-left corner to the container's bottom-left corner (100%,100%), so `translate({y:-50})` then moves it up exactly 50vp from the very bottom edge, full-width minus the 20vp side padding — matching the existing full-width button pattern used elsewhere in this file (e.g. `加密备份并下载`, `导入`).

- [ ] **Step 6: Build the project to verify ArkTS compiles**

Run (from `harmonyos/`):
```bash
cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
```
Expected: `BUILD SUCCESSFUL`. If it fails, read every error, fix root causes (missing imports, type mismatches, ArkTS restrictions), and rerun until it passes — per CLAUDE.md's Error Resolution Loop. Do not consider this task done until the build succeeds.

- [ ] **Step 7: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat(harmonyos): redesign app lock overlay with logo, decor icons, and PIN fallback"
```

---

### Task 5: Copy and link fixes

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/ProfileView.ets:143,162`
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets` (`importModal()` builder, currently lines 1364-1409)
- Modify: `harmonyos/entry/src/main/ets/views/AboutView.ets:307`

**Interfaces:** None — pure text/string literal edits, no new interfaces.

- [ ] **Step 1: Update backup-data subtitle in ProfileView**

In `harmonyos/entry/src/main/ets/views/ProfileView.ets`, line 143:

```ts
                Text(this.isMember ? '加密备份到云端' : '会员专属')
```

becomes:

```ts
                Text(this.isMember ? '加密备份数据到本地存储' : '会员专属')
```

- [ ] **Step 2: Update import-backup subtitle in ProfileView**

In the same file, line 162:

```ts
                Text(this.isMember ? '从云端恢复' : '会员专属')
```

becomes:

```ts
                Text(this.isMember ? '从本地备份恢复' : '会员专属')
```

- [ ] **Step 3: Add the Proton Authenticator import hint**

In `harmonyos/entry/src/main/ets/pages/Index.ets`, inside `importModal()`, the "备份内容" label block currently reads (around line 1376-1383):

```ts
        Column({ space: 6 }) {
          Text('备份内容（粘贴加密或 OTP 文本）').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
          TextArea({ text: this.importText, placeholder: '粘贴备份内容，或粘贴 otpauth:// 格式内容…' })
            .onChange((v) => { this.importText = v; })
            .height(120).backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
            .border({ width: 1, color: this.c('rgba(255,255,255,0.08)', '#E8E2D9') }).borderRadius(12)
            .placeholderColor(this.c('rgba(238,238,245,0.60)', '#6B5B50')).fontSize(12).fontFamily('monospace')
        }.alignItems(HorizontalAlign.Start).width('100%')
```

Replace with (adds a new hint line right after the label):

```ts
        Column({ space: 6 }) {
          Text('备份内容（粘贴加密或 OTP 文本）').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
          Text('支持Proton Authenticator备份文件或格式明文导入').fontSize(11).fontColor(this.c('rgba(238,238,245,0.45)', '#9B8B80'))
          TextArea({ text: this.importText, placeholder: '粘贴备份内容，或粘贴 otpauth:// 格式内容…' })
            .onChange((v) => { this.importText = v; })
            .height(120).backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
            .border({ width: 1, color: this.c('rgba(255,255,255,0.08)', '#E8E2D9') }).borderRadius(12)
            .placeholderColor(this.c('rgba(238,238,245,0.60)', '#6B5B50')).fontSize(12).fontFamily('monospace')
        }.alignItems(HorizontalAlign.Start).width('100%')
```

- [ ] **Step 4: Update the website link in AboutView**

In `harmonyos/entry/src/main/ets/views/AboutView.ets`, line 307:

```ts
                .onClick(() => { this.openUrl('https://www.xiaoanhome.xyz'); })
```

becomes:

```ts
                .onClick(() => { this.openUrl('https://www.xiaoanhome.xyz/arcanekey'); })
```

(Line 174's static privacy-policy text "· 官网：www.xiaoanhome.xyz" stays unchanged per design decision — it's a display string inside the privacy policy body text, not a clickable link.)

- [ ] **Step 5: Build to verify**

Run the same `hvigorw assembleApp` command as Task 4 Step 6.
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 6: Commit**

```bash
git add harmonyos/entry/src/main/ets/views/ProfileView.ets harmonyos/entry/src/main/ets/pages/Index.ets harmonyos/entry/src/main/ets/views/AboutView.ets
git commit -m "fix(harmonyos): update backup/import copy and about-us website link"
```

---

### Task 6: Final full-project build verification

**Files:** None (verification only).

- [ ] **Step 1: Clean incremental build to catch anything the daemon cached over**

Run (from `harmonyos/`):
```bash
cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode project -p product=default assembleApp --analyze=normal --parallel
```
Expected: `BUILD SUCCESSFUL`, zero ArkTS/compilation/resource/import errors.

- [ ] **Step 2: Manual verification checklist (DevEco Studio simulator or device)**

Walk through each scenario from the spec's testing plan and confirm behavior:
- 我的>安全, 主方式=人脸/指纹: new toggle appears; toggling it persists across app restart.
- 我的>安全, 主方式=锁屏密码 or off: new toggle row is absent.
- Device with no lock-screen password set: new toggle is grayed out, "锁屏密码未设置" hint shows at the bottom of 我的>安全.
- Lock overlay: shows product logo, "星枢令已锁定", status text, "重新验证" link, and decorative background icons.
- Lock overlay with fallback ON + face/fingerprint primary: after a failed default-method attempt, bottom "解锁" button becomes enabled; tapping it opens PIN verification directly.
- Lock overlay with fallback OFF: no bottom button ever appears; only "重新验证" retries the default method.
- 我的>备份数据 shows "加密备份数据到本地存储"; 我的>导入备份 shows "从本地备份恢复"; 内容备份 area shows the new Proton Authenticator hint line.
- 关于我们>官网 opens `https://www.xiaoanhome.xyz/arcanekey`.

- [ ] **Step 3: If any manual check fails, return to the relevant task, fix, rebuild, and recheck before proceeding.**

No commit for this task — it's verification-only. If fixes were needed, commit them under their originating task's scope with a `fix(harmonyos): ...` message.
