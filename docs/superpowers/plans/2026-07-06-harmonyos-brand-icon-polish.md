# HarmonyOS Brand Icon Visual Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix three on-device visual issues in the HarmonyOS brand-icon rendering: tint colorless silhouette icons (Apple/OpenAI/GitHub/TikTok) to the current theme accent color, dim Huawei's red in dark mode only, and enlarge the GitHub/Synology circular-badge icons that read as too small.

**Architecture:** Extend `BrandIconConfig` with three optional data fields (`monochrome`, `dimOpacityInDark`, `scale`). Add a `findBrandIconConfig(iconFile)` lookup so `Logo.ets` can go from the matched `iconFile` string back to its full config, then apply the corresponding `Image` modifiers conditionally. Icons with none of the three fields set render exactly as before — zero behavior change for the other 29 icons.

**Tech Stack:** ArkTS (HarmonyOS 6.1 / API 23), ArkUI (`Image.fillColor()`, `Image.opacity()`), no new dependencies.

## Global Constraints

- Platform: HarmonyOS only (`harmonyos/entry/src/main/ets/`). Do not touch `miniprogram/` or the bundled SVG asset files themselves.
- Do not modify `BrandIconMatcher.ets` or `matchBrandIcon()`'s signature/behavior — this plan only adds a *second*, independent lookup (`findBrandIconConfig`), keyed by `iconFile`, not a change to matching.
- The three new `BrandIconConfig` fields are optional and default to "no effect": unset `monochrome` → no `fillColor` applied; unset `dimOpacityInDark` → no `opacity` applied; unset `scale` → rendering size is unchanged (equivalent to `scale: 1`).
- Exact field values required by the spec: `monochrome: true` on `apple`, `openai`, `github`, `tiktok`. `dimOpacityInDark: 0.85` on `huawei` (applied only when `this.isDark` is true; light theme unaffected). `scale: 1.3` on `github` and `synology`.
- No new test framework (repo has none) — verify `findBrandIconConfig()` with a temporary, uncommitted Node mirror script, then a full `assembleApp` build, matching this repo's established verification pattern for `.ets` changes.
- Every task that touches `.ets` files ends with a successful `assembleApp` build (exact command in Task 2). A task is not done if the build fails.
- ArkTS strict mode: no `any`, no anonymous object literal types on `@State`/`@Prop`.

---

### Task 1: Extend BrandIconConfig with visual-polish fields + lookup function

**Files:**
- Modify: `harmonyos/entry/src/main/ets/model/BrandIcons.ets` (current full content shown below)

**Interfaces:**
- Consumes: nothing new (existing `BrandIconConfig` interface, existing `BRAND_ICONS` array).
- Produces: three new optional fields on `BrandIconConfig` (`monochrome?: boolean`, `dimOpacityInDark?: number`, `scale?: number`) and `findBrandIconConfig(iconFile: string): BrandIconConfig | null`, consumed by Task 2's `Logo.ets`.

Current file content (read it yourself before editing, do not rely solely on this copy):

```typescript
export interface BrandIconConfig {
  id: string;
  officialName: string;
  iconFile: string;
  matchKeywords: string[];
  // Email domain suffixes (e.g. '163.com') checked against the token's
  // account field when brand-text matching finds nothing — for brands
  // that are primarily recognized by their email address, not the issuer.
  emailDomains?: string[];
}

// Order is priority: more specific entries must come before generic ones
// that would otherwise also match the same input (e.g. 'gcp' before
// 'google', 'synology-dsm' before 'synology'). The first match wins.
export const BRAND_ICONS: BrandIconConfig[] = [
  { id: 'gcp', officialName: 'Google Cloud', iconFile: 'gcp.svg', matchKeywords: ['gcp', 'google cloud', 'googlecloud'] },
  { id: 'google', officialName: 'Google', iconFile: 'google.svg', matchKeywords: ['google', 'gmail'] },
  { id: 'synology-dsm', officialName: 'Synology DSM', iconFile: 'synology-dsm.svg', matchKeywords: ['dsm', 'synology dsm', 'quickconnect'] },
  { id: 'synology', officialName: 'Synology', iconFile: 'synology.svg', matchKeywords: ['synology', '群晖'] },
  { id: 'netease-mail', officialName: '网易邮箱', iconFile: 'netease-mail.svg', matchKeywords: ['网易邮箱', '163', '126', 'netease mail', 'yeah.net'], emailDomains: ['163.com', '126.com', 'yeah.net'] },
  { id: 'netease', officialName: '网易', iconFile: 'netease.svg', matchKeywords: ['网易', 'netease'] },
  { id: 'alibaba-cloud', officialName: '阿里云', iconFile: 'alibaba-cloud.svg', matchKeywords: ['阿里云', 'alibabacloud', 'aliyun'] },
  { id: 'douyin', officialName: '抖音', iconFile: 'douyin.svg', matchKeywords: ['抖音', 'douyin'] },
  { id: 'baidu-cloud', officialName: '百度云', iconFile: 'baidu-cloud.svg', matchKeywords: ['百度云', 'baiduyun', 'baidu cloud', 'baidunetdisk'] },
  { id: 'dingtalk', officialName: '钉钉', iconFile: 'dingtalk.svg', matchKeywords: ['钉钉', 'dingtalk'] },
  { id: 'tencent-cloud', officialName: '腾讯云', iconFile: 'tencent-cloud.svg', matchKeywords: ['腾讯云', 'tencentcloud', 'tencent cloud', 'qcloud'] },
  { id: 'sina', officialName: '新浪微博', iconFile: 'sina.svg', matchKeywords: ['新浪', 'sina', 'weibo', '微博'] },
  { id: 'feishu', officialName: '飞书', iconFile: 'feishu.svg', matchKeywords: ['飞书', 'feishu', 'lark'] },
  { id: 'amazon', officialName: 'Amazon', iconFile: 'amazon.svg', matchKeywords: ['amazon', 'aws'] },
  { id: 'anthropic', officialName: 'Anthropic', iconFile: 'anthropic.svg', matchKeywords: ['anthropic'] },
  { id: 'apple', officialName: 'Apple', iconFile: 'apple.svg', matchKeywords: ['apple', 'icloud', 'appleid'] },
  { id: 'azure', officialName: 'Microsoft Azure', iconFile: 'azure.svg', matchKeywords: ['azure'] },
  { id: 'binance', officialName: 'Binance', iconFile: 'binance.svg', matchKeywords: ['binance', '币安'] },
  { id: 'claude', officialName: 'Claude', iconFile: 'claude.svg', matchKeywords: ['claude'] },
  { id: 'facebook', officialName: 'Facebook', iconFile: 'facebook.svg', matchKeywords: ['facebook', 'meta'] },
  { id: 'github', officialName: 'GitHub', iconFile: 'github.svg', matchKeywords: ['github'] },
  { id: 'godaddy', officialName: 'GoDaddy', iconFile: 'godaddy.svg', matchKeywords: ['godaddy'] },
  { id: 'huawei', officialName: '华为', iconFile: 'huawei.svg', matchKeywords: ['huawei', '华为'] },
  { id: 'instagram', officialName: 'Instagram', iconFile: 'instagram.svg', matchKeywords: ['instagram'] },
  { id: 'beirui', officialName: '贝锐（向日葵/花生壳）', iconFile: 'beirui.svg', matchKeywords: ['贝锐', '向日葵', '花生壳', 'oray'] },
  { id: 'microsoft', officialName: 'Microsoft', iconFile: 'microsoft.svg', matchKeywords: ['microsoft', 'outlook', 'office365'] },
  { id: 'openai', officialName: 'OpenAI', iconFile: 'openai.svg', matchKeywords: ['openai', 'chatgpt'] },
  { id: 'paypal', officialName: 'PayPal', iconFile: 'paypal.svg', matchKeywords: ['paypal'] },
  { id: 'teamviewer', officialName: 'TeamViewer', iconFile: 'teamviewer.svg', matchKeywords: ['teamviewer'] },
  { id: 'tiktok', officialName: 'TikTok', iconFile: 'tiktok.svg', matchKeywords: ['tiktok'] },
  { id: 'todesk', officialName: 'ToDesk', iconFile: 'todesk.svg', matchKeywords: ['todesk'] },
  { id: 'twitter', officialName: 'X (Twitter)', iconFile: 'twitter.svg', matchKeywords: ['twitter', 'x.com'] },
  { id: 'whatsapp', officialName: 'WhatsApp', iconFile: 'whatsapp.svg', matchKeywords: ['whatsapp'] },
];
```

- [ ] **Step 1: Add the three optional fields to `BrandIconConfig`**

Replace the interface definition:

```typescript
export interface BrandIconConfig {
  id: string;
  officialName: string;
  iconFile: string;
  matchKeywords: string[];
  // Email domain suffixes (e.g. '163.com') checked against the token's
  // account field when brand-text matching finds nothing — for brands
  // that are primarily recognized by their email address, not the issuer.
  emailDomains?: string[];
  // No inherent brand color (a black/near-black silhouette in the source
  // SVG) — render tinted to the current theme accent color instead.
  monochrome?: boolean;
  // Opacity applied only in dark theme, to soften a high-saturation brand
  // color that reads as too harsh on a dark background. Light theme is
  // unaffected. Unset means no dimming.
  dimOpacityInDark?: number;
  // Multiplier on the default render size (logoSize * 0.62), for icons
  // whose source SVG has significant built-in padding (e.g. circular
  // badge logos) and would otherwise look smaller than other icons.
  // Unset means the default size (equivalent to scale: 1).
  scale?: number;
}
```

- [ ] **Step 2: Set the exact field values on the five affected entries**

Change these five lines in `BRAND_ICONS` (leave every other entry byte-for-byte unchanged):

```typescript
  { id: 'synology', officialName: 'Synology', iconFile: 'synology.svg', matchKeywords: ['synology', '群晖'], scale: 1.3 },
```

```typescript
  { id: 'apple', officialName: 'Apple', iconFile: 'apple.svg', matchKeywords: ['apple', 'icloud', 'appleid'], monochrome: true },
```

```typescript
  { id: 'github', officialName: 'GitHub', iconFile: 'github.svg', matchKeywords: ['github'], monochrome: true, scale: 1.3 },
```

```typescript
  { id: 'huawei', officialName: '华为', iconFile: 'huawei.svg', matchKeywords: ['huawei', '华为'], dimOpacityInDark: 0.85 },
```

```typescript
  { id: 'openai', officialName: 'OpenAI', iconFile: 'openai.svg', matchKeywords: ['openai', 'chatgpt'], monochrome: true },
```

```typescript
  { id: 'tiktok', officialName: 'TikTok', iconFile: 'tiktok.svg', matchKeywords: ['tiktok'], monochrome: true },
```

- [ ] **Step 3: Add `findBrandIconConfig()`**

Append this function at the end of the file, after the `BRAND_ICONS` array:

```typescript

export function findBrandIconConfig(iconFile: string): BrandIconConfig | null {
  for (let i = 0; i < BRAND_ICONS.length; i++) {
    if (BRAND_ICONS[i].iconFile === iconFile) {
      return BRAND_ICONS[i];
    }
  }
  return null;
}
```

- [ ] **Step 4: Manually verify with a temporary Node mirror script**

This repo has no test framework (see Global Constraints). Verify the lookup logic with a standalone Node script that mirrors the same data/logic, run outside the ArkTS build, then deleted — it must not be committed.

```bash
mkdir -p /private/tmp/claude-501/-Users-xiaoan-Documents-code-ArcaneKey/008f159b-2d46-43c4-aaf0-7abf8222426a/scratchpad
cat > /private/tmp/claude-501/-Users-xiaoan-Documents-code-ArcaneKey/008f159b-2d46-43c4-aaf0-7abf8222426a/scratchpad/verify-icon-lookup.js <<'EOF'
const BRAND_ICONS = [
  { id: 'apple', iconFile: 'apple.svg', monochrome: true },
  { id: 'openai', iconFile: 'openai.svg', monochrome: true },
  { id: 'github', iconFile: 'github.svg', monochrome: true, scale: 1.3 },
  { id: 'tiktok', iconFile: 'tiktok.svg', monochrome: true },
  { id: 'huawei', iconFile: 'huawei.svg', dimOpacityInDark: 0.85 },
  { id: 'synology', iconFile: 'synology.svg', scale: 1.3 },
  { id: 'binance', iconFile: 'binance.svg' },
];

function findBrandIconConfig(iconFile) {
  for (const config of BRAND_ICONS) {
    if (config.iconFile === iconFile) return config;
  }
  return null;
}

const cases = [
  ['apple.svg', (c) => c && c.monochrome === true && c.scale === undefined, 'apple: monochrome true, no scale'],
  ['github.svg', (c) => c && c.monochrome === true && c.scale === 1.3, 'github: monochrome true, scale 1.3'],
  ['synology.svg', (c) => c && c.monochrome === undefined && c.scale === 1.3, 'synology: no monochrome, scale 1.3'],
  ['huawei.svg', (c) => c && c.dimOpacityInDark === 0.85 && c.monochrome === undefined, 'huawei: dimOpacityInDark 0.85, no monochrome'],
  ['binance.svg', (c) => c && c.monochrome === undefined && c.dimOpacityInDark === undefined && c.scale === undefined, 'binance: no new fields set (unaffected icon)'],
  ['nonexistent.svg', (c) => c === null, 'unknown iconFile returns null'],
];

let failed = 0;
for (const [iconFile, check, label] of cases) {
  const result = findBrandIconConfig(iconFile);
  const ok = check(result);
  if (!ok) failed++;
  console.log(`${ok ? 'PASS' : 'FAIL'} ${label} — findBrandIconConfig(${JSON.stringify(iconFile)}) = ${JSON.stringify(result)}`);
}
process.exit(failed === 0 ? 0 : 1);
EOF
node /private/tmp/claude-501/-Users-xiaoan-Documents-code-ArcaneKey/008f159b-2d46-43c4-aaf0-7abf8222426a/scratchpad/verify-icon-lookup.js
```

Expected: all 6 lines print `PASS`, exit code `0`. If any print `FAIL`, fix the mismatch in the real `BrandIcons.ets` file from Step 1/2 (not the mirror script), then re-run.

- [ ] **Step 5: Delete the temporary verification script**

```bash
rm /private/tmp/claude-501/-Users-xiaoan-Documents-code-ArcaneKey/008f159b-2d46-43c4-aaf0-7abf8222426a/scratchpad/verify-icon-lookup.js
```

- [ ] **Step 6: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/ets/model/BrandIcons.ets
git commit -m "feat(harmonyos): add monochrome/dim/scale fields to BrandIconConfig"
```

---

### Task 2: Apply the visual-polish fields in Logo.ets

**Files:**
- Modify: `harmonyos/entry/src/main/ets/components/Logo.ets` (current full content shown below)

**Interfaces:**
- Consumes: `findBrandIconConfig(iconFile: string): BrandIconConfig | null` and the `BrandIconConfig` interface (with `monochrome?`, `dimOpacityInDark?`, `scale?`) from `harmonyos/entry/src/main/ets/model/BrandIcons.ets` (Task 1). Also consumes existing `matchBrandIcon(brand: string, account?: string): string | null` from `harmonyos/entry/src/main/ets/utils/BrandIconMatcher.ets` (unchanged, from the prior feature).
- Produces: no new exports — `Logo`'s existing `@Prop` interface (`brand`, `accentColor`, `account`, `logoSize`, `isDark`) is unchanged; `TokenCard.ets`, `ScanView.ets`, and the two `Index.ets` call sites keep working without modification.

Current file content (read it yourself before editing):

```typescript
import display from '@ohos.display';
import { matchBrandIcon } from '../utils/BrandIconMatcher';

@Component
export struct Logo {
  @Watch('redraw') @Prop brand: string = '';
  @Watch('redraw') @Prop accentColor: string = '#4080D0';
  @Prop account: string = '';
  @Prop logoSize: number = 40;
  @Prop isDark: boolean = true;

  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private ready: boolean = false;

  private lightColor(): string {
    const r = parseInt(this.accentColor.slice(1, 3), 16);
    const g = parseInt(this.accentColor.slice(3, 5), 16);
    const b = parseInt(this.accentColor.slice(5, 7), 16);
    const lr = Math.min(255, Math.round(r + (255 - r) * 0.60));
    const lg = Math.min(255, Math.round(g + (255 - g) * 0.60));
    const lb = Math.min(255, Math.round(b + (255 - b) * 0.60));
    return '#' + lr.toString(16).padStart(2, '0') + lg.toString(16).padStart(2, '0') + lb.toString(16).padStart(2, '0');
  }

  private draw(): void {
    const s = this.logoSize;
    const density = display.getDefaultDisplaySync().densityPixels;
    const letter = (this.brand || '?')[0].toUpperCase();
    this.ctx.clearRect(0, 0, s, s);
    const grad = this.ctx.createLinearGradient(0, s, s, 0);
    grad.addColorStop(0, this.accentColor);
    grad.addColorStop(1, this.lightColor());
    this.ctx.fillStyle = grad;
    // ctx.font px = physical pixels; multiply by density to match vp coordinate space
    this.ctx.font = `bold ${Math.round(s * 0.46 * density)}px sans-serif`;
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'middle';
    this.ctx.fillText(letter, s / 2, s / 2);
  }

  redraw(): void {
    if (this.ready) this.draw();
  }

  build() {
    Stack() {
      if (matchBrandIcon(this.brand, this.account)) {
        Image($rawfile('brand-icons/' + matchBrandIcon(this.brand, this.account)))
          .width(this.logoSize * 0.62)
          .height(this.logoSize * 0.62)
          .objectFit(ImageFit.Contain)
      } else {
        Canvas(this.ctx)
          .width(this.logoSize)
          .height(this.logoSize)
          .onReady(() => {
            this.ready = true;
            this.draw();
          })
      }
    }
    .width(this.logoSize)
    .height(this.logoSize)
    .borderRadius(this.logoSize * 0.28)
    .backgroundColor(this.accentColor + (this.isDark ? '1a' : '28'))
    .border({ width: 1.5, color: this.accentColor + (this.isDark ? '44' : '55') })
  }
}
```

- [ ] **Step 1: Add the import**

Change the import line:

```typescript
import { matchBrandIcon } from '../utils/BrandIconMatcher';
```

to:

```typescript
import { matchBrandIcon } from '../utils/BrandIconMatcher';
import { findBrandIconConfig } from '../model/BrandIcons';
```

- [ ] **Step 2: Add a helper method that resolves the matched icon's config once per build**

Add this private method, placed after `lightColor()` and before `draw()`:

```typescript
  private matchedIconConfig(): BrandIconConfig | null {
    const iconFile = matchBrandIcon(this.brand, this.account);
    if (!iconFile) {
      return null;
    }
    return findBrandIconConfig(iconFile);
  }
```

You also need the `BrandIconConfig` type import. Change the import block from Step 1 to:

```typescript
import { matchBrandIcon } from '../utils/BrandIconMatcher';
import { findBrandIconConfig, BrandIconConfig } from '../model/BrandIcons';
```

- [ ] **Step 3: Replace `build()` to apply the three fields**

Replace the existing `build()` method with:

```typescript
  build() {
    Stack() {
      if (this.matchedIconConfig()) {
        Image($rawfile('brand-icons/' + this.matchedIconConfig()!.iconFile))
          .width(this.logoSize * 0.62 * (this.matchedIconConfig()!.scale ?? 1))
          .height(this.logoSize * 0.62 * (this.matchedIconConfig()!.scale ?? 1))
          .objectFit(ImageFit.Contain)
          .fillColor(this.matchedIconConfig()!.monochrome ? this.accentColor : undefined)
          .opacity(this.isDark ? (this.matchedIconConfig()!.dimOpacityInDark ?? 1) : 1)
      } else {
        Canvas(this.ctx)
          .width(this.logoSize)
          .height(this.logoSize)
          .onReady(() => {
            this.ready = true;
            this.draw();
          })
      }
    }
    .width(this.logoSize)
    .height(this.logoSize)
    .borderRadius(this.logoSize * 0.28)
    .backgroundColor(this.accentColor + (this.isDark ? '1a' : '28'))
    .border({ width: 1.5, color: this.accentColor + (this.isDark ? '44' : '55') })
  }
```

Leave `lightColor()`, `draw()`, `redraw()`, and the `@Watch`/`@Prop`/`ctx`/`ready` fields untouched — the no-match (letter-avatar) branch is unaffected by this task.

- [ ] **Step 4: Build the project**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey/harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
```

Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 5: If the build fails on `.fillColor(this.matchedIconConfig()!.monochrome ? this.accentColor : undefined)`**

(e.g. a type error because `fillColor` doesn't accept `undefined`, or a non-null-assertion restriction under ArkTS strict mode), replace that single line with an `if`/`else` split instead of a ternary, and drop the non-null assertions in favor of a local `const`. Replace the whole `Image(...)` chain in `build()` with:

```typescript
      if (this.matchedIconConfig()) {
        Image($rawfile('brand-icons/' + this.matchedIconConfig()!.iconFile))
          .width(this.logoSize * 0.62 * (this.matchedIconConfig()!.scale ?? 1))
          .height(this.logoSize * 0.62 * (this.matchedIconConfig()!.scale ?? 1))
          .objectFit(ImageFit.Contain)
          .opacity(this.isDark ? (this.matchedIconConfig()!.dimOpacityInDark ?? 1) : 1)
      } else {
```

and inside the same `if` block, before the `Image(...)` call, compute the config once and branch on `monochrome` explicitly:

```typescript
      if (this.matchedIconConfig()) {
        if (this.matchedIconConfig()!.monochrome) {
          Image($rawfile('brand-icons/' + this.matchedIconConfig()!.iconFile))
            .width(this.logoSize * 0.62 * (this.matchedIconConfig()!.scale ?? 1))
            .height(this.logoSize * 0.62 * (this.matchedIconConfig()!.scale ?? 1))
            .objectFit(ImageFit.Contain)
            .fillColor(this.accentColor)
            .opacity(this.isDark ? (this.matchedIconConfig()!.dimOpacityInDark ?? 1) : 1)
        } else {
          Image($rawfile('brand-icons/' + this.matchedIconConfig()!.iconFile))
            .width(this.logoSize * 0.62 * (this.matchedIconConfig()!.scale ?? 1))
            .height(this.logoSize * 0.62 * (this.matchedIconConfig()!.scale ?? 1))
            .objectFit(ImageFit.Contain)
            .opacity(this.isDark ? (this.matchedIconConfig()!.dimOpacityInDark ?? 1) : 1)
        }
      } else {
```

Rebuild with the Step 4 command. Expected: `BUILD SUCCESSFUL`. Only apply this contingency if the *specific* line fails to compile — if the build fails for an unrelated reason, diagnose that error on its own merits instead.

- [ ] **Step 6: Manual on-device verification**

Run the app on a simulator/device. In both dark and light theme:
- Add tokens with issuer `Apple`, `OpenAI`, `GitHub`, `TikTok` — confirm each renders tinted to the current accent color (change the app's theme color in settings and confirm these 4 icons visibly change color with it).
- Add a token with issuer `Synology` and one with `GitHub` — confirm both render visibly larger than before (compare against an unrelated icon like `Binance` at the same `logoSize` to eyeball the size difference).
- Add a token with issuer `Huawei` — confirm the red looks softer in dark theme, and unchanged (still full-strength red) in light theme.
- Add a token with an unaffected brand (e.g. `Claude` or `WhatsApp`) — confirm it still renders in its own real brand color, unchanged from before this task.

- [ ] **Step 7: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/ets/components/Logo.ets
git commit -m "feat(harmonyos): apply monochrome tint, dark-mode dimming, and size scale to brand icons"
```

---

## Self-Review Notes

- **Spec coverage:** monochrome tinting (Task 1 field + Task 2 `.fillColor()`), Huawei dark-mode dimming (Task 1 field + Task 2 `.opacity()`), GitHub/Synology enlargement (Task 1 field + Task 2 width/height multiplier) all map directly to the design spec's three fixes. The spec's "verification" section is covered by Task 1 Step 4 (lookup logic) and Task 2 Step 6 (on-device visual check).
- **Placeholder scan:** no TBD/TODO; every step has literal file paths, full code, and exact commands with expected output. Task 2 Step 5's contingency is a genuine technical fallback (an ArkTS strict-mode ternary/ResourceColor-typing risk), not a vague placeholder — it gives the complete replacement code.
- **Type consistency:** `findBrandIconConfig(iconFile: string): BrandIconConfig | null` (Task 1) is called identically in Task 2's `matchedIconConfig()`. The three field names (`monochrome`, `dimOpacityInDark`, `scale`) match between Task 1's interface/data and Task 2's usage. `matchBrandIcon(brand, account)`'s existing signature is unchanged and reused as-is.
