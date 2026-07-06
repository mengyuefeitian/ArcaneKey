# HarmonyOS 品牌图标视觉细节修正方案

## 背景

上一版本（2026-07-06 的 HarmonyOS 品牌 logo 本地匹配功能）上线后，用户在真机上做了视觉验证，发现三个问题：

1. **Apple 图标在深色背景下几乎看不清**——`apple.svg` 没有固有品牌色（无 `fill` 属性，默认黑色剪影），在深色卡片背景上对比度很差。
2. **GitHub 和 Synology 的图标显得偏小**——这两个图标本身是圆形徽章造型，在当前 `logoSize * 0.62` 的统一缩放下，视觉占比比其他扁平图形图标小。
3. **华为红色在深色背景下过于刺眼**——`huawei.svg` 是真实品牌色（`#EA020A`），色彩本身没问题，但在深色主题下饱和度/亮度显得突兀。

对 33 个已bundled 的品牌 SVG 做了一次颜色结构扫描（统计每个文件的 `fill` 属性种类），确认：

- 真正"无固有品牌色、只是黑色剪影"的只有 4 个：`apple`（无 fill）、`openai`（无 fill）、`github`（`fill="#231F20"` 近乎黑）、`tiktok`（`fill="#31303D"` 近乎黑）。这 4 个应该跟随主题色变化。
- 其余单色 SVG（`dingtalk` 蓝、`facebook` 蓝、`whatsapp` 绿、`claude` 橙、`huawei` 红等）都是真实品牌色，不应被主题色替换——否则会失去品牌辨识度。
- `synology.svg` 是黑底白字的双色徽章（`fill="#020202"` + 3处 `fill="#FFFFFF"`），不属于"纯色"范畴，只是显示尺寸偏小的问题，与颜色无关。

## 范围

- 只涉及 HarmonyOS 端（`harmonyos/entry/src/main/ets/model/BrandIcons.ets`、`harmonyos/entry/src/main/ets/components/Logo.ets`）。
- 不改动 SVG 素材文件本身，不改动匹配算法（`BrandIconMatcher.ets`）。
- 不涉及 miniprogram 端。

## 设计

延续上一版本 `BrandIconConfig` 的数据驱动扩展模式（已有 `emailDomains?` 先例），新增三个可选字段：

```typescript
export interface BrandIconConfig {
  id: string;
  officialName: string;
  iconFile: string;
  matchKeywords: string[];
  emailDomains?: string[];
  // 无固有品牌色的黑色剪影图标：渲染时跟随当前主题色（this.accentColor）
  monochrome?: boolean;
  // 深色主题下降低不透明度，缓解高饱和品牌色的刺眼感；浅色主题不受影响
  dimOpacityInDark?: number;
  // 相对默认渲染尺寸（this.logoSize * 0.62）的倍数，用于图形本身自带较多留白
  // （如圆形徽章）的图标；不设置则使用默认倍数 1.0
  scale?: number;
}
```

具体赋值：

- `apple`、`openai`、`github`、`tiktok` → `monochrome: true`
- `huawei` → `dimOpacityInDark: 0.85`
- `github`、`synology` → `scale: 1.3`（即渲染尺寸约为 `logoSize * 0.62 * 1.3` ≈ `logoSize * 0.81`）

`Logo.ets` 渲染命中图标的分支目前是：

```typescript
Image($rawfile('brand-icons/' + matchBrandIcon(this.brand, this.account)))
  .width(this.logoSize * 0.62)
  .height(this.logoSize * 0.62)
  .objectFit(ImageFit.Contain)
```

改为：先查一次 `matchBrandIcon()` 结果对应的 `BrandIconConfig`（而不仅仅是 `iconFile` 字符串），再根据配置里的 `monochrome`/`dimOpacityInDark`/`scale` 决定要不要加 `.fillColor(this.accentColor)`、`.opacity(dimOpacityInDark)`（仅当 `this.isDark` 为真时）、以及把宽高乘上 `scale`。这意味着 `BrandIcons.ets` 需要新增一个"根据 `iconFile` 反查完整 config"的辅助函数（或者让 `matchBrandIcon` 直接返回整个 config 而不是裸的 `iconFile` 字符串——但那样要改函数签名和所有调用点）。为了不破坏已经稳定工作的 `matchBrandIcon` 契约（其余 4 个调用点都只关心 `iconFile` 字符串），采用前者：新增一个轻量查找函数，`Logo.ets` 拿到 `iconFile` 之后再查一次配置。

```typescript
// BrandIcons.ets 新增
export function findBrandIconConfig(iconFile: string): BrandIconConfig | null {
  for (let i = 0; i < BRAND_ICONS.length; i++) {
    if (BRAND_ICONS[i].iconFile === iconFile) {
      return BRAND_ICONS[i];
    }
  }
  return null;
}
```

`Logo.ets` 在渲染分支里调用 `findBrandIconConfig(iconFile)` 拿到完整 config，再按上面三个字段决定渲染细节。未设置的字段保持当前行为不变（`monochrome` 缺省不加 `fillColor`、`dimOpacityInDark` 缺省不加 `opacity`、`scale` 缺省为 `1`），因此其余 29 个图标的渲染结果与改动前完全一致。

## 验证

项目仍然没有测试框架，延续上次的验证方式：

1. `findBrandIconConfig()` 是纯函数，用临时 Node 脚本手动验证：4 个 monochrome 图标能查到 `monochrome: true`，huawei 能查到 `dimOpacityInDark: 0.85`，github/synology 能查到 `scale: 1.3`，一个不存在的 `iconFile`（如 `'nonexistent.svg'`）返回 `null`。验证完删除脚本。
2. 跑一次 `assembleApp` 完整构建确认无编译错误。
3. 真机/模拟器上添加 Apple、GitHub、Synology、Huawei 各一个 token，深色和浅色主题下各看一遍，确认：
   - Apple/GitHub/TikTok/OpenAI 图标颜色跟随当前主题色（切换主题色后图标颜色也跟着变）
   - GitHub/Synology 图标视觉上比之前更大、更清楚
   - Huawei 红色在深色主题下没有之前刺眼，浅色主题下不变
   - 其余未修改的图标（如 binance、claude、feishu 等）显示效果与改动前一致，没有跟着变色或变形
