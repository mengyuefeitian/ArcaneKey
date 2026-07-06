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

// Order is priority: more specific entries must come before generic ones
// that would otherwise also match the same input (e.g. 'gcp' before
// 'google', 'synology-dsm' before 'synology'). The first match wins.
export const BRAND_ICONS: BrandIconConfig[] = [
  { id: 'gcp', officialName: 'Google Cloud', iconFile: 'gcp.svg', matchKeywords: ['gcp', 'google cloud', 'googlecloud'] },
  { id: 'google', officialName: 'Google', iconFile: 'google.svg', matchKeywords: ['google', 'gmail'] },
  { id: 'synology-dsm', officialName: 'Synology DSM', iconFile: 'synology-dsm.svg', matchKeywords: ['dsm', 'synology dsm', 'quickconnect'] },
  { id: 'synology', officialName: 'Synology', iconFile: 'synology.svg', matchKeywords: ['synology', '群晖'], scale: 1.3 },
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
  { id: 'apple', officialName: 'Apple', iconFile: 'apple.svg', matchKeywords: ['apple', 'icloud', 'appleid'], monochrome: true },
  { id: 'azure', officialName: 'Microsoft Azure', iconFile: 'azure.svg', matchKeywords: ['azure'] },
  { id: 'binance', officialName: 'Binance', iconFile: 'binance.svg', matchKeywords: ['binance', '币安'] },
  { id: 'claude', officialName: 'Claude', iconFile: 'claude.svg', matchKeywords: ['claude'] },
  { id: 'facebook', officialName: 'Facebook', iconFile: 'facebook.svg', matchKeywords: ['facebook', 'meta'] },
  { id: 'github', officialName: 'GitHub', iconFile: 'github.svg', matchKeywords: ['github'], monochrome: true, scale: 1.3 },
  { id: 'godaddy', officialName: 'GoDaddy', iconFile: 'godaddy.svg', matchKeywords: ['godaddy'] },
  { id: 'huawei', officialName: '华为', iconFile: 'huawei.svg', matchKeywords: ['huawei', '华为'], dimOpacityInDark: 0.85 },
  { id: 'instagram', officialName: 'Instagram', iconFile: 'instagram.svg', matchKeywords: ['instagram'] },
  { id: 'beirui', officialName: '贝锐（向日葵/花生壳）', iconFile: 'beirui.svg', matchKeywords: ['贝锐', '向日葵', '花生壳', 'oray'] },
  { id: 'microsoft', officialName: 'Microsoft', iconFile: 'microsoft.svg', matchKeywords: ['microsoft', 'outlook', 'office365'] },
  { id: 'openai', officialName: 'OpenAI', iconFile: 'openai.svg', matchKeywords: ['openai', 'chatgpt'], monochrome: true },
  { id: 'paypal', officialName: 'PayPal', iconFile: 'paypal.svg', matchKeywords: ['paypal'] },
  { id: 'teamviewer', officialName: 'TeamViewer', iconFile: 'teamviewer.svg', matchKeywords: ['teamviewer'] },
  { id: 'tiktok', officialName: 'TikTok', iconFile: 'tiktok.svg', matchKeywords: ['tiktok'], monochrome: true },
  { id: 'todesk', officialName: 'ToDesk', iconFile: 'todesk.svg', matchKeywords: ['todesk'] },
  { id: 'twitter', officialName: 'X (Twitter)', iconFile: 'twitter.svg', matchKeywords: ['twitter', 'x.com'] },
  { id: 'whatsapp', officialName: 'WhatsApp', iconFile: 'whatsapp.svg', matchKeywords: ['whatsapp'] },
];

export function findBrandIconConfig(iconFile: string): BrandIconConfig | null {
  for (let i = 0; i < BRAND_ICONS.length; i++) {
    if (BRAND_ICONS[i].iconFile === iconFile) {
      return BRAND_ICONS[i];
    }
  }
  return null;
}
