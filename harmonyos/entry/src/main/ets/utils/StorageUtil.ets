import { preferences } from '@kit.ArkData';
import { Token, ThemeItem } from '../model/Token';
import { PasswordEntry } from '../model/PasswordEntry';

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
  boundOpenId: string;
}

export async function loadMember(): Promise<MemberData> {
  try {
    if (!pref) return { isMember: false, boundAccount: '', boundOpenId: '' };
    const val = await pref.get(MEMBER_KEY, '');
    if (val && typeof val === 'string' && val !== '') {
      const raw = JSON.parse(val as string) as Record<string, string | boolean>;
      return {
        isMember: !!raw.isMember,
        boundAccount: (raw.boundAccount as string) || '',
        boundOpenId: (raw.boundOpenId as string) || '',
      };
    }
  } catch (_) {}
  return { isMember: false, boundAccount: '', boundOpenId: '' };
}

export async function saveMember(isMember: boolean, boundAccount: string, boundOpenId?: string): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(MEMBER_KEY, JSON.stringify({ isMember, boundAccount, boundOpenId: boundOpenId || '' }));
    await pref.flush();
  } catch (_) {}
}

export interface LoginData {
  loggedIn: boolean;
  userName: string;
  userPhone: string;
  userAvatar: string;
  harmonyLogin: boolean;
  userOpenId: string;
}

export async function loadLogin(): Promise<LoginData> {
  try {
    if (!pref) return { loggedIn: false, userName: '', userPhone: '', userAvatar: '', harmonyLogin: false, userOpenId: '' };
    const val = await pref.get(LOGIN_KEY, '');
    if (val && typeof val === 'string' && val !== '') {
      const raw = JSON.parse(val as string) as Record<string, string | boolean>;
      return {
        loggedIn: !!raw.loggedIn,
        userName: (raw.userName as string) || '',
        userPhone: (raw.userPhone as string) || '',
        userAvatar: (raw.userAvatar as string) || '',
        harmonyLogin: !!raw.harmonyLogin,
        userOpenId: (raw.userOpenId as string) || '',
      };
    }
  } catch (_) {}
  return { loggedIn: false, userName: '', userPhone: '', userAvatar: '', harmonyLogin: false, userOpenId: '' };
}

export async function saveLogin(loggedIn: boolean, userName: string, userPhone: string, userAvatar: string, harmonyLogin: boolean, userOpenId?: string): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(LOGIN_KEY, JSON.stringify({ loggedIn, userName, userPhone, userAvatar, harmonyLogin, userOpenId: userOpenId || '' }));
    await pref.flush();
  } catch (_) {}
}

const DARK_MODE_KEY = 'ak_dark_mode';

export async function loadThemeMode(): Promise<boolean> {
  try {
    if (!pref) return true;
    const val = await pref.get(DARK_MODE_KEY, true);
    return typeof val === 'boolean' ? (val as boolean) : true;
  } catch (_) {
    return true;
  }
}

export async function saveThemeMode(isDark: boolean): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(DARK_MODE_KEY, isDark);
    await pref.flush();
  } catch (_) {}
}

const CLOUD_SYNC_KEY = 'ak_cloud_sync';

export async function loadCloudSyncEnabled(isMember: boolean): Promise<boolean> {
  try {
    if (!pref) return isMember;
    // Empty-string default marks "unset" so members default on, non-members off
    const val = await pref.get(CLOUD_SYNC_KEY, '');
    if (val === '' || val === null || val === undefined) {
      return isMember;
    }
    if (typeof val === 'boolean') return val as boolean;
    if (typeof val === 'string') return val === 'true' || val === '1';
    return isMember;
  } catch (_) {
    return isMember;
  }
}

export async function saveCloudSyncEnabled(enabled: boolean): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(CLOUD_SYNC_KEY, enabled);
    await pref.flush();
  } catch (_) {}
}

export type SecurityMode = 'off' | 'face' | 'fingerprint' | 'lock';

const SECURITY_MODE_KEY = 'ak_security_mode';

export async function loadSecurityMode(): Promise<SecurityMode> {
  try {
    if (!pref) return 'off';
    const val = await pref.get(SECURITY_MODE_KEY, 'off');
    const s = String(val);
    if (s === 'face' || s === 'fingerprint' || s === 'lock') return s;
    return 'off';
  } catch (_) {
    return 'off';
  }
}

export async function saveSecurityMode(mode: SecurityMode): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(SECURITY_MODE_KEY, mode);
    await pref.flush();
  } catch (_) {}
}

const LOCK_FALLBACK_KEY = 'ak_lock_fallback_enabled';

export async function loadLockFallbackEnabled(): Promise<boolean> {
  try {
    if (!pref) return true;
    const val = await pref.get(LOCK_FALLBACK_KEY, true);
    if (typeof val === 'boolean') return val as boolean;
    if (typeof val === 'string') return val === 'true' || val === '1';
    return true;
  } catch (_) {
    return true;
  }
}

export async function saveLockFallbackEnabled(enabled: boolean): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(LOCK_FALLBACK_KEY, enabled);
    await pref.flush();
  } catch (_) {}
}

const OPEN_COUNT_KEY = 'ak_open_count';
const COMMENT_PROMPTED_VER_KEY = 'ak_comment_prompted_ver';
const COMMENT_DONE_VER_KEY = 'ak_comment_done_ver';

export async function loadOpenCount(): Promise<number> {
  try {
    if (!pref) return 0;
    const val = await pref.get(OPEN_COUNT_KEY, 0);
    if (typeof val === 'number') return val as number;
    const n = Number(val);
    return isNaN(n) ? 0 : n;
  } catch (_) {
    return 0;
  }
}

export async function saveOpenCount(count: number): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(OPEN_COUNT_KEY, count);
    await pref.flush();
  } catch (_) {}
}

export async function loadCommentPromptedVer(): Promise<string> {
  try {
    if (!pref) return '';
    return String(await pref.get(COMMENT_PROMPTED_VER_KEY, ''));
  } catch (_) {
    return '';
  }
}

export async function saveCommentPromptedVer(ver: string): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(COMMENT_PROMPTED_VER_KEY, ver);
    await pref.flush();
  } catch (_) {}
}

export async function loadCommentDoneVer(): Promise<string> {
  try {
    if (!pref) return '';
    return String(await pref.get(COMMENT_DONE_VER_KEY, ''));
  } catch (_) {
    return '';
  }
}

export async function saveCommentDoneVer(ver: string): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(COMMENT_DONE_VER_KEY, ver);
    await pref.flush();
  } catch (_) {}
}

const PASSWORDS_KEY = 'ak_passwords';

export async function loadPasswords(): Promise<PasswordEntry[]> {
  try {
    if (!pref) return [];
    const val = await pref.get(PASSWORDS_KEY, '');
    if (!val || typeof val !== 'string' || val === '') return [];
    const parsed = JSON.parse(val as string) as PasswordEntry[];
    return Array.isArray(parsed) ? parsed : [];
  } catch (e) {
    return [];
  }
}

export async function savePasswords(list: PasswordEntry[]): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(PASSWORDS_KEY, JSON.stringify(list));
    await pref.flush();
  } catch (e) {
    console.error('savePasswords failed: ' + (e as Error).message);
  }
}