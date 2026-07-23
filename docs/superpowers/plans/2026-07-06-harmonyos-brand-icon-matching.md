# HarmonyOS Brand Icon Local-Matching Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the letter-avatar fallback in the HarmonyOS `Logo` component with a real brand SVG logo whenever the token's `brand` string matches a locally bundled icon, with zero network calls and zero changes to stored token data.

**Architecture:** A static config array (`BrandIconConfig[]`) maps brand ids to normalized match keywords and a rawfile SVG filename. A pure function `matchBrandIcon(brand: string): string | null` normalizes the input and does ordered `includes` matching against the config. `Logo.ets` calls this function at render time and swaps its Canvas letter-avatar for an `Image($rawfile(...))` when a match is found; renders nothing new (falls through to existing behavior) when it isn't.

**Tech Stack:** ArkTS (HarmonyOS 6.1 / API 23), ArkUI (`Image`, `$rawfile`), no new dependencies.

## Global Constraints

- Platform: HarmonyOS only (`harmonyos/entry/src/main/ets/`). Do not touch `miniprogram/`.
- Do not add fields to the `Token` interface (`harmonyos/entry/src/main/ets/model/Token.ets`) and do not persist match results.
- Do not normalize/rewrite the user-facing `brand` display text — only the icon changes.
- Matching is `includes`-only after normalization (lowercase + strip whitespace/`:`/`-`/`_`/`.`). No Levenshtein distance, no domain-suffix extraction, in this pass.
- rawfile filenames must be ASCII lowercase with hyphens only — no spaces, no non-ASCII characters, no `+`.
- No new test framework (`hypium` stays unused) — verify with a temporary plain-JS mirror script (deleted after use) plus a full `assembleApp` build, per this repo's CLAUDE.md HarmonyOS rules.
- Every task that touches `.ets` files ends with a successful `assembleApp` build. A task is not done if the build fails.
- ArkTS strict mode: no `any`, every `@State`/`@Prop` field keeps its existing type/initializer, no anonymous object literal types.

---

### Task 1: Bundle brand icon SVGs into rawfile

**Files:**
- Create: `harmonyos/entry/src/main/resources/rawfile/brand-icons/*.svg` (33 files)
- Source: `/Users/xiaoan/Documents/code/ArcaneKey/logo/*.svg` (33 files)

**Interfaces:**
- Produces: 33 files at `harmonyos/entry/src/main/resources/rawfile/brand-icons/<id>.svg`, where `<id>` matches the `iconFile` values used in Task 2's `BRAND_ICONS` config (see the rename table below). This is the exact path fragment (`brand-icons/<id>.svg`) that Task 4 passes into `$rawfile()`.

- [ ] **Step 1: Create the target directory**

```bash
mkdir -p /Users/xiaoan/Documents/code/ArcaneKey/harmonyos/entry/src/main/resources/rawfile/brand-icons
```

- [ ] **Step 2: Copy files that need renaming (non-ASCII / spaces / `+` in source name)**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
cp "logo/阿里云.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/alibaba-cloud.svg
cp "logo/抖音.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/douyin.svg
cp "logo/百度云.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/baidu-cloud.svg
cp "logo/钉钉.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/dingtalk.svg
cp "logo/网易邮箱.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/netease-mail.svg
cp "logo/腾讯云.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/tencent-cloud.svg
cp "logo/新浪.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/sina.svg
cp "logo/网易.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/netease.svg
cp "logo/飞书.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/feishu.svg
cp "logo/贝锐科技彩色logo.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/beirui.svg
cp "logo/synology+dsm.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/synology-dsm.svg
cp "logo/ToDesk.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/todesk.svg
cp "logo/Anthropic.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/anthropic.svg
cp "logo/Instagram.svg" harmonyos/entry/src/main/resources/rawfile/brand-icons/instagram.svg
```

- [ ] **Step 3: Copy files that are already safely named (lowercase to be consistent)**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
for f in amazon apple azure binance claude facebook gcp github godaddy google huawei microsoft openai paypal synology teamviewer tiktok twitter whatsapp; do
  cp "logo/${f}.svg" "harmonyos/entry/src/main/resources/rawfile/brand-icons/${f}.svg"
done
```

- [ ] **Step 4: Verify all 33 files are present**

```bash
ls /Users/xiaoan/Documents/code/ArcaneKey/harmonyos/entry/src/main/resources/rawfile/brand-icons | wc -l
```

Expected: `33`

- [ ] **Step 5: Verify no filename has spaces, uppercase, or non-ASCII characters**

```bash
ls /Users/xiaoan/Documents/code/ArcaneKey/harmonyos/entry/src/main/resources/rawfile/brand-icons | grep -E '[^a-z0-9.-]'
```

Expected: no output (empty match means all names are clean)

- [ ] **Step 6: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/resources/rawfile/brand-icons/
git commit -m "feat(harmonyos): bundle brand icon SVGs into rawfile"
```

---

### Task 2: Brand icon config data model

**Files:**
- Create: `harmonyos/entry/src/main/ets/model/BrandIcons.ets`

**Interfaces:**
- Consumes: nothing (pure data file).
- Produces: `BrandIconConfig` interface (`id: string`, `officialName: string`, `iconFile: string`, `matchKeywords: string[]`) and `BRAND_ICONS: BrandIconConfig[]` (33 entries), consumed by Task 3's `matchBrandIcon()`.

- [ ] **Step 1: Write the config file**

```typescript
// harmonyos/entry/src/main/ets/model/BrandIcons.ets

export interface BrandIconConfig {
  id: string;
  officialName: string;
  iconFile: string;
  matchKeywords: string[];
}

// Order is priority: more specific entries must come before generic ones
// that would otherwise also match the same input (e.g. 'gcp' before
// 'google', 'synology-dsm' before 'synology'). The first match wins.
export const BRAND_ICONS: BrandIconConfig[] = [
  { id: 'gcp', officialName: 'Google Cloud', iconFile: 'gcp.svg', matchKeywords: ['gcp', 'google cloud', 'googlecloud'] },
  { id: 'google', officialName: 'Google', iconFile: 'google.svg', matchKeywords: ['google', 'gmail'] },
  { id: 'synology-dsm', officialName: 'Synology DSM', iconFile: 'synology-dsm.svg', matchKeywords: ['dsm', 'synology dsm', 'quickconnect'] },
  { id: 'synology', officialName: 'Synology', iconFile: 'synology.svg', matchKeywords: ['synology', '群晖'] },
  { id: 'netease-mail', officialName: '网易邮箱', iconFile: 'netease-mail.svg', matchKeywords: ['网易邮箱', '163', '126', 'netease mail', 'yeah.net'] },
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

- [ ] **Step 2: Verify the array length matches the bundled icon count**

```bash
grep -c "iconFile:" /Users/xiaoan/Documents/code/ArcaneKey/harmonyos/entry/src/main/ets/model/BrandIcons.ets
```

Expected: `33`

- [ ] **Step 3: Verify every `iconFile` has a corresponding file from Task 1**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
grep -oE "iconFile: '[a-z0-9.-]+\.svg'" harmonyos/entry/src/main/ets/model/BrandIcons.ets | sed -E "s/iconFile: '(.*)'/\1/" | sort > /tmp/config-icons.txt
ls harmonyos/entry/src/main/resources/rawfile/brand-icons | sort > /tmp/bundled-icons.txt
diff /tmp/config-icons.txt /tmp/bundled-icons.txt
```

Expected: no output (both lists are identical)

- [ ] **Step 4: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/ets/model/BrandIcons.ets
git commit -m "feat(harmonyos): add BrandIcons config for local logo matching"
```

---

### Task 3: Matching function with manual verification

**Files:**
- Create: `harmonyos/entry/src/main/ets/utils/BrandIconMatcher.ets`

**Interfaces:**
- Consumes: `BRAND_ICONS: BrandIconConfig[]` from `harmonyos/entry/src/main/ets/model/BrandIcons.ets` (Task 2).
- Produces: `matchBrandIcon(brand: string): string | null`, consumed by Task 4's `Logo.ets`. Returns the matched `iconFile` value (e.g. `'github.svg'`) or `null`.

- [ ] **Step 1: Write the matcher**

```typescript
// harmonyos/entry/src/main/ets/utils/BrandIconMatcher.ets
import { BRAND_ICONS } from '../model/BrandIcons';

function normalize(input: string): string {
  return input.toLowerCase().replace(/[\s:\-_.]/g, '');
}

export function matchBrandIcon(brand: string): string | null {
  if (!brand) {
    return null;
  }
  const normalizedBrand = normalize(brand);
  for (let i = 0; i < BRAND_ICONS.length; i++) {
    const config = BRAND_ICONS[i];
    for (let j = 0; j < config.matchKeywords.length; j++) {
      if (normalizedBrand.includes(normalize(config.matchKeywords[j]))) {
        return config.iconFile;
      }
    }
  }
  return null;
}
```

- [ ] **Step 2: Manually verify the matching logic with a temporary plain-JS mirror script**

This project has no test runner (see Global Constraints), so verify the algorithm with a standalone Node script that mirrors the same logic and data, run outside the ArkTS build. This is throwaway — it is deleted in Step 4, not committed.

```bash
mkdir -p /private/tmp/claude-501/-Users-xiaoan-Documents-code-ArcaneKey/008f159b-2d46-43c4-aaf0-7abf8222426a/scratchpad
cat > /private/tmp/claude-501/-Users-xiaoan-Documents-code-ArcaneKey/008f159b-2d46-43c4-aaf0-7abf8222426a/scratchpad/verify-brand-match.js <<'EOF'
const BRAND_ICONS = [
  { id: 'gcp', iconFile: 'gcp.svg', matchKeywords: ['gcp', 'google cloud', 'googlecloud'] },
  { id: 'google', iconFile: 'google.svg', matchKeywords: ['google', 'gmail'] },
  { id: 'synology-dsm', iconFile: 'synology-dsm.svg', matchKeywords: ['dsm', 'synology dsm', 'quickconnect'] },
  { id: 'synology', iconFile: 'synology.svg', matchKeywords: ['synology', '群晖'] },
  { id: 'netease-mail', iconFile: 'netease-mail.svg', matchKeywords: ['网易邮箱', '163', '126', 'netease mail', 'yeah.net'] },
  { id: 'netease', iconFile: 'netease.svg', matchKeywords: ['网易', 'netease'] },
  { id: 'alibaba-cloud', iconFile: 'alibaba-cloud.svg', matchKeywords: ['阿里云', 'alibabacloud', 'aliyun'] },
  { id: 'binance', iconFile: 'binance.svg', matchKeywords: ['binance', '币安'] },
  { id: 'github', iconFile: 'github.svg', matchKeywords: ['github'] },
];

function normalize(input) {
  return input.toLowerCase().replace(/[\s:\-_.]/g, '');
}

function matchBrandIcon(brand) {
  if (!brand) return null;
  const normalizedBrand = normalize(brand);
  for (const config of BRAND_ICONS) {
    for (const keyword of config.matchKeywords) {
      if (normalizedBrand.includes(normalize(keyword))) {
        return config.iconFile;
      }
    }
  }
  return null;
}

const cases = [
  ['GitHub', 'github.svg'],
  ['github:myname', 'github.svg'],
  ['币安', 'binance.svg'],
  ['Binance Exchange', 'binance.svg'],
  ['群晖NAS', 'synology.svg'],
  ['群晖DSM登录', 'synology-dsm.svg'],
  ['阿里云OSS', 'alibaba-cloud.svg'],
  ['网易163邮箱', 'netease-mail.svg'],
  ['网易云音乐', 'netease.svg'],
  ['Google Cloud Console', 'gcp.svg'],
  ['My Personal Vault', null],
];

let failed = 0;
for (const [input, expected] of cases) {
  const actual = matchBrandIcon(input);
  const ok = actual === expected;
  if (!ok) failed++;
  console.log(`${ok ? 'PASS' : 'FAIL'} matchBrandIcon(${JSON.stringify(input)}) = ${JSON.stringify(actual)} (expected ${JSON.stringify(expected)})`);
}
process.exit(failed === 0 ? 0 : 1);
EOF
node /private/tmp/claude-501/-Users-xiaoan-Documents-code-ArcaneKey/008f159b-2d46-43c4-aaf0-7abf8222426a/scratchpad/verify-brand-match.js
```

Expected: every line printed as `PASS`, exit code `0`. If any line prints `FAIL`, fix the mismatch in `matchBrandIcon` or the `BRAND_ICONS` entry it points to (in the real `.ets` files from Task 2/Step 1) — the full `BRAND_ICONS` array in Task 2 is the source of truth, this script's shortened copy is only for the sample cases above.

- [ ] **Step 3: Re-run until all cases pass**

Re-run the `node` command from Step 2 after any fix. Do not proceed until output is all-`PASS`.

- [ ] **Step 4: Delete the temporary verification script**

```bash
rm /private/tmp/claude-501/-Users-xiaoan-Documents-code-ArcaneKey/008f159b-2d46-43c4-aaf0-7abf8222426a/scratchpad/verify-brand-match.js
```

- [ ] **Step 5: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/ets/utils/BrandIconMatcher.ets
git commit -m "feat(harmonyos): add matchBrandIcon local matching function"
```

---

### Task 4: Wire matching into the Logo component

**Files:**
- Modify: `harmonyos/entry/src/main/ets/components/Logo.ets`

**Interfaces:**
- Consumes: `matchBrandIcon(brand: string): string | null` from `harmonyos/entry/src/main/ets/utils/BrandIconMatcher.ets` (Task 3).
- Produces: no new exports — `Logo` keeps its existing `@Prop brand`, `@Prop accentColor`, `@Prop logoSize`, `@Prop isDark` interface used by `TokenCard.ets` and other callers.

Current file content (for reference, do not skip reading it before editing):

```typescript
import display from '@ohos.display';

@Component
export struct Logo {
  @Watch('redraw') @Prop brand: string = '';
  @Watch('redraw') @Prop accentColor: string = '#4080D0';
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
      Canvas(this.ctx)
        .width(this.logoSize)
        .height(this.logoSize)
        .onReady(() => {
          this.ready = true;
          this.draw();
        })
    }
    .width(this.logoSize)
    .height(this.logoSize)
    .borderRadius(this.logoSize * 0.28)
    .backgroundColor(this.accentColor + (this.isDark ? '1a' : '28'))
    .border({ width: 1.5, color: this.accentColor + (this.isDark ? '44' : '55') })
  }
}
```

- [ ] **Step 1: Add the import and a computed icon lookup**

Add this import at the top of `harmonyos/entry/src/main/ets/components/Logo.ets`, alongside the existing `display` import:

```typescript
import { matchBrandIcon } from '../utils/BrandIconMatcher';
```

- [ ] **Step 2: Replace `build()` to branch on the match result**

Replace the existing `build()` method with:

```typescript
  build() {
    Stack() {
      if (matchBrandIcon(this.brand)) {
        Image($rawfile('brand-icons/' + matchBrandIcon(this.brand)))
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
```

Leave `lightColor()`, `draw()`, `redraw()`, and the `@Watch`/`@Prop`/`ctx`/`ready` fields untouched — they still run for the no-match branch.

- [ ] **Step 3: Build the project**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey/harmonyos && DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  /Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon
```

Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: If the build fails specifically on the `$rawfile('brand-icons/' + matchBrandIcon(this.brand))` line** (e.g. "argument must be a compile-time constant" or similar), replace `build()`'s `Image` branch with a resolver function using a literal `switch`, since `$rawfile()` may not accept a runtime-concatenated string in this ArkTS version.

Add this function above `build()` in `Logo.ets`:

```typescript
  private resolveIconResource(iconFile: string): Resource | null {
    switch (iconFile) {
      case 'gcp.svg': return $rawfile('brand-icons/gcp.svg');
      case 'google.svg': return $rawfile('brand-icons/google.svg');
      case 'synology-dsm.svg': return $rawfile('brand-icons/synology-dsm.svg');
      case 'synology.svg': return $rawfile('brand-icons/synology.svg');
      case 'netease-mail.svg': return $rawfile('brand-icons/netease-mail.svg');
      case 'netease.svg': return $rawfile('brand-icons/netease.svg');
      case 'alibaba-cloud.svg': return $rawfile('brand-icons/alibaba-cloud.svg');
      case 'douyin.svg': return $rawfile('brand-icons/douyin.svg');
      case 'baidu-cloud.svg': return $rawfile('brand-icons/baidu-cloud.svg');
      case 'dingtalk.svg': return $rawfile('brand-icons/dingtalk.svg');
      case 'tencent-cloud.svg': return $rawfile('brand-icons/tencent-cloud.svg');
      case 'sina.svg': return $rawfile('brand-icons/sina.svg');
      case 'feishu.svg': return $rawfile('brand-icons/feishu.svg');
      case 'amazon.svg': return $rawfile('brand-icons/amazon.svg');
      case 'anthropic.svg': return $rawfile('brand-icons/anthropic.svg');
      case 'apple.svg': return $rawfile('brand-icons/apple.svg');
      case 'azure.svg': return $rawfile('brand-icons/azure.svg');
      case 'binance.svg': return $rawfile('brand-icons/binance.svg');
      case 'claude.svg': return $rawfile('brand-icons/claude.svg');
      case 'facebook.svg': return $rawfile('brand-icons/facebook.svg');
      case 'github.svg': return $rawfile('brand-icons/github.svg');
      case 'godaddy.svg': return $rawfile('brand-icons/godaddy.svg');
      case 'huawei.svg': return $rawfile('brand-icons/huawei.svg');
      case 'instagram.svg': return $rawfile('brand-icons/instagram.svg');
      case 'beirui.svg': return $rawfile('brand-icons/beirui.svg');
      case 'microsoft.svg': return $rawfile('brand-icons/microsoft.svg');
      case 'openai.svg': return $rawfile('brand-icons/openai.svg');
      case 'paypal.svg': return $rawfile('brand-icons/paypal.svg');
      case 'teamviewer.svg': return $rawfile('brand-icons/teamviewer.svg');
      case 'tiktok.svg': return $rawfile('brand-icons/tiktok.svg');
      case 'todesk.svg': return $rawfile('brand-icons/todesk.svg');
      case 'twitter.svg': return $rawfile('brand-icons/twitter.svg');
      case 'whatsapp.svg': return $rawfile('brand-icons/whatsapp.svg');
      default: return null;
    }
  }
```

Then change the `Image` line inside `build()` from:

```typescript
        Image($rawfile('brand-icons/' + matchBrandIcon(this.brand)))
```

to:

```typescript
        Image(this.resolveIconResource(matchBrandIcon(this.brand) as string))
```

Re-run the Step 3 build command. Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 5: Manual runtime verification**

Run the app on a simulator/device (via DevEco Studio or `hdc` per existing project workflow). Add a token with issuer `GitHub` and confirm the card shows the GitHub SVG logo instead of a "G" letter avatar. Add a second token with an issuer that matches nothing (e.g. `My Private Vault`) and confirm it still shows the letter-avatar gradient as before. Take a screenshot of both states.

- [ ] **Step 6: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/ets/components/Logo.ets
git commit -m "feat(harmonyos): render matched brand SVG logo in Logo component"
```

---

## Self-Review Notes

- **Spec coverage:** asset bundling (Task 1), config data (Task 2), matcher + verification (Task 3), Logo integration + fallback contingency (Task 4) all map directly to the design spec's five sections. The spec's "risk" callouts (dynamic `$rawfile` support, SVG rendering on dark background) are handled by Task 4 Step 4 (switch fallback) and Task 4 Step 5 (visual check) respectively.
- **Placeholder scan:** no TBD/TODO; every step has literal file paths, full code, and exact commands with expected output.
- **Type consistency:** `matchBrandIcon(brand: string): string | null` (Task 3) is called identically in Task 4. `BrandIconConfig`/`BRAND_ICONS` (Task 2) field names (`id`, `officialName`, `iconFile`, `matchKeywords`) are used consistently in Task 3's import and iteration.
