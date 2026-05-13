# 会员系统与反馈功能 Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** 添加会员管理、扫码自动添加、删除确认、云端备份同步、意见反馈等核心功能。

**Architecture:** 两平台各自实现会员状态管理（isMember/memberExpiry）。微信小程序用云开发实现云端存储备份和反馈；鸿蒙App用华为Cloud Kit实现云端存储。

**Tech Stack:**
- 微信小程序: 微信云开发 (wx.cloud.database, wx.cloud.callFunction), 微信支付
- HarmonyOS: ArkTS, @kit.CloudKit (华为Cloud Kit)

---

## Cross-platform constants to add (两个平台)

在以下文件中添加会员相关常量:
- `miniprogram/app.js` (WeChat)
- `harmonyos/entry/src/main/ets/model/Token.ets` (HarmonyOS)

```js
const FREE_TOKEN_LIMIT = 5;  // 免费用户最大token数
const MEMBERSHIP_PRICE = 19.90; // 年费价格（元）
const APP_NAME = '玄钥';
```

---

## Phase 1: 微信小程序

### Task 1.1: 会员状态管理 + 云开发初始化

**objective:** 在小程序中实现会员状态持久化，初始化微信云开发环境。

**Files:**
- Modify: `miniprogram/app.js`
- Modify: `miniprogram/app.json`

**Step 1: app.js 中添加会员状态**

在 `globalData` 中添加:

```js
isMember: false,
memberExpiry: null,
```

在 `onLaunch` 中添加:

```js
// 初始化云开发
wx.cloud.init({ env: 'your-env-id' });

// 加载会员状态
const memberData = wx.getStorageSync('ak_membership');
if (memberData) {
  this.globalData.isMember = memberData.isMember;
  this.globalData.memberExpiry = memberData.expiry ? new Date(memberData.expiry) : null;
}
```

添加 `saveMemberData` 方法:

```js
saveMemberData(isMember, expiry) {
  this.globalData.isMember = isMember;
  this.globalData.memberExpiry = expiry;
  wx.setStorageSync('ak_membership', { isMember, expiry: expiry ? expiry.toISOString() : null });
},
```

**Step 2: Commit**

```bash
git add miniprogram/app.js miniprogram/app.json
git commit -m "feat: miniprogram - 会员状态管理+云开发初始化"
```

---

### Task 1.2: 扫码需登录 + 扫码成功自动添加 + 密钥隐藏

**objective:** 未登录点击扫码则引导登录；扫码成功直接添加；编辑页面密钥默认隐藏。

**Files:**
- Modify: `miniprogram/pages/index/index.js`
- Modify: `miniprogram/pages/index/index.wxml`

**Step 1: 扫码需登录**

在 `onNavigate` 中加检查:

```js
onNavigate(e) {
  const { screen } = e.detail;
  if (screen === 'scan' && !this.data.loggedIn) {
    this.onLoginOpen();
    this.showToast('扫码功能需要登录后使用');
    return;
  }
  // ...existing code
}
```

**Step 2: 扫码成功自动添加**

修改 `_parseScanResult`，扫码后直接添加并返回 home，不再切换到 manual tab:

```js
_parseScanResult(result) {
  try {
    if (!result || result.indexOf('otpauth://totp/') !== 0) throw new Error('not otpauth');
    const after = result.substring('otpauth://totp/'.length);
    const qIdx = after.indexOf('?');
    const label = qIdx >= 0 ? after.substring(0, qIdx) : after;
    const queryStr = qIdx >= 0 ? after.substring(qIdx + 1) : '';

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

    // 检查数量限制
    if (!this.data.isMember && this.data.tokens.length >= 5) {
      this.showToast('免费用户最多添加5个口令');
      this.setData({ screen: 'profile' });
      return;
    }

    // 直接添加
    const tok = {
      id: Date.now().toString(),
      brand: brand.trim(),
      account: account.trim(),
      secret: (params.secret || '').trim().toUpperCase(),
    };
    if (!tok.secret) { this.showToast('二维码中未找到密钥'); return; }
    const updated = [...this.data.tokens, tok];
    app.globalData.tokens = updated;
    saveTokens(updated);
    this.setData({
      tokens: updated, screen: 'home',
      scanForm: { brand: '', account: '', secret: '' },
      scanScanned: false, scanTab: 'camera',
    });
    this._filterTokens();
    this._updateOtpMap();
    this.showToast(`已添加 ${tok.brand}`);
    // 触发云端备份（如果会员）
    if (this.data.isMember) this._cloudBackup(updated);
  } catch (e) {
    this.showToast('无法解析二维码（仅支持 otpauth 格式）');
  }
},
```

注意：`onScanCamera` 中 `wx.scanCode` 成功后直接调用 `_parseScanResult`，不再设置 `scanScanning` 状态。

**Step 3: 编辑页面密钥隐藏**

在 index.js data 中添加 `editSecretVisible: false`。

在 `onEditToken` 中重置:

```js
onEditToken(e) {
  const { token } = e.detail;
  this.setData({
    editToken: token,
    editForm: { brand: token.brand, account: token.account },
    editSecretMask: '*'.repeat(Math.min(token.secret.length, 20)),
    editSecretVisible: false,
    confirmDelete: false,
  });
},
```

添加 `onToggleEditSecret`:

```js
onToggleEditSecret() {
  if (!this.data.isMember) return;
  this.setData({ editSecretVisible: !this.data.editSecretVisible });
},
```

在 wxml 的 Edit Modal secret 区域:

```xml
<view class="field-wrap">
  <text class="field-label">Secret Key（只读）
    <text wx:if="{{isMember}}" style="color:{{accentColor}};font-size:11px;margin-left:6px" bindtap="onToggleEditSecret">
      {{editSecretVisible ? '隐藏' : '查看'}}
    </text>
  </text>
  <view class="field-input readonly-field">
    <text class="mono" style="font-size:13px;color:{{editSecretVisible ? '#eeeef5' : 'rgba(238,238,245,0.4)'}};letter-spacing:1px">
      {{editSecretVisible ? editToken.secret : editSecretMask}}
    </text>
  </view>
  <text wx:if="{{!isMember}}" style="font-size:11px;color:rgba(238,238,245,0.25);margin-top:4px">🔒 开通会员可查看密钥</text>
</view>
```

**Step 4: Commit**

```bash
git add miniprogram/pages/index/index.js miniprogram/pages/index/index.wxml
git commit -m "feat: miniprogram - 扫码需登录+自动添加+密钥隐藏"
```

---

### Task 1.3: 5个token限制 + 会员购买页面

**objective:** 添加 token 时检查限制；会员购买接入微信支付（演示模式）。

**Files:**
- Modify: `miniprogram/pages/index/index.js` (onAddToken)
- Create: `miniprogram/pages/membership/membership.js`
- Create: `miniprogram/pages/membership/membership.wxml`
- Create: `miniprogram/pages/membership/membership.wxss`
- Create: `miniprogram/pages/membership/membership.json`
- Modify: `miniprogram/app.json`

**Step 1: 添加限制到 onAddToken（手动输入场景）**

```js
onAddToken() {
  const { scanForm, tokens, isMember } = this.data;
  if (!isMember && tokens.length >= 5) {
    this.showToast('免费用户最多添加5个口令');
    this.setData({ screen: 'profile' });
    return;
  }
  // ...existing code...
}
```

**Step 2: 会员购买页面**

`miniprogram/pages/membership/membership.json`:
```json
{ "usingComponents": {} }
```

`miniprogram/pages/membership/membership.wxml`:
```xml
<view class="page" style="--accent:{{accentColor}}">
  <view class="header">
    <view class="back-btn" bindtap="onBack">×</view>
    <text class="title">开通会员</text>
  </view>
  <scroll-view class="content" scroll-y>
    <block wx:if="{{isMember}}">
      <view class="member-status" style="background:{{accentColor}}18;border-color:{{accentColor}}30">
        <text class="status-title" style="color:{{accentColor}}">✨ 您已是会员</text>
        <text class="status-desc">有效期至 {{memberExpiryText}}\n享受无限制添加、云端备份、数据同步等特权</text>
      </view>
    </block>
    <block wx:else>
      <view class="price-section">
        <view class="price-icon">👑</view>
        <text class="price-amount">¥19.90</text>
        <text class="price-unit">/年</text>
      </view>
      <view class="benefits">
        <view class="benefit-item" wx:for="{{['无限制添加动态口令','加密备份数据导入导出','查看 Secret Key','云端数据每小时自动同步']}}" wx:key="*this">
          <text class="benefit-check" style="color:{{accentColor}}">✓</text>
          <text class="benefit-text">{{item}}</text>
        </view>
      </view>
      <button class="pay-btn" style="background:linear-gradient(135deg,#f59e0b,#d97706)" bindtap="onPay">
        立即开通会员 ¥19.90/年
      </button>
      <text class="pay-note">演示模式：点击直接开通</text>
    </block>
  </scroll-view>
</view>
```

`miniprogram/pages/membership/membership.wxss`:
```css
.page { min-height: 100vh; background: #0d0d12; }
.header { display: flex; align-items: center; padding: 14px 16px; gap: 12px; }
.back-btn { background: rgba(255,255,255,0.08); border-radius: 11px; width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; color: rgba(238,238,245,0.75); font-size: 20px; }
.title { font-size: 17px; font-weight: 650; color: #eeeef5; }
.content { padding: 0 20px; }
.price-section { text-align: center; padding: 32px 0 24px; }
.price-icon { font-size: 48px; margin-bottom: 12px; }
.price-amount { font-size: 36px; font-weight: 800; color: #eeeef5; }
.price-unit { font-size: 14px; color: rgba(238,238,245,0.4); }
.benefits { background: #191920; border-radius: 16px; padding: 16px; margin-bottom: 24px; }
.benefit-item { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
.benefit-check { font-weight: 700; font-size: 16px; }
.benefit-text { font-size: 14px; color: rgba(238,238,245,0.7); }
.pay-btn { width: 100%; height: 50px; border-radius: 15px; border: none; font-size: 16px; font-weight: 700; color: #fff; margin-bottom: 12px; }
.pay-note { font-size: 11px; color: rgba(238,238,245,0.3); text-align: center; display: block; padding-bottom: 40px; }
.member-status { padding: 16px; border-radius: 16px; margin-top: 24px; }
.status-title { font-size: 16px; font-weight: 700; display: block; margin-bottom: 8px; }
.status-desc { font-size: 13px; color: rgba(238,238,245,0.5); display: block; line-height: 1.7; white-space: pre-line; }
```

`miniprogram/pages/membership/membership.js`:
```js
const app = getApp();

Page({
  data: { accentColor: '#4080D0', isMember: false, memberExpiryText: '' },

  onLoad() {
    this.setData({ accentColor: app.globalData.theme.color });
    this.updateMemberStatus();
  },

  onShow() { this.updateMemberStatus(); },

  updateMemberStatus() {
    const { isMember, memberExpiry } = app.globalData;
    this.setData({
      isMember,
      memberExpiryText: memberExpiry ? memberExpiry.toLocaleDateString('zh-CN') : '',
    });
  },

  onBack() { wx.navigateBack(); },

  onPay() {
    // TODO: 生产环境需调用后端创建订单 → wx.requestPayment
    const expiry = new Date();
    expiry.setFullYear(expiry.getFullYear() + 1);
    app.saveMemberData(true, expiry);
    this.updateMemberStatus();
    wx.showToast({ title: '开通成功（演示）', icon: 'success' });
  },
});
```

在 `miniprogram/app.json` 中注册页面:

```json
{
  "pages": [
    "pages/index/index",
    "pages/membership/membership"
  ],
  ...
}
```

**Step 3: Commit**

```bash
git add miniprogram/pages/membership/ miniprogram/app.json
git commit -m "feat: miniprogram - 5个token限制+会员购买页面"
```

---

### Task 1.4: 删除确认（区分会员/非会员）+ 备份权限

**objective:** 非会员删除弹窗简单确认；会员删除弹窗提供"仅删除本地"/"同时删除云端"/"取消"三个选项；备份/导入仅限会员。

**Files:**
- Modify: `miniprogram/pages/index/index.js`
- Modify: `miniprogram/pages/index/index.wxml`
- Modify: `miniprogram/pages/index/index.wxss`

**Step 1: 删除确认逻辑**

在 index.js data 中添加:

```js
deleteTarget: null,
showDeleteModal: false,
```

修改 `onConfirmDelete`:

```js
onConfirmDelete() {
  const { editToken } = this.data;
  if (!editToken) return;
  this.setData({ deleteTarget: { id: editToken.id, brand: editToken.brand }, showDeleteModal: true });
},

executeDelete() {
  const { deleteTarget, tokens } = this.data;
  if (!deleteTarget) return;
  const updated = tokens.filter(t => t.id !== deleteTarget.id);
  app.globalData.tokens = updated;
  saveTokens(updated);
  this.setData({ tokens: updated, editToken: null, deleteTarget: null, showDeleteModal: false });
  this._filterTokens();
  this._updateOtpMap();
  this.showToast('已删除');
  // 会员同步删除云端
  if (this.data.isMember) this._cloudDelete(deleteTarget.id);
},

executeDeleteCloud() {
  // 与 executeDelete 相同，已包含 _cloudDelete 调用
  this.executeDelete();
},

cancelDelete() {
  this.setData({ deleteTarget: null, showDeleteModal: false });
},
```

**Step 2: 删除确认弹窗 (wxml)**

在 wxml 末尾（toast 之前）添加:

```xml
<view wx:if="{{showDeleteModal}}" class="delete-modal-overlay">
  <view class="delete-dialog">
    <text class="delete-title">确认删除</text>
    <text class="delete-content">确定要删除「{{deleteTarget.brand}}」吗？{{isMember ? '\n选择删除方式：' : '\n此操作不可撤销'}}</text>
    <block wx:if="{{isMember}}">
      <view class="delete-btns">
        <view class="delete-btn local" bindtap="executeDelete">仅本地</view>
        <view class="delete-btn cloud" bindtap="executeDeleteCloud">本地+云端</view>
        <view class="delete-btn cancel" bindtap="cancelDelete">取消</view>
      </view>
    </block>
    <block wx:else>
      <view class="delete-btns">
        <view class="delete-btn cancel" bindtap="cancelDelete">取消</view>
        <view class="delete-btn confirm" bindtap="executeDelete">确认删除</view>
      </view>
    </block>
  </view>
</view>
```

在 wxss 中添加:

```css
.delete-modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center; z-index: 999; }
.delete-dialog { background: #191920; border-radius: 20px; padding: 24px; width: 85%; max-width: 320px; text-align: center; }
.delete-title { font-size: 16px; font-weight: 700; color: #eeeef5; display: block; margin-bottom: 8px; }
.delete-content { font-size: 14px; color: rgba(238,238,245,0.6); display: block; margin-bottom: 20px; line-height: 1.6; white-space: pre-line; }
.delete-btns { display: flex; gap: 10px; flex-wrap: wrap; }
.delete-btn { flex: 1; min-width: 80px; padding: 12px 8px; border-radius: 12px; font-size: 14px; font-weight: 600; text-align: center; }
.delete-btn.cancel { border: 1px solid rgba(255,255,255,0.1); color: rgba(238,238,245,0.6); }
.delete-btn.confirm, .delete-btn.cloud { background: #ef4444; color: #fff; }
.delete-btn.local { background: rgba(255,255,255,0.08); color: rgba(238,238,245,0.7); border: 1px solid rgba(255,255,255,0.1); }
```

**Step 3: 备份权限**

修改 `onMenuTap` 中 backup 和 import 分支:

```js
if (id === 'backup' || id === 'import') {
  if (!this.data.isMember) {
    this.showToast('备份功能需要开通会员');
    wx.navigateTo({ url: '/pages/membership/membership' });
    return;
  }
  // ...existing code
}
```

在 wxml 的 profile 菜单中添加会员入口和反馈入口:

```xml
<!-- 替换原有的 menu-group -->
<view class="menu-group">
  <view class="menu-item" data-id="membership" data-locked="{{false}}" bindtap="onMenuTap" style="{{isMember ? 'border-left:3px solid ' + accentColor : ''}}">
    <text class="menu-icon">👑</text>
    <view style="flex:1">
      <text class="menu-label">{{isMember ? '会员特权' : '开通会员'}}</text>
      <text class="menu-desc">{{isMember ? '有效期至 ' + memberExpiryText : '¥19.90/年，无限制添加'}}</text>
    </view>
    ›
    <view class="menu-divider"/>
  </view>
  <!-- 原有 backup, import, theme 项 -->
  ...
  <view class="menu-item" data-id="feedback" data-locked="{{false}}" bindtap="onMenuTap">
    <text class="menu-icon">💬</text>
    <view style="flex:1">
      <text class="menu-label">意见与建议</text>
      <text class="menu-desc">向我们反馈问题或建议</text>
    </view>
    ›
  </view>
</view>
```

同时需要在 data 中添加 `memberExpiryText`，在 onLoad 中初始化:

```js
onLoad() {
  // ...existing code...
  const gd = app.globalData;
  this.setData({
    isMember: gd.isMember,
    memberExpiryText: gd.memberExpiry ? gd.memberExpiry.toLocaleDateString('zh-CN') : '',
  });
},
```

**Step 4: Commit**

```bash
git add miniprogram/pages/index/index.js miniprogram/pages/index/index.wxml miniprogram/pages/index/index.wxss
git commit -m "feat: miniprogram - 删除确认(区分会员)+备份权限"
```

---

### Task 1.5: 云端备份与同步（微信云开发）

**objective:** 会员添加 token 后自动备份到微信云数据库；每小时自动同步；登录时从云端恢复。

**Files:**
- Modify: `miniprogram/pages/index/index.js`

**Step 1: 云端备份函数**

在 index.js 中添加:

```js
// 云端备份
_cloudBackup(tokens) {
  if (!this.data.isMember) return;
  const db = wx.cloud.database();
  const openid = app.globalData.userInfo?.openid || 'demo';
  db.collection('user_backups').where({ openid }).get()
    .then(res => {
      if (res.data.length > 0) {
        db.collection('user_backups').doc(res.data[0]._id).update({
          data: { tokens, timestamp: db.serverDate() }
        });
      } else {
        db.collection('user_backups').add({
          data: { openid, tokens, timestamp: db.serverDate() }
        });
      }
    })
    .catch(() => {});
},

// 从云端恢复
_cloudRestore() {
  if (!this.data.isMember) return;
  const db = wx.cloud.database();
  const openid = app.globalData.userInfo?.openid || 'demo';
  db.collection('user_backups').where({ openid }).get()
    .then(res => {
      if (res.data.length > 0 && res.data[0].tokens) {
        const cloudTokens = res.data[0].tokens;
        const localIds = new Set(this.data.tokens.map(t => t.id));
        const newTokens = cloudTokens.filter(t => !localIds.has(t.id));
        if (newTokens.length > 0) {
          const merged = [...this.data.tokens, ...newTokens];
          app.globalData.tokens = merged;
          saveTokens(merged);
          this.setData({ tokens: merged });
          this._filterTokens();
          this._updateOtpMap();
          this.showToast(`从云端同步 ${newTokens.length} 个账号`);
        }
      }
    })
    .catch(() => {});
},

// 云端删除
_cloudDelete(tokenId) {
  const db = wx.cloud.database();
  const openid = app.globalData.userInfo?.openid || 'demo';
  db.collection('user_backups').where({ openid }).get()
    .then(res => {
      if (res.data.length > 0) {
        const updated = res.data[0].tokens.filter(t => t.id !== tokenId);
        db.collection('user_backups').doc(res.data[0]._id).update({ data: { tokens: updated } });
      }
    })
    .catch(() => {});
},

// 每小时同步
_startAutoSync() {
  if (!this.data.isMember) return;
  this._autoSyncTimer = setInterval(() => {
    this._cloudBackup(this.data.tokens);
  }, 60 * 60 * 1000);
},
```

**Step 2: 生命周期集成**

在 `onLoad` 中触发恢复和自动同步:

```js
onLoad() {
  // ...existing code...
  if (this.data.isMember) {
    this._cloudRestore();
    this._startAutoSync();
  }
},
```

在 `onUnload` 中清理定时器:

```js
onUnload() {
  // ...existing code...
  if (this._autoSyncTimer) clearInterval(this._autoSyncTimer);
},
```

在 `onAddToken` 末尾加备份:

```js
if (this.data.isMember) this._cloudBackup(updated);
```

**Step 3: Commit**

```bash
git add miniprogram/pages/index/index.js
git commit -m "feat: miniprogram - 云端备份同步(微信云开发)"
```

---

### Task 1.6: 意见反馈（小程序）

**objective:** 添加意见反馈页面，支持反馈类型、内容、图片、联系方式，提交后通过云函数发送邮件到 mengyuefeitian@gmail.com。

**Files:**
- Create: `miniprogram/pages/feedback/feedback.js`
- Create: `miniprogram/pages/feedback/feedback.wxml`
- Create: `miniprogram/pages/feedback/feedback.wxss`
- Create: `miniprogram/pages/feedback/feedback.json`
- Create: `miniprogram/cloudfunctions/sendFeedback/index.js`
- Create: `miniprogram/cloudfunctions/sendFeedback/package.json`
- Modify: `miniprogram/app.json`
- Modify: `miniprogram/pages/index/index.js`

**Step 1: 注册反馈页面**

在 `miniprogram/app.json` 的 pages 数组中添加:

```json
"pages/feedback/feedback"
```

**Step 2: 创建反馈页面**

`miniprogram/pages/feedback/feedback.json`:
```json
{ "usingComponents": {} }
```

`miniprogram/pages/feedback/feedback.wxml`:
```xml
<view class="page" style="--accent:{{accentColor}}">
  <view class="header">
    <view class="back-btn" bindtap="onBack">×</view>
    <text class="title">意见与建议</text>
  </view>
  <scroll-view class="content" scroll-y>
    <!-- 反馈类型 -->
    <view class="section">
      <text class="section-label">反馈类型</text>
      <view class="type-group">
        <view class="type-btn {{type === '需求' ? 'active' : ''}}"
          style="{{type === '需求' ? 'border-color:' + accentColor + '60;background:' + accentColor + '18;color:' + accentColor : ''}}"
          bindtap="onTypeChange" data-type="需求">需求</view>
        <view class="type-btn {{type === 'Bug' ? 'active' : ''}}"
          style="{{type === 'Bug' ? 'border-color:' + accentColor + '60;background:' + accentColor + '18;color:' + accentColor : ''}}"
          bindtap="onTypeChange" data-type="Bug">Bug</view>
      </view>
    </view>
    <!-- 反馈内容 -->
    <view class="section">
      <text class="section-label">反馈内容 <text style="color:var(--accent)">*</text></text>
      <textarea class="content-input" value="{{content}}" bindinput="onContentInput"
        placeholder="请描述您的问题或建议（至少10个字，最多500字）" maxlength="500" auto-height/>
      <text class="char-count {{content.length > 500 ? 'over-limit' : ''}}">{{content.length}}/500</text>
    </view>
    <!-- 图片附件 -->
    <view class="section">
      <text class="section-label">附件（可选，最多3张，单张≤10MB）</text>
      <view class="image-list">
        <view class="image-item" wx:for="{{images}}" wx:key="index">
          <image class="image-thumb" src="{{item}}" mode="aspectFill"/>
          <view class="image-remove" bindtap="onRemoveImage" data-index="{{index}}">×</view>
        </view>
        <view wx:if="{{images.length < 3}}" class="image-add" bindtap="onAddImage">+</view>
      </view>
    </view>
    <!-- 联系方式 -->
    <view class="section">
      <text class="section-label">联系方式（选填，手机号或邮箱）</text>
      <input class="contact-input" value="{{contact}}" bindinput="onContactInput" placeholder="手机号或邮箱"/>
    </view>
    <view class="submit-btn {{canSubmit ? '' : 'btn-disabled'}}"
      style="background:{{canSubmit ? accentColor : '#191920'}};color:{{canSubmit ? '#fff' : 'rgba(238,238,245,0.3)'}}"
      bindtap="onSubmit">
      {{sending ? '提交中…' : '提交反馈'}}
    </view>
    <text class="submit-note">您的反馈将发送至开发团队，我们认真对待每一条建议</text>
  </scroll-view>
</view>
```

`miniprogram/pages/feedback/feedback.wxss`:
```css
.page { min-height: 100vh; background: #0d0d12; }
.header { display: flex; align-items: center; padding: 14px 16px; gap: 12px; position: sticky; top: 0; background: #0d0d12; z-index: 10; }
.back-btn { background: rgba(255,255,255,0.08); border-radius: 11px; width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; color: rgba(238,238,245,0.75); font-size: 20px; }
.title { font-size: 17px; font-weight: 650; color: #eeeef5; }
.content { padding: 0 20px 40px; }
.section { margin-bottom: 20px; }
.section-label { font-size: 12px; color: rgba(238,238,245,0.45); display: block; margin-bottom: 8px; }
.type-group { display: flex; gap: 8px; }
.type-btn { flex: 1; padding: 10px; border-radius: 12px; border: 1px solid rgba(255,255,255,0.08); background: transparent; color: rgba(238,238,245,0.5); font-size: 14px; font-weight: 600; text-align: center; }
.content-input { width: 100%; min-height: 120px; background: #191920; border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; color: #eeeef5; font-size: 14px; padding: 12px; box-sizing: border-box; }
.char-count { font-size: 11px; color: rgba(238,238,245,0.25); display: block; text-align: right; margin-top: 4px; }
.char-count.over-limit { color: #f87171; }
.image-list { display: flex; gap: 8px; flex-wrap: wrap; }
.image-item { position: relative; width: 72px; height: 72px; }
.image-thumb { width: 100%; height: 100%; border-radius: 8px; }
.image-remove { position: absolute; top: -4px; right: -4px; width: 18px; height: 18px; border-radius: 9px; background: rgba(0,0,0,0.7); color: #fff; font-size: 10px; display: flex; align-items: center; justify-content: center; }
.image-add { width: 72px; height: 72px; border-radius: 8px; border: 1px dashed rgba(255,255,255,0.15); display: flex; align-items: center; justify-content: center; font-size: 24px; color: rgba(238,238,245,0.3); }
.contact-input { width: 100%; padding: 12px 14px; background: #191920; border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; color: #eeeef5; font-size: 14px; box-sizing: border-box; }
.submit-btn { width: 100%; height: 50px; border-radius: 15px; font-size: 15px; font-weight: 650; text-align: center; line-height: 50px; margin-top: 12px; }
.submit-note { font-size: 11px; color: rgba(238,238,245,0.2); text-align: center; display: block; margin-top: 12px; }
```

`miniprogram/pages/feedback/feedback.js`:
```js
const app = getApp();

Page({
  data: {
    accentColor: '#4080D0', type: '需求', content: '', images: [],
    contact: '', sending: false, canSubmit: false,
  },

  onLoad() {
    this.setData({ accentColor: app.globalData.theme.color });
  },

  onBack() { wx.navigateBack(); },
  onTypeChange(e) { this.setData({ type: e.currentTarget.dataset.type }); },
  onContentInput(e) {
    const content = e.detail.value;
    this.setData({ content, canSubmit: content.length >= 10 && content.length <= 500 });
  },
  onContactInput(e) { this.setData({ contact: e.detail.value }); },

  onAddImage() {
    const { images } = this.data;
    if (images.length >= 3) return;
    wx.chooseMedia({
      count: 3 - images.length, mediaType: ['image'], sizeType: ['compressed'],
      success: (res) => {
        const paths = res.tempFiles.map(f => f.tempFilePath);
        this.setData({ images: [...images, ...paths] });
      },
    });
  },

  onRemoveImage(e) {
    const idx = e.currentTarget.dataset.index;
    this.setData({ images: this.data.images.filter((_, i) => i !== idx) });
  },

  onSubmit() {
    const { type, content, images, contact, canSubmit } = this.data;
    if (!canSubmit) {
      if (content.length < 10) { wx.showToast({ title: '至少10个字', icon: 'none' }); }
      return;
    }
    this.setData({ sending: true });

    const uploadPromises = images.map((path, i) =>
      wx.cloud.uploadFile({ cloudPath: `feedback/${Date.now()}_${i}.jpg`, filePath: path })
    );

    Promise.all(uploadPromises)
      .then(fileResults => {
        const fileIds = fileResults.map(r => r.fileID);
        return wx.cloud.callFunction({
          name: 'sendFeedback',
          data: { type, content, contact, fileIds, userInfo: app.globalData.userInfo },
        });
      })
      .then(() => {
        wx.showToast({ title: '反馈已提交', icon: 'success' });
        wx.navigateBack();
      })
      .catch(() => { wx.showToast({ title: '提交失败', icon: 'error' }); })
      .finally(() => { this.setData({ sending: false }); });
  },
});
```

**Step 3: 云函数发送邮件**

`miniprogram/cloudfunctions/sendFeedback/package.json`:
```json
{
  "name": "sendFeedback",
  "version": "1.0.0",
  "dependencies": {
    "wx-server-sdk": "~2.6.3",
    "nodemailer": "^6.9.0"
  }
}
```

`miniprogram/cloudfunctions/sendFeedback/index.js`:
```js
const cloud = require('wx-server-sdk');
cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });
const nodemailer = require('nodemailer');

exports.main = async (event, context) => {
  const { type, content, contact, fileIds, userInfo } = event;

  const transporter = nodemailer.createTransport({
    host: process.env.MAIL_HOST,
    port: parseInt(process.env.MAIL_PORT || '465'),
    secure: true,
    auth: { user: process.env.MAIL_USER, pass: process.env.MAIL_PASS },
  });

  let htmlContent = `<h3>反馈类型: ${type}</h3><pre>${content}</pre>`;
  if (contact) htmlContent += `<p>联系方式: ${contact}</p>`;
  if (userInfo) htmlContent += `<p>用户: ${userInfo.name || ''}</p>`;
  if (fileIds && fileIds.length > 0) {
    htmlContent += `<p>附件数量: ${fileIds.length}（请在云控制台查看）</p>`;
  }

  await transporter.sendMail({
    from: process.env.MAIL_USER,
    to: 'mengyuefeitian@gmail.com',
    subject: `[玄钥][${type}]`,
    html: htmlContent,
  });

  const db = cloud.database();
  await db.collection('feedbacks').add({
    data: { type, content, contact, fileIds, userInfo, createdAt: db.serverDate() },
  });

  return { success: true };
};
```

**Step 4: 在 index.js 的 onMenuTap 中添加反馈路由**

```js
else if (id === 'feedback') {
  wx.navigateTo({ url: '/pages/feedback/feedback' });
}
```

**Step 5: Commit**

```bash
git add miniprogram/pages/feedback/ miniprogram/cloudfunctions/sendFeedback/ miniprogram/pages/index/index.js
git commit -m "feat: miniprogram - 意见反馈功能"
```

---

## Phase 2: HarmonyOS App

### Task 2.1: 会员状态管理

**objective:** 在鸿蒙 App 中添加会员状态，用 preferences 持久化。

**Files:**
- Modify: `harmonyos/entry/src/main/ets/utils/StorageUtil.ets`
- Modify: `harmonyos/entry/src/main/ets/model/Token.ets`
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets`

**Step 1: Token.ets 中添加常量**

在 `harmonyos/entry/src/main/ets/model/Token.ets` 中导出:

```ets
export const FREE_TOKEN_LIMIT: number = 5;
export const MEMBERSHIP_PRICE: number = 19.90;
export const APP_NAME: string = '玄钥';
```

**Step 2: StorageUtil 中添加会员存储**

在 `StorageUtil.ets` 中添加:

```ets
export interface MemberData {
  isMember: boolean;
  expiry: string | null;
}

export async function loadMember(): MemberData {
  try {
    const val = preferences.getString('ak_membership', '');
    if (val) return JSON.parse(val) as MemberData;
  } catch (_) {}
  return { isMember: false, expiry: null };
}

export async function saveMember(isMember: boolean, expiry: string | null): Promise<void> {
  try {
    await preferences.putString('ak_membership', JSON.stringify({ isMember, expiry }));
    await preferences.flush();
  } catch (_) {}
}
```

**Step 3: Index.ets 中添加 state**

添加导入:

```ets
import { loadMember, saveMember } from '../utils/StorageUtil';
```

添加 state:

```ets
@State isMember: boolean = false;
@State memberExpiry: string = '';
```

在 `loadData` 中加载:

```ets
const member = await loadMember();
this.isMember = member.isMember;
this.memberExpiry = member.expiry || '';
```

**Step 4: Commit**

```bash
git add harmonyos/entry/src/main/ets/utils/StorageUtil.ets harmonyos/entry/src/main/ets/model/Token.ets harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat: harmonyos - 会员状态管理"
```

---

### Task 2.2: 扫码需登录 + 自动添加 + 密钥隐藏

**objective:** 未登录时扫码引导登录；扫码成功直接添加；编辑页面密钥默认隐藏且会员可查看。

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets`
- Modify: `harmonyos/entry/src/main/ets/views/ScanView.ets`

**Step 1: 扫码需登录**

在 Index.ets 的 bottomNav 扫码 onClick 中加检查:

```ets
.onClick(() => {
  if (!this.loggedIn) {
    this.showLogin = true;
    return;
  }
  this.currentTab = 1;
  this.navVisible = true;
})
```

**Step 2: ScanView 自动添加**

读取 `harmonyos/entry/src/main/ets/views/ScanView.ets`，修改扫码成功后的逻辑：解析 QR 成功后直接调用 `onAdd` 回调，不再切换到手动输入页面。

**Step 3: 编辑页面密钥隐藏**

在 Index.ets 中添加 `@State editSecretVisible: boolean = false;`。

修改 editModal 的 secret 区域:

```ets
Column({ space: 6 }) {
  Row() {
    Text('Secret Key（只读）').fontSize(12).fontColor('rgba(238,238,245,0.45)')
    if (this.isMember) {
      Text(this.editSecretVisible ? '隐藏' : '查看')
        .fontSize(11).fontColor(this.accentColor).margin({ left: 8 })
        .onClick(() => { this.editSecretVisible = !this.editSecretVisible; })
    }
  }
  Text(this.isMember && this.editSecretVisible ? this.editToken.secret : '*'.repeat(Math.min(this.editToken.secret.length, 20)))
    .fontSize(13)
    .fontColor(this.isMember && this.editSecretVisible ? '#eeeef5' : 'rgba(238,238,245,0.4)')
    .fontFamily('monospace').letterSpacing(1)
    .width('100%').height(44)
    .padding({ left: 14, right: 14 })
    .textAlign(TextAlign.Start)
    .backgroundColor('#191920')
    .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
  if (!this.isMember) {
    Text('🔒 开通会员可查看密钥')
      .fontSize(11).fontColor('rgba(238,238,245,0.25)').margin({ top: 4 })
  }
}
```

在 `editToken` 赋值时重置 `this.editSecretVisible = false;`。

**Step 4: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets harmonyos/entry/src/main/ets/views/ScanView.ets
git commit -m "feat: harmonyos - 扫码需登录+自动添加+密钥隐藏"
```

---

### Task 2.3: 5个token限制 + 会员购买 + 删除确认

**objective:** 同小程序逻辑，鸿蒙 App 实现 token 限制、会员购买 UI、删除区分会员/非会员。

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets`
- Modify: `harmonyos/entry/src/main/ets/views/ProfileView.ets`

**Step 1: addToken 中加限制**

```ets
private addToken(brand: string, account: string, secret: string): void {
  if (!this.isMember && this.tokens.length >= FREE_TOKEN_LIMIT) {
    this.toast(`免费用户最多添加${FREE_TOKEN_LIMIT}个口令`);
    this.currentTab = 2;
    return;
  }
  const tok: Token = { id: Date.now().toString(), brand, account, secret: secret.toUpperCase() };
  this.tokens = this.tokens.concat([tok]);
  saveTokens(this.tokens);
  this.refreshOtp();
  this.currentTab = 0;
  this.toast(`已添加 ${brand}`);
  if (this.isMember) this.cloudBackup();
}
```

**Step 2: 删除确认**

添加 state:

```ets
@State deleteTarget: Token = {} as Token;
@State showDeleteConfirm: boolean = false;
```

修改删除流程:

```ets
private requestDeleteToken(tok: Token): void {
  this.deleteTarget = tok;
  this.showDeleteConfirm = true;
}

private executeDelete(localOnly: boolean): void {
  if (!this.deleteTarget.id) return;
  this.tokens = this.tokens.filter((t: Token) => t.id !== this.deleteTarget.id);
  saveTokens(this.tokens);
  this.refreshOtp();
  this.editToken = {} as Token;
  this.showDeleteConfirm = false;
  const deletedId = this.deleteTarget.id;
  this.deleteTarget = {} as Token;
  this.toast('已删除');
  if (this.isMember && !localOnly) this.cloudDelete(deletedId);
}
```

在 editModal 中，将"确认删除"按钮改为调用 `requestDeleteToken`:

```ets
Button('删除账号')
  .flexGrow(1)
  .backgroundColor('rgba(248,113,113,0.08)')
  .border({ width: 1, color: 'rgba(248,113,113,0.25)' })
  .borderRadius(14).fontColor('#f87171').fontSize(14).fontWeight(600)
  .onClick(() => { this.requestDeleteToken(this.editToken); })
```

添加删除确认 @Builder:

```ets
@Builder
deleteConfirmDialog() {
  Column() {
    Text('确认删除').fontSize(16).fontWeight(700).fontColor('#eeeef5').margin({ bottom: 8 })
    Text(`确定要删除「${this.deleteTarget.brand}」吗？${this.isMember ? '\n选择删除方式：' : '\n此操作不可撤销'}`)
      .fontSize(14).fontColor('rgba(238,238,245,0.6)').textAlign(TextAlign.Center).margin({ bottom: 20 })
    if (this.isMember) {
      Row({ space: 10 }) {
        Button('仅本地').flexGrow(1).backgroundColor('rgba(255,255,255,0.08)')
          .border({ width: 1, color: 'rgba(255,255,255,0.1)' }).borderRadius(12)
          .fontColor('rgba(238,238,245,0.7)').fontSize(14)
          .onClick(() => this.executeDelete(true))
        Button('本地+云端').flexGrow(1).backgroundColor('#ef4444').borderRadius(12)
          .fontColor('#fff').fontSize(14).fontWeight(650)
          .onClick(() => this.executeDelete(false))
      }.width('100%')
      Button('取消').width('100%').marginTop(10).backgroundColor(Color.Transparent)
        .border({ width: 1, color: 'rgba(255,255,255,0.1)' }).borderRadius(12)
        .fontColor('rgba(238,238,245,0.6)').fontSize(14)
        .onClick(() => { this.showDeleteConfirm = false; this.deleteTarget = {} as Token; })
    } else {
      Row({ space: 10 }) {
        Button('取消').flexGrow(1).backgroundColor(Color.Transparent)
          .border({ width: 1, color: 'rgba(255,255,255,0.1)' }).borderRadius(12)
          .fontColor('rgba(238,238,245,0.6)').fontSize(14)
          .onClick(() => { this.showDeleteConfirm = false; this.deleteTarget = {} as Token; })
        Button('确认删除').flexGrow(1).backgroundColor('#ef4444').borderRadius(12)
          .fontColor('#fff').fontSize(14).fontWeight(650)
          .onClick(() => this.executeDelete(true))
      }.width('100%')
    }
  }
  .padding(24).backgroundColor('#191920').borderRadius(20).width('85%')
}
```

在 build() 的 Stack 中添加（在 modals 之后）:

```ets
if (this.showDeleteConfirm) {
  Column() {
    this.deleteConfirmDialog()
  }
  .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.6)')
  .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
  .zIndex(999)
}
```

**Step 3: 会员购买 UI**

在 ProfileView 中添加会员卡片（props 中传入 `isMember`, `memberExpiry`, `onMembershipTap`），或新建 `@Builder membershipModal` 在 Index.ets 中。

**Step 4: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets harmonyos/entry/src/main/ets/views/ProfileView.ets
git commit -m "feat: harmonyos - token限制+删除确认+会员购买"
```

---

### Task 2.4: 云端备份同步（华为 Cloud Kit）+ 意见反馈

**objective:** 会员云端备份到华为 Cloud Kit，每小时自动同步；意见反馈界面。

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets`
- Create: `harmonyos/entry/src/main/ets/views/FeedbackView.ets`
- Modify: `harmonyos/entry/src/main/ets/views/ProfileView.ets`

**Step 1: 云端备份（Cloud Kit）**

在 Index.ets 中添加:

```ets
private cloudBackup(): void {
  if (!this.isMember) return;
  // 使用 Cloud Kit KV 存储
  try {
    const kvStore = getCloudKVStore(); // @kit.CloudKit 封装
    kvStore.put('tokens_backup', JSON.stringify(this.tokens)).then(() => {
      this.toast('云端备份成功');
    }).catch(() => {});
  } catch (_) {}
}

private cloudRestore(): void {
  if (!this.isMember) return;
  try {
    const kvStore = getCloudKVStore();
    kvStore.get('tokens_backup').then((data: string) => {
      if (data) {
        const cloudTokens = JSON.parse(data) as Token[];
        const ids = new Set(this.tokens.map((t: Token) => t.id));
        const newTokens = cloudTokens.filter((t: Token) => !ids.has(t.id));
        if (newTokens.length > 0) {
          this.tokens = this.tokens.concat(newTokens);
          saveTokens(this.tokens);
          this.refreshOtp();
          this.toast(`从云端同步 ${newTokens.length} 个账号`);
        }
      }
    }).catch(() => {});
  } catch (_) {}
}

private cloudDelete(tokenId: string): void {
  if (!this.isMember) return;
  try {
    const kvStore = getCloudKVStore();
    kvStore.get('tokens_backup').then((data: string) => {
      if (data) {
        const tokens = (JSON.parse(data) as Token[]).filter((t: Token) => t.id !== tokenId);
        kvStore.put('tokens_backup', JSON.stringify(tokens));
      }
    }).catch(() => {});
  } catch (_) {}
}

private startAutoSync(): void {
  if (!this.isMember) return;
  setInterval(() => {
    this.cloudBackup();
  }, 60 * 60 * 1000);
}
```

在 `aboutToAppear` 中调用:

```ets
aboutToAppear(): void {
  this.loadData();
  if (this.isMember) {
    this.cloudRestore();
    this.startAutoSync();
  }
  // ...timer...
}
```

**Step 2: 意见反馈**

创建 `harmonyos/entry/src/main/ets/views/FeedbackView.ets`:

```ets
import { common } from '@kit.AbilityKit';

@Component
export struct FeedbackView {
  @Prop accentColor: string = '#4080D0';
  @State type: string = '需求';
  @State content: string = '';
  @State contact: string = '';
  @State sending: boolean = false;
  onClose: () => void = () => {};

  get canSubmit(): boolean {
    return this.content.length >= 10 && this.content.length <= 500;
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Button({ type: ButtonType.Normal }) { Text('×').fontSize(20).fontColor('rgba(238,238,245,0.75)') }
          .backgroundColor('rgba(255,255,255,0.08)').borderRadius(11).width(36).height(36)
          .onClick(this.onClose)
        Text('意见与建议').fontSize(17).fontWeight(650).fontColor('#eeeef5')
      }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 8 })

      Scroll() {
        Column({ space: 16 }) {
          Text('反馈类型').fontSize(12).fontColor('rgba(238,238,245,0.45)')
          Row({ space: 8 }) {
            Button('需求').flexGrow(1)
              .backgroundColor(this.type === '需求' ? this.accentColor + '18' : Color.Transparent)
              .border({ width: 1, color: this.type === '需求' ? this.accentColor + '60' : 'rgba(255,255,255,0.08)' })
              .borderRadius(12).fontColor(this.type === '需求' ? this.accentColor : 'rgba(238,238,245,0.5)')
              .fontSize(14).fontWeight(600)
              .onClick(() => { this.type = '需求'; })
            Button('Bug').flexGrow(1)
              .backgroundColor(this.type === 'Bug' ? this.accentColor + '18' : Color.Transparent)
              .border({ width: 1, color: this.type === 'Bug' ? this.accentColor + '60' : 'rgba(255,255,255,0.08)' })
              .borderRadius(12).fontColor(this.type === 'Bug' ? this.accentColor : 'rgba(238,238,245,0.5)')
              .fontSize(14).fontWeight(600)
              .onClick(() => { this.type = 'Bug'; })
          }.width('100%')

          Text('反馈内容 *').fontSize(12).fontColor('rgba(238,238,245,0.45)')
          TextArea({ text: this.content, placeholder: '请描述您的问题或建议（至少10个字，最多500字）' })
            .onChange((v: string) => { this.content = v; })
            .height(140).backgroundColor('#191920').fontColor('#eeeef5')
            .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
            .fontSize(14)

          Text('联系方式（选填，手机号或邮箱）').fontSize(12).fontColor('rgba(238,238,245,0.45)')
          TextInput({ text: this.contact, placeholder: '手机号或邮箱' })
            .onChange((v: string) => { this.contact = v; })
            .backgroundColor('#191920').fontColor('#eeeef5')
            .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
            .height(44)

          Button(this.sending ? '提交中…' : '提交反馈')
            .width('100%').height(50).borderRadius(15)
            .backgroundColor(this.canSubmit ? this.accentColor : '#191920')
            .fontColor(this.canSubmit ? '#fff' : 'rgba(238,238,245,0.3)')
            .fontSize(15).fontWeight(650)
            .onClick(() => this.submitFeedback())
        }
        .padding({ left: 20, right: 20, top: 8 })
      }.scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor('#0d0d12')
  }

  private submitFeedback(): void {
    if (!this.canSubmit) return;
    this.sending = true;
    const subject = `[玄钥][${this.type}]`;
    let body = `反馈类型: ${this.type}\n\n反馈内容:\n${this.content}\n\n`;
    if (this.contact) body += `联系方式: ${this.contact}\n`;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const want: Want = {
        action: 'ohos.want.action.sendData',
        uri: `mailto:mengyuefeitian@gmail.com?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`,
      };
      ctx.startAbility(want);
    } catch (_) {}
    this.sending = false;
    this.onClose();
  }
}
```

**Step 3: 在 ProfileView 和 Index.ets 中集成反馈入口**

在 ProfileView 菜单中添加"意见与建议"项，点击后在 Index.ets 中打开 FeedbackView（作为 @Builder 或全屏覆盖）。

**Step 4: Commit**

```bash
git add harmonyos/entry/src/main/ets/pages/Index.ets harmonyos/entry/src/main/ets/views/FeedbackView.ets harmonyos/entry/src/main/ets/views/ProfileView.ets
git commit -m "feat: harmonyos - 云端备份同步+意见反馈"
```

---

## Phase 3: 文档更新

### Task 3.1: 更新 CLAUDE.md

**objective:** 更新 CLAUDE.md 文档，记录新增的跨平台常量和功能。

**Files:**
- Modify: `CLAUDE.md`

在跨平台常量部分添加:

```
- `FREE_TOKEN_LIMIT` — 免费用户最大 token 数 (5)
- `MEMBERSHIP_PRICE` — 会员年费 (19.90)
- `APP_NAME` — '玄钥'
```

在架构描述中补充会员功能说明。

**Commit**

```bash
git add CLAUDE.md
git commit -m "docs: 更新会员功能和跨平台常量说明"
```

---

## 注意事项

1. **微信支付**: 演示模式直接设置会员状态。生产环境需要:
   - 后端调用微信支付 API 创建订单
   - 前端调用 `wx.requestPayment`
   - 后端处理支付回调更新会员状态

2. **华为 Cloud Kit**: 需要在华为开发者联盟控制台开通 Cloud Kit 服务，配置数据存储权限。Cloud Kit 的 KV Store API 可能因 SDK 版本有所不同。

3. **微信云开发**: 需要在微信小程序后台开通云开发，创建 `user_backups` 和 `feedbacks` 数据库集合，上传云函数。云函数环境变量中需配置 SMTP 信息 (`MAIL_HOST`, `MAIL_PORT`, `MAIL_USER`, `MAIL_PASS`)。
