# 小程序品牌 Logo 本地匹配方案

## 目标

将今天在 HarmonyOS 端已完成并合并到 `main` 的"本地品牌 logo 匹配"功能移植到微信小程序端：token 的 `brand`/`account` 匹配到已知品牌时，用真实品牌 logo 替代当前的"首字母渐变头像"；未匹配到时完全保留现有展示方式。不涉及网络请求，不涉及鸿蒙端后续又撤销的 `fillColor`/`opacity` 特效（那部分因为在真机上把 Amazon/Synology 渲染成纯黑块而被完全去掉，最终鸿蒙方案是"匹配到就用统一白底展示"，本次移植直接对齐这个最终版本）。

## 范围

- 只涉及 `miniprogram/`（`components/logo/`、新建的 `utils/brandIcons.js`、`components/token-card/`、`pages/index/index.wxml` 里另外两处 `<logo>` 调用）。
- 不改动 `harmonyos/` 或 `docs/` 之外的任何文件。
- 不重新引入鸿蒙端已经撤销的按图标着色/调暗的特效——匹配到的图标统一走"白底 + logo"展示，不随主题变化。
- 不做除"品牌 logo 匹配"之外的其他鸿蒙功能移植（如账号头像修复、会员卡片等，那些是鸿蒙特有的 bug，不涉及小程序）。

## 素材

小程序 `<image>` 组件对 SVG 支持不稳定（官方不推荐，多色路径的 SVG 容易渲染异常）。按用户要求，第一步先直接用 SVG 试，在 DevTools 里目测效果；如果渲染有问题，再转 PNG（后续单独处理，不在本次实施范围内，但设计上要让替换 PNG 时改动最小——图标始终通过统一的 `iconPath` 字符串引用，格式后缀集中在一处拼接）。

素材来源：`harmonyos/entry/src/main/resources/rawfile/brand-icons/`（已经是 33 个 ASCII 安全命名的 svg，鸿蒙端已经处理过一轮改名/清理），原样拷贝到 `miniprogram/images/brand-icons/`。

## 匹配数据与逻辑

新建 `miniprogram/utils/brandIcons.js`，风格延续小程序现有 `utils/` 目录约定（每个文件是一个独立职责单元，不像鸿蒙端拆成 `model/`+`utils/` 两层）：

```javascript
// BRAND_ICONS: 与鸿蒙端 harmonyos/entry/src/main/ets/model/BrandIcons.ets 的
// BRAND_ICONS 数组完全一致的 33 条数据，同样保留 emailDomains、scale 字段，
// 不包含鸿蒙端已经撤销的 monochrome / dimOpacityInDark 字段。
// 顺序即优先级：更具体的条目排在通用条目之前（如 gcp 在 google 之前）。
const BRAND_ICONS = [ /* 33 条，见实施计划 */ ];

function normalize(input) {
  return input.toLowerCase().replace(/[\s:\-_.]/g, '');
}

function matchByEmailDomain(account) {
  const lowerAccount = (account || '').toLowerCase().trim();
  for (const config of BRAND_ICONS) {
    if (!config.emailDomains) continue;
    for (const domain of config.emailDomains) {
      if (lowerAccount.endsWith('@' + domain)) return config.iconFile;
    }
  }
  return null;
}

function matchBrandIcon(brand, account) {
  if (brand) {
    const normalizedBrand = normalize(brand);
    for (const config of BRAND_ICONS) {
      for (const keyword of config.matchKeywords) {
        if (normalizedBrand.includes(normalize(keyword))) return config.iconFile;
      }
    }
  }
  if (account) return matchByEmailDomain(account);
  return null;
}

function findBrandIconConfig(iconFile) {
  for (const config of BRAND_ICONS) {
    if (config.iconFile === iconFile) return config;
  }
  return null;
}

module.exports = { BRAND_ICONS, matchBrandIcon, findBrandIconConfig };
```

逻辑与鸿蒙端 `BrandIconMatcher.ets` 一一对应：先按 `brand` 归一化包含匹配，找不到再按 `account` 的邮箱后缀匹配（163.com/126.com/yeah.net → 网易邮箱）。

## Logo 组件改造

`miniprogram/components/logo/logo.js`：
- `properties` 新增 `account: { type: String, value: '' }`。
- `observers` 里的 `'brand, size'` 改为监听 `'brand, account, size'`，计算逻辑改为：先调用 `matchBrandIcon(brand, account)`；
  - 匹配到 → 用 `findBrandIconConfig(iconFile)` 取出 `scale`（未设置则为 1），计算 `iconPath = '/images/brand-icons/' + iconFile`、图标渲染尺寸 `iconSize = size * 0.62 * scale`、容器仍是 `size x size` 的白底圆角方块；
  - 未匹配到 → 完全保留现状（`BRAND_COLORS` 查表、字母、渐变色 style 字符串），不做任何改动。
- `attached()` 生命周期里的重复计算逻辑同步做同样的改动（现状就是 observers 和 attached 里各写了一遍同样的计算，保持这个已有的重复模式，不做额外重构）。

`miniprogram/components/logo/logo.wxml`：

```xml
<view class="logo-wrap" style="{{style}}" wx:if="{{!iconPath}}">{{letter}}</view>
<view class="logo-icon-wrap" style="{{iconWrapStyle}}" wx:else>
  <image class="logo-icon-img" src="{{iconPath}}" style="{{iconImgStyle}}" mode="aspectFit"/>
</view>
```

`miniprogram/components/logo/logo.wxss` 新增 `.logo-icon-wrap`（白底、圆角、浅灰描边，`display:flex; align-items:center; justify-content:center;`）和 `.logo-icon-img`。容器的圆角/白底/描边尺寸由 `iconWrapStyle`（内联 style 字符串，与现有 `style` 字段用法一致）驱动，保持与现有代码同样"JS 里拼 style 字符串、WXML 只做绑定"的写法。

## 调用点改动

- `miniprogram/components/token-card/token-card.wxml`：`<logo brand="{{token.brand}}" size="{{42}}"/>` → 加上 `account="{{token.account}}"`。
- `miniprogram/pages/index/index.wxml` 第 129 行（扫码预览）：`<logo brand="{{scanForm.brand}}" size="{{36}}"/>` → 加上 `account="{{scanForm.account}}"`。
- `miniprogram/pages/index/index.wxml` 第 243 行（编辑弹窗）：`<logo brand="{{editForm.brand || editToken.brand || ''}}" size="{{64}}"/>` → 加上 `account="{{editForm.account || editToken.account || ''}}"`。

## 验证

小程序端目前没有任何测试框架（与鸿蒙端一致），延续同样的验证方式：

1. `matchBrandIcon`/`findBrandIconConfig` 是纯函数，用临时 Node 脚本手动验证一批 issuer/account 字符串（复用鸿蒙端已经验证过的用例：`GitHub`、`github:myname`、`币安`、`群晖DSM登录`、`阿里云OSS`、`zhangsan@163.com`、无法匹配的自定义文本）。验证完删除脚本。
2. 在微信开发者工具里跑一遍：添加 GitHub、Synology、网易邮箱（账号填 `xxx@163.com`）token，确认显示真实 logo（白底）而不是字母头像；添加一个无法匹配的品牌，确认字母头像不变。
3. 目测确认 SVG 在 `<image>` 里渲染是否正常（这是本次设计明确标注的风险点，若渲染异常则后续单独排期转 PNG，不阻塞本次功能验收——只要匹配逻辑和白底容器结构是对的）。
