# HarmonyOS 品牌 Logo 本地匹配方案

## 目标

当前 `Logo.ets` 组件对所有 token 都渲染"首字母 + 主题色渐变"头像，没有真实品牌 logo。用户已在 `/Users/xiaoan/Documents/code/ArcaneKey/logo` 收集了 33 个品牌 SVG 素材。本次改动为 HarmonyOS 端引入**纯本地**的品牌名 → logo 匹配，命中则显示真实 logo，未命中则保留现有首字母头像作为兜底。不涉及任何联网请求，不涉及 miniprogram 端（后续视情况单独排期）。

## 范围

- **平台**：仅 HarmonyOS（`harmonyos/entry/src/main/ets/`）。
- **不改动**：`Token` 数据结构（不新增字段）、用户输入的 `brand` 显示文本（不做 official_name 规范化）、miniprogram 端。
- **不做**：Levenshtein 编辑距离模糊匹配（先做归一化+包含匹配，效果不够再加）、域名后缀提取匹配。

## 素材落地

拷贝 `/Users/xiaoan/Documents/code/ArcaneKey/logo/*.svg` 到 `harmonyos/entry/src/main/resources/rawfile/brand-icons/`。

rawfile 路径应避免非 ASCII 字符、空格、`+` 号，因此中文/特殊文件名统一重命名为小写英文连字符 id：

| 原文件名 | 目标文件名 |
|---|---|
| 阿里云.svg | alibaba-cloud.svg |
| 抖音.svg | douyin.svg |
| 百度云.svg | baidu-cloud.svg |
| 钉钉.svg | dingtalk.svg |
| 网易邮箱.svg | netease-mail.svg |
| 腾讯云.svg | tencent-cloud.svg |
| 新浪.svg | sina.svg |
| 网易.svg | netease.svg |
| 飞书.svg | feishu.svg |
| 贝锐科技彩色logo.svg | beirui.svg |
| synology+dsm.svg | synology-dsm.svg |
| ToDesk.svg | todesk.svg |
| Anthropic.svg | anthropic.svg |
| Instagram.svg | instagram.svg |

其余文件（`amazon`、`apple`、`azure`、`binance`、`claude`、`facebook`、`gcp`、`github`、`godaddy`、`google`、`huawei`、`microsoft`、`openai`、`paypal`、`synology`、`teamviewer`、`tiktok`、`twitter`、`whatsapp`）已是安全命名，原样拷贝（统一小写）。

## 配置数据

新建 `harmonyos/entry/src/main/ets/model/BrandIcons.ets`：

```typescript
export interface BrandIconConfig {
  id: string;
  officialName: string;
  iconFile: string;
  matchKeywords: string[];
}

export const BRAND_ICONS: BrandIconConfig[] = [
  // 更具体的条目排在通用条目之前 —— 数组顺序即匹配优先级，命中即停
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

关键词只收录能安全 `includes` 匹配、不易与其他品牌误撞的词（例如不收录单独的 `x`、`ig`、`ins` 这类过短/高歧义关键词）。用户实际使用中发现某个品牌总识别不到或误识别，再回来补充/调整 `matchKeywords` 或调整顺序。

## 匹配函数

新建 `harmonyos/entry/src/main/ets/utils/BrandIconMatcher.ets`：

```typescript
import { BRAND_ICONS } from '../model/BrandIcons';

function normalize(input: string): string {
  return input.toLowerCase().replace(/[\s:\-_.]/g, '');
}

export function matchBrandIcon(brand: string): string | null {
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
```

纯函数，无副作用，输入输出都是字符串/null，独立可验证。

## Logo 组件改造

`harmonyos/entry/src/main/ets/components/Logo.ets`：

- `build()` 中先调用 `matchBrandIcon(this.brand)`。
- 命中（返回非 null 的 `iconFile`）：在现有 `Stack` 容器内用 `Image($rawfile('brand-icons/' + iconFile))` 渲染，容器的圆角/背景色/边框样式保持不变，只是内容从 Canvas 换成 Image。
- 未命中（返回 `null`）：完全保留现有 Canvas 首字母渐变头像逻辑，不做任何改动。
- `@Watch('redraw')` 监听逻辑需要同时覆盖"匹配结果变化时重新决定渲染分支"，不仅是重绘 Canvas。

## 数据流

```
Token.brand (string)
      │
      ▼
matchBrandIcon(brand) ── 归一化 + 遍历 BRAND_ICONS 包含匹配
      │
      ├─ 命中 iconFile ──▶ Image($rawfile('brand-icons/' + iconFile))
      │
      └─ 未命中 (null) ──▶ 现有 Canvas 首字母渐变头像（不变）
```

匹配是**实时计算**，不写入 Token 数据、不缓存、不需要处理已有数据的迁移。

## 验证方式

项目当前没有任何测试基础设施（`hypium` 依赖已声明但从未被使用），本次不新搭测试框架。验证方式：

1. 写完 `matchBrandIcon` 后，用临时脚本或 `console.log` 手动跑一批关键 issuer 字符串核对匹配结果：`GitHub`、`github:myname`、`币安`、`Binance Exchange`、`群晖NAS`、`阿里云OSS`、`网易163邮箱`、不匹配任何品牌的自定义文本（应返回 `null`）。核对无误后删除临时验证代码。
2. 真机/模拟器运行，添加对应品牌的 token，截图确认 Logo 显示真实 svg 而非首字母头像；再添加一个无法匹配的品牌，确认仍显示首字母头像作为兜底。
3. 参照 CLAUDE.md 的 HarmonyOS 构建校验流程，跑一次完整 `assembleApp` 构建确认无编译错误。

## 风险 / 待确认点

- `$rawfile()` 是否接受运行时拼接的字符串变量（而非纯字面量）——需要在实现阶段用最小示例先验证一次，如果不支持动态拼接，需要改为 switch/映射表逐一列出 `$rawfile('brand-icons/xxx.svg')` 字面量。
- ArkUI `Image` 组件对 SVG 的渲染效果（颜色空间、viewBox 缩放）需要实机核对，个别 svg 素材如果显示异常（比如白色 logo 在深色背景消失，如 `apple.svg`）可能需要单独调整背景色或素材本身。
