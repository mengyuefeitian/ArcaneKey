# HarmonyOS Comment / Scan Lifecycle / Lock Fallback / Search Focus Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship four HarmonyOS improvements: AppGallery in-app comment (entry + smart prompt), release camera and leave scan on background, auto PIN fallback when face/fingerprint auth fails for non-cancel reasons, and auto keyboard on search.

**Architecture:** Lifecycle signals via `AppStorage` (`appBackgroundSeq` mirrors existing `appForegroundSeq`). Auth returns `AuthOutcome` with UserAuth result codes so Index can auto-call lock-screen PIN. Comment is a thin util over `commentManager.showCommentDialog` with preferences-based rate limits. Search focus uses ArkUI `defaultFocus` on the conditional search `TextInput`.

**Tech Stack:** ArkTS / HarmonyOS API 23, `@kit.UserAuthenticationKit`, `@kit.AppGalleryKit` (`commentManager`), `@kit.ArkData` preferences, existing Index / ScanView / HomeView / ProfileView patterns.

**Spec:** `docs/superpowers/specs/2026-07-25-harmonyos-comment-scan-lock-search-design.md`

**Note on tests:** This repo has no unit-test harness for HarmonyOS. Each task verifies via: (1) TypeScript/ArkTS consistency in-editor, (2) full `hvigorw assembleApp` build after related groups of tasks, (3) manual UAT checklist at the end. Do not invent a test framework for this plan.

---

## File map

| File | Responsibility |
|------|----------------|
| `harmonyos/entry/src/main/ets/entryability/EntryAbility.ets` | Init `appBackgroundSeq`; bump on `onBackground` |
| `harmonyos/entry/src/main/ets/utils/SecurityUtil.ets` | `AuthOutcome`; return result codes |
| `harmonyos/entry/src/main/ets/views/SecurityView.ets` | Consume `outcome.ok` |
| `harmonyos/entry/src/main/ets/utils/StorageUtil.ets` | Open count + comment version prefs |
| `harmonyos/entry/src/main/ets/utils/CommentUtil.ets` | **Create** — show dialog + error mapping + smart-prompt helpers |
| `harmonyos/entry/src/main/ets/pages/Index.ets` | Background → home; auto PIN; wire comment triggers + Profile callback |
| `harmonyos/entry/src/main/ets/views/ProfileView.ets` | Menu row「给星枢令评分」 |
| `harmonyos/entry/src/main/ets/views/HomeView.ets` | Search `defaultFocus` + id |
| `harmonyos/entry/src/main/ets/views/ScanView.ets` | Optional double-stop on background (only if needed after Index tab reset) |

---

### Task 1: SecurityUtil returns AuthOutcome

**Files:**
- Modify: `harmonyos/entry/src/main/ets/utils/SecurityUtil.ets`
- Modify: `harmonyos/entry/src/main/ets/views/SecurityView.ets` (call site)

- [ ] **Step 1: Replace boolean return with AuthOutcome in SecurityUtil**

Replace the file content of `SecurityUtil.ets` with:

```typescript
import { userAuth } from '@kit.UserAuthenticationKit';
import { SecurityMode } from './StorageUtil';

export interface AuthOutcome {
  ok: boolean;
  /** userAuth.UserAuthResultCode value, or -1 for local/NAPI failure */
  code: number;
}

function toAuthType(mode: SecurityMode): userAuth.UserAuthType | null {
  if (mode === 'face') {
    return userAuth.UserAuthType.FACE;
  }
  if (mode === 'fingerprint') {
    return userAuth.UserAuthType.FINGERPRINT;
  }
  if (mode === 'lock') {
    return userAuth.UserAuthType.PIN;
  }
  return null;
}

export function isSecurityTypeAvailable(mode: SecurityMode): boolean {
  const authType = toAuthType(mode);
  if (authType === null) {
    return false;
  }
  try {
    userAuth.getAvailableStatus(authType, userAuth.AuthTrustLevel.ATL1);
    return true;
  } catch (_) {
    return false;
  }
}

function buildChallenge(): Uint8Array {
  return new Uint8Array([
    0x41, 0x72, 0x63, 0x61, 0x6e, 0x65, 0x4b, 0x65,
    0x79, 0x53, 0x65, 0x63, 0x75, 0x72, 0x65, 0x00
  ]);
}

/** True when face/fingerprint failure should auto-route to lock-screen PIN. */
export function shouldAutoLockFallback(code: number): boolean {
  if (code === -1) {
    return true;
  }
  if (code === userAuth.UserAuthResultCode.BUSY) {
    return true;
  }
  if (code === userAuth.UserAuthResultCode.FAIL) {
    return true;
  }
  if (code === userAuth.UserAuthResultCode.GENERAL_ERROR) {
    return true;
  }
  if (code === userAuth.UserAuthResultCode.TIMEOUT) {
    return true;
  }
  return false;
}

export function authenticateSecurity(mode: SecurityMode): Promise<AuthOutcome> {
  return new Promise<AuthOutcome>((resolve: (value: AuthOutcome) => void) => {
    const authType = toAuthType(mode);
    if (authType === null) {
      resolve({ ok: true, code: userAuth.UserAuthResultCode.SUCCESS });
      return;
    }
    try {
      const authParam: userAuth.AuthParam = {
        challenge: buildChallenge(),
        authType: [authType],
        authTrustLevel: userAuth.AuthTrustLevel.ATL1
      };
      const widgetParam: userAuth.WidgetParam = {
        title: '验证以继续'
      };
      const instance: userAuth.UserAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
      const callback: userAuth.IAuthCallback = {
        onResult: (result: userAuth.UserAuthResult) => {
          const code: number = result.result;
          resolve({
            ok: code === userAuth.UserAuthResultCode.SUCCESS,
            code: code
          });
        }
      };
      instance.on('result', callback);
      instance.start();
    } catch (e) {
      console.error('[SecurityUtil] authenticateSecurity failed: ' +
        (e instanceof Error ? e.message : String(e)));
      resolve({ ok: false, code: -1 });
    }
  });
}
```

- [ ] **Step 2: Update SecurityView tryEnable to use outcome.ok**

In `SecurityView.ets`, change:

```typescript
    const ok: boolean = await authenticateSecurity(target);
    if (!ok) {
```

to:

```typescript
    const outcome = await authenticateSecurity(target);
    if (!outcome.ok) {
```

- [ ] **Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/utils/SecurityUtil.ets \
  harmonyos/entry/src/main/ets/views/SecurityView.ets
git commit -m "feat(harmonyos): return AuthOutcome from authenticateSecurity"
```

---

### Task 2: Index auto PIN fallback on face/fingerprint failure

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets` (imports + `runSecurityUnlock` / `runLockFallbackUnlock`)

- [ ] **Step 1: Update imports**

Change SecurityUtil import to:

```typescript
import {
  authenticateSecurity,
  isSecurityTypeAvailable,
  shouldAutoLockFallback,
  AuthOutcome
} from '../utils/SecurityUtil';
```

- [ ] **Step 2: Rewrite runSecurityUnlock and runLockFallbackUnlock**

Replace the two methods with:

```typescript
  private async runSecurityUnlock(): Promise<void> {
    if (this.securityMode === 'off' || !this.loggedIn) {
      this.securityLocked = false;
      this.securityAuthFailed = false;
      return;
    }
    if (this.securityUnlocking) {
      return;
    }
    this.securityUnlocking = true;
    this.securityAuthFailed = false;
    try {
      const outcome: AuthOutcome = await authenticateSecurity(this.securityMode);
      if (outcome.ok) {
        this.securityLocked = false;
        this.securityAuthFailed = false;
        return;
      }
      // Face/fingerprint recoverable failure → auto lock-screen PIN (no retry trap)
      const canFallback: boolean =
        this.lockFallbackEnabled &&
        (this.securityMode === 'face' || this.securityMode === 'fingerprint') &&
        isSecurityTypeAvailable('lock') &&
        shouldAutoLockFallback(outcome.code);
      if (canFallback) {
        // Keep locked; do not flash failed UI before PIN sheet
        this.securityLocked = true;
        this.securityAuthFailed = false;
        this.securityUnlocking = false;
        await this.runLockFallbackUnlock();
        return;
      }
      this.securityLocked = true;
      this.securityAuthFailed = true;
    } finally {
      this.securityUnlocking = false;
    }
  }

  private async runLockFallbackUnlock(): Promise<void> {
    if (this.securityUnlocking) {
      return;
    }
    this.securityUnlocking = true;
    try {
      const outcome: AuthOutcome = await authenticateSecurity('lock');
      this.securityLocked = !outcome.ok;
      if (outcome.ok) {
        this.securityAuthFailed = false;
      } else {
        this.securityAuthFailed = true;
      }
    } finally {
      this.securityUnlocking = false;
    }
  }
```

**Important:** When auto-fallback calls `runLockFallbackUnlock`, the parent clears `securityUnlocking` before the call so the fallback is not no-op'd by the guard. The `finally` of `runSecurityUnlock` also sets `securityUnlocking = false` — ensure order is:

```typescript
        this.securityUnlocking = false;
        await this.runLockFallbackUnlock();
        return;
```

and that the outer `finally` does not re-enter a bad state. Prefer structuring without double-finally race:

```typescript
  private async runSecurityUnlock(): Promise<void> {
    if (this.securityMode === 'off' || !this.loggedIn) {
      this.securityLocked = false;
      this.securityAuthFailed = false;
      return;
    }
    if (this.securityUnlocking) {
      return;
    }
    this.securityUnlocking = true;
    this.securityAuthFailed = false;
    let handoffToFallback: boolean = false;
    try {
      const outcome: AuthOutcome = await authenticateSecurity(this.securityMode);
      if (outcome.ok) {
        this.securityLocked = false;
        this.securityAuthFailed = false;
        return;
      }
      const canFallback: boolean =
        this.lockFallbackEnabled &&
        (this.securityMode === 'face' || this.securityMode === 'fingerprint') &&
        isSecurityTypeAvailable('lock') &&
        shouldAutoLockFallback(outcome.code);
      if (canFallback) {
        this.securityLocked = true;
        this.securityAuthFailed = false;
        handoffToFallback = true;
        return;
      }
      this.securityLocked = true;
      this.securityAuthFailed = true;
    } finally {
      this.securityUnlocking = false;
    }
    if (handoffToFallback) {
      await this.runLockFallbackUnlock();
    }
  }
```

Use this **handoff** version (avoids re-entrancy with `securityUnlocking`).

- [ ] **Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat(harmonyos): auto lock-screen PIN when biometric unlock fails"
```

---

### Task 3: Background leaves scan and frees camera

**Files:**
- Modify: `harmonyos/entry/src/main/ets/entryability/EntryAbility.ets`
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: EntryAbility init + onBackground**

In `onCreate`, next to `appForegroundSeq`:

```typescript
    AppStorage.setOrCreate('appBackgroundSeq', 0);
```

Replace empty `onBackground`:

```typescript
  onBackground(): void {
    // Bump so Index can leave scan tab and free the camera before re-auth
    const prev = AppStorage.get<number>('appBackgroundSeq') ?? 0;
    AppStorage.setOrCreate('appBackgroundSeq', prev + 1);
  }
```

- [ ] **Step 2: Index watches background and resets tab**

Add field near `foregroundSeq`:

```typescript
  @StorageLink('appBackgroundSeq') @Watch('onBackgroundSeqChanged') backgroundSeq: number = 0;
```

Add method:

```typescript
  private onBackgroundSeqChanged(): void {
    // Leave scan so customScan releases the camera (face unlock needs it)
    if (this.currentTab === 1) {
      this.currentTab = 0;
    }
    if (this.searching) {
      this.searching = false;
      this.searchQ = '';
    }
  }
```

`ScanView` already stops the camera when `isActive` becomes false (`currentTab !== 1`). No ScanView change required if Tabs rebind works; verify on device. If camera still held, add Task 3b below.

- [ ] **Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/entryability/EntryAbility.ets \
  harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "fix(harmonyos): leave scan and free camera on app background"
```

---

### Task 3b (only if device still holds camera): ScanView background stop

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/ScanView.ets`

- [ ] **Step 1: Add StorageProp watch**

```typescript
  @StorageProp('appBackgroundSeq') @Watch('onAppBackground') private bgSeq: number = 0;

  private onAppBackground(): void {
    this.stopEmbeddedCamera();
  }
```

- [ ] **Step 2: Commit if used**

```bash
git add harmonyos/entry/src/main/ets/views/ScanView.ets
git commit -m "fix(harmonyos): stop embedded scan camera on background"
```

---

### Task 4: Comment storage + CommentUtil

**Files:**
- Modify: `harmonyos/entry/src/main/ets/utils/StorageUtil.ets` (append at end)
- Create: `harmonyos/entry/src/main/ets/utils/CommentUtil.ets`

- [ ] **Step 1: Append prefs helpers to StorageUtil.ets**

```typescript
const OPEN_COUNT_KEY = 'ak_open_count';
const COMMENT_PROMPTED_VER_KEY = 'ak_comment_prompted_ver';
const COMMENT_DONE_VER_KEY = 'ak_comment_done_ver';

export async function loadOpenCount(): Promise<number> {
  try {
    if (!pref) return 0;
    const val = await pref.get(OPEN_COUNT_KEY, 0);
    if (typeof val === 'number') return val as number;
    const n = Number(val);
    return isNaN(n) ? 0 : n;
  } catch (_) {
    return 0;
  }
}

export async function saveOpenCount(count: number): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(OPEN_COUNT_KEY, count);
    await pref.flush();
  } catch (_) {}
}

export async function loadCommentPromptedVer(): Promise<string> {
  try {
    if (!pref) return '';
    return String(await pref.get(COMMENT_PROMPTED_VER_KEY, ''));
  } catch (_) {
    return '';
  }
}

export async function saveCommentPromptedVer(ver: string): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(COMMENT_PROMPTED_VER_KEY, ver);
    await pref.flush();
  } catch (_) {}
}

export async function loadCommentDoneVer(): Promise<string> {
  try {
    if (!pref) return '';
    return String(await pref.get(COMMENT_DONE_VER_KEY, ''));
  } catch (_) {
    return '';
  }
}

export async function saveCommentDoneVer(ver: string): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(COMMENT_DONE_VER_KEY, ver);
    await pref.flush();
  } catch (_) {}
}
```

- [ ] **Step 2: Create CommentUtil.ets**

```typescript
import { common, bundleManager } from '@kit.AbilityKit';
import { commentManager } from '@kit.AppGalleryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  loadCommentDoneVer,
  loadCommentPromptedVer,
  saveCommentDoneVer,
  saveCommentPromptedVer
} from './StorageUtil';

export function getAppVersionName(): string {
  try {
    const info = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
    return info.versionName || '0';
  } catch (_) {
    return '0';
  }
}

export function mapCommentError(code: number): string {
  // From @hms.core.appgalleryservice.commentManager.d.ts
  if (code === 1021500006) {
    return '请先登录华为账号后再评价';
  }
  if (code === 1021500007) {
    return '您已评价过当前版本，感谢支持';
  }
  if (code === 1021500008) {
    return '评价次数已达上限';
  }
  if (code === 1021500009) {
    return '您近期已评价过，感谢支持';
  }
  if (code === 1021500003) {
    return '无法连接应用市场，请稍后重试';
  }
  return '暂时无法打开评价，请稍后重试';
}

/**
 * Manual entry: always attempt to show the dialog.
 * @returns toast message for failures; empty string on success / silent cancel paths
 */
export async function showAppComment(
  context: common.UIAbilityContext,
  markDoneOnSuccess: boolean
): Promise<string> {
  const ver = getAppVersionName();
  try {
    await commentManager.showCommentDialog(context);
    if (markDoneOnSuccess) {
      await saveCommentDoneVer(ver);
    }
    return '';
  } catch (e) {
    const err = e as BusinessError;
    const code: number = err.code !== undefined ? err.code : -1;
    console.warn('[CommentUtil] showCommentDialog failed:', code, err.message);
    // Treat "already commented" as done so smart prompt stops
    if (code === 1021500007 || code === 1021500009) {
      await saveCommentDoneVer(ver);
    }
    return mapCommentError(code);
  }
}

/** Whether smart prompt is allowed this version (not done, not already auto-prompted). */
export async function canSmartPromptComment(): Promise<boolean> {
  const ver = getAppVersionName();
  const done = await loadCommentDoneVer();
  if (done === ver) {
    return false;
  }
  const prompted = await loadCommentPromptedVer();
  if (prompted === ver) {
    return false;
  }
  return true;
}

export async function markCommentPrompted(): Promise<void> {
  await saveCommentPromptedVer(getAppVersionName());
}
```

- [ ] **Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/utils/StorageUtil.ets \
  harmonyos/entry/src/main/ets/utils/CommentUtil.ets
git commit -m "feat(harmonyos): AppGallery comment util and preference keys"
```

---

### Task 5: Profile entry + Index wiring for comment prompts

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/ProfileView.ets`
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: ProfileView — add callback and menu row**

Add prop callback with other handlers:

```typescript
  onCommentTap: () => void = () => {};
```

Insert menu block **between** Feedback and About Us (before About's Column):

```typescript
          // Rate / Comment
          Column() {
            Row({ space: 0 }) {
              Stack() { Text('⭐').fontSize(16) }
                .width(34).height(34).borderRadius(10)
                .backgroundColor(this.accentColor + '28')
                .margin({ right: 14 })
              Column({ space: 2 }) {
                Text('给星枢令评分').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                Text('在应用市场留下评价').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .onClick(() => this.onCommentTap())
            Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
          }
```

- [ ] **Step 2: Index — imports and helpers**

Extend StorageUtil import with:

```typescript
loadOpenCount, saveOpenCount
```

Add:

```typescript
import { showAppComment, canSmartPromptComment, markCommentPrompted } from '../utils/CommentUtil';
```

Add methods on Index:

```typescript
  private async openAppComment(fromSmart: boolean): Promise<void> {
    if (this.securityLocked) {
      return;
    }
    const ctx = AppStorage.get<common.UIAbilityContext>('context');
    if (!ctx) {
      this.toast('上下文错误，请重启应用');
      return;
    }
    if (fromSmart) {
      const allowed = await canSmartPromptComment();
      if (!allowed) {
        return;
      }
      await markCommentPrompted();
    }
    const msg = await showAppComment(ctx, true);
    if (msg.length > 0) {
      this.toast(msg);
    }
  }

  private maybeSmartCommentAfterSuccess(): void {
    if (this.securityLocked) {
      return;
    }
    setTimeout(() => {
      this.openAppComment(true);
    }, 700);
  }

  private async bumpOpenCountAndMaybePrompt(): Promise<void> {
    const n = await loadOpenCount();
    const next = n + 1;
    await saveOpenCount(next);
    if (next >= 3) {
      this.maybeSmartCommentAfterSuccess();
    }
  }
```

- [ ] **Step 3: Call bumpOpenCount from loadData end (once per cold start)**

At the end of successful `loadData` try block (after security unlock kickoff is fine):

```typescript
      // Cold-start open count for smart AppGallery comment prompt
      this.bumpOpenCountAndMaybePrompt();
```

- [ ] **Step 4: Trigger after backup / import / membership success**

In `doBackup` success path (when toast `已备份` after successful save):

```typescript
          this.maybeSmartCommentAfterSuccess();
```

after successful toast in both success branches if appropriate — only when user completed save (saveResult length > 0).

In `importFromUris` after successful import toast:

```typescript
    this.maybeSmartCommentAfterSuccess();
```

In `buyMembership` after `this.toast('开通成功')`:

```typescript
      this.maybeSmartCommentAfterSuccess();
```

In `restorePurchase` when result is truthy after `this.toast('会员已恢复')`:

```typescript
        this.maybeSmartCommentAfterSuccess();
```

- [ ] **Step 5: Wire ProfileView onCommentTap**

Where `ProfileView({...})` is constructed, add:

```typescript
            onCommentTap: () => { this.openAppComment(false); },
```

- [ ] **Step 6: Commit**

```bash
git add harmonyos/entry/src/main/ets/views/ProfileView.ets \
  harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat(harmonyos): AppGallery comment entry and smart prompts"
```

---

### Task 6: Search auto keyboard

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/HomeView.ets`

- [ ] **Step 1: Focus the search TextInput**

Update the search `TextInput` block:

```typescript
            TextInput({ text: this.searchQ, placeholder: '搜索品牌或账号' })
              .id('home_search_input')
              .defaultFocus(true)
              .flexGrow(1)
              .backgroundColor(Color.Transparent)
              .fontColor(this.c('#eeeef5', '#2C1810'))
              .placeholderColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
              .fontSize(13)
              .height(28)
              .padding(0)
              .onChange((v) => { this.searchQ = v; })
```

If real device still does not open keyboard, add after build properties:

```typescript
              .onAppear(() => {
                // Fallback focus when defaultFocus is ignored after conditional mount
                setTimeout(() => {
                  try {
                    focusControl.requestFocus('home_search_input');
                  } catch (_) {}
                }, 50);
              })
```

`focusControl` is a global ArkUI API in HarmonyOS; no import required in ArkTS component context (if build fails, use `import { focusControl } from '@kit.ArkUI'` — verify against SDK).

- [ ] **Step 2: Commit**

```bash
git add harmonyos/entry/src/main/ets/views/HomeView.ets
git commit -m "feat(harmonyos): auto-focus search input to open keyboard"
```

---

### Task 7: Full build verification

- [ ] **Step 1: Build**

```bash
cd harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
```

Expected: **BUILD SUCCESSFUL**, zero ArkTS errors.

- [ ] **Step 2: Fix any compile errors** (imports, AuthOutcome call sites, focusControl)

Grep remaining boolean uses:

```bash
rg "authenticateSecurity\(" harmonyos/entry/src/main/ets -n
```

Every call site must use `.ok` or full `AuthOutcome`.

- [ ] **Step 3: Commit build fixes if any**

```bash
git add -u harmonyos/
git commit -m "fix(harmonyos): compile fixes for comment/scan/lock/search"
```

---

### Task 8: Manual UAT checklist (device)

- [ ] Scan → Home → background → reopen: face works; lands on **home**, not camera
- [ ] If face fails with camera busy residual: auto PIN appears without tapping 重试
- [ ] Cancel face: stays locked; 重新验证 + 解锁 still work
- [ ] Search: keyboard opens on search tap
- [ ] Profile → 给星枢令评分: dialog or friendly toast
- [ ] Open app 3 times (fresh prefs): smart comment attempt once per version
- [ ] Backup / import / membership success: at most one auto prompt per version

---

## Spec coverage (self-review)

| Spec item | Task |
|-----------|------|
| Background leave scan + free camera | Task 3 (+3b) |
| Auto PIN on face fail (non-cancel) | Task 1–2 |
| commentManager entry | Task 4–5 |
| Smart prompt open≥3 / backup / import / member | Task 5 |
| Search keyboard | Task 6 |
| Build / API 23 | Task 7 |
| UAT | Task 8 |

No TBD placeholders. Types: `AuthOutcome`, `shouldAutoLockFallback` consistent across tasks.
