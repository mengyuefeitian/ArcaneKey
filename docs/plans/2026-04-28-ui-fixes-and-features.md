# UI Fixes & Feature Enhancements Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Fix miniprogram UI issues (input clipping, missing cancel button, missing icons, bottom nav auto-hide, nav bar redesign) and add features (WeChat login, profile branding, HarmonyOS login) across both miniprogram and HarmonyOS platforms.

**Architecture:** Two independent codebases (miniprogram + HarmonyOS) share the same product logic. Changes are applied to both platforms in parallel. No test infrastructure exists; verification is visual in WeChat DevTools and DevEco Studio.

**Tech Stack:** WeChat Mini Program (WXML/WXSS/JS), HarmonyOS ArkTS (API 12+)

---

## Part A: WeChat Miniprogram

### Task 1: Fix input field text clipping in miniprogram

**Objective:** Input fields in the edit modal and scan/manual form clip text vertically — user can only see the top half of the text. Fix by adjusting input height and line-height.

**Files:**
- Modify: `miniprogram/pages/index/index.wxss` — `.field-input` rule (line ~173)

**Step 1: Update `.field-input` CSS**

The current `.field-input` has `padding: 12px 14px` but no explicit `height` or `line-height`, causing the default input height to be too small on some devices. Add explicit height and line-height:

```css
.field-input {
  width: 100%;
  height: 48px;
  line-height: 24px;
  padding: 12px 14px;
  background: #191920;
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 12px;
  color: #eeeef5;
  font-size: 14px;
  box-sizing: border-box;
}
```

**Step 2: Verify** — Open in WeChat DevTools, edit a token, confirm brand name and account text are fully visible.

**Step 3: Commit**

```bash
git add miniprogram/pages/index/index.wxss
git commit -m "fix: miniprogram input field text clipping — add explicit height/line-height"
```

---

### Task 2: Add cancel button to edit modal in miniprogram

**Objective:** The edit modal only has a "保存" (Save) button. Add a "取消" (Cancel) button so users can dismiss edits without saving.

**Files:**
- Modify: `miniprogram/pages/index/index.wxml` — Edit Modal section (the `save-btn` area)

**Step 1: Update edit modal header**

Replace the save button row in the edit modal header. Currently:
```xml
<view class="save-btn" style="background:{{accentColor}}" bindtap="onSaveEdit">保存</view>
```

Change to:
```xml
<view class="edit-header-actions">
  <view class="cancel-edit-btn" bindtap="onCloseEdit">取消</view>
  <view class="save-btn" style="background:{{accentColor}}" bindtap="onSaveEdit">保存</view>
</view>
```

**Step 2: Add CSS for the cancel button and row**

Add to `miniprogram/pages/index/index.wxss`:

```css
.edit-header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-left: auto;
}
.cancel-edit-btn {
  border-radius: 11px;
  padding: 8px 16px;
  color: rgba(238,238,245,0.6);
  font-size: 14px;
  font-weight: 500;
  border: 1px solid rgba(255,255,255,0.1);
}
```

**Step 3: Verify** — Open edit modal, confirm both "取消" and "保存" buttons appear, and "取消" closes the modal without saving.

**Step 4: Commit**

```bash
git add miniprogram/pages/index/index.wxml miniprogram/pages/index/index.wxss
git commit -m "feat: miniprogram add cancel button to edit modal"
```

---

### Task 3: Add SVG icons to bottom nav tabs in miniprogram

**Objective:** The bottom nav currently uses SVG for home/profile but the scan icon needs updating to show both scan + add. All three icons should be clear and consistent.

**Files:**
- Modify: `miniprogram/components/bottom-nav/bottom-nav.wxml`

**Step 1: Update bottom nav icons**

Replace the scan center icon SVG with one that combines a scan frame and a "+" symbol:

For the scan (center) tab, replace the current SVG path with:
```xml
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3 7V5a2 2 0 012-2h2M17 3h2a2 2 0 012 2v2M21 17v2a2 2 0 01-2 2h-2M7 21H5a2 2 0 01-2-2v-2"/>
  <path d="M11 8v8M8 11h8"/>
</svg>
```

The home and profile icons already have SVGs. No change needed for them.

**Step 2: Verify** — Check bottom nav in DevTools: home (house), scan (frame + cross/plus), profile (person) icons all render.

**Step 3: Commit**

```bash
git add miniprogram/components/bottom-nav/bottom-nav.wxml
git commit -m "feat: miniprogram update scan icon to show scan+add"
```

---

### Task 4: Implement bottom nav auto-hide on scroll in miniprogram

**Objective:** The bottom nav should hide when scrolling down and show when scrolling up. Currently the `onHomeScroll` handler exists in `index.js` and the CSS transition exists in `bottom-nav.wxss`, but the `navVisible` prop may not be triggering correctly.

**Files:**
- Modify: `miniprogram/components/bottom-nav/bottom-nav.wxss` — verify transition
- Modify: `miniprogram/pages/index/index.wxml` — ensure `navVisible` is passed correctly
- Modify: `miniprogram/pages/index/index.js` — verify `onHomeScroll` logic

**Step 1: Verify scroll-view binding**

In `index.wxml`, the home screen scroll-view already has `bindscroll="onHomeScroll"` and `enhanced="{{true}}"`. The `onHomeScroll` in `index.js` already sets `navVisible` based on scroll direction. The bottom-nav component already receives `visible="{{navVisible}}"`.

The CSS already has:
```css
transform:{{visible ? 'translateY(0)' : 'translateY(120%)'}};
transition: transform 0.35s cubic-bezier(0.32, 0.72, 0, 1);
```

The issue is that the scroll-view's `bindscroll` may not fire on the home page if the content doesn't actually scroll. But since the `onHomeScroll` logic is already implemented, this should work when there are enough tokens to scroll. Let me also add scroll handling to the profile screen.

Add to the profile scroll-view in `index.wxml`:
```xml
<scroll-view class="screen" scroll-y show-scrollbar="{{false}}" bindscroll="onProfileScroll">
```

And add the handler in `index.js`:
```javascript
onProfileScroll(e) {
  const y = e.detail.scrollTop;
  const last = this.data.lastScrollY;
  if (y < 30) {
    this.setData({ navVisible: true, lastScrollY: y });
    return;
  }
  this.setData({ navVisible: y <= last, lastScrollY: y });
},
```

**Step 2: Verify** — Scroll down on home/profile screens, confirm nav hides; scroll up, confirm nav reappears.

**Step 3: Commit**

```bash
git add miniprogram/pages/index/index.wxml miniprogram/pages/index/index.js
git commit -m "feat: miniprogram bottom nav auto-hide on scroll for all screens"
```

---

### Task 5: Redesign bottom nav bar — HarmonyOS 6.0 immersive light-effect style

**Objective:** The current nav bar is too large and bulky. Redesign with a slimmer, more refined look inspired by HarmonyOS 6.0: compact proportions, subtle blur, refined pill shape, gradient light accent on the active scan button.

**Files:**
- Modify: `miniprogram/components/bottom-nav/bottom-nav.wxss`
- Modify: `miniprogram/components/bottom-nav/bottom-nav.wxml`

**Step 1: Redesign nav bar CSS**

Replace the entire `bottom-nav.wxss` content with a refined version:

```css
.nav-outer {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  justify-content: center;
  padding: 0 20px 14px;
  transition: transform 0.35s cubic-bezier(0.32, 0.72, 0, 1);
  z-index: 200;
  pointer-events: auto;
}
.nav-bar {
  display: flex;
  align-items: center;
  background: rgba(18,18,24,0.72);
  backdrop-filter: blur(32px) saturate(200%);
  border-radius: 28px;
  padding: 4px 5px;
  box-shadow: 0 2px 24px rgba(0,0,0,0.4), inset 0 0.5px 0 rgba(255,255,255,0.08);
  border: 0.5px solid rgba(255,255,255,0.08);
  gap: 2px;
}
.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2px;
  border-radius: 22px;
  padding: 7px 18px;
  min-width: 60px;
  cursor: pointer;
  transition: all 0.22s;
}
.nav-item.active { background: rgba(255,255,255,0.1); }
.nav-center {
  border-radius: 20px;
  padding: 8px 18px;
  min-width: 56px;
  position: relative;
  overflow: hidden;
}
.nav-center::before {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: inherit;
  background: linear-gradient(135deg, rgba(255,255,255,0.15) 0%, transparent 60%);
  pointer-events: none;
}
.nav-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
}
.nav-label { font-size: 9px; font-weight: 400; letter-spacing: 0.1px; }
.nav-label-active { font-weight: 650; }
```

**Step 2: Verify** — The nav bar should be visibly smaller, with a subtle glassmorphism effect and a light gradient overlay on the scan button.

**Step 3: Commit**

```bash
git add miniprogram/components/bottom-nav/bottom-nav.wxss
git commit -m "feat: miniprogram redesign bottom nav — slimmer immersive light-effect style"
```

---

### Task 6: Add WeChat login support in miniprogram

**Objective:** Replace the current simulated "微信登录" tab with actual `wx.login()` and phone number retrieval via `<button open-type="getPhoneNumber">`. Add an "账号管理" menu item in profile that shows bound phone number.

**Files:**
- Modify: `miniprogram/pages/index/index.wxml` — login modal WeChat tab + profile menu
- Modify: `miniprogram/pages/index/index.js` — WeChat login logic + account management
- Modify: `miniprogram/pages/index/index.wxss` — styles for new elements

**Step 1: Update WeChat login tab in login modal**

In the login modal, replace the `wx:elif="{{loginTab === 'wechat'}}"` block with an actual WeChat login button:

```xml
<block wx:elif="{{loginTab === 'wechat'}}">
  <view style="display:flex;flex-direction:column;align-items:center;gap:20px;padding-top:20px">
    <view style="width:72px;height:72px;background:#07C160;border-radius:20px;display:flex;align-items:center;justify-content:center">
      <svg width="36" height="36" viewBox="0 0 24 24" fill="#fff">
        <path d="M8.691 2.188C3.891 2.188 0 5.476 0 9.53c0 2.212 1.17 4.203 3.002 5.55a.59.59 0 0 1 .213.665l-.39 1.48c-.019.07-.048.141-.048.213 0 .163.13.295.29.295a.326.326 0 0 0 .167-.054l1.903-1.114a.864.864 0 0 1 .717-.098 10.16 10.16 0 0 0 2.837.403c.276 0 .543-.027.811-.05-.857-2.578.157-4.972 1.932-6.446 1.703-1.415 3.882-1.98 5.853-1.838-.576-3.583-4.196-6.348-8.596-6.348zM5.785 5.991c.642 0 1.162.529 1.162 1.18a1.17 1.17 0 0 1-1.162 1.178A1.17 1.17 0 0 1 4.623 7.17c0-.651.52-1.18 1.162-1.18zm5.813 0c.642 0 1.162.529 1.162 1.18a1.17 1.17 0 0 1-1.162 1.178 1.17 1.17 0 0 1-1.162-1.178c0-.651.52-1.18 1.162-1.18zm3.636 4.735c-3.935 0-7.139 2.753-7.139 6.134 0 3.38 3.204 6.133 7.139 6.133.826 0 1.622-.12 2.361-.336a.72.72 0 0 1 .598.082l1.585.927a.272.272 0 0 0 .14.045.245.245 0 0 0 .241-.245c0-.06-.024-.118-.04-.177l-.324-1.233a.492.492 0 0 1 .177-.554C21.881 19.85 22.947 18.1 22.947 16.86c0-3.38-3.204-6.134-7.139-6.134zm-2.65 3.576c.535 0 .969.44.969.983a.976.976 0 0 1-.969.983.976.976 0 0 1-.969-.983c0-.543.434-.983.97-.983zm5.3 0c.535 0 .969.44.969.983a.976.976 0 0 1-.969.983.976.976 0 0 1-.969-.983c0-.543.434-.983.969-.983z"/>
      </svg>
    </view>
    <text style="color:rgba(238,238,245,0.55);font-size:14px;text-align:center;line-height:1.7">使用微信账号快速登录</text>
    <button class="wechat-login-btn" open-type="getPhoneNumber" bindgetphonenumber="onWeChatPhone">微信一键登录</button>
    <text style="font-size:11px;color:rgba(238,238,245,0.3)">将获取微信绑定的手机号</text>
  </view>
</block>
```

Remove the primary-btn login button at the bottom of the login modal when on wechat tab (since the button is now inline).

**Step 2: Update the primary-btn at bottom of login modal**

Change the bottom login button to only show for phone tab:
```xml
<block wx:if="{{loginTab === 'phone'}}">
  <view class="primary-btn" style="margin-top:auto;background:{{loginPhone.length>=11 && loginCode.length>=4 ? accentColor : '#191920'}};color:{{loginPhone.length>=11 && loginCode.length>=4 ? '#fff' : 'rgba(238,238,245,0.3)'}}" bindtap="onLogin">
    登录
  </view>
</block>
```

**Step 3: Add WeChat login styles**

Add to `index.wxss`:
```css
.wechat-login-btn {
  width: 100%;
  padding: 14px;
  border-radius: 15px;
  background: #07C160;
  color: #fff;
  font-size: 15px;
  font-weight: 650;
  text-align: center;
  border: none;
  line-height: normal;
}
.wechat-login-btn::after { border: none; }
```

**Step 4: Update `index.js` — add WeChat login handlers**

Replace the `onLogin` method and add `onWeChatPhone`:

```javascript
onWeChatPhone(e) {
  if (e.detail.errMsg !== 'getPhoneNumber:ok') {
    this.showToast('微信登录取消');
    return;
  }
  // In production: send e.detail.code to backend to decrypt phone number
  // Demo: use wx.login to get code, mock phone retrieval
  wx.login({
    success: (res) => {
      const name = '微信用户';
      const info = { name, phone: '', wechatLogin: true };
      app.globalData.loggedIn = true;
      app.globalData.userInfo = info;
      this.setData({ loggedIn: true, userInfo: info, showLoginModal: false });
      this.showToast('微信登录成功');
    },
    fail: () => {
      this.showToast('微信登录失败');
    },
  });
},
```

**Step 5: Add "账号管理" menu item in profile**

In the profile screen menu, add an "账号管理" item after the existing items (before theme). In `index.wxml`, add to the `wx:for` array:

```javascript
{id:'account',icon:'👤',label:'账号管理',desc:loggedIn ? (userInfo.phone || '绑定手机号') : '登录后可用',locked:true}
```

Add handler in `index.js`:
```javascript
// In onMenuTap, add:
else if (id === 'account') {
  // Account management — for now just show phone binding prompt
  if (this.data.userInfo && this.data.userInfo.wechatLogin && !this.data.userInfo.phone) {
    this.setData({ showLoginModal: true, loginTab: 'wechat' });
  }
}
```

**Step 6: Verify** — Open login modal, switch to WeChat tab, tap "微信一键登录", confirm login success with WeChat user info.

**Step 7: Commit**

```bash
git add miniprogram/pages/index/index.wxml miniprogram/pages/index/index.wxss miniprogram/pages/index/index.js
git commit -m "feat: miniprogram WeChat login with phone number binding"
```

---

### Task 7: Remove "验证码" title from home header in miniprogram

**Objective:** Remove the "验证码" text from the home screen header top-left.

**Files:**
- Modify: `miniprogram/pages/index/index.wxml` — home header section
- Modify: `miniprogram/pages/index/index.wxss` — `.home-title` rule

**Step 1: Remove the title text**

In the home header, when not searching, the current code is:
```xml
<view class="home-title-row">
  <text class="home-title">验证码</text>
  <view class="search-btn" bindtap="onSearchTap">...</view>
</view>
```

Replace with just the search button (right-aligned):
```xml
<view class="home-title-row">
  <view style="flex:1"/>
  <view class="search-btn" bindtap="onSearchTap">
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="rgba(238,238,245,0.65)" stroke-width="2.2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></svg>
  </view>
</view>
```

**Step 2: Verify** — Home screen no longer shows "验证码" in the top-left.

**Step 3: Commit**

```bash
git add miniprogram/pages/index/index.wxml
git commit -m "feat: miniprogram remove 验证码 title from home header"
```

---

### Task 8: Redesign profile page with product branding "玄钥" in miniprogram

**Objective:** Update the profile ("我的") page to show product name "玄钥", description, and account info. Replace current avatar/login section.

**Files:**
- Modify: `miniprogram/pages/index/index.wxml` — profile screen
- Modify: `miniprogram/pages/index/index.wxss` — profile styles

**Step 1: Update profile screen template**

Replace the `avatar-section` block in the profile screen with:

```xml
<!-- Product branding -->
<view class="product-section">
  <view class="product-logo" style="background:{{accentColor}};box-shadow:0 8px 32px {{accentColor}}55">
    <text style="font-size:32px;color:#fff;font-weight:800">玄</text>
  </view>
  <text class="product-name">玄钥</text>
  <text class="product-subtitle">Authenticator: 身份验证器</text>
  <text class="product-desc">为你所有的重要账号（如腾讯云、阿里云、AI账号、游戏等）配备了一把"动态的、每30秒换一次的数字钥匙"</text>
</view>

<!-- Account info -->
<view class="account-section">
  <block wx:if="{{loggedIn}}">
    <view class="account-card" style="border-color:{{accentColor}}30">
      <view class="account-avatar" style="background:{{accentColor}}">
        <text style="font-size:18px;color:#fff;font-weight:700">{{userInfo.name[0] || 'U'}}</text>
      </view>
      <view style="flex:1">
        <text style="font-size:15px;color:#eeeef5;font-weight:600">{{userInfo.name}}</text>
        <text wx:if="{{userInfo.phone}}" style="display:block;font-size:12px;color:rgba(238,238,245,0.4);margin-top:2px">{{userInfo.phone}}</text>
      </view>
    </view>
  </block>
  <block wx:else>
    <view class="login-prompt-card" bindtap="onLoginOpen">
      <text style="font-size:14px;color:rgba(238,238,245,0.55)">登录后解锁更多功能</text>
      <view class="login-btn" style="background:{{accentColor}};box-shadow:0 4px 20px {{accentColor}}55">
        <text style="color:#fff;font-size:14px;font-weight:600">登录账号</text>
      </view>
    </view>
  </block>
</view>
```

**Step 2: Add CSS for new profile layout**

Add to `index.wxss` (replacing `.avatar-section`, `.avatar`, `.user-name`, `.user-phone`, `.login-prompt`, `.login-btn` styles):

```css
.product-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 16px 0 20px;
}
.product-logo {
  width: 64px;
  height: 64px;
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 12px;
}
.product-name {
  font-size: 24px;
  font-weight: 800;
  color: #eeeef5;
  letter-spacing: -0.5px;
}
.product-subtitle {
  font-size: 13px;
  color: rgba(238,238,245,0.4);
  margin-top: 4px;
}
.product-desc {
  font-size: 12px;
  color: rgba(238,238,245,0.3);
  text-align: center;
  line-height: 1.8;
  margin-top: 8px;
  padding: 0 20px;
}
.account-section { margin-bottom: 20px; }
.account-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  background: #191920;
  border-radius: 14px;
  border: 1px solid;
}
.account-avatar {
  width: 40px;
  height: 40px;
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.login-prompt-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 16px;
  background: #191920;
  border-radius: 14px;
  border: 1px solid rgba(255,255,255,0.05);
}
.login-btn {
  padding: 8px 20px;
  border-radius: 18px;
}
```

**Step 3: Verify** — Profile page shows "玄钥" logo, product name, description, and account info.

**Step 4: Commit**

```bash
git add miniprogram/pages/index/index.wxml miniprogram/pages/index/index.wxss
git commit -m "feat: miniprogram redesign profile page with 玄钥 branding"
```

---

## Part B: HarmonyOS App

### Task 9: Fix HarmonyOS SDK version configuration

**Objective:** Fix `compileSdkVersion`, `compatibleSdkVersion`, `targetSdkVersion` values that cause build failure.

**Files:**
- Modify: `harmonyos/build-profile.json5`

**Step 1: Update SDK versions**

The current `build-profile.json5` has `"compatibleSdkVersion": "5.0.0(12)"` and `"targetSdkVersion": "1"`. The targetSdkVersion "1" is invalid for API 12. Fix:

```json5
{
  "app": {
    "signingConfigs": [],
    "products": [
      {
        "name": "default",
        "signingConfig": "default",
        "compatibleSdkVersion": "5.0.0(12)",
        "runtimeOS": "HarmonyOS",
        "buildOption": { "strictMode": { "caseSensitiveCheck": true } },
        "targetSdkVersion": "5.0.0(12)"
      }
    ],
    "buildModeSet": [
      { "name": "debug" },
      { "name": "release" }
    ]
  },
  "modules": [
    { "name": "entry", "srcPath": "./entry", "targets": [{ "name": "default", "applyToProducts": ["default"] }] }
  ]
}
```

**Step 2: Verify** — Rebuild in DevEco Studio, confirm no SDK version errors.

**Step 3: Commit**

```bash
git add harmonyos/build-profile.json5
git commit -m "fix: harmonyos correct targetSdkVersion to match API 12"
```

---

### Task 10: Fix HarmonyOS input field text clipping

**Objective:** Same issue as miniprogram — input text is clipped in edit and login modals. Ensure TextInput has adequate height.

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets` — editModal and loginModal TextInput components

**Step 1: Add explicit height to TextInput fields**

In the edit modal, the `TextInput` components for brand and account don't have explicit height. Add `.height(48)` to each:

For edit modal brand TextInput:
```typescript
TextInput({ text: this.editBrand, placeholder: '' })
  .onChange((v) => { this.editBrand = v; })
  .backgroundColor('#191920').fontColor('#eeeef5')
  .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
  .height(48)
  .padding({ left: 14, right: 14 })
```

Apply the same `.height(48).padding({ left: 14, right: 14 })` to:
- Edit modal account TextInput
- Login modal phone TextInput
- Login modal code TextInput
- Login modal backup/import TextInputs
- ScanView manual form TextInputs

**Step 2: Verify** — Open edit modal in DevEco Studio preview, confirm text fully visible.

**Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets harmonyos/entry/src/main/ets/views/ScanView.ets
git commit -m "fix: harmonyos input field text clipping — add explicit height"
```

---

### Task 11: Add cancel button to edit modal in HarmonyOS

**Objective:** Same as miniprogram — add "取消" button next to "保存" in edit modal header.

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets` — editModal builder

**Step 1: Update edit modal header**

In the editModal builder, replace the save button area with both cancel and save:

```typescript
Row({ space: 12 }) {
  Button({ type: ButtonType.Normal }) {
    Text('×').fontSize(20).fontColor('rgba(238,238,245,0.75)')
  }
  .backgroundColor('rgba(255,255,255,0.08)').borderRadius(11).width(36).height(36)
  .onClick(() => { this.editToken = null; })
  Text('编辑账号').fontSize(17).fontWeight(650).fontColor('#eeeef5').flexGrow(1)
  Button('取消')
    .backgroundColor(Color.Transparent)
    .border({ width: 1, color: 'rgba(255,255,255,0.1)' }).borderRadius(11)
    .fontColor('rgba(238,238,245,0.6)').fontSize(14)
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .onClick(() => { this.editToken = null; })
  Button('保存')
    .backgroundColor(this.accentColor).fontColor('#fff').fontSize(14).fontWeight(650)
    .borderRadius(11).padding({ left: 18, right: 18, top: 8, bottom: 8 })
    .onClick(() => this.saveEdit())
}
```

**Step 2: Verify** — Edit modal shows both "取消" and "保存" buttons.

**Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat: harmonyos add cancel button to edit modal"
```

---

### Task 12: Update bottom nav icons and style in HarmonyOS

**Objective:** Same as miniprogram Tasks 3+5 — update scan icon to show scan+add, and redesign nav bar with immersive light-effect style.

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets` — navBar builder

**Step 1: Redesign navBar builder**

Replace the navBar builder with a refined version. The scan center icon should use a combined scan+add symbol. The nav bar should be slimmer with light gradient overlay:

```typescript
@Builder
navBar() {
  Row({ space: 2 }) {
    // Home
    Column({ space: 2 }) {
      Image($r('sys.media.ohos_ic_public_home')).width(20).height(20).fillColor(this.currentTab === 0 ? this.accentColor : 'rgba(238,238,245,0.38)')
      Text('首页').fontSize(9).fontColor(this.currentTab === 0 ? this.accentColor : 'rgba(238,238,245,0.38)')
    }
    .flexGrow(1).alignItems(HorizontalAlign.Center).padding({ left: 7, right: 7, top: 7, bottom: 7 })
    .backgroundColor(this.currentTab === 0 ? 'rgba(255,255,255,0.1)' : Color.Transparent)
    .borderRadius(22)
    .onClick(() => { this.currentTab = 0; this.navVisible = true; })

    // Scan (center) — using ⊞ symbol for scan+add
    Column({ space: 2 }) {
      Stack() {
        Text('⊞').fontSize(20).fontColor('#fff')
      }.width(20).height(20).alignContent(Alignment.Center)
      Text('扫码').fontSize(9).fontColor('#fff').fontWeight(650)
    }
    .alignItems(HorizontalAlign.Center).padding({ left: 18, right: 18, top: 8, bottom: 8 })
    .backgroundColor(this.accentColor).borderRadius(20)
    .position({ x: 0, y: 0 })
    .onClick(() => { this.currentTab = 1; this.navVisible = true; })
    // Light gradient overlay
    Stack() {
      Column()
        .width('100%').height('100%')
        .linearGradient({ direction: GradientDirection.TopRight, colors: [['rgba(255,255,255,0.15)', 0], ['transparent', 0.6]] })
        .borderRadius(20)
    }
    .position({ x: 0, y: 0 }).width('100%').height('100%')
    .hitTestBehavior(HitTestMode.None)

    // Profile
    Column({ space: 2 }) {
      Image($r('sys.media.ohos_ic_public_contacts')).width(20).height(20).fillColor(this.currentTab === 2 ? this.accentColor : 'rgba(238,238,245,0.38)')
      Text('我').fontSize(9).fontColor(this.currentTab === 2 ? this.accentColor : 'rgba(238,238,245,0.38)')
    }
    .flexGrow(1).alignItems(HorizontalAlign.Center).padding({ left: 7, right: 7, top: 7, bottom: 7 })
    .backgroundColor(this.currentTab === 2 ? 'rgba(255,255,255,0.1)' : Color.Transparent)
    .borderRadius(22)
    .onClick(() => { this.currentTab = 2; this.navVisible = true; })
  }
  .padding({ left: 5, right: 5, top: 4, bottom: 4 })
  .backgroundColor('rgba(18,18,24,0.72)')
  .backdropBlur(32)
  .borderRadius(28)
  .border({ width: 0.5, color: 'rgba(255,255,255,0.08)' })
  .shadow({ radius: 24, color: 'rgba(0,0,0,0.4)', offsetX: 0, offsetY: 2 })
  .margin({ left: 20, right: 20, bottom: 14 })
  .translate({ y: this.navVisible ? 0 : 120 })
  .animation({ duration: 350, curve: Curve.EaseInOut })
}
```

**Step 2: Verify** — Nav bar is slimmer, scan icon shows scan+add, light gradient on center button.

**Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat: harmonyos redesign bottom nav — immersive light-effect style"
```

---

### Task 13: Replace WeChat login with HarmonyOS account login

**Objective:** HarmonyOS app should use HarmonyOS account login instead of WeChat login. The login modal should have "手机验证码" and "鸿蒙账号" tabs.

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets` — loginModal builder

**Step 1: Update login tab labels**

In the loginModal, change the tab labels from `['手机验证码', '微信登录']` to `['手机验证码', '鸿蒙账号']`.

**Step 2: Update the WeChat login content**

Replace the QR code / WeChat content (the `else` branch when `loginTab === 1`) with a HarmonyOS account login button:

```typescript
Column({ space: 20 }) {
  Stack() {
    Column()
      .width(72).height(72).borderRadius(20)
      .backgroundColor('#ff0000')
    Text('H').fontSize(32).fontColor('#fff').fontWeight(800)
  }
  .width(72).height(72)
  Text('使用鸿蒙账号快速登录')
    .fontSize(14).fontColor('rgba(238,238,245,0.55)').textAlign(TextAlign.Center)
  Button('鸿蒙账号登录')
    .width('100%').height(50).borderRadius(15)
    .backgroundColor('#ff0000').fontColor('#fff').fontSize(15).fontWeight(650)
    .onClick(() => {
      // In production: use @hms.core.authentication or HarmonyOS ID
      // Demo: simulate login
      this.loggedIn = true;
      this.userName = '鸿蒙用户';
      this.userPhone = '';
      this.showLogin = false;
      this.toast('鸿蒙账号登录成功');
    })
  Text('将使用设备上的鸿蒙账号')
    .fontSize(11).fontColor('rgba(238,238,245,0.3)').textAlign(TextAlign.Center)
}
.width('100%').alignItems(HorizontalAlign.Center).padding({ top: 20 })
```

**Step 3: Update the bottom login button text**

Change `this.loginTab === 1 ? '微信登录（演示）' : ...` to `this.loginTab === 1 ? '鸿蒙账号登录' : ...`.

**Step 4: Verify** — Login modal shows "鸿蒙账号" tab, tapping it shows HarmonyOS branding and login button.

**Step 5: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat: harmonyos replace WeChat login with HarmonyOS account login"
```

---

### Task 14: Remove "验证码" title from home header in HarmonyOS

**Objective:** Same as miniprogram Task 7.

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/HomeView.ets`

**Step 1: Remove title text**

In HomeView, the non-searching header currently has:
```typescript
Text('验证码')
  .fontSize(22).fontWeight(750).fontColor('#eeeef5').letterSpacing(-0.5)
```

Remove this `Text` component and the `Blank()` before the search button.

**Step 2: Verify** — Home screen no longer shows "验证码".

**Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/views/HomeView.ets
git commit -m "feat: harmonyos remove 验证码 title from home header"
```

---

### Task 15: Redesign profile page with "玄钥" branding in HarmonyOS

**Objective:** Same as miniprogram Task 8 — update ProfileView with product branding.

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/ProfileView.ets`

**Step 1: Replace avatar section with product branding**

Replace the avatar Column in ProfileView with:

```typescript
// Product branding
Column({ space: 0 }) {
  Stack() {
    Text('玄').fontSize(32).fontColor('#fff').fontWeight(800)
  }
  .width(64).height(64).borderRadius(20)
  .backgroundColor(this.accentColor)
  .shadow({ radius: 32, color: this.accentColor + '55', offsetX: 0, offsetY: 8 })
  .margin({ bottom: 12 })

  Text('玄钥').fontSize(24).fontWeight(800).fontColor('#eeeef5').letterSpacing(-0.5)
  Text('Authenticator: 身份验证器')
    .fontSize(13).fontColor('rgba(238,238,245,0.4)').margin({ top: 4 })
  Text('为你所有的重要账号（如腾讯云、阿里云、AI账号、游戏等）配备了一把"动态的、每30秒换一次的数字钥匙"')
    .fontSize(12).fontColor('rgba(238,238,245,0.3)').textAlign(TextAlign.Center)
    .lineHeight(21).margin({ top: 8 }).padding({ left: 20, right: 20 })
}
.width('100%').alignItems(HorizontalAlign.Center).padding({ top: 16, bottom: 20 })

// Account section
if (this.loggedIn) {
  Row({ space: 12 }) {
    Stack() {
      Text(this.userName[0]?.toUpperCase() ?? 'U')
        .fontSize(18).fontColor('#fff').fontWeight(700)
    }
    .width(40).height(40).borderRadius(20)
    .backgroundColor(this.accentColor)
    Column({ space: 2 }) {
      Text(this.userName).fontSize(15).fontColor('#eeeef5').fontWeight(600)
      if (this.userPhone) {
        Text(this.userPhone).fontSize(12).fontColor('rgba(238,238,245,0.4)')
      }
    }.alignItems(HorizontalAlign.Start).flexGrow(1)
  }
  .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
  .backgroundColor('#191920').borderRadius(14)
  .border({ width: 1, color: this.accentColor + '30' })
  .margin({ bottom: 20 })
} else {
  Row() {
    Text('登录后解锁更多功能')
      .fontSize(14).fontColor('rgba(238,238,245,0.55)')
    Button('登录账号')
      .backgroundColor(this.accentColor).fontColor('#fff')
      .fontSize(14).fontWeight(600).borderRadius(18)
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .shadow({ radius: 20, color: this.accentColor + '55', offsetX: 0, offsetY: 4 })
      .onClick(() => this.onLoginTap())
  }
  .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
  .backgroundColor('#191920').borderRadius(14)
  .border({ width: 1, color: 'rgba(255,255,255,0.05)' })
  .justifyContent(FlexAlign.SpaceBetween)
  .margin({ bottom: 20 })
}
```

**Step 2: Verify** — Profile page shows "玄钥" branding, description, and account info.

**Step 3: Commit**

```bash
git add harmonyos/entry/src/main/ets/views/ProfileView.ets
git commit -m "feat: harmonyos redesign profile page with 玄钥 branding"
```

---

## Task Dependency Map

Miniprogram Tasks 1-8 can be done sequentially (they touch overlapping files).
HarmonyOS Tasks 9-15 can be done sequentially (they touch overlapping files).
Miniprogram and HarmonyOS tasks are independent of each other.

## Total: 15 tasks
