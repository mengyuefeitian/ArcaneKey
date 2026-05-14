# Conventions

**Last updated:** 2025-05-14

## Language & UI

- **UI Language:** Chinese (中文)
- **All labels, theme names, button text:** Chinese (e.g. 海洋蓝, 皇室紫, 扫一扫)
- **Code comments:** Mixed Chinese/English
- **Product name:** 玄钥 (ArcaneKey)

---

## Code Style

### WeChat Mini Program

- **JavaScript:** ES5/ES6, no TypeScript
- **Component pattern:** `Component({ properties, data, methods, observers, lifetimes })`
- **Page pattern:** `Page({ data, onLoad, methods })`
- **Event binding:** `bindtap`, `bindinput`, `bind:custom-event`
- **State updates:** `this.setData({ key: value })`

### HarmonyOS

- **ArkTS:** TypeScript-like with decorators
- **Component pattern:** `@Component struct Name { @State, build() }`
- **Entry pattern:** `@Entry @Component struct Index`
- **Builder pattern:** `@Builder function ModalName()`
- **State updates:** Direct assignment to `@State` vars

---

## Naming Patterns

| Context | Pattern | Example |
|---------|---------|---------|
| Event handlers | `onXxx` | `onCopyTap`, `onEditToken` |
| Internal methods | `_xxx` | `_updateOtpMap`, `_filterTokens` |
| Data properties | camelCase | `timeLeft`, `accentColor`, `otpMap` |
| WXML classes | kebab-case | `.card-bottom`, `.otp-digit` |
| Components | kebab-case | `token-card`, `bottom-nav` |

---

## Error Handling

- **Toast notifications:** Custom toast component, not `wx.showToast`
- **Error messages:** Chinese (e.g. "复制失败", "无法解析二维码")
- **Fail callbacks:** Always show user feedback via toast

```javascript
wx.setClipboardData({
  data: code,
  success: () => this.showToast(`已复制 ${token.brand} 验证码`),
  fail: () => this.showToast('复制失败'),
});
```

---

## Styling Conventions

### Color System

- **Theme colors:** 10 accent colors in `THEMES` array
- **Background:** Dark (`#0d0d12`, `#191920`)
- **Text:** Light (`#eeeef5`, `rgba(238,238,245,0.xx)`)
- **Brand colors:** Hardcoded map for popular brands

### Layout

- **Navigation:** Floating bottom bar, glassmorphism effect
- **Cards:** Rounded corners (18px), dark backgrounds
- **Spacing:** Consistent padding (14px, 16px, 20px)
- **Radius:** Consistent (8px, 12px, 18px)

---

## Data Patterns

### TOTP Flow

```javascript
// Update OTP codes every 30 seconds
setInterval(() => {
  const tl = timeLeft();
  this.setData({ timeLeft: tl });
  if (tl === 30) this._updateOtpMap(); // Regenerate at cycle start
}, 1000);
```

### Storage Keys

| Key | Platform | Purpose |
|-----|----------|---------|
| `ak_tokens` | WeChat | Token array |
| `ak_theme` | WeChat | Theme object |
| `ak_membership` | Both | Membership status |
| `arcankey_cloud` | HarmonyOS | Cloud backup |

---

## Component Communication

WeChat uses event bubbling:

```xml
<token-card bind:edit="onEditToken" bind:copy="onCopyOtp" />
```

```javascript
// token-card.js
this.triggerEvent('edit', { token: this.properties.token });
this.triggerEvent('copy', { token, code });
```

---

## Magic Numbers

| Value | Context |
|-------|---------|
| 30 | TOTP cycle seconds |
| 5 | Free token limit |
| 19.90 | Membership price (¥) |
| 6 | OTP code digits |
| 3 | Max feedback images |