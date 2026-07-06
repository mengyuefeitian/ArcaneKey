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
