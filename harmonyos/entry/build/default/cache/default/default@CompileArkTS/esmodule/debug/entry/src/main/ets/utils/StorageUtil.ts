import preferences from "@ohos:data.preferences";
import type { Token, ThemeItem } from '../model/Token';
const TOKENS_KEY = 'auth_tokens';
const THEME_KEY = 'auth_theme';
const PREF_NAME = 'arcankey_prefs';
let pref: preferences.Preferences | null = null;
export async function initPreferences(context: Context): Promise<void> {
    pref = await preferences.getPreferences(context, PREF_NAME);
}
export async function loadTokens(): Promise<Token[] | null> {
    try {
        if (!pref)
            return null;
        const val = await pref.get(TOKENS_KEY, '');
        if (!val || typeof val !== 'string' || val === '')
            return null;
        return JSON.parse(val as string) as Token[];
    }
    catch (e) {
        return null;
    }
}
export async function saveTokens(tokens: Token[]): Promise<void> {
    try {
        if (!pref)
            return;
        await pref.put(TOKENS_KEY, JSON.stringify(tokens));
        await pref.flush();
    }
    catch (e) {
        console.error('saveTokens failed: ' + (e as Error).message);
    }
}
export async function loadTheme(): Promise<ThemeItem | null> {
    try {
        if (!pref)
            return null;
        const val = await pref.get(THEME_KEY, '');
        if (!val || typeof val !== 'string' || val === '')
            return null;
        return JSON.parse(val as string) as ThemeItem;
    }
    catch (e) {
        return null;
    }
}
export async function saveTheme(theme: ThemeItem): Promise<void> {
    try {
        if (!pref)
            return;
        await pref.put(THEME_KEY, JSON.stringify(theme));
        await pref.flush();
    }
    catch (e) {
        console.error('saveTheme failed: ' + (e as Error).message);
    }
}
