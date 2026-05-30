import { pasteboard } from '@kit.BasicServicesKit';
import { authentication } from '@kit.AccountKit';
import { common, Want } from '@kit.AbilityKit';
import { window, display } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { preferences } from '@kit.ArkData';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import { Token, OtpPair, ThemeItem, THEMES, INITIAL_TOKENS, FREE_TOKEN_LIMIT, MEMBERSHIP_PRICE, APP_NAME } from '../model/Token';
import { totp, timeLeft } from '../utils/TOTP';
import { initPreferences, loadTokens, saveTokens, loadTheme, saveTheme, loadMember, saveMember, MemberData } from '../utils/StorageUtil';
import { launchPurchase, restoreOwnedPurchases, acknowledgePurchase } from '../utils/IAPUtil';
import { iap } from '@kit.IAPKit';
import { encryptData, decryptData } from '../utils/CryptoUtil';
import { HomeView } from '../views/HomeView';
import { ScanView } from '../views/ScanView';
import { ProfileView } from '../views/ProfileView';
import { Logo } from '../components/Logo';
import { FeedbackView } from '../views/FeedbackView';

interface SaveOptions {
  newFileNames: string[];
}

interface IapError {
  code: number;
}

@Entry
@Component
struct Index {
  // ── Core State ──────────────────────────────────────────────────
  @State tokens: Token[] = [];
  @State otpMap: Record<string, OtpPair> = {};
  @State timeLeft_: number = 30;
  @State currentTab: number = 0;
  @State navVisible: boolean = true;
  @State accentColor: string = '#4080D0';
  @State currentTheme: ThemeItem = THEMES[0];
  @State loggedIn: boolean = false;
  @State userName: string = '';
  @State userPhone: string = '';
  @State userAvatar: string = '';
  @State loginNickname: string = '';

  // ── Edit Modal ──────────────────────────────────────────────────
  @State editToken: Token = {} as Token;
  @State editBrand: string = '';
  @State editAccount: string = '';
  @State confirmDelete: boolean = false;

  // ── Login Modal ─────────────────────────────────────────────────
  @State showLogin: boolean = false;
  @State loginTab: number = 0;
  @State loginPhone: string = '';
  @State loginCode: string = '';
  @State loginCodeSent: boolean = false;
  @State loginCodeCd: number = 0;

  // ── Backup Modal ────────────────────────────────────────────────
  @State showBackup: boolean = false;
  @State backupPw: string = '';
  @State backupPw2: string = '';

  // ── Import Modal ────────────────────────────────────────────────
  @State showImport: boolean = false;
  @State importPw: string = '';
  @State importText: string = '';
  @State importFileUri: string = '';
  @State importFileName: string = '';

  // ── Theme Modal ─────────────────────────────────────────────────
  @State showTheme: boolean = false;

  // ── HarmonyOS Login Flag ────────────────────────────────────────
  @State harmonyLogin: boolean = false;
  @State showAccountInfo: boolean = false;
  @State privacyAgreed: boolean = false;

  // ── Membership ──────────────────────────────────────────────────
  @State isMember: boolean = false;
  @State boundAccount: string = '';

  // ── Edit Secret Visibility ──────────────────────────────────────
  @State editSecretVisible: boolean = false;

  // ── Delete Confirmation ─────────────────────────────────────────
  @State deleteTarget: Token = {} as Token;
  @State showDeleteConfirm: boolean = false;

  // ── QR Export Modal ─────────────────────────────────────────────
  @State showQrToken: Token | null = null;
  @State qrUri: string = '';

  // ── Feedback & Membership Modals ────────────────────────────────
  @State showFeedback: boolean = false;
  @State showMembership: boolean = false;

  // ── Search ──────────────────────────────────────────────────────
  @State searching: boolean = false;
  @State searchQ: string = '';

  // ── Toast ───────────────────────────────────────────────────────
  @State toastMsg: string = '';
  @State toastVisible: boolean = false;

  // ── Navigation safe area (gesture bar height in vp) ─────────────
  @State navSafeBottom: number = 34;

  private timer: number = -1;
  private toastTimer: number = -1;
  private cdTimer: number = -1;
  private autoSyncTimer: number = -1;

  // ── Lifecycle ───────────────────────────────────────────────────
  aboutToAppear(): void {
    this.loadData();
    this.timer = setInterval(() => {
      this.timeLeft_ = timeLeft();
      if (this.timeLeft_ === 30) this.refreshOtp();
    }, 1000) as number;
    this.queryNavSafeArea();
  }

  private queryNavSafeArea(): void {
    const ctx = AppStorage.get<common.UIAbilityContext>('context');
    if (!ctx) return;
    window.getLastWindow(ctx).then((win) => {
      const avoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const density = display.getDefaultDisplaySync().densityPixels;
      const heightVP = avoidArea.bottomRect.height / density;
      if (heightVP > 0) {
        this.navSafeBottom = Math.round(heightVP);
      }
    }).catch(() => {});
  }

  aboutToDisappear(): void {
    clearInterval(this.timer);
    clearTimeout(this.toastTimer);
    if (this.cdTimer !== -1) clearInterval(this.cdTimer);
    if (this.autoSyncTimer !== -1) clearInterval(this.autoSyncTimer);
  }

  // ── Data ────────────────────────────────────────────────────────
  private async loadData(): Promise<void> {
    const ctx = AppStorage.get<common.UIAbilityContext>('context');
    if (!ctx) {
      this.tokens = INITIAL_TOKENS.slice();
      return;
    }
    const inited = await initPreferences(ctx);
    if (!inited) {
      this.tokens = INITIAL_TOKENS.slice();
      return;
    }
    try {
      const saved = await loadTokens();
      this.tokens = (saved && saved.length > 0) ? saved : INITIAL_TOKENS.slice();
      const theme = await loadTheme();
      if (theme) { this.accentColor = theme.color; this.currentTheme = theme; }
      const member: MemberData = await loadMember();
      this.isMember = member.isMember;
      this.boundAccount = member.boundAccount;
      this.refreshOtp();
      if (this.isMember) {
        this.cloudRestore();
        this.startAutoSync();
      } else {
        try {
          const restored = await restoreOwnedPurchases(ctx);
          if (restored) {
            // Preserve existing boundAccount — this.userName is '' at cold-start
            if (!member.isMember) {
              await saveMember(true, member.boundAccount);
            }
            this.isMember = true;
            this.boundAccount = member.boundAccount;
          }
        } catch (_) {}
      }
    } catch (_) {
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
    if (!this.isMember && this.tokens.length >= FREE_TOKEN_LIMIT) {
      this.toast(`免费用户最多添加${FREE_TOKEN_LIMIT}个口令`);
      this.currentTab = 2;
      return;
    }
    const tok: Token = { id: Date.now().toString(), brand: brand, account: account, secret: secret.toUpperCase() };
    this.tokens = this.tokens.concat([tok]);
    saveTokens(this.tokens);
    this.refreshOtp();
    this.currentTab = 0;
    this.toast(`已添加 ${brand}`);
    if (this.isMember) this.cloudBackup();
  }

  private saveEdit(): void {
    if (!this.editToken.id) return;
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

  private isValidToken(t: object): boolean {
    const tok = t as Record<string, string>;
    return typeof tok['id'] === 'string' && tok['id'].length > 0 &&
      typeof tok['secret'] === 'string' && tok['secret'].length > 0;
  }

  private deleteToken(localOnly: boolean): void {
    if (!this.deleteTarget.id && !this.editToken.id) return;
    const id = this.deleteTarget.id || this.editToken.id;
    this.tokens = this.tokens.filter((t: Token) => t.id !== id);
    saveTokens(this.tokens);
    this.refreshOtp();
    this.editToken = {} as Token;
    this.showDeleteConfirm = false;
    this.deleteTarget = {} as Token;
    this.toast('已删除');
    if (this.isMember && !localOnly) this.cloudDelete(id);
  }

  private requestDeleteToken(tok: Token): void {
    this.deleteTarget = tok;
    this.showDeleteConfirm = true;
  }

  private toggleEditSecret(): void {
    if (!this.isMember) return;
    this.editSecretVisible = !this.editSecretVisible;
  }

  private copyCode(code: string, brand: string): void {
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, code);
      pasteboard.getSystemPasteboard().setData(data);
      this.toast(`已复制 ${brand} 验证码`);
    } catch (_) { this.toast('复制失败'); }
  }

  private async doHarmonyLogin(): Promise<void> {
    if (!this.privacyAgreed) { this.toast('请先同意隐私保护协议'); return; }
    const ctx = AppStorage.get<common.UIAbilityContext>('context');
    if (!ctx) { this.toast('系统错误，请重试'); return; }
    try {
      const request = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
      request.scopes = ['openid', 'profile'];
      request.forceAuthorization = true;
      const controller = new authentication.AuthenticationController(ctx);
      const resp = await controller.executeRequest(request);
      const cred = (resp as authentication.AuthorizationWithHuaweiIDResponse).data;
      this.loggedIn = true;
      this.userName = cred?.nickName || '华为用户';
      this.userAvatar = cred?.avatarUri || '';
      this.harmonyLogin = true;
      this.showLogin = false;
      this.privacyAgreed = false;
      this.toast(`[OK] nick=${cred?.nickName ?? 'null'}`);
    } catch (e) {
      const code = (e as IapError).code;
      if (code === authentication.AuthenticationErrorCode.USER_CANCELED) {
        this.toast('已取消登录');
      } else {
        this.loggedIn = true;
        this.userName = '华为用户';
        this.userAvatar = '';
        this.harmonyLogin = true;
        this.showLogin = false;
        this.privacyAgreed = false;
        this.toast(`[ERR] code=${code}`);
      }
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
    if (!this.backupPw || this.backupPw !== this.backupPw2) return;
    const ctx = AppStorage.get<common.UIAbilityContext>('context');
    if (!ctx) { this.toast('上下文错误，请重启应用'); return; }
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
        } else {
          this.toast('保存取消');
        }
        try { fs.unlink(tmpPath); } catch (_) {}
      }).catch(() => {
        this.showBackup = false;
        this.toast(`已备份 ${this.tokens.length} 个账号`);
        try { fs.unlink(tmpPath); } catch (_) {}
      });
    } catch (_) { this.toast('备份失败'); }
  }

  private resetImportState(): void {
    this.importText = '';
    this.importPw = '';
    this.importFileUri = '';
    this.importFileName = '';
  }

  private doImport(): void {
    if (!this.importText || !this.importPw) return;
    try {
      const data = decryptData(this.importText, this.importPw) as Token[];
      if (!Array.isArray(data)) throw new Error('invalid');
      const ids = new Set(this.tokens.map((t: Token) => t.id));
      const imported = data.filter((t: Token) => this.isValidToken(t as object) && !ids.has(t.id));
      this.tokens = this.tokens.concat(imported);
      saveTokens(this.tokens);
      this.refreshOtp();
      this.resetImportState();
      this.showImport = false;
      this.toast(`成功导入 ${imported.length} 个账号`);
    } catch (_) { this.toast('解密失败，请检查密码'); }
  }

  private selectImportFile(): void {
    const ctx = AppStorage.get<common.UIAbilityContext>('context');
    if (!ctx) { this.toast('上下文错误，请重启应用'); return; }
    const docPicker = new picker.DocumentViewPicker(ctx);
    docPicker.select({ maxSelectNumber: 1 }).then((result: string[]) => {
      if (result && result.length > 0) {
        const uri = result[0];
        const fileName = uri.substring(uri.lastIndexOf('/') + 1);
        this.importFileUri = uri;
        this.importFileName = fileName;
        const file: fs.File = fs.openSync(uri, fs.OpenMode.READ_ONLY);
        const stat: fs.Stat = fs.statSync(uri);
        if (stat.size > 1024 * 1024) { fs.closeSync(file.fd); this.toast('文件过大，请选择小于1MB的备份文件'); return; }
        const buf: ArrayBuffer = new ArrayBuffer(stat.size);
        fs.readSync(file.fd, buf);
        const decoder = new util.TextDecoder('utf-8');
        this.importText = decoder.decodeToString(new Uint8Array(buf));
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

  // ── Cloud Backup & Sync (Cloud Kit) ─────────────────────────────
  private cloudBackup(): void {
    if (!this.isMember) return;
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('context');
      if (!ctx) return;
      const prefs = preferences.getPreferencesSync(ctx, { name: 'arcankey_cloud' });
      const data = JSON.stringify(this.tokens);
      prefs.putSync('tokens_backup', data);
      prefs.flushSync();
    } catch (_) {}
  }

  private cloudRestore(): void {
    if (!this.isMember) return;
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('context');
      if (!ctx) return;
      const prefs = preferences.getPreferencesSync(ctx, { name: 'arcankey_cloud' });
      const data = prefs.getSync('tokens_backup', '') as string;
      if (data) {
        const cloudTokens = JSON.parse(data) as Token[];
        if (!Array.isArray(cloudTokens)) return;
        const ids = new Set(this.tokens.map((t: Token) => t.id));
        const newTokens = cloudTokens.filter((t: Token) => this.isValidToken(t as object) && !ids.has(t.id));
        if (newTokens.length > 0) {
          this.tokens = this.tokens.concat(newTokens);
          saveTokens(this.tokens);
          this.refreshOtp();
          this.toast(`从云端同步 ${newTokens.length} 个账号`);
        }
      }
    } catch (_) {}
  }

  private cloudDelete(tokenId: string): void {
    if (!this.isMember) return;
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('context');
      if (!ctx) return;
      const prefs = preferences.getPreferencesSync(ctx, { name: 'arcankey_cloud' });
      const data = prefs.getSync('tokens_backup', '') as string;
      if (data) {
        const parsed = JSON.parse(data) as object;
        if (!Array.isArray(parsed)) return;
        const tokens = (parsed as Token[]).filter((t: Token) => t.id !== tokenId);
        prefs.putSync('tokens_backup', JSON.stringify(tokens));
        prefs.flushSync();
      }
    } catch (_) {}
  }

  private startAutoSync(): void {
    if (!this.isMember) return;
    this.autoSyncTimer = setInterval(() => {
      this.cloudBackup();
    }, 60 * 60 * 1000) as number;
  }

  private async buyMembership(): Promise<void> {
    if (!this.loggedIn) {
      this.showLogin = true;
      return;
    }
    const ctx = AppStorage.get<common.UIAbilityContext>('context');
    if (!ctx) { this.toast('系统错误，请重试'); return; }
    try {
      const tokenResult = await launchPurchase(ctx);
      await saveMember(true, this.userName);
      this.isMember = true;
      this.boundAccount = this.userName;
      this.toast('开通成功');
      this.showMembership = false;
      // Acknowledge purchase to prevent auto-refund after 24h
      try { await acknowledgePurchase(ctx, tokenResult.purchaseToken, tokenResult.purchaseOrderId); } catch (_) {}
    } catch (e) {
      const code = (e as IapError).code;
      if (code === iap.IAPErrorCode.USER_CANCELED) {
        this.toast('已取消');
      } else if (code === iap.IAPErrorCode.ACCOUNT_NOT_LOGGED_IN) {
        this.toast('请先在系统设置中登录华为账号');
      } else if (code === iap.IAPErrorCode.NETWORK_ERROR) {
        this.toast('网络异常，请检查网络后重试');
      } else if (code === iap.IAPErrorCode.PRODUCT_OWNED) {
        await this.restorePurchase();
      } else {
        this.toast(`开通失败（${code ?? '未知'}），请重试`);
      }
    }
  }

  private async restorePurchase(): Promise<void> {
    const ctx = AppStorage.get<common.UIAbilityContext>('context');
    if (!ctx) { this.toast('系统错误，请重试'); return; }
    try {
      const result = await restoreOwnedPurchases(ctx);
      if (result) {
        const bound = this.userName || this.boundAccount;
        await saveMember(true, bound);
        this.isMember = true;
        this.boundAccount = bound;
        this.toast('会员已恢复');
      } else {
        this.toast('未找到有效购买记录');
      }
    } catch (_) {
      this.toast('恢复失败，请检查网络后重试');
    }
  }

  // ── Builder: Tab Bar Icon ───────────────────────────────────────
  @Builder
  tabIcon(type: string, tabIndex: number) {
    if (type === 'home') {
      SymbolGlyph($r('sys.symbol.house'))
        .fontColor([this.currentTab === 0 ? this.accentColor : '#d0d0dd'])
        .fontSize(24)
    } else if (type === 'scan') {
      SymbolGlyph($r('sys.symbol.qrcode'))
        .fontColor([this.currentTab === 1 ? this.accentColor : '#d0d0dd'])
        .fontSize(24)
    } else if (type === 'profile') {
      SymbolGlyph($r('sys.symbol.person'))
        .fontColor([this.currentTab === 2 ? this.accentColor : '#d0d0dd'])
        .fontSize(24)
    }
  }

  // ── Builder: Bottom Nav (悬浮胶囊) ─────────────────────────────
  @Builder
  bottomNav() {
    Row() {
      // 首页
      Column({ space: 3 }) {
        this.tabIcon('home', 0)
        Text('首页')
          .fontSize(11)
          .fontWeight(this.currentTab === 0 ? 600 : 500)
          .fontColor(this.currentTab === 0 ? this.accentColor : '#d0d0dd')
      }
      .layoutWeight(1)
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.currentTab = 0;
        if (this.searching) { this.searching = false; this.searchQ = ''; }
        this.navVisible = true;
      })

      // 搜索 (紧跟首页)
      Column({ space: 3 }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontColor([this.searching ? this.accentColor : '#d0d0dd'])
          .fontSize(24)
        Text('搜索')
          .fontSize(10)
          .fontWeight(this.searching ? 600 : 500)
          .fontColor(this.searching ? this.accentColor : '#d0d0dd')
      }
      .layoutWeight(1)
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        if (this.currentTab !== 0) { this.currentTab = 0; }
        this.searching = !this.searching;
        if (!this.searching) { this.searchQ = ''; }
        this.navVisible = true;
      })

      // 扫码
      Column({ space: 3 }) {
        this.tabIcon('scan', 1)
        Text('扫码')
          .fontSize(10)
          .fontWeight(this.currentTab === 1 ? 600 : 500)
          .fontColor(this.currentTab === 1 ? this.accentColor : '#d0d0dd')
      }
      .layoutWeight(1)
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        if (!this.loggedIn) {
          this.showLogin = true;
          return;
        }
        this.currentTab = 1; this.navVisible = true;
      })

      // 我的
      Column({ space: 3 }) {
        this.tabIcon('profile', 2)
        Text('我的')
          .fontSize(11)
          .fontWeight(this.currentTab === 2 ? 600 : 500)
          .fontColor(this.currentTab === 2 ? this.accentColor : '#d0d0dd')
      }
      .layoutWeight(1)
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .onClick(() => { this.currentTab = 2; this.navVisible = true; })
    }
    .width('90%')
    .height(60)
    .position({ x: '5%', y: '100%' })
    .translate({ x: 0, y: this.navVisible ? -(60 + this.navSafeBottom + 16) : 0 })
    .animation({ duration: 300, curve: Curve.EaseInOut })
    .backgroundColor('rgba(30,30,40,0.45)')
    .backdropBlur(20)
    .borderRadius(30)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.3)', offsetX: 0, offsetY: 4 })
    .justifyContent(FlexAlign.SpaceAround)
  }

  // ── Builder: Toast ──────────────────────────────────────────────
  @Builder
  toastView() {
    Row({ space: 7 }) {
      Text('✓').fontSize(13).fontColor('#f0f0f5')
      Text(this.toastMsg).fontSize(13).fontColor('#f0f0f5').fontWeight(500)
    }
    .padding({ left: 20, right: 20, top: 9, bottom: 9 })
    .backgroundColor('rgba(22,22,30,0.96)')
    .borderRadius(22)
    .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
    .shadow({ radius: 24, color: 'rgba(0,0,0,0.55)', offsetX: 0, offsetY: 4 })
    .position({ x: '50%', y: '0%' })
    .translate({ x: '-50%', y: 0 })
    .margin({ bottom: 96 })
  }

  // ── Builder: Modal Header ───────────────────────────────────────
  @Builder
  modalHeader(title: string, onClose: () => void) {
    Row({ space: 12 }) {
      Button({ type: ButtonType.Normal }) {
        Text('×').fontSize(20).fontColor('rgba(238,238,245,0.75)')
      }
      .backgroundColor('rgba(255,255,255,0.08)').borderRadius(11).width(36).height(36)
      .onClick(onClose)
      Text(title).fontSize(17).fontWeight(650).fontColor('#eeeef5')
    }
    .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 0 })
  }

  // ── Builder: Edit Modal ─────────────────────────────────────────
  @Builder
  editModal() {
    Stack() {
      Column() {
        // Header
        Row() {
          Button({ type: ButtonType.Normal }) {
            Text('×').fontSize(20).fontColor('rgba(238,238,245,0.75)')
          }
          .backgroundColor('rgba(255,255,255,0.08)').borderRadius(11).width(36).height(36)
          .onClick(() => { this.editToken = {} as Token; })
          Text('编辑账号').fontSize(17).fontWeight(650).fontColor('#eeeef5')
          Text('').width(36).height(36)
        }
        .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 8 })
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)

        // Content
        Scroll() {
          Column({ space: 14 }) {
            Row() {
              Logo({ brand: this.editBrand || (this.editToken?.brand ?? ''), logoSize: 64 })
            }
            .width('100%').padding({ top: 8, bottom: 8 }).justifyContent(FlexAlign.Center)

            Column({ space: 6 }) {
              Text('品牌名称').fontSize(12).fontColor('rgba(238,238,245,0.45)')
              TextInput({ text: this.editBrand, placeholder: '' })
                .onChange((v) => { this.editBrand = v; })
                .backgroundColor('#191920').fontColor('#eeeef5')
                .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
                .height(44).padding({ left: 14, right: 14 })
            }.alignItems(HorizontalAlign.Start).width('100%')

            Column({ space: 6 }) {
              Text('账号信息').fontSize(12).fontColor('rgba(238,238,245,0.45)')
              TextInput({ text: this.editAccount, placeholder: '' })
                .onChange((v) => { this.editAccount = v; })
                .backgroundColor('#191920').fontColor('#eeeef5')
                .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
                .height(44).padding({ left: 14, right: 14 })
            }.alignItems(HorizontalAlign.Start).width('100%')

            Column({ space: 6 }) {
              Row({ space: 6 }) {
                Text('Secret Key').fontSize(12).fontColor('rgba(238,238,245,0.45)').flexGrow(1)
                if (this.isMember) {
                  Button({ type: ButtonType.Normal }) {
                    SymbolGlyph(this.editSecretVisible ? $r('sys.symbol.eye_slash') : $r('sys.symbol.eye'))
                      .fontSize(15).fontColor([this.accentColor])
                  }
                  .width(30).height(30).borderRadius(10)
                  .backgroundColor('rgba(255,255,255,0.06)')
                  .onClick(() => { this.editSecretVisible = !this.editSecretVisible; })
                  Button({ type: ButtonType.Normal }) {
                    SymbolGlyph($r('sys.symbol.qrcode'))
                      .fontSize(15).fontColor([this.accentColor])
                  }
                  .width(30).height(30).borderRadius(10)
                  .backgroundColor('rgba(255,255,255,0.06)')
                  .onClick(() => {
                    const t = this.editToken;
                    this.qrUri = 'otpauth://totp/' + encodeURIComponent(t.brand) + ':' +
                      encodeURIComponent(t.account) + '?secret=' + t.secret +
                      '&issuer=' + encodeURIComponent(t.brand);
                    this.showQrToken = t;
                    this.editToken = {} as Token;
                    this.confirmDelete = false;
                  })
                }
              }.alignItems(VerticalAlign.Center)
              Text(this.isMember && this.editSecretVisible ? (this.editToken?.secret ?? '') : '*'.repeat(Math.min(this.editToken?.secret.length ?? 0, 20)))
                .fontSize(13)
                .fontColor(this.isMember && this.editSecretVisible ? '#eeeef5' : 'rgba(238,238,245,0.4)')
                .fontFamily('monospace').letterSpacing(1)
                .width('100%').height(44)
                .padding({ left: 14, right: 14 })
                .textAlign(TextAlign.Start)
                .backgroundColor('#191920')
                .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
                .onClick(() => {
                  if (this.isMember && this.editSecretVisible && this.editToken?.secret) {
                    const d = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.editToken.secret);
                    pasteboard.getSystemPasteboard().setData(d);
                    this.toast('密钥已复制');
                  }
                })
              if (!this.isMember) {
                Text('🔒 开通会员可查看密钥')
                  .fontSize(11).fontColor('rgba(238,238,245,0.25)').margin({ top: 4 })
              }
            }
            .alignItems(HorizontalAlign.Start).width('100%')

            // Bottom bar
            Column({ space: 0 }) {
              if (!this.confirmDelete) {
                Row({ space: 10 }) {
                  Button('删除账号')
                    .flexGrow(1).backgroundColor('rgba(248,113,113,0.08)')
                    .border({ width: 1, color: 'rgba(248,113,113,0.25)' })
                    .borderRadius(14).fontColor('#f87171').fontSize(14).fontWeight(600)
                    .onClick(() => { this.requestDeleteToken(this.editToken); })
                  Button('保存')
                    .flexGrow(1).backgroundColor(this.accentColor)
                    .borderRadius(14).fontColor('#fff').fontSize(14).fontWeight(650)
                    .onClick(() => this.saveEdit())
                }.width('100%')
              } else {
                Row({ space: 10 }) {
                  Button('取消').flexGrow(1).backgroundColor(Color.Transparent)
                    .border({ width: 1, color: 'rgba(255,255,255,0.1)' }).borderRadius(14)
                    .fontColor('rgba(238,238,245,0.6)').fontSize(14)
                    .onClick(() => { this.confirmDelete = false; })
                  Button('确认删除').flexGrow(1).backgroundColor('#ef4444').borderRadius(14)
                    .fontColor('#fff').fontSize(14).fontWeight(650)
                    .onClick(() => this.deleteToken(true))
                }.width('100%')
              }
            }
            .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 12 })
          }
          .padding({ left: 20, right: 20 })
        }.scrollBar(BarState.Off)
      }
      .width('100%').height('100%').backgroundColor('#0d0d12')
      .padding({ top: 44 })
    }
    .width('100%').height('100%').zIndex(300)
  }

  // ── Builder: QR Export Modal ────────────────────────────────────
  @Builder
  qrModal() {
    Stack() {
      Column() {
        Row() {
          Button({ type: ButtonType.Normal }) {
            Text('×').fontSize(20).fontColor('rgba(238,238,245,0.75)')
          }
          .backgroundColor('rgba(255,255,255,0.08)').borderRadius(11).width(36).height(36)
          .onClick(() => { this.showQrToken = null; this.qrUri = ''; })
          Text('导出账号').fontSize(17).fontWeight(650).fontColor('#eeeef5')
          Text('').width(36).height(36)
        }
        .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 8 })
        .justifyContent(FlexAlign.SpaceBetween)

        Scroll() {
          Column({ space: 24 }) {
            Logo({ brand: this.showQrToken?.brand ?? '', logoSize: 56 })
            Column({ space: 12 }) {
              QRCode(this.qrUri)
                .width(240).height(240)
                .color('#eeeef5').backgroundColor('#191920')
                .borderRadius(12)
              Text('用其他验证器扫描此码可直接导入').fontSize(12)
                .fontColor('rgba(238,238,245,0.4)').textAlign(TextAlign.Center)
            }.alignItems(HorizontalAlign.Center).width('100%')
          }
          .alignItems(HorizontalAlign.Center)
          .padding({ left: 20, right: 20, top: 12, bottom: 32 })
        }.scrollBar(BarState.Off).layoutWeight(1)
      }
      .width('100%').height('100%').backgroundColor('#0d0d12')
      .padding({ top: 44 })
    }
    .width('100%').height('100%').zIndex(350)
  }

  // ── Builder: Login Modal ────────────────────────────────────────
  @Builder
  loginModal() {
    Column() {
      this.modalHeader('登录账号', () => {
        if (this.cdTimer !== -1) { clearInterval(this.cdTimer); this.cdTimer = -1; }
        this.showLogin = false;
      })
      Column({ space: 20 }) {
        Stack() {
          Column()
            .width(72).height(72).borderRadius(20)
            .backgroundColor(this.accentColor)
          Text('H').fontSize(32).fontColor('#fff').fontWeight(800)
        }
        .width(72).height(72)

        Text('使用鸿蒙账号快速登录')
          .fontSize(14).fontColor('rgba(238,238,245,0.55)').textAlign(TextAlign.Center)

        // Privacy agreement
        Row({ space: 8 }) {
          Stack() {
            if (this.privacyAgreed) {
              Text('✓').fontSize(10).fontColor('#fff').fontWeight(700)
            }
          }
          .width(18).height(18).borderRadius(4)
          .backgroundColor(this.privacyAgreed ? this.accentColor : Color.Transparent)
          .border({ width: 1.5, color: this.privacyAgreed ? this.accentColor : 'rgba(238,238,245,0.3)' })
          .onClick(() => { this.privacyAgreed = !this.privacyAgreed; })

          Text() {
            Span('我已阅读并同意 ')
              .fontSize(12).fontColor('rgba(238,238,245,0.45)')
            Span('《隐私保护协议》')
              .fontSize(12).fontColor(this.accentColor).fontWeight(500)
              .onClick(() => {
                const ctx = AppStorage.get<common.UIAbilityContext>('context');
                if (!ctx) return;
                const want: Want = {
                  action: 'ohos.want.action.viewData',
                  uri: 'https://mengyuefeitian.github.io/ArcaneKey/privacy.html',
                  entities: ['entity.system.browsable'],
                };
                ctx.startAbility(want).catch((_: Error) => {
                  this.toast('无法打开链接');
                });
              })
            Span('，授权获取头像、昵称信息')
              .fontSize(12).fontColor('rgba(238,238,245,0.45)')
          }
          .flexGrow(1)
        }
        .width('100%')
        .padding({ left: 4, right: 4 })

        Button('鸿蒙账号登录')
          .width('100%').height(50).borderRadius(15)
          .backgroundColor(this.privacyAgreed ? this.accentColor : '#191920')
          .fontColor(this.privacyAgreed ? '#fff' : 'rgba(238,238,245,0.3)')
          .fontSize(15).fontWeight(650)
          .onClick(() => { this.doHarmonyLogin(); })
        Text('将使用设备上的鸿蒙账号信息')
          .fontSize(11).fontColor('rgba(238,238,245,0.3)').textAlign(TextAlign.Center)
      }
      .padding({ left: 20, right: 20, top: 20 })
      .flexGrow(1)
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%').backgroundColor('#0d0d12')
    .padding({ top: 44 })
    .position({ x: 0, y: 0 }).zIndex(400)
  }

  // ── Builder: Backup Modal ───────────────────────────────────────
  @Builder
  backupModal() {
    Column() {
      this.modalHeader('备份数据', () => { this.showBackup = false; })
      Column({ space: 14 }) {
        Text('ℹ️ 备份文件将使用您设置的密码加密。请牢记密码，忘记密码将无法恢复数据。')
          .fontSize(13).fontColor('rgba(238,238,245,0.65)').lineHeight(22)
          .padding(14).backgroundColor('rgba(59,130,246,0.1)')
          .borderRadius(12).border({ width: 1, color: 'rgba(59,130,246,0.2)' })

        Column({ space: 6 }) {
          Text('加密密码').fontSize(12).fontColor('rgba(238,238,245,0.45)')
          TextInput({ text: this.backupPw, placeholder: '设置备份密码' })
            .type(InputType.Password)
            .onChange((v) => { this.backupPw = v; })
            .backgroundColor('#191920').fontColor('#eeeef5')
            .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
            .height(44).padding({ left: 14, right: 14 })
        }.alignItems(HorizontalAlign.Start).width('100%')

        Column({ space: 6 }) {
          Text('确认密码').fontSize(12).fontColor('rgba(238,238,245,0.45)')
          TextInput({ text: this.backupPw2, placeholder: '再次输入密码' })
            .type(InputType.Password)
            .onChange((v) => { this.backupPw2 = v; })
            .backgroundColor('#191920').fontColor('#eeeef5')
            .border({ width: 1, color: this.backupPw && this.backupPw2 && this.backupPw !== this.backupPw2 ? '#f87171' : 'rgba(255,255,255,0.08)' })
            .borderRadius(12)
            .height(44).padding({ left: 14, right: 14 })
        }.alignItems(HorizontalAlign.Start).width('100%')

        if (this.backupPw && this.backupPw2 && this.backupPw !== this.backupPw2) {
          Text('两次密码不一致').fontSize(12).fontColor('#f87171')
        }
        Text(`将备份 ${this.tokens.length} 个账号`)
          .fontSize(13).fontColor('rgba(238,238,245,0.35)')

        Button('加密备份并下载')
          .width('100%').height(50).borderRadius(15)
          .backgroundColor(this.backupPw && this.backupPw === this.backupPw2 ? this.accentColor : '#191920')
          .fontColor(this.backupPw && this.backupPw === this.backupPw2 ? '#fff' : 'rgba(238,238,245,0.3)')
          .fontSize(15).fontWeight(650).margin({ top: 'auto' })
          .onClick(() => this.doBackup())
      }
      .padding({ left: 20, right: 20, top: 16 })
      .flexGrow(1)
    }
    .width('100%').height('100%').backgroundColor('#0d0d12')
    .padding({ top: 44 })
    .position({ x: 0, y: 0 }).zIndex(400)
  }

  // ── Builder: Import Modal ───────────────────────────────────────
  @Builder
  importModal() {
    Column() {
      this.modalHeader('导入备份', () => { this.resetImportState(); this.showImport = false; })
      Column({ space: 14 }) {
        Button(this.importFileName ? `已选择: ${this.importFileName}` : '选择备份文件')
          .width('100%').height(44).borderRadius(12)
          .backgroundColor(this.importFileName ? this.accentColor + '22' : '#191920')
          .fontColor(this.importFileName ? this.accentColor : 'rgba(238,238,245,0.4)')
          .fontSize(13).fontWeight(500)
          .onClick(() => this.selectImportFile())

        Column({ space: 6 }) {
          Text('备份内容（粘贴加密文本）').fontSize(12).fontColor('rgba(238,238,245,0.45)')
          TextArea({ text: this.importText, placeholder: '粘贴备份内容…' })
            .onChange((v) => { this.importText = v; })
            .height(120).backgroundColor('#191920').fontColor('#eeeef5')
            .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
            .placeholderColor('rgba(238,238,245,0.25)').fontSize(12).fontFamily('monospace')
        }.alignItems(HorizontalAlign.Start).width('100%')

        Column({ space: 6 }) {
          Text('解密密码').fontSize(12).fontColor('rgba(238,238,245,0.45)')
          TextInput({ text: this.importPw, placeholder: '输入备份时设置的密码' })
            .type(InputType.Password)
            .onChange((v) => { this.importPw = v; })
            .backgroundColor('#191920').fontColor('#eeeef5')
            .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
            .height(44).padding({ left: 14, right: 14 })
        }.alignItems(HorizontalAlign.Start).width('100%')

        Button('解密并导入')
          .width('100%').height(50).borderRadius(15)
          .backgroundColor(this.importText && this.importPw ? this.accentColor : '#191920')
          .fontColor(this.importText && this.importPw ? '#fff' : 'rgba(238,238,245,0.3)')
          .fontSize(15).fontWeight(650).margin({ top: 'auto' })
          .onClick(() => this.doImport())
      }
      .padding({ left: 20, right: 20, top: 16 })
      .flexGrow(1)
    }
    .width('100%').height('100%').backgroundColor('#0d0d12')
    .padding({ top: 44 })
    .position({ x: 0, y: 0 }).zIndex(400)
  }

  // ── Builder: Theme Modal ────────────────────────────────────────
  @Builder
  memberBenefits() {
    Column({ space: 10 }) {
      ForEach(
        ['无限制添加动态口令', '加密备份数据导入导出', '查看 Secret Key', '云端数据自动同步'],
        (item: string) => {
          Row({ space: 8 }) {
            Text('✓').fontSize(12).fontWeight(700).fontColor(this.accentColor)
            Text(item).fontSize(13).fontColor('rgba(238,238,245,0.7)')
          }.width('100%')
        },
        (item: string) => item
      )
    }
    .padding(14).backgroundColor('#191920').borderRadius(14).width('100%')
  }

  @Builder
  themeModal() {
    Column() {
      this.modalHeader('皮肤主题', () => { this.showTheme = false; })
      Grid() {
        ForEach(THEMES, (t: ThemeItem, idx: number) => {
          GridItem() {
            Column({ space: 7 }) {
              Stack() {
                if (this.currentTheme.name === t.name) {
                  Text('✓').fontSize(18).fontColor('#fff')
                }
              }
              .width(50).height(50).borderRadius(16)
              .backgroundColor(t.color)
              .border({ width: 3, color: this.currentTheme.name === t.name ? '#fff' : Color.Transparent })
              .shadow({ radius: this.currentTheme.name === t.name ? 18 : 12, color: t.color + (this.currentTheme.name === t.name ? '' : '55'), offsetX: 0, offsetY: 4 })
              Text(t.name).fontSize(10).textAlign(TextAlign.Center).lineHeight(13)
                .fontColor(this.currentTheme.name === t.name ? '#eeeef5' : 'rgba(238,238,245,0.45)')
                .fontWeight(this.currentTheme.name === t.name ? 600 : 400)
            }.alignItems(HorizontalAlign.Center)
            .onClick(() => this.selectTheme(idx))
          }
        }, (t: ThemeItem) => t.name)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .columnsGap(14).rowsGap(14)
      .padding({ left: 16, right: 16, top: 8 })
    }
    .width('100%').height('100%').backgroundColor('#0d0d12')
    .padding({ top: 44 })
    .position({ x: 0, y: 0 }).zIndex(400)
  }

  // ── Builder: Delete Confirmation ────────────────────────────────
  @Builder
  deleteConfirmDialog() {
    Column() {
      Text('确认删除').fontSize(16).fontWeight(700).fontColor('#eeeef5').margin({ bottom: 8 })
      Text(`确定要删除「${this.deleteTarget.brand}」吗？${this.isMember ? '\n选择删除方式：' : '\n此操作不可撤销'}`)
        .fontSize(14).fontColor('rgba(238,238,245,0.6)').textAlign(TextAlign.Center).margin({ bottom: 20 }).lineHeight(22)
      if (this.isMember) {
        Row({ space: 10 }) {
          Button('仅本地').flexGrow(1).backgroundColor('rgba(255,255,255,0.08)')
            .border({ width: 1, color: 'rgba(255,255,255,0.1)' }).borderRadius(12)
            .fontColor('rgba(238,238,245,0.7)').fontSize(14)
            .onClick(() => this.deleteToken(true))
          Button('本地+云端').flexGrow(1).backgroundColor('#ef4444').borderRadius(12)
            .fontColor('#fff').fontSize(14).fontWeight(650)
            .onClick(() => this.deleteToken(false))
        }.width('100%')
        Button('取消').width('100%').margin({ top: 10 }).backgroundColor(Color.Transparent)
          .border({ width: 1, color: 'rgba(255,255,255,0.1)' }).borderRadius(12)
          .fontColor('rgba(238,238,245,0.6)').fontSize(14)
          .onClick(() => { this.showDeleteConfirm = false; this.deleteTarget = {} as Token; })
      } else {
        Row({ space: 10 }) {
          Button('取消').flexGrow(1).backgroundColor(Color.Transparent)
            .border({ width: 1, color: 'rgba(255,255,255,0.1)' }).borderRadius(12)
            .fontColor('rgba(238,238,245,0.6)').fontSize(14)
            .onClick(() => { this.showDeleteConfirm = false; this.deleteTarget = {} as Token; })
          Button('确认删除').flexGrow(1).backgroundColor('#ef4444').borderRadius(12)
            .fontColor('#fff').fontSize(14).fontWeight(650)
            .onClick(() => this.deleteToken(true))
        }.width('100%')
      }
    }
    .padding(24).backgroundColor('#191920').borderRadius(20).width('85%')
  }

  // ── Builder: Membership Modal ───────────────────────────────────
  @Builder
  membershipModal() {
    Column() {
      this.modalHeader('开通会员', () => { this.showMembership = false; })
      Scroll() {
        Column({ space: 16 }) {

          if (this.isMember) {
            // ── 状态 3：已开通 ────────────────────────────────────────
            Column({ space: 0 }) {
              Text('✨').fontSize(32).margin({ bottom: 8 })
              Text('您已是会员').fontSize(17).fontWeight(700).fontColor(this.accentColor)
              Text('永久有效').fontSize(12).fontColor('rgba(238,238,245,0.5)').margin({ top: 4 })
            }
            .width('100%').padding(20).alignItems(HorizontalAlign.Center)
            .backgroundColor(this.accentColor + '1e')
            .border({ width: 1, color: this.accentColor + '4d' })
            .borderRadius(14)

            Column({ space: 6 }) {
              Text('绑定账号').fontSize(10).fontColor('rgba(238,238,245,0.4)')
              Row({ space: 10 }) {
                Stack() {
                  Text(this.boundAccount.length > 0 ? this.boundAccount[0].toUpperCase() : '鸿')
                    .fontSize(14).fontColor('#fff').fontWeight(700)
                }
                .width(32).height(32).borderRadius(16)
                .backgroundColor(this.accentColor)
                Column({ space: 2 }) {
                  Text(this.boundAccount || '鸿蒙用户').fontSize(13).fontWeight(600).fontColor('#eeeef5')
                  Text('换设备登录同账号可恢复会员').fontSize(11).fontColor('rgba(238,238,245,0.35)')
                }.alignItems(HorizontalAlign.Start)
              }.width('100%')
            }
            .padding(12).backgroundColor('#191920').borderRadius(12).width('100%')
            .alignItems(HorizontalAlign.Start)

            this.memberBenefits()

          } else {
            // ── 共用：icon + 价格 ─────────────────────────────────────
            Column() {
              Text('👑').fontSize(40)
              Row({ space: 4 }) {
                Text('¥19.90').fontSize(28).fontWeight(800).fontColor('#eeeef5')
                Text('永久会员').fontSize(12).fontColor('rgba(238,238,245,0.4)')
              }
              .alignItems(VerticalAlign.Bottom)
              .margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 24, bottom: 20 })
            .width('100%')

            // ── 共用：权益列表 ────────────────────────────────────────
            this.memberBenefits()

            if (!this.loggedIn) {
              // ── 状态 1：未登录 ──────────────────────────────────────
              Column({ space: 4 }) {
                Text('购买会员需要先登录').fontSize(12).fontColor('rgba(238,238,245,0.55)')
                Text('会员将绑定至您的鸿蒙账号').fontSize(11).fontColor('rgba(238,238,245,0.35)')
              }
              .width('100%').padding(10).alignItems(HorizontalAlign.Center)
              .backgroundColor(this.accentColor + '1a')
              .border({ width: 1, color: this.accentColor + '40' })
              .borderRadius(10)

              Button('登录后开通')
                .width('100%').height(50).borderRadius(15)
                .backgroundColor(this.accentColor).fontColor('#fff')
                .fontSize(15).fontWeight(650)
                .onClick(() => {
                  this.showMembership = false;
                  this.loginPhone = '';
                  this.loginCode = '';
                  this.loginCodeSent = false;
                  this.loginCodeCd = 0;
                  this.showLogin = true;
                })

            } else {
              // ── 状态 2：已登录 · 未开通 ─────────────────────────────
              Row({ space: 8 }) {
                Text('👤').fontSize(16)
                Column({ space: 2 }) {
                  Text('购买后绑定至').fontSize(10).fontColor('rgba(238,238,245,0.5)')
                  Text(this.userName || '鸿蒙用户').fontSize(12).fontWeight(600).fontColor('#eeeef5')
                }.alignItems(HorizontalAlign.Start)
              }
              .width('100%').padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor(this.accentColor + '14')
              .border({ width: 1, color: this.accentColor + '33' })
              .borderRadius(10)

              Column({ space: 8 }) {
                Button('立即开通会员')
                  .width('100%').height(50).borderRadius(15)
                  .backgroundColor(this.accentColor).fontColor('#fff')
                  .fontSize(15).fontWeight(650)
                  .onClick(() => { this.buyMembership(); })

                Row() {
                  Text('换机后可用同一账号 ').fontSize(11).fontColor('rgba(238,238,245,0.3)')
                  Text('恢复购买')
                    .fontSize(11).fontColor(this.accentColor)
                    .onClick(() => { this.restorePurchase(); })
                }
                .justifyContent(FlexAlign.Center).width('100%')
              }
            }
          }

        }
        .padding({ left: 20, right: 20, bottom: 40 })
      }
      .scrollBar(BarState.Off).flexGrow(1)
    }
    .width('100%').height('100%').backgroundColor('#0d0d12')
    .padding({ top: 44 })
    .position({ x: 0, y: 0 }).zIndex(400)
  }

  // ── Builder: Account Info Modal ─────────────────────────────────
  @Builder
  accountInfoModal() {
    Column() {
      this.modalHeader('账号信息', () => { this.showAccountInfo = false; })
      Column({ space: 16 }) {
        Stack() {
          Text(this.userName.length > 0 ? this.userName[0].toUpperCase() : 'U')
            .fontSize(36).fontColor('#fff').fontWeight(800)
        }
        .width(80).height(80).borderRadius(40)
        .backgroundColor(this.accentColor)
        .shadow({ radius: 32, color: this.accentColor + '55', offsetX: 0, offsetY: 8 })

        Text(this.userName).fontSize(20).fontColor('#eeeef5').fontWeight(700)
        if (this.userPhone) {
          Text(this.userPhone).fontSize(14).fontColor('rgba(238,238,245,0.4)')
        }
        if (this.harmonyLogin) {
          Text('鸿蒙账号登录').fontSize(12).fontColor(this.accentColor).fontWeight(500)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .backgroundColor(this.accentColor + '15')
            .borderRadius(8)
        }

        Button('退出登录')
          .width('100%').height(50).borderRadius(15)
          .backgroundColor('#ef4444').fontColor('#fff')
          .fontSize(15).fontWeight(650).margin({ top: 24 })
          .onClick(() => {
            this.showAccountInfo = false;
            this.loggedIn = false;
            this.userName = '';
            this.userPhone = '';
            this.userAvatar = '';
            this.toast('已退出登录');
          })
      }
      .padding({ left: 20, right: 20, top: 20 })
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .flexGrow(1)
    }
    .width('100%').height('100%').backgroundColor('#0d0d12')
    .padding({ top: 44 })
    .position({ x: 0, y: 0 }).zIndex(400)
  }

  // ── Build ───────────────────────────────────────────────────────
  build() {
    Stack() {
      // ── Tab content ─────────────────────────────────────────────
      Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
        TabContent() {
          HomeView({
            tokens: this.tokens,
            otpMap: this.otpMap,
            timeLeft: this.timeLeft_,
            accentColor: this.accentColor,
            searching: $searching,
            searchQ: $searchQ,
            onEdit: (tok: Token) => {
              this.editToken = tok;
              this.editBrand = tok.brand;
              this.editAccount = tok.account;
              this.editSecretVisible = false;
              this.confirmDelete = false;
            },
            onCopy: (code: string, brand: string) => this.copyCode(code, brand),
            onDelete: (tok: Token) => this.requestDeleteToken(tok),
            onNavHide: () => { this.navVisible = false; },
            onNavShow: () => { this.navVisible = true; },
          })
        }
        .tabBar(this.tabIcon('home', 0))

        TabContent() {
          ScanView({
            accentColor: this.accentColor,
            navBottomPad: 60 + this.navSafeBottom + 16,
            onAdd: (brand: string, account: string, secret: string) => {
              this.addToken(brand, account, secret);
            },
            onClose: () => { this.currentTab = 0; },
          })
        }
        .tabBar(this.tabIcon('scan', 1))

        TabContent() {
          ProfileView({
            accentColor: this.accentColor,
            loggedIn: this.loggedIn,
            userName: this.userName,
            userPhone: this.userPhone,
            userAvatar: this.userAvatar,
            themeName: this.currentTheme.name,
            harmonyLogin: this.harmonyLogin,
            isMember: this.isMember,
            boundAccount: this.boundAccount,
            onLoginTap: () => {
              this.loginPhone = ''; this.loginCode = ''; this.loginCodeSent = false; this.loginCodeCd = 0;
              this.loginNickname = '';
              this.showLogin = true;
            },
            onBindPhone: () => {
              this.loginPhone = ''; this.loginCode = ''; this.loginCodeSent = false; this.loginCodeCd = 0;
              this.loginTab = 1;
              this.showLogin = true;
            },
            onLogout: () => { this.loggedIn = false; this.userName = ''; this.userPhone = ''; this.userAvatar = ''; this.toast('已退出登录'); },
            onBackupTap: () => {
              if (!this.isMember) { this.toast('备份功能需要开通会员'); this.showMembership = true; return; }
              this.backupPw = ''; this.backupPw2 = ''; this.showBackup = true;
            },
            onImportTap: () => {
              if (!this.isMember) { this.toast('导入功能需要开通会员'); this.showMembership = true; return; }
              this.importPw = ''; this.importText = ''; this.showImport = true;
            },
            onThemeTap: () => { this.showTheme = true; },
            onAccountTap: () => { this.showAccountInfo = true; },
            onMembershipTap: () => { this.showMembership = true; },
            onFeedbackTap: () => { this.showFeedback = true; },
          })
        }
        .tabBar(this.tabIcon('profile', 2))
      }
      .width('100%')
      .height('100%')
      .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        this.currentTab = index;
        if (this.searching && index !== 0) { this.searching = false; this.searchQ = ''; }
      })
      // Hide the default tab bar — we use our custom floating nav
      .barWidth(0)
      .barHeight(0)
      .padding({ top: 44 })

      // ── Custom floating bottom nav ──────────────────────────────
      this.bottomNav()

      // ── Modals (overlaid on top) ────────────────────────────────
      if (this.editToken.id) { this.editModal() }
      if (this.showQrToken !== null && this.isMember) { this.qrModal() }
      if (this.showLogin)  { this.loginModal() }
      if (this.showBackup) { this.backupModal() }
      if (this.showImport) { this.importModal() }
      if (this.showTheme)  { this.themeModal() }
      if (this.showAccountInfo) { this.accountInfoModal() }
      if (this.showMembership) { this.membershipModal() }
      if (this.showFeedback) {
        FeedbackView({
          accentColor: this.accentColor,
          onClose: () => { this.showFeedback = false; }
        })
      }
      if (this.showDeleteConfirm) {
        Column() {
          this.deleteConfirmDialog()
        }
        .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.6)')
        .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
        .zIndex(999)
      }

      // ── Toast ───────────────────────────────────────────────────
      if (this.toastVisible) {
        Column() {
          this.toastView()
        }
        .width('100%')
        .position({ x: 0, y: '100%' })
        .translate({ y: -96 })
        .alignItems(HorizontalAlign.Center)
        .zIndex(9999)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0d0d12')
  }
}
