if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface Index_Params {
    tokens?: Token[];
    otpMap?: Record<string, OtpPair>;
    timeLeft_?: number;
    currentTab?: number;
    navVisible?: boolean;
    accentColor?: string;
    currentTheme?: ThemeItem;
    loggedIn?: boolean;
    userName?: string;
    userPhone?: string;
    userAvatar?: string;
    loginNickname?: string;
    editToken?: Token;
    editBrand?: string;
    editAccount?: string;
    confirmDelete?: boolean;
    showLogin?: boolean;
    loginTab?: number;
    loginPhone?: string;
    loginCode?: string;
    loginCodeSent?: boolean;
    loginCodeCd?: number;
    showBackup?: boolean;
    backupPw?: string;
    backupPw2?: string;
    showImport?: boolean;
    importPw?: string;
    importText?: string;
    importFileUri?: string;
    importFileName?: string;
    showTheme?: boolean;
    harmonyLogin?: boolean;
    showAccountInfo?: boolean;
    privacyAgreed?: boolean;
    searching?: boolean;
    searchQ?: string;
    toastMsg?: string;
    toastVisible?: boolean;
    timer?: number;
    toastTimer?: number;
    cdTimer?: number;
}
import pasteboard from "@ohos:pasteboard";
import type common from "@ohos:app.ability.common";
import picker from "@ohos:file.picker";
import fs from "@ohos:file.fs";
import { THEMES, INITIAL_TOKENS } from "@bundle:com.example.arcankey/entry/ets/model/Token";
import type { Token, OtpPair, ThemeItem } from "@bundle:com.example.arcankey/entry/ets/model/Token";
import { totp, timeLeft } from "@bundle:com.example.arcankey/entry/ets/utils/TOTP";
import { initPreferences, loadTokens, saveTokens, loadTheme, saveTheme } from "@bundle:com.example.arcankey/entry/ets/utils/StorageUtil";
import { encryptData, decryptData } from "@bundle:com.example.arcankey/entry/ets/utils/CryptoUtil";
import { HomeView } from "@bundle:com.example.arcankey/entry/ets/views/HomeView";
import { ScanView } from "@bundle:com.example.arcankey/entry/ets/views/ScanView";
import { ProfileView } from "@bundle:com.example.arcankey/entry/ets/views/ProfileView";
import { Logo } from "@bundle:com.example.arcankey/entry/ets/components/Logo";
interface SaveOptions {
    newFileNames: string[];
}
class Index extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__tokens = new ObservedPropertyObjectPU([], this, "tokens");
        this.__otpMap = new ObservedPropertyObjectPU({}, this, "otpMap");
        this.__timeLeft_ = new ObservedPropertySimplePU(30, this, "timeLeft_");
        this.__currentTab = new ObservedPropertySimplePU(0, this, "currentTab");
        this.__navVisible = new ObservedPropertySimplePU(true, this, "navVisible");
        this.__accentColor = new ObservedPropertySimplePU('#4080D0', this, "accentColor");
        this.__currentTheme = new ObservedPropertyObjectPU(THEMES[0], this, "currentTheme");
        this.__loggedIn = new ObservedPropertySimplePU(false, this, "loggedIn");
        this.__userName = new ObservedPropertySimplePU('', this, "userName");
        this.__userPhone = new ObservedPropertySimplePU('', this, "userPhone");
        this.__userAvatar = new ObservedPropertySimplePU('', this, "userAvatar");
        this.__loginNickname = new ObservedPropertySimplePU('', this, "loginNickname");
        this.__editToken = new ObservedPropertyObjectPU({} as Token, this, "editToken");
        this.__editBrand = new ObservedPropertySimplePU('', this, "editBrand");
        this.__editAccount = new ObservedPropertySimplePU('', this, "editAccount");
        this.__confirmDelete = new ObservedPropertySimplePU(false, this, "confirmDelete");
        this.__showLogin = new ObservedPropertySimplePU(false, this, "showLogin");
        this.__loginTab = new ObservedPropertySimplePU(0, this, "loginTab");
        this.__loginPhone = new ObservedPropertySimplePU('', this, "loginPhone");
        this.__loginCode = new ObservedPropertySimplePU('', this, "loginCode");
        this.__loginCodeSent = new ObservedPropertySimplePU(false, this, "loginCodeSent");
        this.__loginCodeCd = new ObservedPropertySimplePU(0, this, "loginCodeCd");
        this.__showBackup = new ObservedPropertySimplePU(false, this, "showBackup");
        this.__backupPw = new ObservedPropertySimplePU('', this, "backupPw");
        this.__backupPw2 = new ObservedPropertySimplePU('', this, "backupPw2");
        this.__showImport = new ObservedPropertySimplePU(false, this, "showImport");
        this.__importPw = new ObservedPropertySimplePU('', this, "importPw");
        this.__importText = new ObservedPropertySimplePU('', this, "importText");
        this.__importFileUri = new ObservedPropertySimplePU('', this, "importFileUri");
        this.__importFileName = new ObservedPropertySimplePU('', this, "importFileName");
        this.__showTheme = new ObservedPropertySimplePU(false, this, "showTheme");
        this.__harmonyLogin = new ObservedPropertySimplePU(false, this, "harmonyLogin");
        this.__showAccountInfo = new ObservedPropertySimplePU(false, this, "showAccountInfo");
        this.__privacyAgreed = new ObservedPropertySimplePU(false, this, "privacyAgreed");
        this.__searching = new ObservedPropertySimplePU(false, this, "searching");
        this.__searchQ = new ObservedPropertySimplePU('', this, "searchQ");
        this.__toastMsg = new ObservedPropertySimplePU('', this, "toastMsg");
        this.__toastVisible = new ObservedPropertySimplePU(false, this, "toastVisible");
        this.timer = -1;
        this.toastTimer = -1;
        this.cdTimer = -1;
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: Index_Params) {
        if (params.tokens !== undefined) {
            this.tokens = params.tokens;
        }
        if (params.otpMap !== undefined) {
            this.otpMap = params.otpMap;
        }
        if (params.timeLeft_ !== undefined) {
            this.timeLeft_ = params.timeLeft_;
        }
        if (params.currentTab !== undefined) {
            this.currentTab = params.currentTab;
        }
        if (params.navVisible !== undefined) {
            this.navVisible = params.navVisible;
        }
        if (params.accentColor !== undefined) {
            this.accentColor = params.accentColor;
        }
        if (params.currentTheme !== undefined) {
            this.currentTheme = params.currentTheme;
        }
        if (params.loggedIn !== undefined) {
            this.loggedIn = params.loggedIn;
        }
        if (params.userName !== undefined) {
            this.userName = params.userName;
        }
        if (params.userPhone !== undefined) {
            this.userPhone = params.userPhone;
        }
        if (params.userAvatar !== undefined) {
            this.userAvatar = params.userAvatar;
        }
        if (params.loginNickname !== undefined) {
            this.loginNickname = params.loginNickname;
        }
        if (params.editToken !== undefined) {
            this.editToken = params.editToken;
        }
        if (params.editBrand !== undefined) {
            this.editBrand = params.editBrand;
        }
        if (params.editAccount !== undefined) {
            this.editAccount = params.editAccount;
        }
        if (params.confirmDelete !== undefined) {
            this.confirmDelete = params.confirmDelete;
        }
        if (params.showLogin !== undefined) {
            this.showLogin = params.showLogin;
        }
        if (params.loginTab !== undefined) {
            this.loginTab = params.loginTab;
        }
        if (params.loginPhone !== undefined) {
            this.loginPhone = params.loginPhone;
        }
        if (params.loginCode !== undefined) {
            this.loginCode = params.loginCode;
        }
        if (params.loginCodeSent !== undefined) {
            this.loginCodeSent = params.loginCodeSent;
        }
        if (params.loginCodeCd !== undefined) {
            this.loginCodeCd = params.loginCodeCd;
        }
        if (params.showBackup !== undefined) {
            this.showBackup = params.showBackup;
        }
        if (params.backupPw !== undefined) {
            this.backupPw = params.backupPw;
        }
        if (params.backupPw2 !== undefined) {
            this.backupPw2 = params.backupPw2;
        }
        if (params.showImport !== undefined) {
            this.showImport = params.showImport;
        }
        if (params.importPw !== undefined) {
            this.importPw = params.importPw;
        }
        if (params.importText !== undefined) {
            this.importText = params.importText;
        }
        if (params.importFileUri !== undefined) {
            this.importFileUri = params.importFileUri;
        }
        if (params.importFileName !== undefined) {
            this.importFileName = params.importFileName;
        }
        if (params.showTheme !== undefined) {
            this.showTheme = params.showTheme;
        }
        if (params.harmonyLogin !== undefined) {
            this.harmonyLogin = params.harmonyLogin;
        }
        if (params.showAccountInfo !== undefined) {
            this.showAccountInfo = params.showAccountInfo;
        }
        if (params.privacyAgreed !== undefined) {
            this.privacyAgreed = params.privacyAgreed;
        }
        if (params.searching !== undefined) {
            this.searching = params.searching;
        }
        if (params.searchQ !== undefined) {
            this.searchQ = params.searchQ;
        }
        if (params.toastMsg !== undefined) {
            this.toastMsg = params.toastMsg;
        }
        if (params.toastVisible !== undefined) {
            this.toastVisible = params.toastVisible;
        }
        if (params.timer !== undefined) {
            this.timer = params.timer;
        }
        if (params.toastTimer !== undefined) {
            this.toastTimer = params.toastTimer;
        }
        if (params.cdTimer !== undefined) {
            this.cdTimer = params.cdTimer;
        }
    }
    updateStateVars(params: Index_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__tokens.purgeDependencyOnElmtId(rmElmtId);
        this.__otpMap.purgeDependencyOnElmtId(rmElmtId);
        this.__timeLeft_.purgeDependencyOnElmtId(rmElmtId);
        this.__currentTab.purgeDependencyOnElmtId(rmElmtId);
        this.__navVisible.purgeDependencyOnElmtId(rmElmtId);
        this.__accentColor.purgeDependencyOnElmtId(rmElmtId);
        this.__currentTheme.purgeDependencyOnElmtId(rmElmtId);
        this.__loggedIn.purgeDependencyOnElmtId(rmElmtId);
        this.__userName.purgeDependencyOnElmtId(rmElmtId);
        this.__userPhone.purgeDependencyOnElmtId(rmElmtId);
        this.__userAvatar.purgeDependencyOnElmtId(rmElmtId);
        this.__loginNickname.purgeDependencyOnElmtId(rmElmtId);
        this.__editToken.purgeDependencyOnElmtId(rmElmtId);
        this.__editBrand.purgeDependencyOnElmtId(rmElmtId);
        this.__editAccount.purgeDependencyOnElmtId(rmElmtId);
        this.__confirmDelete.purgeDependencyOnElmtId(rmElmtId);
        this.__showLogin.purgeDependencyOnElmtId(rmElmtId);
        this.__loginTab.purgeDependencyOnElmtId(rmElmtId);
        this.__loginPhone.purgeDependencyOnElmtId(rmElmtId);
        this.__loginCode.purgeDependencyOnElmtId(rmElmtId);
        this.__loginCodeSent.purgeDependencyOnElmtId(rmElmtId);
        this.__loginCodeCd.purgeDependencyOnElmtId(rmElmtId);
        this.__showBackup.purgeDependencyOnElmtId(rmElmtId);
        this.__backupPw.purgeDependencyOnElmtId(rmElmtId);
        this.__backupPw2.purgeDependencyOnElmtId(rmElmtId);
        this.__showImport.purgeDependencyOnElmtId(rmElmtId);
        this.__importPw.purgeDependencyOnElmtId(rmElmtId);
        this.__importText.purgeDependencyOnElmtId(rmElmtId);
        this.__importFileUri.purgeDependencyOnElmtId(rmElmtId);
        this.__importFileName.purgeDependencyOnElmtId(rmElmtId);
        this.__showTheme.purgeDependencyOnElmtId(rmElmtId);
        this.__harmonyLogin.purgeDependencyOnElmtId(rmElmtId);
        this.__showAccountInfo.purgeDependencyOnElmtId(rmElmtId);
        this.__privacyAgreed.purgeDependencyOnElmtId(rmElmtId);
        this.__searching.purgeDependencyOnElmtId(rmElmtId);
        this.__searchQ.purgeDependencyOnElmtId(rmElmtId);
        this.__toastMsg.purgeDependencyOnElmtId(rmElmtId);
        this.__toastVisible.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__tokens.aboutToBeDeleted();
        this.__otpMap.aboutToBeDeleted();
        this.__timeLeft_.aboutToBeDeleted();
        this.__currentTab.aboutToBeDeleted();
        this.__navVisible.aboutToBeDeleted();
        this.__accentColor.aboutToBeDeleted();
        this.__currentTheme.aboutToBeDeleted();
        this.__loggedIn.aboutToBeDeleted();
        this.__userName.aboutToBeDeleted();
        this.__userPhone.aboutToBeDeleted();
        this.__userAvatar.aboutToBeDeleted();
        this.__loginNickname.aboutToBeDeleted();
        this.__editToken.aboutToBeDeleted();
        this.__editBrand.aboutToBeDeleted();
        this.__editAccount.aboutToBeDeleted();
        this.__confirmDelete.aboutToBeDeleted();
        this.__showLogin.aboutToBeDeleted();
        this.__loginTab.aboutToBeDeleted();
        this.__loginPhone.aboutToBeDeleted();
        this.__loginCode.aboutToBeDeleted();
        this.__loginCodeSent.aboutToBeDeleted();
        this.__loginCodeCd.aboutToBeDeleted();
        this.__showBackup.aboutToBeDeleted();
        this.__backupPw.aboutToBeDeleted();
        this.__backupPw2.aboutToBeDeleted();
        this.__showImport.aboutToBeDeleted();
        this.__importPw.aboutToBeDeleted();
        this.__importText.aboutToBeDeleted();
        this.__importFileUri.aboutToBeDeleted();
        this.__importFileName.aboutToBeDeleted();
        this.__showTheme.aboutToBeDeleted();
        this.__harmonyLogin.aboutToBeDeleted();
        this.__showAccountInfo.aboutToBeDeleted();
        this.__privacyAgreed.aboutToBeDeleted();
        this.__searching.aboutToBeDeleted();
        this.__searchQ.aboutToBeDeleted();
        this.__toastMsg.aboutToBeDeleted();
        this.__toastVisible.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    // ── Core State ──────────────────────────────────────────────────
    private __tokens: ObservedPropertyObjectPU<Token[]>;
    get tokens() {
        return this.__tokens.get();
    }
    set tokens(newValue: Token[]) {
        this.__tokens.set(newValue);
    }
    private __otpMap: ObservedPropertyObjectPU<Record<string, OtpPair>>;
    get otpMap() {
        return this.__otpMap.get();
    }
    set otpMap(newValue: Record<string, OtpPair>) {
        this.__otpMap.set(newValue);
    }
    private __timeLeft_: ObservedPropertySimplePU<number>;
    get timeLeft_() {
        return this.__timeLeft_.get();
    }
    set timeLeft_(newValue: number) {
        this.__timeLeft_.set(newValue);
    }
    private __currentTab: ObservedPropertySimplePU<number>;
    get currentTab() {
        return this.__currentTab.get();
    }
    set currentTab(newValue: number) {
        this.__currentTab.set(newValue);
    }
    private __navVisible: ObservedPropertySimplePU<boolean>;
    get navVisible() {
        return this.__navVisible.get();
    }
    set navVisible(newValue: boolean) {
        this.__navVisible.set(newValue);
    }
    private __accentColor: ObservedPropertySimplePU<string>;
    get accentColor() {
        return this.__accentColor.get();
    }
    set accentColor(newValue: string) {
        this.__accentColor.set(newValue);
    }
    private __currentTheme: ObservedPropertyObjectPU<ThemeItem>;
    get currentTheme() {
        return this.__currentTheme.get();
    }
    set currentTheme(newValue: ThemeItem) {
        this.__currentTheme.set(newValue);
    }
    private __loggedIn: ObservedPropertySimplePU<boolean>;
    get loggedIn() {
        return this.__loggedIn.get();
    }
    set loggedIn(newValue: boolean) {
        this.__loggedIn.set(newValue);
    }
    private __userName: ObservedPropertySimplePU<string>;
    get userName() {
        return this.__userName.get();
    }
    set userName(newValue: string) {
        this.__userName.set(newValue);
    }
    private __userPhone: ObservedPropertySimplePU<string>;
    get userPhone() {
        return this.__userPhone.get();
    }
    set userPhone(newValue: string) {
        this.__userPhone.set(newValue);
    }
    private __userAvatar: ObservedPropertySimplePU<string>;
    get userAvatar() {
        return this.__userAvatar.get();
    }
    set userAvatar(newValue: string) {
        this.__userAvatar.set(newValue);
    }
    private __loginNickname: ObservedPropertySimplePU<string>;
    get loginNickname() {
        return this.__loginNickname.get();
    }
    set loginNickname(newValue: string) {
        this.__loginNickname.set(newValue);
    }
    // ── Edit Modal ──────────────────────────────────────────────────
    private __editToken: ObservedPropertyObjectPU<Token>;
    get editToken() {
        return this.__editToken.get();
    }
    set editToken(newValue: Token) {
        this.__editToken.set(newValue);
    }
    private __editBrand: ObservedPropertySimplePU<string>;
    get editBrand() {
        return this.__editBrand.get();
    }
    set editBrand(newValue: string) {
        this.__editBrand.set(newValue);
    }
    private __editAccount: ObservedPropertySimplePU<string>;
    get editAccount() {
        return this.__editAccount.get();
    }
    set editAccount(newValue: string) {
        this.__editAccount.set(newValue);
    }
    private __confirmDelete: ObservedPropertySimplePU<boolean>;
    get confirmDelete() {
        return this.__confirmDelete.get();
    }
    set confirmDelete(newValue: boolean) {
        this.__confirmDelete.set(newValue);
    }
    // ── Login Modal ─────────────────────────────────────────────────
    private __showLogin: ObservedPropertySimplePU<boolean>;
    get showLogin() {
        return this.__showLogin.get();
    }
    set showLogin(newValue: boolean) {
        this.__showLogin.set(newValue);
    }
    private __loginTab: ObservedPropertySimplePU<number>;
    get loginTab() {
        return this.__loginTab.get();
    }
    set loginTab(newValue: number) {
        this.__loginTab.set(newValue);
    }
    private __loginPhone: ObservedPropertySimplePU<string>;
    get loginPhone() {
        return this.__loginPhone.get();
    }
    set loginPhone(newValue: string) {
        this.__loginPhone.set(newValue);
    }
    private __loginCode: ObservedPropertySimplePU<string>;
    get loginCode() {
        return this.__loginCode.get();
    }
    set loginCode(newValue: string) {
        this.__loginCode.set(newValue);
    }
    private __loginCodeSent: ObservedPropertySimplePU<boolean>;
    get loginCodeSent() {
        return this.__loginCodeSent.get();
    }
    set loginCodeSent(newValue: boolean) {
        this.__loginCodeSent.set(newValue);
    }
    private __loginCodeCd: ObservedPropertySimplePU<number>;
    get loginCodeCd() {
        return this.__loginCodeCd.get();
    }
    set loginCodeCd(newValue: number) {
        this.__loginCodeCd.set(newValue);
    }
    // ── Backup Modal ────────────────────────────────────────────────
    private __showBackup: ObservedPropertySimplePU<boolean>;
    get showBackup() {
        return this.__showBackup.get();
    }
    set showBackup(newValue: boolean) {
        this.__showBackup.set(newValue);
    }
    private __backupPw: ObservedPropertySimplePU<string>;
    get backupPw() {
        return this.__backupPw.get();
    }
    set backupPw(newValue: string) {
        this.__backupPw.set(newValue);
    }
    private __backupPw2: ObservedPropertySimplePU<string>;
    get backupPw2() {
        return this.__backupPw2.get();
    }
    set backupPw2(newValue: string) {
        this.__backupPw2.set(newValue);
    }
    // ── Import Modal ────────────────────────────────────────────────
    private __showImport: ObservedPropertySimplePU<boolean>;
    get showImport() {
        return this.__showImport.get();
    }
    set showImport(newValue: boolean) {
        this.__showImport.set(newValue);
    }
    private __importPw: ObservedPropertySimplePU<string>;
    get importPw() {
        return this.__importPw.get();
    }
    set importPw(newValue: string) {
        this.__importPw.set(newValue);
    }
    private __importText: ObservedPropertySimplePU<string>;
    get importText() {
        return this.__importText.get();
    }
    set importText(newValue: string) {
        this.__importText.set(newValue);
    }
    private __importFileUri: ObservedPropertySimplePU<string>;
    get importFileUri() {
        return this.__importFileUri.get();
    }
    set importFileUri(newValue: string) {
        this.__importFileUri.set(newValue);
    }
    private __importFileName: ObservedPropertySimplePU<string>;
    get importFileName() {
        return this.__importFileName.get();
    }
    set importFileName(newValue: string) {
        this.__importFileName.set(newValue);
    }
    // ── Theme Modal ─────────────────────────────────────────────────
    private __showTheme: ObservedPropertySimplePU<boolean>;
    get showTheme() {
        return this.__showTheme.get();
    }
    set showTheme(newValue: boolean) {
        this.__showTheme.set(newValue);
    }
    // ── HarmonyOS Login Flag ────────────────────────────────────────
    private __harmonyLogin: ObservedPropertySimplePU<boolean>;
    get harmonyLogin() {
        return this.__harmonyLogin.get();
    }
    set harmonyLogin(newValue: boolean) {
        this.__harmonyLogin.set(newValue);
    }
    private __showAccountInfo: ObservedPropertySimplePU<boolean>;
    get showAccountInfo() {
        return this.__showAccountInfo.get();
    }
    set showAccountInfo(newValue: boolean) {
        this.__showAccountInfo.set(newValue);
    }
    private __privacyAgreed: ObservedPropertySimplePU<boolean>;
    get privacyAgreed() {
        return this.__privacyAgreed.get();
    }
    set privacyAgreed(newValue: boolean) {
        this.__privacyAgreed.set(newValue);
    }
    // ── Search ──────────────────────────────────────────────────────
    private __searching: ObservedPropertySimplePU<boolean>;
    get searching() {
        return this.__searching.get();
    }
    set searching(newValue: boolean) {
        this.__searching.set(newValue);
    }
    private __searchQ: ObservedPropertySimplePU<string>;
    get searchQ() {
        return this.__searchQ.get();
    }
    set searchQ(newValue: string) {
        this.__searchQ.set(newValue);
    }
    // ── Toast ───────────────────────────────────────────────────────
    private __toastMsg: ObservedPropertySimplePU<string>;
    get toastMsg() {
        return this.__toastMsg.get();
    }
    set toastMsg(newValue: string) {
        this.__toastMsg.set(newValue);
    }
    private __toastVisible: ObservedPropertySimplePU<boolean>;
    get toastVisible() {
        return this.__toastVisible.get();
    }
    set toastVisible(newValue: boolean) {
        this.__toastVisible.set(newValue);
    }
    private timer: number;
    private toastTimer: number;
    private cdTimer: number;
    // ── Lifecycle ───────────────────────────────────────────────────
    aboutToAppear(): void {
        this.loadData();
        this.timer = setInterval(() => {
            this.timeLeft_ = timeLeft();
            if (this.timeLeft_ === 30)
                this.refreshOtp();
        }, 1000) as number;
    }
    aboutToDisappear(): void {
        clearInterval(this.timer);
        clearTimeout(this.toastTimer);
        if (this.cdTimer !== -1)
            clearInterval(this.cdTimer);
    }
    // ── Data ────────────────────────────────────────────────────────
    private async loadData(): Promise<void> {
        try {
            const ctx = getContext(this) as common.UIAbilityContext;
            await initPreferences(ctx);
            const saved = await loadTokens();
            this.tokens = (saved && saved.length > 0) ? saved : INITIAL_TOKENS.slice();
            const theme = await loadTheme();
            if (theme) {
                this.accentColor = theme.color;
                this.currentTheme = theme;
            }
            this.refreshOtp();
        }
        catch (_) {
            this.tokens = INITIAL_TOKENS.slice();
        }
    }
    private refreshOtp(): void {
        const m: Record<string, OtpPair> = {};
        for (const t of this.tokens) {
            m[t.id] = { current: totp(t.secret, 0), next: totp(t.secret, 1) };
        }
        this.otpMap = m;
    }
    private toast(msg: string): void {
        clearTimeout(this.toastTimer);
        this.toastMsg = msg;
        this.toastVisible = true;
        this.toastTimer = setTimeout(() => { this.toastVisible = false; }, 2200) as number;
    }
    private addToken(brand: string, account: string, secret: string): void {
        const tok: Token = { id: Date.now().toString(), brand: brand, account: account, secret: secret.toUpperCase() };
        this.tokens = this.tokens.concat([tok]);
        saveTokens(this.tokens);
        this.refreshOtp();
        this.currentTab = 0;
        this.toast(`已添加 ${brand}`);
    }
    private saveEdit(): void {
        if (!this.editToken.id)
            return;
        const id = this.editToken.id;
        this.tokens = this.tokens.map((t: Token): Token => {
            if (t.id === id) {
                return { id: t.id, brand: this.editBrand, account: this.editAccount, secret: t.secret };
            }
            return t;
        });
        saveTokens(this.tokens);
        this.refreshOtp();
        this.editToken = {} as Token;
        this.toast('已保存');
    }
    private deleteToken(): void {
        if (!this.editToken.id)
            return;
        const id = this.editToken.id;
        this.tokens = this.tokens.filter((t: Token) => t.id !== id);
        saveTokens(this.tokens);
        this.refreshOtp();
        this.editToken = {} as Token;
        this.toast('已删除');
    }
    private copyCode(code: string, brand: string): void {
        try {
            const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, code);
            pasteboard.getSystemPasteboard().setData(data);
            this.toast(`已复制 ${brand} 验证码`);
        }
        catch (_) {
            this.toast('复制失败');
        }
    }
    private doLogin(): void {
        const wasLoggedIn = this.loggedIn;
        this.loggedIn = true;
        if (!this.userName || this.userName.length === 0) {
            this.userName = `用户${this.loginPhone.slice(-4) || '****'}`;
        }
        this.userPhone = this.loginPhone;
        this.showLogin = false;
        this.toast(wasLoggedIn ? '手机号绑定成功' : '登录成功');
    }
    private doBackup(): void {
        if (!this.backupPw || this.backupPw !== this.backupPw2)
            return;
        const ctx = getContext(this) as common.UIAbilityContext;
        const fileName = `auth_backup_${Date.now()}.atbk`;
        const tmpPath = `${ctx.filesDir}/${fileName}`;
        try {
            const enc = encryptData(this.tokens, this.backupPw);
            const tmpFile: fs.File = fs.openSync(tmpPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
            fs.writeSync(tmpFile.fd, enc);
            fs.closeSync(tmpFile.fd);
            // Let user save to public directory via picker
            const savePicker = new picker.DocumentViewPicker(ctx);
            const opts: SaveOptions = { newFileNames: [fileName] };
            savePicker.save(opts).then((saveResult: string[]) => {
                if (saveResult && saveResult.length > 0) {
                    const destUri = saveResult[0];
                    // Read tmp and write to dest
                    const srcF: fs.File = fs.openSync(tmpPath, fs.OpenMode.READ_ONLY);
                    const st: fs.Stat = fs.statSync(tmpPath);
                    const buf: ArrayBuffer = new ArrayBuffer(st.size);
                    fs.readSync(srcF.fd, buf);
                    fs.closeSync(srcF);
                    const destF: fs.File = fs.openSync(destUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
                    fs.writeSync(destF.fd, buf);
                    fs.closeSync(destF);
                    this.showBackup = false;
                    this.toast(`已备份 ${this.tokens.length} 个账号到下载目录`);
                }
                else {
                    this.toast('保存取消');
                }
                try {
                    fs.unlink(tmpPath);
                }
                catch (_) { }
            }).catch(() => {
                this.showBackup = false;
                this.toast(`已备份 ${this.tokens.length} 个账号`);
                try {
                    fs.unlink(tmpPath);
                }
                catch (_) { }
            });
        }
        catch (_) {
            this.toast('备份失败');
        }
    }
    private doImport(): void {
        if (!this.importText || !this.importPw)
            return;
        try {
            const data = decryptData(this.importText, this.importPw) as Token[];
            if (!Array.isArray(data))
                throw new Error('invalid');
            const ids = new Set(this.tokens.map((t: Token) => t.id));
            const imported = data.filter((t: Token) => !ids.has(t.id));
            this.tokens = this.tokens.concat(imported);
            saveTokens(this.tokens);
            this.refreshOtp();
            this.showImport = false;
            this.toast(`成功导入 ${imported.length} 个账号`);
        }
        catch (_) {
            this.toast('解密失败，请检查密码');
        }
    }
    private selectImportFile(): void {
        const ctx = getContext(this) as common.UIAbilityContext;
        const docPicker = new picker.DocumentViewPicker(ctx);
        docPicker.select({ maxSelectNumber: 1 }).then((result: string[]) => {
            if (result && result.length > 0) {
                const uri = result[0];
                const fileName = uri.substring(uri.lastIndexOf('/') + 1);
                this.importFileUri = uri;
                this.importFileName = fileName;
                const file: fs.File = fs.openSync(uri, fs.OpenMode.READ_ONLY);
                const stat: fs.Stat = fs.statSync(uri);
                const buf: ArrayBuffer = new ArrayBuffer(stat.size);
                fs.readSync(file.fd, buf);
                this.importText = String.fromCodePoint(...new Uint8Array(buf));
                fs.closeSync(file.fd);
            }
        }).catch(() => { this.toast('选择文件取消'); });
    }
    private selectTheme(idx: number): void {
        const t = THEMES[idx];
        this.accentColor = t.color;
        this.currentTheme = t;
        saveTheme(t);
        this.showTheme = false;
    }
    // ── Builder: Tab Bar Icon ───────────────────────────────────────
    tabIcon(type: string, tabIndex: number, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (type === 'home') {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        SymbolGlyph.create({ "id": 125831533, "type": 40000, params: [], "bundleName": "com.example.arcankey", "moduleName": "entry" });
                        SymbolGlyph.fontColor([this.currentTab === 0 ? this.accentColor : '#d0d0dd']);
                        SymbolGlyph.fontSize(24);
                    }, SymbolGlyph);
                });
            }
            else if (type === 'scan') {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        SymbolGlyph.create({ "id": 125831600, "type": 40000, params: [], "bundleName": "com.example.arcankey", "moduleName": "entry" });
                        SymbolGlyph.fontColor([this.currentTab === 1 ? this.accentColor : '#d0d0dd']);
                        SymbolGlyph.fontSize(24);
                    }, SymbolGlyph);
                });
            }
            else if (type === 'profile') {
                this.ifElseBranchUpdateFunction(2, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        SymbolGlyph.create({ "id": 125832135, "type": 40000, params: [], "bundleName": "com.example.arcankey", "moduleName": "entry" });
                        SymbolGlyph.fontColor([this.currentTab === 2 ? this.accentColor : '#d0d0dd']);
                        SymbolGlyph.fontSize(24);
                    }, SymbolGlyph);
                });
            }
            else // ── Builder: Bottom Nav (悬浮胶囊) ─────────────────────────────
             {
                this.ifElseBranchUpdateFunction(3, () => {
                });
            }
        }, If);
        If.pop();
    }
    // ── Builder: Bottom Nav (悬浮胶囊) ─────────────────────────────
    bottomNav(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            globalThis.Context.animation({ duration: 300, curve: Curve.EaseInOut });
            Row.width('90%');
            Row.height(62);
            Row.position({ x: '5%', y: '100%' });
            Row.translate({ x: 0, y: this.navVisible ? -82 : 0 });
            globalThis.Context.animation(null);
            Row.backgroundColor('rgba(30,30,42,0.92)');
            Row.borderRadius(31);
            Row.border({ width: 0.5, color: 'rgba(255,255,255,0.12)' });
            Row.shadow({ radius: 20, color: 'rgba(0,0,0,0.4)', offsetX: 0, offsetY: 8 });
            Row.justifyContent(FlexAlign.SpaceAround);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 首页
            Column.create({ space: 3 });
            // 首页
            Column.layoutWeight(1);
            // 首页
            Column.width('100%');
            // 首页
            Column.height('100%');
            // 首页
            Column.alignItems(HorizontalAlign.Center);
            // 首页
            Column.justifyContent(FlexAlign.Center);
            // 首页
            Column.onClick(() => {
                this.currentTab = 0;
                if (this.searching) {
                    this.searching = false;
                    this.searchQ = '';
                }
                this.navVisible = true;
            });
        }, Column);
        this.tabIcon.bind(this)('home', 0);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('首页');
            Text.fontSize(11);
            Text.fontWeight(this.currentTab === 0 ? 600 : 500);
            Text.fontColor(this.currentTab === 0 ? this.accentColor : '#d0d0dd');
        }, Text);
        Text.pop();
        // 首页
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 搜索 (紧跟首页)
            Column.create({ space: 3 });
            // 搜索 (紧跟首页)
            Column.layoutWeight(1);
            // 搜索 (紧跟首页)
            Column.width('100%');
            // 搜索 (紧跟首页)
            Column.height('100%');
            // 搜索 (紧跟首页)
            Column.alignItems(HorizontalAlign.Center);
            // 搜索 (紧跟首页)
            Column.justifyContent(FlexAlign.Center);
            // 搜索 (紧跟首页)
            Column.onClick(() => {
                if (this.currentTab !== 0) {
                    this.currentTab = 0;
                }
                this.searching = !this.searching;
                if (!this.searching) {
                    this.searchQ = '';
                }
                this.navVisible = true;
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            SymbolGlyph.create({ "id": 125831500, "type": 40000, params: [], "bundleName": "com.example.arcankey", "moduleName": "entry" });
            SymbolGlyph.fontColor([this.searching ? this.accentColor : '#d0d0dd']);
            SymbolGlyph.fontSize(24);
        }, SymbolGlyph);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('搜索');
            Text.fontSize(10);
            Text.fontWeight(this.searching ? 600 : 500);
            Text.fontColor(this.searching ? this.accentColor : '#d0d0dd');
        }, Text);
        Text.pop();
        // 搜索 (紧跟首页)
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 扫码
            Column.create({ space: 3 });
            // 扫码
            Column.layoutWeight(1);
            // 扫码
            Column.width('100%');
            // 扫码
            Column.height('100%');
            // 扫码
            Column.alignItems(HorizontalAlign.Center);
            // 扫码
            Column.justifyContent(FlexAlign.Center);
            // 扫码
            Column.onClick(() => { this.currentTab = 1; this.navVisible = true; });
        }, Column);
        this.tabIcon.bind(this)('scan', 1);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('扫码');
            Text.fontSize(10);
            Text.fontWeight(this.currentTab === 1 ? 600 : 500);
            Text.fontColor(this.currentTab === 1 ? this.accentColor : '#d0d0dd');
        }, Text);
        Text.pop();
        // 扫码
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 我的
            Column.create({ space: 3 });
            // 我的
            Column.layoutWeight(1);
            // 我的
            Column.width('100%');
            // 我的
            Column.height('100%');
            // 我的
            Column.alignItems(HorizontalAlign.Center);
            // 我的
            Column.justifyContent(FlexAlign.Center);
            // 我的
            Column.onClick(() => { this.currentTab = 2; this.navVisible = true; });
        }, Column);
        this.tabIcon.bind(this)('profile', 2);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('我的');
            Text.fontSize(11);
            Text.fontWeight(this.currentTab === 2 ? 600 : 500);
            Text.fontColor(this.currentTab === 2 ? this.accentColor : '#d0d0dd');
        }, Text);
        Text.pop();
        // 我的
        Column.pop();
        Row.pop();
    }
    // ── Builder: Toast ──────────────────────────────────────────────
    toastView(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 7 });
            Row.padding({ left: 20, right: 20, top: 9, bottom: 9 });
            Row.backgroundColor('rgba(22,22,30,0.96)');
            Row.borderRadius(22);
            Row.border({ width: 1, color: 'rgba(255,255,255,0.08)' });
            Row.shadow({ radius: 24, color: 'rgba(0,0,0,0.55)', offsetX: 0, offsetY: 4 });
            Row.position({ x: '50%', y: '0%' });
            Row.translate({ x: '-50%', y: 0 });
            Row.margin({ bottom: 96 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('✓');
            Text.fontSize(13);
            Text.fontColor('#f0f0f5');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.toastMsg);
            Text.fontSize(13);
            Text.fontColor('#f0f0f5');
            Text.fontWeight(500);
        }, Text);
        Text.pop();
        Row.pop();
    }
    // ── Builder: Modal Header ───────────────────────────────────────
    modalHeader(title: string, onClose: () => void, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 12 });
            Row.width('100%');
            Row.padding({ left: 16, right: 16, top: 14, bottom: 0 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild({ type: ButtonType.Normal });
            Button.backgroundColor('rgba(255,255,255,0.08)');
            Button.borderRadius(11);
            Button.width(36);
            Button.height(36);
            Button.onClick(onClose);
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('×');
            Text.fontSize(20);
            Text.fontColor('rgba(238,238,245,0.75)');
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(title);
            Text.fontSize(17);
            Text.fontWeight(650);
            Text.fontColor('#eeeef5');
        }, Text);
        Text.pop();
        Row.pop();
    }
    // ── Builder: Edit Modal ─────────────────────────────────────────
    editModal(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.width('100%');
            Stack.height('100%');
            Stack.zIndex(300);
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#0d0d12');
            Column.padding({ top: 44 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Header
            Row.create();
            // Header
            Row.width('100%');
            // Header
            Row.padding({ left: 16, right: 16, top: 14, bottom: 8 });
            // Header
            Row.justifyContent(FlexAlign.SpaceBetween);
            // Header
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild({ type: ButtonType.Normal });
            Button.backgroundColor('rgba(255,255,255,0.08)');
            Button.borderRadius(11);
            Button.width(36);
            Button.height(36);
            Button.onClick(() => { this.editToken = {} as Token; });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('×');
            Text.fontSize(20);
            Text.fontColor('rgba(238,238,245,0.75)');
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('编辑账号');
            Text.fontSize(17);
            Text.fontWeight(650);
            Text.fontColor('#eeeef5');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('');
            Text.width(36);
            Text.height(36);
        }, Text);
        Text.pop();
        // Header
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Content
            Scroll.create();
            // Content
            Scroll.scrollBar(BarState.Off);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 14 });
            Column.padding({ left: 20, right: 20 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.padding({ top: 8, bottom: 8 });
            Row.justifyContent(FlexAlign.Center);
        }, Row);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new Logo(this, { brand: this.editBrand || (this.editToken?.brand ?? ''), logoSize: 64 }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 420, col: 15 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            brand: this.editBrand || (this.editToken?.brand ?? ''),
                            logoSize: 64
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        brand: this.editBrand || (this.editToken?.brand ?? ''), logoSize: 64
                    });
                }
            }, { name: "Logo" });
        }
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 6 });
            Column.alignItems(HorizontalAlign.Start);
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('品牌名称');
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.45)');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ text: this.editBrand, placeholder: '' });
            TextInput.onChange((v) => { this.editBrand = v; });
            TextInput.backgroundColor('#191920');
            TextInput.fontColor('#eeeef5');
            TextInput.border({ width: 1, color: 'rgba(255,255,255,0.08)' });
            TextInput.borderRadius(12);
            TextInput.height(44);
            TextInput.padding({ left: 14, right: 14 });
        }, TextInput);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 6 });
            Column.alignItems(HorizontalAlign.Start);
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('账号信息');
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.45)');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ text: this.editAccount, placeholder: '' });
            TextInput.onChange((v) => { this.editAccount = v; });
            TextInput.backgroundColor('#191920');
            TextInput.fontColor('#eeeef5');
            TextInput.border({ width: 1, color: 'rgba(255,255,255,0.08)' });
            TextInput.borderRadius(12);
            TextInput.height(44);
            TextInput.padding({ left: 14, right: 14 });
        }, TextInput);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 6 });
            Column.alignItems(HorizontalAlign.Start);
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('Secret Key（只读）');
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.45)');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('*'.repeat(Math.min(this.editToken?.secret.length ?? 0, 20)));
            Text.fontSize(13);
            Text.fontColor('rgba(238,238,245,0.4)');
            Text.fontFamily('monospace');
            Text.letterSpacing(1);
            Text.width('100%');
            Text.height(44);
            Text.padding({ left: 14, right: 14 });
            Text.textAlign(TextAlign.Start);
            Text.backgroundColor('#191920');
            Text.border({ width: 1, color: 'rgba(255,255,255,0.08)' });
            Text.borderRadius(12);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Bottom bar
            Row.create({ space: 10 });
            // Bottom bar
            Row.width('100%');
            // Bottom bar
            Row.padding({ left: 20, right: 20, top: 12, bottom: 12 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (!this.confirmDelete) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('删除账号');
                        Button.flexGrow(1);
                        Button.backgroundColor('rgba(248,113,113,0.08)');
                        Button.border({ width: 1, color: 'rgba(248,113,113,0.25)' });
                        Button.borderRadius(14);
                        Button.fontColor('#f87171');
                        Button.fontSize(14);
                        Button.fontWeight(600);
                        Button.onClick(() => { this.confirmDelete = true; });
                    }, Button);
                    Button.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('保存');
                        Button.flexGrow(1);
                        Button.backgroundColor(this.accentColor);
                        Button.borderRadius(14);
                        Button.fontColor('#fff');
                        Button.fontSize(14);
                        Button.fontWeight(650);
                        Button.onClick(() => this.saveEdit());
                    }, Button);
                    Button.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('取消');
                        Button.flexGrow(1);
                        Button.backgroundColor(Color.Transparent);
                        Button.border({ width: 1, color: 'rgba(255,255,255,0.1)' });
                        Button.borderRadius(14);
                        Button.fontColor('rgba(238,238,245,0.6)');
                        Button.fontSize(14);
                        Button.onClick(() => { this.confirmDelete = false; });
                    }, Button);
                    Button.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('确认删除');
                        Button.flexGrow(1);
                        Button.backgroundColor('#ef4444');
                        Button.borderRadius(14);
                        Button.fontColor('#fff');
                        Button.fontSize(14);
                        Button.fontWeight(650);
                        Button.onClick(() => this.deleteToken());
                    }, Button);
                    Button.pop();
                });
            }
        }, If);
        If.pop();
        // Bottom bar
        Row.pop();
        Column.pop();
        // Content
        Scroll.pop();
        Column.pop();
        Stack.pop();
    }
    // ── Builder: Login Modal ────────────────────────────────────────
    loginModal(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#0d0d12');
            Column.padding({ top: 44 });
            Column.position({ x: 0, y: 0 });
            Column.zIndex(400);
        }, Column);
        this.modalHeader.bind(this)('登录账号', () => {
            if (this.cdTimer !== -1) {
                clearInterval(this.cdTimer);
                this.cdTimer = -1;
            }
            this.showLogin = false;
        });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 20 });
            Column.padding({ left: 20, right: 20, top: 20 });
            Column.flexGrow(1);
            Column.width('100%');
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.width(72);
            Stack.height(72);
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(72);
            Column.height(72);
            Column.borderRadius(20);
            Column.backgroundColor(this.accentColor);
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('H');
            Text.fontSize(32);
            Text.fontColor('#fff');
            Text.fontWeight(800);
        }, Text);
        Text.pop();
        Stack.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('使用鸿蒙账号快速登录');
            Text.fontSize(14);
            Text.fontColor('rgba(238,238,245,0.55)');
            Text.textAlign(TextAlign.Center);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Privacy agreement
            Row.create({ space: 8 });
            // Privacy agreement
            Row.width('100%');
            // Privacy agreement
            Row.padding({ left: 4, right: 4 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.width(18);
            Stack.height(18);
            Stack.borderRadius(4);
            Stack.backgroundColor(this.privacyAgreed ? this.accentColor : Color.Transparent);
            Stack.border({ width: 1.5, color: this.privacyAgreed ? this.accentColor : 'rgba(238,238,245,0.3)' });
            Stack.onClick(() => { this.privacyAgreed = !this.privacyAgreed; });
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.privacyAgreed) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('✓');
                        Text.fontSize(10);
                        Text.fontColor('#fff');
                        Text.fontWeight(700);
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Stack.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create();
            Text.flexGrow(1);
        }, Text);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Span.create('我已阅读并同意 ');
            Span.fontSize(12);
            Span.fontColor('rgba(238,238,245,0.45)');
        }, Span);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Span.create('《隐私保护协议》');
            Span.fontSize(12);
            Span.fontColor(this.accentColor);
            Span.fontWeight(500);
        }, Span);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Span.create('，授权获取头像、昵称信息');
            Span.fontSize(12);
            Span.fontColor('rgba(238,238,245,0.45)');
        }, Span);
        Text.pop();
        // Privacy agreement
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('鸿蒙账号登录');
            Button.width('100%');
            Button.height(50);
            Button.borderRadius(15);
            Button.backgroundColor(this.privacyAgreed ? this.accentColor : '#191920');
            Button.fontColor(this.privacyAgreed ? '#fff' : 'rgba(238,238,245,0.3)');
            Button.fontSize(15);
            Button.fontWeight(650);
            Button.onClick(() => {
                if (!this.privacyAgreed) {
                    this.toast('请先同意隐私保护协议');
                    return;
                }
                this.loggedIn = true;
                this.userName = '鸿蒙用户';
                this.userPhone = '';
                this.harmonyLogin = true;
                this.showLogin = false;
                this.privacyAgreed = false;
                this.toast('鸿蒙账号登录成功');
            });
        }, Button);
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('将使用设备上的鸿蒙账号信息');
            Text.fontSize(11);
            Text.fontColor('rgba(238,238,245,0.3)');
            Text.textAlign(TextAlign.Center);
        }, Text);
        Text.pop();
        Column.pop();
        Column.pop();
    }
    // ── Builder: Backup Modal ───────────────────────────────────────
    backupModal(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#0d0d12');
            Column.padding({ top: 44 });
            Column.position({ x: 0, y: 0 });
            Column.zIndex(400);
        }, Column);
        this.modalHeader.bind(this)('备份数据', () => { this.showBackup = false; });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 14 });
            Column.padding({ left: 20, right: 20, top: 16 });
            Column.flexGrow(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('ℹ️ 备份文件将使用您设置的密码加密。请牢记密码，忘记密码将无法恢复数据。');
            Text.fontSize(13);
            Text.fontColor('rgba(238,238,245,0.65)');
            Text.lineHeight(22);
            Text.padding(14);
            Text.backgroundColor('rgba(59,130,246,0.1)');
            Text.borderRadius(12);
            Text.border({ width: 1, color: 'rgba(59,130,246,0.2)' });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 6 });
            Column.alignItems(HorizontalAlign.Start);
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('加密密码');
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.45)');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ text: this.backupPw, placeholder: '设置备份密码' });
            TextInput.type(InputType.Password);
            TextInput.onChange((v) => { this.backupPw = v; });
            TextInput.backgroundColor('#191920');
            TextInput.fontColor('#eeeef5');
            TextInput.border({ width: 1, color: 'rgba(255,255,255,0.08)' });
            TextInput.borderRadius(12);
            TextInput.height(44);
            TextInput.padding({ left: 14, right: 14 });
        }, TextInput);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 6 });
            Column.alignItems(HorizontalAlign.Start);
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('确认密码');
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.45)');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ text: this.backupPw2, placeholder: '再次输入密码' });
            TextInput.type(InputType.Password);
            TextInput.onChange((v) => { this.backupPw2 = v; });
            TextInput.backgroundColor('#191920');
            TextInput.fontColor('#eeeef5');
            TextInput.border({ width: 1, color: this.backupPw && this.backupPw2 && this.backupPw !== this.backupPw2 ? '#f87171' : 'rgba(255,255,255,0.08)' });
            TextInput.borderRadius(12);
            TextInput.height(44);
            TextInput.padding({ left: 14, right: 14 });
        }, TextInput);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.backupPw && this.backupPw2 && this.backupPw !== this.backupPw2) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('两次密码不一致');
                        Text.fontSize(12);
                        Text.fontColor('#f87171');
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`将备份 ${this.tokens.length} 个账号`);
            Text.fontSize(13);
            Text.fontColor('rgba(238,238,245,0.35)');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('加密备份并下载');
            Button.width('100%');
            Button.height(50);
            Button.borderRadius(15);
            Button.backgroundColor(this.backupPw && this.backupPw === this.backupPw2 ? this.accentColor : '#191920');
            Button.fontColor(this.backupPw && this.backupPw === this.backupPw2 ? '#fff' : 'rgba(238,238,245,0.3)');
            Button.fontSize(15);
            Button.fontWeight(650);
            Button.margin({ top: 'auto' });
            Button.onClick(() => this.doBackup());
        }, Button);
        Button.pop();
        Column.pop();
        Column.pop();
    }
    // ── Builder: Import Modal ───────────────────────────────────────
    importModal(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#0d0d12');
            Column.padding({ top: 44 });
            Column.position({ x: 0, y: 0 });
            Column.zIndex(400);
        }, Column);
        this.modalHeader.bind(this)('导入备份', () => { this.showImport = false; });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 14 });
            Column.padding({ left: 20, right: 20, top: 16 });
            Column.flexGrow(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel(this.importFileName ? `已选择: ${this.importFileName}` : '选择备份文件');
            Button.width('100%');
            Button.height(44);
            Button.borderRadius(12);
            Button.backgroundColor(this.importFileName ? this.accentColor + '22' : '#191920');
            Button.fontColor(this.importFileName ? this.accentColor : 'rgba(238,238,245,0.4)');
            Button.fontSize(13);
            Button.fontWeight(500);
            Button.onClick(() => this.selectImportFile());
        }, Button);
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 6 });
            Column.alignItems(HorizontalAlign.Start);
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('备份内容（粘贴加密文本）');
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.45)');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextArea.create({ text: this.importText, placeholder: '粘贴备份内容…' });
            TextArea.onChange((v) => { this.importText = v; });
            TextArea.height(120);
            TextArea.backgroundColor('#191920');
            TextArea.fontColor('#eeeef5');
            TextArea.border({ width: 1, color: 'rgba(255,255,255,0.08)' });
            TextArea.borderRadius(12);
            TextArea.placeholderColor('rgba(238,238,245,0.25)');
            TextArea.fontSize(12);
            TextArea.fontFamily('monospace');
        }, TextArea);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 6 });
            Column.alignItems(HorizontalAlign.Start);
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('解密密码');
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.45)');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ text: this.importPw, placeholder: '输入备份时设置的密码' });
            TextInput.type(InputType.Password);
            TextInput.onChange((v) => { this.importPw = v; });
            TextInput.backgroundColor('#191920');
            TextInput.fontColor('#eeeef5');
            TextInput.border({ width: 1, color: 'rgba(255,255,255,0.08)' });
            TextInput.borderRadius(12);
            TextInput.height(44);
            TextInput.padding({ left: 14, right: 14 });
        }, TextInput);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('解密并导入');
            Button.width('100%');
            Button.height(50);
            Button.borderRadius(15);
            Button.backgroundColor(this.importText && this.importPw ? this.accentColor : '#191920');
            Button.fontColor(this.importText && this.importPw ? '#fff' : 'rgba(238,238,245,0.3)');
            Button.fontSize(15);
            Button.fontWeight(650);
            Button.margin({ top: 'auto' });
            Button.onClick(() => this.doImport());
        }, Button);
        Button.pop();
        Column.pop();
        Column.pop();
    }
    // ── Builder: Theme Modal ────────────────────────────────────────
    themeModal(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#0d0d12');
            Column.padding({ top: 44 });
            Column.position({ x: 0, y: 0 });
            Column.zIndex(400);
        }, Column);
        this.modalHeader.bind(this)('皮肤主题', () => { this.showTheme = false; });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Grid.create();
            Grid.columnsTemplate('1fr 1fr 1fr 1fr 1fr');
            Grid.columnsGap(14);
            Grid.rowsGap(14);
            Grid.padding({ left: 16, right: 16, top: 8 });
        }, Grid);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, idx: number) => {
                const t = _item;
                {
                    const itemCreation2 = (elmtId, isInitialRender) => {
                        GridItem.create(() => { }, false);
                    };
                    const observedDeepRender = () => {
                        this.observeComponentCreation2(itemCreation2, GridItem);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Column.create({ space: 7 });
                            Column.alignItems(HorizontalAlign.Center);
                            Column.onClick(() => this.selectTheme(idx));
                        }, Column);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Stack.create();
                            Stack.width(50);
                            Stack.height(50);
                            Stack.borderRadius(16);
                            Stack.backgroundColor(t.color);
                            Stack.border({ width: 3, color: this.currentTheme.name === t.name ? '#fff' : Color.Transparent });
                            Stack.shadow({ radius: this.currentTheme.name === t.name ? 18 : 12, color: t.color + (this.currentTheme.name === t.name ? '' : '55'), offsetX: 0, offsetY: 4 });
                        }, Stack);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            If.create();
                            if (this.currentTheme.name === t.name) {
                                this.ifElseBranchUpdateFunction(0, () => {
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create('✓');
                                        Text.fontSize(18);
                                        Text.fontColor('#fff');
                                    }, Text);
                                    Text.pop();
                                });
                            }
                            else {
                                this.ifElseBranchUpdateFunction(1, () => {
                                });
                            }
                        }, If);
                        If.pop();
                        Stack.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(t.name);
                            Text.fontSize(10);
                            Text.textAlign(TextAlign.Center);
                            Text.lineHeight(13);
                            Text.fontColor(this.currentTheme.name === t.name ? '#eeeef5' : 'rgba(238,238,245,0.45)');
                            Text.fontWeight(this.currentTheme.name === t.name ? 600 : 400);
                        }, Text);
                        Text.pop();
                        Column.pop();
                        GridItem.pop();
                    };
                    observedDeepRender();
                }
            };
            this.forEachUpdateFunction(elmtId, THEMES, forEachItemGenFunction, (t: ThemeItem) => t.name, true, false);
        }, ForEach);
        ForEach.pop();
        Grid.pop();
        Column.pop();
    }
    // ── Builder: Account Info Modal ─────────────────────────────────
    accountInfoModal(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#0d0d12');
            Column.padding({ top: 44 });
            Column.position({ x: 0, y: 0 });
            Column.zIndex(400);
        }, Column);
        this.modalHeader.bind(this)('账号信息', () => { this.showAccountInfo = false; });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 16 });
            Column.padding({ left: 20, right: 20, top: 20 });
            Column.width('100%');
            Column.alignItems(HorizontalAlign.Center);
            Column.flexGrow(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.width(80);
            Stack.height(80);
            Stack.borderRadius(40);
            Stack.backgroundColor(this.accentColor);
            Stack.shadow({ radius: 32, color: this.accentColor + '55', offsetX: 0, offsetY: 8 });
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.userName.length > 0 ? this.userName[0].toUpperCase() : 'U');
            Text.fontSize(36);
            Text.fontColor('#fff');
            Text.fontWeight(800);
        }, Text);
        Text.pop();
        Stack.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.userName);
            Text.fontSize(20);
            Text.fontColor('#eeeef5');
            Text.fontWeight(700);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.userPhone) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.userPhone);
                        Text.fontSize(14);
                        Text.fontColor('rgba(238,238,245,0.4)');
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.harmonyLogin) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('鸿蒙账号登录');
                        Text.fontSize(12);
                        Text.fontColor(this.accentColor);
                        Text.fontWeight(500);
                        Text.padding({ left: 12, right: 12, top: 4, bottom: 4 });
                        Text.backgroundColor(this.accentColor + '15');
                        Text.borderRadius(8);
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('退出登录');
            Button.width('100%');
            Button.height(50);
            Button.borderRadius(15);
            Button.backgroundColor('#ef4444');
            Button.fontColor('#fff');
            Button.fontSize(15);
            Button.fontWeight(650);
            Button.margin({ top: 24 });
            Button.onClick(() => {
                this.showAccountInfo = false;
                this.loggedIn = false;
                this.userName = '';
                this.userPhone = '';
                this.userAvatar = '';
                this.toast('已退出登录');
            });
        }, Button);
        Button.pop();
        Column.pop();
        Column.pop();
    }
    // ── Build ───────────────────────────────────────────────────────
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.width('100%');
            Stack.height('100%');
            Stack.backgroundColor('#0d0d12');
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // ── Tab content ─────────────────────────────────────────────
            Tabs.create({ barPosition: BarPosition.End, index: this.currentTab });
            // ── Tab content ─────────────────────────────────────────────
            Tabs.width('100%');
            // ── Tab content ─────────────────────────────────────────────
            Tabs.height('100%');
            // ── Tab content ─────────────────────────────────────────────
            Tabs.barMode(BarMode.Fixed);
            // ── Tab content ─────────────────────────────────────────────
            Tabs.onChange((index: number) => {
                this.currentTab = index;
                if (this.searching && index !== 0) {
                    this.searching = false;
                    this.searchQ = '';
                }
            });
            // ── Tab content ─────────────────────────────────────────────
            Tabs.barWidth(0);
            // ── Tab content ─────────────────────────────────────────────
            Tabs.padding({ top: 44, bottom: 80 });
        }, Tabs);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new HomeView(this, {
                                tokens: this.tokens,
                                otpMap: this.otpMap,
                                timeLeft: this.timeLeft_,
                                accentColor: this.accentColor,
                                searching: this.__searching,
                                searchQ: this.__searchQ,
                                onEdit: (tok: Token) => {
                                    this.editToken = tok;
                                    this.editBrand = tok.brand;
                                    this.editAccount = tok.account;
                                    this.confirmDelete = false;
                                },
                                onCopy: (code: string, brand: string) => this.copyCode(code, brand),
                                onNavHide: () => { this.navVisible = false; },
                                onNavShow: () => { this.navVisible = true; },
                            }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 752, col: 11 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {
                                    tokens: this.tokens,
                                    otpMap: this.otpMap,
                                    timeLeft: this.timeLeft_,
                                    accentColor: this.accentColor,
                                    searching: this.searching,
                                    searchQ: this.searchQ,
                                    onEdit: (tok: Token) => {
                                        this.editToken = tok;
                                        this.editBrand = tok.brand;
                                        this.editAccount = tok.account;
                                        this.confirmDelete = false;
                                    },
                                    onCopy: (code: string, brand: string) => this.copyCode(code, brand),
                                    onNavHide: () => { this.navVisible = false; },
                                    onNavShow: () => { this.navVisible = true; }
                                };
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {
                                tokens: this.tokens,
                                otpMap: this.otpMap,
                                timeLeft: this.timeLeft_,
                                accentColor: this.accentColor
                            });
                        }
                    }, { name: "HomeView" });
                }
            });
            TabContent.tabBar({ builder: () => {
                    this.tabIcon.call(this, 'home', 0);
                } });
        }, TabContent);
        TabContent.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new ScanView(this, {
                                accentColor: this.accentColor,
                                onAdd: (brand: string, account: string, secret: string) => {
                                    this.addToken(brand, account, secret);
                                },
                                onClose: () => { this.currentTab = 0; },
                            }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 773, col: 11 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {
                                    accentColor: this.accentColor,
                                    onAdd: (brand: string, account: string, secret: string) => {
                                        this.addToken(brand, account, secret);
                                    },
                                    onClose: () => { this.currentTab = 0; }
                                };
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {
                                accentColor: this.accentColor
                            });
                        }
                    }, { name: "ScanView" });
                }
            });
            TabContent.tabBar({ builder: () => {
                    this.tabIcon.call(this, 'scan', 1);
                } });
        }, TabContent);
        TabContent.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new ProfileView(this, {
                                accentColor: this.accentColor,
                                loggedIn: this.loggedIn,
                                userName: this.userName,
                                userPhone: this.userPhone,
                                userAvatar: this.userAvatar,
                                themeName: this.currentTheme.name,
                                harmonyLogin: this.harmonyLogin,
                                onLoginTap: () => {
                                    this.loginPhone = '';
                                    this.loginCode = '';
                                    this.loginCodeSent = false;
                                    this.loginCodeCd = 0;
                                    this.loginNickname = '';
                                    this.showLogin = true;
                                },
                                onBindPhone: () => {
                                    this.loginPhone = '';
                                    this.loginCode = '';
                                    this.loginCodeSent = false;
                                    this.loginCodeCd = 0;
                                    this.loginTab = 1;
                                    this.showLogin = true;
                                },
                                onLogout: () => { this.loggedIn = false; this.userName = ''; this.userPhone = ''; this.userAvatar = ''; this.toast('已退出登录'); },
                                onBackupTap: () => { this.backupPw = ''; this.backupPw2 = ''; this.showBackup = true; },
                                onImportTap: () => { this.importPw = ''; this.importText = ''; this.showImport = true; },
                                onThemeTap: () => { this.showTheme = true; },
                                onAccountTap: () => { this.showAccountInfo = true; },
                            }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 784, col: 11 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {
                                    accentColor: this.accentColor,
                                    loggedIn: this.loggedIn,
                                    userName: this.userName,
                                    userPhone: this.userPhone,
                                    userAvatar: this.userAvatar,
                                    themeName: this.currentTheme.name,
                                    harmonyLogin: this.harmonyLogin,
                                    onLoginTap: () => {
                                        this.loginPhone = '';
                                        this.loginCode = '';
                                        this.loginCodeSent = false;
                                        this.loginCodeCd = 0;
                                        this.loginNickname = '';
                                        this.showLogin = true;
                                    },
                                    onBindPhone: () => {
                                        this.loginPhone = '';
                                        this.loginCode = '';
                                        this.loginCodeSent = false;
                                        this.loginCodeCd = 0;
                                        this.loginTab = 1;
                                        this.showLogin = true;
                                    },
                                    onLogout: () => { this.loggedIn = false; this.userName = ''; this.userPhone = ''; this.userAvatar = ''; this.toast('已退出登录'); },
                                    onBackupTap: () => { this.backupPw = ''; this.backupPw2 = ''; this.showBackup = true; },
                                    onImportTap: () => { this.importPw = ''; this.importText = ''; this.showImport = true; },
                                    onThemeTap: () => { this.showTheme = true; },
                                    onAccountTap: () => { this.showAccountInfo = true; }
                                };
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {
                                accentColor: this.accentColor,
                                loggedIn: this.loggedIn,
                                userName: this.userName,
                                userPhone: this.userPhone,
                                userAvatar: this.userAvatar,
                                themeName: this.currentTheme.name,
                                harmonyLogin: this.harmonyLogin
                            });
                        }
                    }, { name: "ProfileView" });
                }
            });
            TabContent.tabBar({ builder: () => {
                    this.tabIcon.call(this, 'profile', 2);
                } });
        }, TabContent);
        TabContent.pop();
        // ── Tab content ─────────────────────────────────────────────
        Tabs.pop();
        // ── Custom floating bottom nav ──────────────────────────────
        this.bottomNav.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // ── Modals (overlaid on top) ────────────────────────────────
            if (this.editToken.id) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.editModal.bind(this)();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.showLogin) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.loginModal.bind(this)();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.showBackup) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.backupModal.bind(this)();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.showImport) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.importModal.bind(this)();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.showTheme) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.themeModal.bind(this)();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.showAccountInfo) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.accountInfoModal.bind(this)();
                });
            }
            // ── Toast ───────────────────────────────────────────────────
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // ── Toast ───────────────────────────────────────────────────
            if (this.toastVisible) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                        Column.position({ x: 0, y: '100%' });
                        Column.translate({ y: -96 });
                        Column.alignItems(HorizontalAlign.Center);
                        Column.zIndex(9999);
                    }, Column);
                    this.toastView.bind(this)();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Stack.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "Index";
    }
}
registerNamedRoute(() => new Index(undefined, {}), "", { bundleName: "com.example.arcankey", moduleName: "entry", pagePath: "pages/Index", pageFullPath: "entry/src/main/ets/pages/Index", integratedHsp: "false", moduleType: "followWithHap" });
