export interface Token {
  id: string;
  brand: string;
  account: string;
  secret: string;
}

export interface OtpPair {
  current: string;
  next: string;
}

export interface ThemeItem {
  name: string;
  color: string;
}

export const THEMES: ThemeItem[] = [
  { name: '海洋蓝', color: '#4080D0' },
  { name: '皇室紫', color: '#9060D0' },
  { name: '玫瑰粉', color: '#D04080' },
  { name: '热情红', color: '#D04040' },
  { name: '暖橙色', color: '#D07030' },
  { name: '琥珀金', color: '#C09030' },
  { name: '森林绿', color: '#30A060' },
  { name: '青绿色', color: '#2090A0' },
  { name: '天空蓝', color: '#3080C0' },
  { name: '深靛蓝', color: '#6050C8' },
];

export const BRAND_COLORS: Record<string, string> = {
  'Google': '#EA4335', 'Microsoft': '#00A4EF', 'GitHub': '#e6edf3',
  'Apple': '#aaaaaa', 'Twitter': '#1DA1F2', 'X (Twitter)': '#e7e9ea',
  'Dropbox': '#0061FF', 'Facebook': '#1877F2', 'Amazon': '#FF9900',
  'Slack': '#4A154B', 'Discord': '#5865F2', 'Notion': '#ffffff',
  'Stripe': '#635BFF', 'Figma': '#F24E1E', 'LinkedIn': '#0A66C2',
  'Steam': '#c6d4df', 'Netflix': '#E50914', 'Spotify': '#1DB954',
};

export const INITIAL_TOKENS: Token[] = [];

export const FREE_TOKEN_LIMIT: number = 5;
export const MEMBERSHIP_PRICE: number = 19.90;
export const APP_NAME: string = '星枢令';
