# Bug Fixes & Feature Enhancements Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Fix 7 reported bugs and implement feature enhancements across Web, WeChat Mini Program, and HarmonyOS platforms.

**Architecture:** Three independent codebases (Web, miniprogram, HarmonyOS) with shared product logic. Each platform is modified independently. No test infrastructure — verification is visual.

**Tech Stack:** Web (React 18 UMD + Babel), WeChat (WXML/WXSS/JS), HarmonyOS (ArkTS API 23)

---

## Part A: WeChat Mini Program

### Task 1: WeChat login — avatar and nickname not captured after login

**Objective:** After WeChat login via `getPhoneNumber`, the avatar and nickname collected via `chooseAvatar` and nickname input should be displayed on the profile page, and the "绑定手机号" link should not appear since WeChat login already provides identity.

**Root cause:** WeChat login uses `chooseAvatar` (avatar) + nickname input + `getPhoneNumber` button. The `onWeChatPhone` correctly saves `avatar` and `name` into `userInfo`. However, after login the profile card shows "绑定手机号" because `userInfo.phone` is empty string.

**Files:**
- Modify: `miniprogram/pages/index/index.wxml` — profile account card (line ~179)
- Modify: `miniprogram/pages/index/index.js` — `onMenuTap` account handling (line ~307-311)

**Step 1: Fix profile card — don't show "绑定手机号" for WeChat logged-in users**

In `index.wxml`, around line 179, change:
```xml
<view wx:elif="{{!userInfo.phone}}" class="bind-phone-link" style="color:{{accentColor}}" bindtap="onBindPhone">绑定手机号</view>
```
To:
```xml
<view wx:elif="{{!userInfo.phone && !userInfo.wechatLogin}}" class="bind-phone-link" style="color:{{accentColor}}" bindtap="onBindPhone">绑定手机号</view>
```

**Step 2: Fix "账号管理" menu — don't redirect to login for WeChat logged-in users**

In `index.js`, in `onMenuTap`, change the account handling:
```javascript
else if (id === 'account') {
  if (!this.data.userInfo || (!this.data.userInfo.phone && !this.data.userInfo.wechatLogin)) {
    this.setData({ showLoginModal: true, loginTab: 'phone' });
  }
}
```

**Step 3: Verify** — Login via WeChat tab, confirm avatar and nickname appear on profile. Confirm clicking "账号管理" doesn't redirect to login if already logged in via WeChat.

**Step 4: Commit**
```bash
git add miniprogram/pages/index/index.wxml miniprogram/pages/index/index.js
git commit -m "fix: miniprogram WeChat login avatar/nickname display and account management flow"
```

---

### Task 2: QR code parsing fails for Microsoft codes

**Objective:** Fix `_parseScanResult` to handle `otpauth://` URIs that fail when parsed with `new URL()`, which doesn't support non-http schemes in WeChat's environment.

**Root cause:** `new URL(result)` may fail on `otpauth://totp/...` URIs in WeChat's JS environment because the URL constructor only supports http/https/file schemes.

**Files:**
- Modify: `miniprogram/pages/index/index.js:241-258` — `_parseScanResult` method

**Step 1: Replace URL-based parsing with manual string parsing**

Replace the entire `_parseScanResult` method:
```javascript
_parseScanResult(result) {
  try {
    if (!result || result.indexOf('otpauth://totp/') !== 0) throw new Error('not otpauth');
    const after = result.substring('otpauth://totp/'.length);
    const qIdx = after.indexOf('?');
    const label = qIdx >= 0 ? after.substring(0, qIdx) : after;
    const queryStr = qIdx >= 0 ? after.substring(qIdx + 1) : '';

    // Parse query params manually
    const params = {};
    if (queryStr) {
      queryStr.split('&').forEach(p => {
        const eqIdx = p.indexOf('=');
        if (eqIdx > 0) {
          params[p.substring(0, eqIdx)] = decodeURIComponent(p.substring(eqIdx + 1));
        }
      });
    }

    const decoded = decodeURIComponent(label);
    const account = decoded.includes(':') ? decoded.split(':')[1] : decoded;
    const brand = params.issuer || (decoded.includes(':') ? decoded.split(':')[0] : decoded);

    this.setData({
      scanForm: { brand: brand || '', account: account || '', secret: params.secret || '' },
      scanScanned: true,
      scanTab: 'manual',
    });
  } catch (e) {
    this.showToast('无法解析二维码（仅支持 otpauth 格式）');
  }
},
```

**Step 2: Verify** — Scan Microsoft TOTP QR code, confirm it parses and fills the manual form.

**Step 3: Commit**
```bash
git add miniprogram/pages/index/index.js
git commit -m "fix: miniprogram QR code parsing — replace URL() with manual string parsing for otpauth://"
```

---

### Task 3: WeChat backup — share file to contact for import

**Objective:** Change backup from saving to local app directory to sharing the `.atbk` file via WeChat's share mechanism. Update import to support receiving files from WeChat contacts.

**Files:**
- Modify: `miniprogram/pages/index/index.js` — `onDoBackup` method
- Modify: `miniprogram/pages/index/index.wxml` — backup modal UI
- Modify: `miniprogram/app.json` — add `shareAppMessage` support

**Step 1: Change `onDoBackup` to create shareable file**

Replace `onDoBackup`:
```javascript
onDoBackup() {
  const { backupPw, backupPw2, tokens } = this.data;
  if (backupPw !== backupPw2 || !backupPw) return;
  try {
    const data = encryptData(tokens, backupPw);
    const fs = wx.getFileSystemManager();
    const fileName = `auth_backup_${Date.now()}.atbk`;
    const path = `${wx.env.USER_DATA_PATH}/${fileName}`;
    fs.writeFileSync(path, data, 'utf8');
    this.setData({ showBackupModal: false });
    this.showToast(`已备份 ${tokens.length} 个账号`);
    // Share the file
    wx.shareFileMessage({
      filePath: path,
      fileName: fileName,
      success: () => this.showToast('分享成功'),
      fail: () => {
        wx.showModal({
          title: '备份文件已生成',
          content: `文件路径：${path}\n\n您可以手动在文件管理中分享此文件`,
          showCancel: false,
          confirmText: '知道了',
        });
      },
    });
  } catch (err) {
    this.showToast('备份失败');
  }
},
```

**Step 2: Update import to support both `chooseMessageFile` and direct file**

The import already uses `wx.chooseMessageFile` which reads from WeChat contacts. No change needed for import — it already supports receiving files from chat.

**Step 3: Verify** — Backup creates a `.atbk` file and opens the share sheet. Import from a chat message file works.

**Step 4: Commit**
```bash
git add miniprogram/pages/index/index.js
git commit -m "feat: miniprogram backup shares .atbk file via WeChat message"
```

---

### Task 4: Add account info page in miniprogram

**Objective:** Add a new "账号信息" modal that shows full user profile: avatar, nickname, phone, WeChat binding status.

**Files:**
- Modify: `miniprogram/pages/index/index.wxml` — add account info modal after profile section
- Modify: `miniprogram/pages/index/index.js` — add `showAccountModal` state and `onShowAccount` handler
- Modify: `miniprogram/pages/index/index.wxss` — add account info modal styles

**Step 1: Add state**

In `data`:
```javascript
showAccountModal: false,
```

**Step 2: Add account info modal template**

Add before `</view>` closing tag of the profile screen:
```xml
<!-- ═══ ACCOUNT INFO MODAL ═══ -->
<view wx:if="{{showAccountModal}}" class="full-modal">
  <view class="modal-header">
    <view class="icon-btn" bindtap="onCloseAccount">×</view>
    <text class="modal-title">账号信息</text>
  </view>
  <view style="padding:0 20px;display:flex;flex-direction:column;gap:16px;flex:1">
    <!-- Avatar -->
    <view style="display:flex;flex-direction:column;align-items:center;padding:20px 0">
      <image wx:if="{{userInfo.avatar}}" class="account-info-avatar" src="{{userInfo.avatar}}" mode="aspectFill"/>
      <view wx:else class="account-info-avatar-placeholder" style="background:{{accentColor}}">
        <text style="font-size:28px;color:#fff;font-weight:700">{{userInfo.name[0] || 'U'}}</text>
      </view>
    </view>
    <!-- Fields -->
    <view class="account-info-row">
      <text class="account-info-label">昵称</text>
      <text class="account-info-value">{{userInfo.name}}</text>
    </view>
    <view class="account-info-row">
      <text class="account-info-label">手机号</text>
      <text class="account-info-value">{{userInfo.phone || '未绑定'}}</text>
    </view>
    <view class="account-info-row" wx:if="{{userInfo.wechatLogin}}">
      <text class="account-info-label">微信</text>
      <text class="account-info-value" style="color:#07C160">已绑定</text>
    </view>
    <view wx:else class="account-info-row">
      <text class="account-info-label">微信</text>
      <text class="account-info-value" style="color:{{accentColor}}" bindtap="onBindWechat">点击绑定</text>
    </view>
  </view>
</view>
```

**Step 3: Add handlers in JS**

```javascript
onShowAccount() { this.setData({ showAccountModal: true }); },
onCloseAccount() { this.setData({ showAccountModal: false }); },
onBindWechat() {
  this.setData({ showAccountModal: false, showLoginModal: true, loginTab: 'wechat' });
},
```

**Step 4: Update `onMenuTap` account handler**

Change the account handling:
```javascript
else if (id === 'account') {
  if (this.data.loggedIn) {
    this.onShowAccount();
  } else {
    this.setData({ showLoginModal: true, loginTab: 'phone' });
  }
}
```

**Step 5: Add CSS**

In `index.wxss`:
```css
.account-info-avatar { width: 80px; height: 80px; border-radius: 40px; }
.account-info-avatar-placeholder { width: 80px; height: 80px; border-radius: 40px; display: flex; align-items: center; justify-content: center; }
.account-info-row { display: flex; align-items: center; justify-content: space-between; padding: 14px 0; border-bottom: 1px solid rgba(255,255,255,0.05); }
.account-info-label { font-size: 14px; color: rgba(238,238,245,0.5); }
.account-info-value { font-size: 14px; color: #eeeef5; font-weight: 500; }
```

**Step 6: Verify** — Click "账号管理" when logged in, see full account info modal.

**Step 7: Commit**
```bash
git add miniprogram/pages/index/index.wxml miniprogram/pages/index/index.js miniprogram/pages/index/index.wxss
git commit -m "feat: miniprogram account info modal showing avatar, nickname, phone, WeChat binding"
```

---

## Part B: HarmonyOS App

### Task 5: Fix QR code parsing (same root cause as miniprogram)

**Objective:** Update `ScanView.ets` `parseOtpUri` to handle URIs that might have encoding issues.

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/ScanView.ets:27-47` — `parseOtpUri` method

**Step 1: The current `parseOtpUri` uses manual string parsing already, so it should work. Add try-catch improvement for edge cases.**

No code change needed — the HarmonyOS version already uses manual string parsing unlike the miniprogram. Verify by testing with Microsoft QR code.

**Step 2: Verify** — Scan Microsoft TOTP QR code in DevEco Studio, confirm parsing succeeds.

---

### Task 6: HarmonyOS login — skip phone binding after HarmonyOS account login

**Objective:** After logging in with "鸿蒙账号", the user should see their account info without being prompted to bind a phone number. The account management view should show logged-in status without requiring phone.

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets` — HarmonyOS login handler (line ~408-417)
- Modify: `harmonyos/entry/src/main/ets/views/ProfileView.ets` — account menu item (line ~26, ~118)

**Step 1: Update HarmonyOS login to set a flag**

In `Index.ets`, the HarmonyOS login button's `onClick`:
```typescript
.onClick(() => {
  this.loggedIn = true;
  this.userName = this.loginNickname || '鸿蒙用户';
  this.userPhone = '';
  this.harmonyLogin = true;
  this.showLogin = false;
  this.toast('鸿蒙账号登录成功');
})
```

Add state declaration at the top of `Index` struct:
```typescript
@State harmonyLogin: boolean = false;
```

**Step 2: Pass `harmonyLogin` to ProfileView**

In the ProfileView props in `Index.ets` build method:
```typescript
ProfileView({
  // ...existing props...
  harmonyLogin: this.harmonyLogin,
  onAccountTap: () => { this.showAccountInfo = true; },
  // ...
})
```

**Step 3: Add `showAccountInfo` state**

```typescript
@State showAccountInfo: boolean = false;
```

**Step 4: Update ProfileView to accept new props**

In `ProfileView.ets`, add:
```typescript
@Prop harmonyLogin: boolean = false;
onAccountTap: () => void = () => {};
```

Update the account menu item onClick:
```typescript
if (item.id === 'account') {
  if (!this.loggedIn) this.onLoginTap();
  else this.onAccountTap();
}
```

**Step 5: Update account card — don't show "绑定手机号" for HarmonyOS logged-in users**

In `ProfileView.ets`, change the phone display:
```typescript
if (this.userPhone) {
  Text(this.userPhone).fontSize(12).fontColor('rgba(238,238,245,0.4)')
} else if (!this.harmonyLogin) {
  Text('绑定手机号')
    .fontSize(12).fontColor(this.accentColor).fontWeight(500)
    .onClick(() => this.onBindPhone())
}
```

**Step 6: Add account info modal in Index.ets**

Add a new `@Builder accountInfoModal()` similar to the miniprogram version showing avatar, nickname, phone, and HarmonyOS binding status.

**Step 7: Commit**
```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets harmonyos/entry/src/main/ets/views/ProfileView.ets
git commit -m "feat: harmonyOS skip phone binding after HarmonyOS account login, add account info page"
```

---

### Task 7: HarmonyOS backup — export to file instead of clipboard

**Objective:** Change backup from copying to clipboard to saving a `.atbk` file. Add file picker for import.

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets` — `doBackup` method
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets` — `importModal` builder
- Modify: `harmonyos/entry/src/main/ets/model/Token.ets` — add `@kit.CoreFileKit` import in Index.ets

**Step 1: Add file picker imports**

At the top of `Index.ets`, add:
```typescript
import { picker } from '@kit.CoreFileKit';
import { fs } from '@kit.CoreFileKit';
```

**Step 2: Update `doBackup` to save file**

Replace the current `doBackup`:
```typescript
private async doBackup(): Promise<void> {
  if (!this.backupPw || this.backupPw !== this.backupPw2) return;
  try {
    const enc = encryptData(this.tokens, this.backupPw);
    const ctx = getContext(this) as common.UIAbilityContext;
    const cachePath = ctx.cacheDir + `/auth_backup_${Date.now()}.atbk`;
    const file = fs.openSync(cachePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    fs.writeSync(file.fd, enc);
    fs.closeSync(file);

    // Use file picker to save
    const savePicker = picker.createSavePicker();
    savePicker.saveFile(ctx, {
      title: '备份文件',
      suggestedFileName: `auth_backup_${Date.now()}.atbk`,
      fileType: 'application/octet-stream',
      uri: `file://${cachePath}`
    }).then(() => {
      this.showBackup = false;
      this.toast(`已备份 ${this.tokens.length} 个账号`);
    }).catch(() => {
      this.toast('备份已取消');
    });
  } catch (e) { this.toast('备份失败'); }
}
```

**Step 3: Update import modal to use file picker**

Replace the import modal's manual text input with a file picker button. Add state:
```typescript
@State importFileUri: string = '';
@State importFileName: string = '';
```

Add a "选择文件" button that uses `picker.createDocumentViewPicker()`:
```typescript
private selectImportFile(): void {
  const ctx = getContext(this) as common.UIAbilityContext;
  const docPicker = picker.createDocumentViewPicker();
  docPicker.select(ctx, {
    maxSelectNumber: 1,
    filter: new picker.DocumentViewPickerFilter({
      postfix: ['atbk'],
    }),
  }).then((result: string[]) => {
    if (result && result.length > 0) {
      const uri = result[0];
      const fileName = uri.substring(uri.lastIndexOf('/') + 1);
      this.importFileUri = uri;
      this.importFileName = fileName;
      // Read file content
      const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(uri);
      const buf = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buf);
      this.importText = String.fromCodePoint(...new Uint8Array(buf));
      fs.closeSync(file);
    }
  }).catch(() => { this.toast('选择文件取消'); });
}
```

**Step 4: Verify** — Backup saves a `.atbk` file. Import reads from a `.atbk` file.

**Step 5: Commit**
```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat: harmonyos backup exports .atbk file, import uses file picker"
```

---

## Part C: All Platforms — UI Improvements

### Task 8: Bottom nav — unify style across all platforms

**Objective:** Unify the bottom navigation bar style across all three platforms. The current styles differ significantly between platforms. The new design should be a floating pill-style nav with consistent proportions, glassmorphism background, and a highlighted center button using the theme accent color.

**Reference design:** Floating rounded pill bar, ~32px border-radius, dark translucent background with blur, three items with icon+label, center button uses accent color background with white icon/label, side items get subtle active background when selected.

**Files:**
- Modify: `miniprogram/components/bottom-nav/bottom-nav.wxss` — full redesign
- Modify: `miniprogram/components/bottom-nav/bottom-nav.wxml` — use SVG icons instead of emoji
- Modify: `app.jsx` — `BottomNav` component (line ~244-289)
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets` — `navBar` builder (line ~203-246)

**Step 1: Update miniprogram bottom nav — use SVG icons**

Replace `bottom-nav.wxml` with SVG icons matching the web version:
```xml
<view class="nav-outer" style="transform:{{visible ? 'translateY(0)' : 'translateY(120%)'}}">
  <view class="nav-bar">
    <view class="nav-item {{current === 'home' ? 'active' : ''}}"
          data-screen="home" bindtap="onTap">
      <view class="nav-icon" style="color:{{current === 'home' ? accentColor : 'rgba(238,238,245,0.38)'}}">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
          <path d="M11.03 2.59a1.5 1.5 0 011.94 0l7.5 6.363A1.5 1.5 0 0121 10.097V19.5A1.5 1.5 0 0119.5 21h-4a1.5 1.5 0 01-1.5-1.5v-4h-4v4A1.5 1.5 0 018.5 21h-4A1.5 1.5 0 013 19.5v-9.403a1.5 1.5 0 01.53-1.144l7.5-6.363z"/>
        </svg>
      </view>
      <text class="nav-label {{current === 'home' ? 'nav-label-active' : ''}}" style="color:{{current === 'home' ? accentColor : 'rgba(238,238,245,0.38)'}}">首页</text>
    </view>

    <view class="nav-item nav-center" data-screen="scan" bindtap="onTap">
      <view class="nav-center-glow"/>
      <view class="nav-icon" style="color:#fff">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M3 7V5a2 2 0 012-2h2M17 3h2a2 2 0 012 2v2M21 17v2a2 2 0 01-2 2h-2M7 21H5a2 2 0 01-2-2v-2"/>
          <rect x="7" y="7" width="10" height="10" rx="1.5"/>
        </svg>
      </view>
      <text class="nav-label" style="color:#fff;font-weight:650">扫码</text>
    </view>

    <view class="nav-item {{current === 'profile' ? 'active' : ''}}"
          data-screen="profile" bindtap="onTap">
      <view class="nav-icon" style="color:{{current === 'profile' ? accentColor : 'rgba(238,238,245,0.38)'}}">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 12a5 5 0 100-10 5 5 0 000 10zm-7 9a7 7 0 1114 0H5z"/>
        </svg>
      </view>
      <text class="nav-label {{current === 'profile' ? 'nav-label-active' : ''}}" style="color:{{current === 'profile' ? accentColor : 'rgba(238,238,245,0.38)'}}">我</text>
    </view>
  </view>
</view>
```

**Step 2: Update miniprogram CSS**

Replace `bottom-nav.wxss`:
```css
.nav-outer {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  justify-content: center;
  padding: 0 20px 20px;
  transition: transform 0.35s cubic-bezier(0.32, 0.72, 0, 1);
  z-index: 200;
  pointer-events: auto;
}
.nav-bar {
  display: flex;
  align-items: center;
  background: rgba(18,18,24,0.85);
  backdrop-filter: blur(24px) saturate(180%);
  -webkit-backdrop-filter: blur(24px) saturate(180%);
  border-radius: 36px;
  padding: 5px 6px;
  box-shadow: 0 8px 40px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.07);
  border: 1px solid rgba(255,255,255,0.07);
  gap: 2px;
}
.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 3px;
  border-radius: 28px;
  padding: 9px 20px;
  min-width: 64px;
  cursor: pointer;
  transition: all 0.22s;
}
.nav-item.active { background: rgba(255,255,255,0.1); }
.nav-center {
  border-radius: 26px;
  padding: 11px 20px;
  min-width: 68px;
  position: relative;
  overflow: hidden;
  box-shadow: 0 4px 16px rgba(0,0,0,0.3);
}
.nav-center-glow {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  background: linear-gradient(135deg, rgba(255,255,255,0.18) 0%, transparent 60%);
  pointer-events: none;
}
.nav-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
}
.nav-label { font-size: 10px; font-weight: 400; letter-spacing: 0.2px; }
.nav-label-active { font-weight: 650; }
```

**Step 3: Update web app BottomNav**

Replace the `BottomNav` function in `app.jsx`:
```javascript
function BottomNav({ screen, onNav, visible, accent }) {
  const tabs = [
    { key: 'home', label: '首页', Icon: HomeIcon },
    { key: 'scan', label: '扫码', Icon: ScanIcon, center: true },
    { key: 'profile', label: '我', Icon: MeIcon },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 200,
      display: 'flex', justifyContent: 'center',
      padding: '0 16px 20px',
      transform: visible ? 'translateY(0)' : 'translateY(120%)',
      transition: 'transform 0.35s cubic-bezier(0.32, 0.72, 0, 1)',
      pointerEvents: visible ? 'auto' : 'none',
    }}>
      <div style={{
        display: 'flex', alignItems: 'center',
        background: 'rgba(18,18,24,0.85)', backdropFilter: 'blur(24px) saturate(180%)',
        borderRadius: 36, padding: '5px 6px',
        boxShadow: '0 8px 40px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.07)',
        border: '1px solid rgba(255,255,255,0.07)',
        gap: 2,
      }}>
        {tabs.map(({ key, label, Icon, center }) => {
          const active = screen === key;
          return (
            <button key={key} onClick={() => onNav(key)} style={{
              display: 'flex', flexDirection: 'column', alignItems: 'center',
              justifyContent: 'center', gap: 3,
              background: center ? accent : active ? 'rgba(255,255,255,0.1)' : 'transparent',
              border: 'none',
              color: center ? '#fff' : active ? accent : 'rgba(238,238,245,0.38)',
              borderRadius: center ? 26 : 28,
              cursor: 'pointer', padding: center ? '11px 20px' : '9px 20px',
              transition: 'all 0.22s',
              minWidth: center ? 68 : 64,
            }}>
              <Icon s={center ? 20 : 20}/>
              <span style={{ fontSize: 10, fontWeight: active || center ? 650 : 400, letterSpacing: 0.2 }}>{label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
```

**Step 4: Update HarmonyOS navBar**

Replace the `navBar` builder in `Index.ets`:
```typescript
@Builder
navBar() {
  Row({ space: 2 }) {
    // Home
    Column({ space: 3 }) {
      Text('⌂').fontSize(20).fontColor(this.currentTab === 0 ? this.accentColor : 'rgba(238,238,245,0.38)')
      Text('首页').fontSize(10).fontColor(this.currentTab === 0 ? this.accentColor : 'rgba(238,238,245,0.38)')
        .fontWeight(this.currentTab === 0 ? 650 : 400)
    }
    .flexGrow(1).alignItems(HorizontalAlign.Center).padding({ left: 9, right: 9, top: 9, bottom: 9 })
    .backgroundColor(this.currentTab === 0 ? 'rgba(255,255,255,0.1)' : Color.Transparent)
    .borderRadius(28)
    .onClick(() => { this.currentTab = 0; this.navVisible = true; })

    // Scan (center)
    Column({ space: 3 }) {
      Text('⊞').fontSize(20).fontColor('#fff')
      Text('扫码').fontSize(10).fontColor('#fff').fontWeight(650)
    }
    .alignItems(HorizontalAlign.Center).padding({ left: 18, right: 18, top: 11, bottom: 11 })
    .backgroundColor(this.accentColor).borderRadius(26)
    .shadow({ radius: 16, color: this.accentColor + '66', offsetX: 0, offsetY: 4 })
    .onClick(() => { this.currentTab = 1; this.navVisible = true; })

    // Profile
    Column({ space: 3 }) {
      Text('👤').fontSize(20).fontColor(this.currentTab === 2 ? this.accentColor : 'rgba(238,238,245,0.38)')
      Text('我').fontSize(10).fontColor(this.currentTab === 2 ? this.accentColor : 'rgba(238,238,245,0.38)')
        .fontWeight(this.currentTab === 2 ? 650 : 400)
    }
    .flexGrow(1).alignItems(HorizontalAlign.Center).padding({ left: 9, right: 9, top: 9, bottom: 9 })
    .backgroundColor(this.currentTab === 2 ? 'rgba(255,255,255,0.1)' : Color.Transparent)
    .borderRadius(28)
    .onClick(() => { this.currentTab = 2; this.navVisible = true; })
  }
  .padding({ left: 6, right: 6, top: 5, bottom: 5 })
  .backgroundColor('rgba(18,18,24,0.85)')
  .borderRadius(36)
  .border({ width: 1, color: 'rgba(255,255,255,0.07)' })
  .shadow({ radius: 40, color: 'rgba(0,0,0,0.6)', offsetX: 0, offsetY: 8 })
  .margin({ left: 20, right: 20, bottom: 20 })
  .translate({ y: this.navVisible ? 0 : 120 })
  .animation({ duration: 350, curve: Curve.EaseInOut })
}
```

**Step 5: Verify** — All three platforms show consistent floating pill-style bottom nav.

**Step 6: Commit** (3 separate commits)
```bash
git add miniprogram/components/bottom-nav/bottom-nav.wxss miniprogram/components/bottom-nav/bottom-nav.wxml
git commit -m "feat: miniprogram unify bottom nav — floating pill style with SVG icons"

git add app.jsx
git commit -m "feat: web unify bottom nav — floating pill style"

git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat: harmonyos unify bottom nav — floating pill style"
```

---

### Task 9: Countdown ring — remove amber warning color, keep theme color throughout

**Objective:** The countdown ring and OTP code digits should always use the theme accent color throughout the 30-second cycle. Remove the amber (#f59e0b) warning color when timeLeft <= 7.

**Files:**
- Modify: `app.jsx:137-138` — CountdownRing
- Modify: `miniprogram/components/countdown-ring/countdown-ring.js:10-11,29-30,61` — warn color
- Modify: `miniprogram/components/token-card/token-card.wxml:22` — digit color
- Modify: `miniprogram/components/token-card/token-card.js:53,61` — warn state
- Modify: `harmonyos/entry/src/main/ets/components/CountdownRing.ets:23-24,43` — warn color

**Step 1: Web app — remove amber warning**

In `app.jsx` line 137-138:
```javascript
// OLD:
const warn = timeLeft <= 7;
const col = warn ? '#f59e0b' : accent;
// NEW:
const col = accent;
```

In `app.jsx` line 149:
```javascript
// OLD: color: col,
// NEW: color: accent,
```

**Step 2: Miniprogram countdown ring — remove amber**

In `countdown-ring.js`:
```javascript
// observers:
'timeLeft, accentColor': function(tl, ac) {
  const r = 12;
  const circ = 2 * Math.PI * r;
  const col = ac;
  const dash = circ * tl / 30;
  const gap  = circ - dash;
  this.setData({ col, dash, gap, tl });
},
```

Remove all `warn` checks. In `lifetimes.attached`:
```javascript
attached() {
  const { timeLeft, accentColor } = this.properties;
  const r = 12, circ = 2 * Math.PI * r;
  const col = accentColor;
  this.setData({ col, dash: circ * timeLeft / 30, gap: circ * (1 - timeLeft / 30), tl: timeLeft });
},
```

Remove `warn` from `data` and the `timeLeft` observer.

**Step 3: Miniprogram token card — remove amber**

In `token-card.wxml` line 22:
```xml
<!-- OLD -->
<text class="otp-digit" style="color:{{warn ? '#f59e0b' : item}}">{{curFmt[index]}}</text>
<!-- NEW -->
<text class="otp-digit" style="color:{{item}}">{{curFmt[index]}}</text>
```

In `token-card.js`, remove `warn` from data, observers, and the `timeLeft` observer.

**Step 4: HarmonyOS countdown ring — remove amber**

In `CountdownRing.ets`:
```typescript
// OLD line 23-24:
const warn = this.timeLeft <= 7;
const col = warn ? '#f59e0b' : this.accentColor;
// NEW:
const col = this.accentColor;
```

Line 43:
```typescript
// OLD:
.fontColor(this.timeLeft <= 7 ? '#f59e0b' : this.accentColor)
// NEW:
.fontColor(this.accentColor)
```

**Step 5: Verify** — All three platforms show theme accent color throughout the full 30-second cycle.

**Step 6: Commit** (3 separate commits)
```bash
git add app.jsx
git commit -m "fix: web countdown ring keeps theme color throughout 30s cycle"

git add miniprogram/components/countdown-ring/countdown-ring.js miniprogram/components/countdown-ring/countdown-ring.wxml miniprogram/components/token-card/token-card.wxml miniprogram/components/token-card/token-card.js
git commit -m "fix: miniprogram countdown ring and OTP digits keep theme color"

git add harmonyos/entry/src/main/ets/components/CountdownRing.ets
git commit -m "fix: harmonyos countdown ring keeps theme color throughout 30s cycle"
```

---

## Task Dependency Map

- Part A (miniprogram) Tasks 1-4 are independent of each other but touch overlapping files (`index.js`, `index.wxml`, `index.wxss`). Apply sequentially.
- Part B (HarmonyOS) Tasks 5-7 are independent but touch overlapping files (`Index.ets`, `ProfileView.ets`). Apply sequentially.
- Part C Tasks 8-9 touch different files across platforms. Can be done in any order.

**Total: 9 tasks**
