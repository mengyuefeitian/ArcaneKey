# Coding Conventions

**Analysis Date:** 2026-05-19

## Naming Patterns

### Event Handlers

**WeChat Mini Program (JS):**
- Public tap handlers use `onXxxTap`: `onEditTap`, `onCopyTap`, `onPressStart`, `onPressEnd`
- Triggered via `triggerEvent` to parent: `this.triggerEvent('edit', { token })`, `this.triggerEvent('copy', { ... })`
- Page-level handlers: `onEditToken`, `onCopyTap`, `onScanSuccess`

**HarmonyOS (ArkTS):**
- Inline arrow callbacks directly in `onClick(()  => ...)` and `onChange(v => ...)`
- No separate handler method naming convention — logic often written inline in `build()`
- Lifecycle methods use ArkTS names: `aboutToAppear()`, `aboutToDisappear()`

### Internal (Private) Methods

**WeChat Mini Program:**
- Private/internal methods prefixed with `_`: `_interpolateColor`, `_computeDigitColors`, `_updateOtpMap`, `_filterTokens`
- Observers declared in `observers: { 'propName': function(val) { ... } }`

**HarmonyOS:**
- Private helper methods use `private` keyword and camelCase: `private interpolateColor(hex, t)`, `private timer: number`
- No `_` prefix convention — `private` keyword is used instead

### State / Data Properties

Both platforms use `camelCase` for all state:
- `timeLeft`, `accentColor`, `otpMap`, `isMember`, `memberExpiry`
- Boolean flags: `showLogin`, `showBackup`, `showImport`, `showTheme`, `loggedIn`, `navVisible`, `searching`
- Short abbreviations accepted for modal state: `backupPw`, `backupPw2`, `importPw`, `searchQ`

**HarmonyOS — trailing underscore to avoid name collision with imported function:**
- `timeLeft_: number` (state var) vs `timeLeft()` (imported util function)

### Timer Handles

All timers stored as `private` number fields with descriptive names:
- `private timer: number = -1` (TOTP refresh interval)
- `private toastTimer: number = -1`
- `private cdTimer: number = -1` (countdown)
- `private autoSyncTimer: number = -1`
- Initialized to `-1` as sentinel value for "not running"

### CSS/WXML Classes (WeChat)

kebab-case: `.card-top`, `.card-bottom`, `.card-info`, `.otp-code-wrap`, `.otp-digit`, `.next-wrap`, `.copy-hint-row`, `.next-label`, `.next-code`

### Component Names

**WeChat:** kebab-case in WXML and `usingComponents` config: `token-card`, `bottom-nav`, `countdown-ring`, `logo`

**HarmonyOS:** PascalCase struct names: `TokenCard`, `CountdownRing`, `Logo`, `HomeView`, `ProfileView`

### Types and Interfaces

PascalCase on both platforms:
- `Token`, `OtpPair`, `ThemeItem`, `MemberData`, `SaveOptions`

### Constants

UPPER_SNAKE_CASE:
- `THEMES`, `BRAND_COLORS`, `INITIAL_TOKENS`, `FREE_TOKEN_LIMIT`, `MEMBERSHIP_PRICE`, `APP_NAME`
- Storage key constants (HarmonyOS): `TOKENS_KEY`, `THEME_KEY`, `MEMBER_KEY`, `PREF_NAME`

---

## Code Style Patterns

### HarmonyOS (ArkTS)

**Component pattern:**
```typescript
@Component
export struct TokenCard {
  @Prop token: Token = { id: '', brand: '', account: '', secret: '' };
  @Prop accentColor: string = '#4080D0';
  onEdit: (tok: Token) => void = () => {};

  private interpolateColor(hex: string, t: number): string { ... }

  build() {
    Column() {
      Row({ space: 12 }) { ... }
    }
    .width('100%')
    .borderRadius(18)
    .backgroundColor('#191920')
  }
}
```

**Entry page pattern** (`Index.ets`):
```typescript
@Entry
@Component
struct Index {
  // ── Section Name ──────────────────────────────────────────────
  @State tokens: Token[] = [];
  @State otpMap: Record<string, OtpPair> = {};

  private timer: number = -1;

  aboutToAppear(): void { ... }
  aboutToDisappear(): void { ... }

  build() { ... }
}
```

**Section separators in Index.ets** use a consistent ASCII banner format:
```typescript
// ── Core State ──────────────────────────────────────────────────
// ── Edit Modal ──────────────────────────────────────────────────
// ── Lifecycle ───────────────────────────────────────────────────
```

**Builder functions** (modals in Index.ets): `@Builder` decorator, no separate file, defined within or alongside the struct.

**State updates:** Direct assignment to `@State` variables (ArkTS reactivity). No `setState` or `setData` needed.

**Prop defaults:** Every `@Prop` has an explicit default value to prevent undefined crashes:
```typescript
@Prop token: Token = { id: '', brand: '', account: '', secret: '' };
@Prop otp: OtpPair = { current: '------', next: '------' };
```

### WeChat Mini Program (JS)

**Component pattern:**
```javascript
Component({
  properties: {
    token:       { type: Object, value: {} },
    accentColor: { type: String, value: '#4080D0' },
  },
  data: { curFmt: '--- ---', pressed: false, digitColors: [] },
  methods: { onEditTap() { ... }, _interpolateColor(hex, t) { ... } },
  observers: { 'otp': function(otp) { ... } },
});
```

**Page pattern:**
```javascript
Page({
  data: { tokens: [], otpMap: {}, timeLeft: 30 },
  onLoad() { ... },
  onUnload() { ... },
  // methods as flat object keys
  onCopyTap(e) { ... },
  _updateOtpMap() { ... },
});
```

**State updates:** Always `this.setData({ key: value })` — never mutate `this.data` directly.

**Event binding in WXML:** `bindtap`, `bindinput`, `bind:custom-event`

---

## UI Language

All user-visible strings are Chinese. This is a hard requirement.

**Examples:**
- Button labels: `扫一扫`, `点击复制`, `下一个`, `确认`, `取消`
- Theme names: `海洋蓝`, `皇室紫`, `玫瑰粉`, `热情红`, `暖橙色`, `琥珀金`, `森林绿`, `青绿色`, `天空蓝`, `深靛蓝`
- Toast/error messages: `复制失败`, `无法解析二维码`, `保存成功`
- Product name: `玄钥` (used in `APP_NAME` constant)

**Code comments:** Mixed Chinese and English. English for technical references; Chinese for user-facing rationale. Example from `token-card.js`:
```javascript
// Mix from lighter version (40% white mix at t=0) to full accent at t=1
```

---

## Color System Conventions

### Palette Structure

- **Background:** `#0d0d12` (page/screen), `#191920` (card surface)
- **Text primary:** `#eeeef5`
- **Text secondary:** `rgba(238,238,245,0.42)`
- **Text tertiary/hint:** `rgba(238,238,245,0.28)`, `rgba(238,238,245,0.32)`
- **Divider:** `rgba(255,255,255,0.055)`
- **Card border:** `rgba(255,255,255,0.05)`

### Accent Color System

The `accentColor` string (`#RRGGBB` hex) flows from:
1. `THEMES[n].color` in `model/Token.ets` / `app.js`
2. Stored in `currentTheme` state → `accentColor` state
3. Passed as `@Prop accentColor` down to `TokenCard`, `CountdownRing`, `Logo`

**Gradient on OTP digits:** Both platforms implement `interpolateColor(hex, t)` where `t` runs 0→1 across the 6 digits, blending from a lighter tint (40% white mix) to full accent. Implemented as a private method on the component in both platforms.

### Theme Constants Location

- HarmonyOS: `harmonyos/entry/src/main/ets/model/Token.ets` — `THEMES`, `BRAND_COLORS`
- WeChat: `miniprogram/app.js` — `THEMES`, `BRAND_COLORS` (duplicated, must stay in sync)

**When changing themes or brand colors, update both files.**

---

## Layout Conventions

### Spacing Values

| Context | Value |
|---------|-------|
| Card horizontal padding | 16px |
| Card vertical padding (top) | 14px |
| Card vertical padding (bottom) | 14px |
| Card inner divider gap | 10–11px |
| Element gap (Row space) | 12px |
| Margin between cards | 10px (bottom) |

### Border Radius Values

| Element | Radius |
|---------|--------|
| Token card | 18px |
| Buttons / inputs | 8–12px |
| Modal sheets | 18–20px |
| Bottom nav capsule | 28px |

### Floating Bottom Navigation

Both platforms use a floating glassmorphism bottom nav bar:
- 90% width, 28px border radius
- Blur backdrop: `.backdropFilter('blur(20px)')` (HarmonyOS) / `backdrop-filter: blur(20px)` (WeChat CSS)
- Positioned with `translate({ y: navVisible ? -20 : 80 })` to hide/show on scroll
- Content has `.padding({ bottom: 80 })` to avoid overlap
- Nav icons: clean SVG paths (not platform system symbols)

### HarmonyOS Layout Idioms

- `Column()` as primary layout container for vertical stacks
- `Row({ space: N })` for horizontal rows with gap
- `.flexGrow(1).flexShrink(1)` for elastic middle elements in rows
- `.alignItems(HorizontalAlign.Start)` / `HorizontalAlign.End` for column alignment
- `Blank()` for flexible spacer between row elements
- `.clip(true)` on cards to enforce border radius clipping

---

## Error Handling Patterns

### Toast Notifications

Both platforms use a custom toast (not platform native alert):

**WeChat:** `toast` component in `components/toast/` — triggered via `this.showToast(msg)`

**HarmonyOS:** `@State toastMsg: string` and `@State toastVisible: boolean` in `Index.ets`. Toast shown by setting both state vars; auto-dismissed via `toastTimer`.

**All user-facing errors are Chinese strings.**

### Async Error Handling (HarmonyOS)

```typescript
// Pattern: silent fail with null return
export async function loadTokens(): Promise<Token[] | null> {
  try {
    if (!pref) return null;
    const val = await pref.get(TOKENS_KEY, '');
    return JSON.parse(val as string) as Token[];
  } catch (e) {
    return null;  // Silent null return on storage error
  }
}

// Pattern: log to console.error on write failure
export async function saveTokens(tokens: Token[]): Promise<void> {
  try { ... } catch (e) {
    console.error('saveTokens failed: ' + (e as Error).message);
  }
}
```

**Storage reads:** Return `null` on any error (silent).
**Storage writes:** Log via `console.error` with descriptive message, then swallow.
**TOTP errors:** Fall back to deterministic hash-based code rather than throwing.

---

## Comment Style

### Section Banners (HarmonyOS Index.ets)

```typescript
// ── Section Name ──────────────────────────────────────────────────
```

Used to visually separate logical blocks of `@State` declarations in the large `Index.ets` struct. Not used in smaller utility files.

### Inline Comments

Short English phrases on same line or line above:
```typescript
// Upper row — edit
// Lower row — copy
// Mix from lighter version (40% white mix at t=0) to full accent at t=1
```

### No JSDoc / TSDoc

Neither platform uses JSDoc or TSDoc annotation. No `/** @param */` patterns present anywhere in the codebase.

---

## Data Patterns

### TOTP Flow

```
secret (base32 string)
  → base32Decode() → key bytes
  → current Unix epoch / 30000 → counter t
  → HMAC-SHA1(key, t as 8-byte big-endian)
  → dynamic truncation → 6-digit code (zero-padded)
```

Both `TOTP.ets` and `utils/totp.js` implement identical algorithms. The HarmonyOS version also exports `fmtCode()` (formats `"123456"` → `"123 456"`). On decode error, a deterministic hash fallback is used (not an exception).

### OTP Refresh Timing

- A 1-second `setInterval` ticks `timeLeft_` down each second
- When `timeLeft === 30` (i.e., new 30s window): regenerate all OTP codes in `otpMap`
- `otpMap` is `Record<string, OtpPair>` keyed by `token.id`, value `{ current, next }`

### Storage Key Convention

| Key | Platform | Stores |
|-----|----------|--------|
| `auth_tokens` | HarmonyOS preferences | JSON array of `Token[]` |
| `auth_theme` | HarmonyOS preferences | JSON `ThemeItem` object |
| `ak_membership` | Both platforms | JSON `{ isMember, expiry }` |
| `arcankey_prefs` | HarmonyOS preferences name | (preference store name) |
| `arcankey_cloud` | HarmonyOS (separate pref store) | Cloud backup proxy |
| `ak_tokens` | WeChat storage | JSON array of `Token[]` |
| `ak_theme` | WeChat storage | Theme object |

**HarmonyOS preference store name:** `arcankey_prefs` (initialized once via `initPreferences(context)`)

### Backup Encryption

**Current format (`ENC2`):** MAGIC bytes `[0x45, 0x4E, 0x43, 0x32]` + 16-byte random salt + PBKDF2-HMAC-SHA1 (10000 iterations) XOR'd ciphertext, Base64-encoded. Implemented in `harmonyos/.../utils/CryptoUtil.ets`.

**Legacy format:** Simple XOR with repeating password bytes (no salt, no PBKDF2). Fallback supported in `decryptData()` for backward compatibility.

**WeChat format:** Simple XOR via `utils/crypto.js` — different implementation, not PBKDF2.

---

*Convention analysis: 2026-05-19*
