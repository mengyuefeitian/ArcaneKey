import { BRAND_ICONS } from '../model/BrandIcons';

function normalize(input: string): string {
  return input.toLowerCase().replace(/[\s:\-_.]/g, '');
}

function matchByEmailDomain(account: string): string | null {
  const lowerAccount = account.toLowerCase().trim();
  for (let i = 0; i < BRAND_ICONS.length; i++) {
    const config = BRAND_ICONS[i];
    if (!config.emailDomains) {
      continue;
    }
    for (let j = 0; j < config.emailDomains.length; j++) {
      if (lowerAccount.endsWith('@' + config.emailDomains[j])) {
        return config.iconFile;
      }
    }
  }
  return null;
}

export function matchBrandIcon(brand: string, account?: string): string | null {
  if (brand) {
    const normalizedBrand = normalize(brand);
    for (let i = 0; i < BRAND_ICONS.length; i++) {
      const config = BRAND_ICONS[i];
      for (let j = 0; j < config.matchKeywords.length; j++) {
        if (normalizedBrand.includes(normalize(config.matchKeywords[j]))) {
          return config.iconFile;
        }
      }
    }
  }
  if (account) {
    return matchByEmailDomain(account);
  }
  return null;
}
