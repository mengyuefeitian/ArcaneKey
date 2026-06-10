import { preferences } from '@kit.ArkData';
import { Token, ThemeItem } from '../model/Token';

const TOKENS_KEY = 'auth_tokens';
const THEME_KEY = 'auth_theme';
const MEMBER_KEY = 'ak_membership';
const LOGIN_KEY = 'ak_login';
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
  boundAccount: string;
}

export async function loadMember(): Promise<MemberData> {
  try {
    if (!pref) return { isMember: false, boundAccount: '' };
    const val = await pref.get(MEMBER_KEY, '');
    if (val && typeof val === 'string' && val !== '') {
      const raw = JSON.parse(val as string) as Record<string, string | boolean>;
      return { isMember: !!raw.isMember, boundAccount: (raw.boundAccount as string) || '' };
    }
  } catch (_) {}
  return { isMember: false, boundAccount: '' };
}

export async function saveMember(isMember: boolean, boundAccount: string): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(MEMBER_KEY, JSON.stringify({ isMember, boundAccount }));
    await pref.flush();
  } catch (_) {}
}

export interface LoginData {
  loggedIn: boolean;
  userName: string;
  userPhone: string;
  userAvatar: string;
  harmonyLogin: boolean;
}

export async function loadLogin(): Promise<LoginData> {
  try {
    if (!pref) return { loggedIn: false, userName: '', userPhone: '', userAvatar: '', harmonyLogin: false };
    const val = await pref.get(LOGIN_KEY, '');
    if (val && typeof val === 'string' && val !== '') {
      return JSON.parse(val as string) as LoginData;
    }
  } catch (_) {}
  return { loggedIn: false, userName: '', userPhone: '', userAvatar: '', harmonyLogin: false };
}

export async function saveLogin(loggedIn: boolean, userName: string, userPhone: string, userAvatar: string, harmonyLogin: boolean): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(LOGIN_KEY, JSON.stringify({ loggedIn, userName, userPhone, userAvatar, harmonyLogin }));
    await pref.flush();
  } catch (_) {}
}