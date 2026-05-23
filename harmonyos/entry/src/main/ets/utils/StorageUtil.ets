import { preferences } from '@kit.ArkData';
import { Token, ThemeItem } from '../model/Token';

const TOKENS_KEY = 'auth_tokens';
const THEME_KEY = 'auth_theme';
const MEMBER_KEY = 'ak_membership';
const PREF_NAME = 'arcankey_prefs';

let pref: preferences.Preferences | null = null;

export async function initPreferences(context: Context): Promise<boolean> {
  try {
    pref = await preferences.getPreferences(context, PREF_NAME);
    return true;
  } catch (e) {
    console.error('initPreferences failed: ' + (e as Error).message);
    return false;
  }
}

export async function loadTokens(): Promise<Token[] | null> {
  try {
    if (!pref) return null;
    const val = await pref.get(TOKENS_KEY, '');
    if (!val || typeof val !== 'string' || val === '') return null;
    return JSON.parse(val as string) as Token[];
  } catch (e) {
    return null;
  }
}

export async function saveTokens(tokens: Token[]): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(TOKENS_KEY, JSON.stringify(tokens));
    await pref.flush();
  } catch (e) {
    console.error('saveTokens failed: ' + (e as Error).message);
  }
}

export async function loadTheme(): Promise<ThemeItem | null> {
  try {
    if (!pref) return null;
    const val = await pref.get(THEME_KEY, '');
    if (!val || typeof val !== 'string' || val === '') return null;
    return JSON.parse(val as string) as ThemeItem;
  } catch (e) {
    return null;
  }
}

export async function saveTheme(theme: ThemeItem): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(THEME_KEY, JSON.stringify(theme));
    await pref.flush();
  } catch (e) {
    console.error('saveTheme failed: ' + (e as Error).message);
  }
}

export interface MemberData {
  isMember: boolean;
  expiry: string | null;
}

export async function loadMember(): Promise<MemberData> {
  try {
    if (!pref) return { isMember: false, expiry: null };
    const val = await pref.get(MEMBER_KEY, '');
    if (val && typeof val === 'string' && val !== '') return JSON.parse(val as string) as MemberData;
  } catch (_) {}
  return { isMember: false, expiry: null };
}

export async function saveMember(isMember: boolean, expiry: string | null): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(MEMBER_KEY, JSON.stringify({ isMember, expiry }));
    await pref.flush();
  } catch (_) {}
}
