import { Logo } from '../components/Logo';
import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { scanBarcode, scanCore, customScan } from '@kit.ScanKit';
import { display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct ScanView {
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  @Prop navBottomPad: number = 110;
  // Parent Tabs index===1. aboutToAppear only runs once while tab content stays alive;
  // @Watch on isActive starts/stops the embedded camera every enter/leave.
  @Prop @Watch('onActiveChanged') isActive: boolean = false;
  onAdd: (brand: string, account: string, secret: string) => void = () => {};
  onClose: () => void = () => {};

  @State tab: number = 0; // 0=camera,1=album,2=manual
  @State brand: string = '';
  @State account: string = '';
  @State secret: string = '';
  @State brandErr: string = '';
  @State secretErr: string = '';
  @State scanned: boolean = false;
  @State scanning: boolean = false;
  @State scanErrMsg: string = '';
  // Surface size in px for customScan.ViewControl
  @State private surfaceW: number = 0;
  @State private surfaceH: number = 0;
  // Preview container size in vp — drives square viewfinder + side/top/bottom masks
  @State private previewW: number = 0;
  @State private previewH: number = 0;

  private xController: XComponentController = new XComponentController();
  private surfaceId: string = '';
  private cameraRunning: boolean = false;
  // Prevent double init/start while permission dialog or start is in flight
  private cameraStarting: boolean = false;

  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  /** Side length of the square clear window (vp). */
  private squareSideVp(): number {
    if (this.previewW <= 0 || this.previewH <= 0) {
      return 0;
    }
    // ~82% of the shorter edge so top/bottom/side masks all show
    return Math.floor(Math.min(this.previewW, this.previewH) * 0.82);
  }

  private maskTopBottomVp(): number {
    const side = this.squareSideVp();
    if (side <= 0) {
      return 0;
    }
    return Math.max(0, Math.floor((this.previewH - side) / 2));
  }

  private maskLeftRightVp(): number {
    const side = this.squareSideVp();
    if (side <= 0) {
      return 0;
    }
    return Math.max(0, Math.floor((this.previewW - side) / 2));
  }

  private onPreviewAreaChange(widthVp: number, heightVp: number): void {
    if (widthVp > 0 && heightVp > 0) {
      this.previewW = widthVp;
      this.previewH = heightVp;
    }
  }

  aboutToAppear(): void {
    if (this.isActive) {
      this.resetScanUiState();
    } else {
      this.resetScanUiState();
    }
  }

  aboutToDisappear(): void {
    this.stopEmbeddedCamera();
  }

  private onActiveChanged(): void {
    if (this.isActive) {
      this.resetScanUiState();
      // XComponent mounts when tab===0; onLoad / size ready will start camera
      if (this.tab === 0 && this.surfaceId.length > 0) {
        this.startEmbeddedCamera();
      }
    } else {
      this.stopEmbeddedCamera();
    }
  }

  private resetScanUiState(): void {
    this.brand = '';
    this.account = '';
    this.secret = '';
    this.brandErr = '';
    this.secretErr = '';
    this.scanned = false;
    this.tab = 0;
    this.scanErrMsg = '';
    this.scanning = false;
  }

  private onSubTabChange(idx: number): void {
    if (idx === this.tab) {
      return;
    }
    // Leaving camera sub-tab → release camera immediately
    if (this.tab === 0 && idx !== 0) {
      this.stopEmbeddedCamera();
    }
    this.tab = idx;
    // Entering camera sub-tab while scan page active
    if (idx === 0 && this.isActive && this.surfaceId.length > 0) {
      this.startEmbeddedCamera();
    }
  }

  private validate(): boolean {
    this.brandErr = this.brand.trim() ? '' : '请输入品牌名称';
    this.secretErr = this.secret.trim() ? '' : '请输入 Secret Key';
    return !this.brandErr && !this.secretErr;
  }

  private parseOtpUri(uri: string): void {
    if (!uri.startsWith('otpauth://totp/')) {
      this.scanErrMsg = '无法识别二维码内容';
      setTimeout(() => { this.scanErrMsg = ''; }, 2200);
      return;
    }
    try {
      const q = uri.split('?')[1] ?? '';
      const params: Record<string, string> = {};
      q.split('&').forEach((p: string) => {
        const kv = p.split('=');
        const k = kv[0];
        const v = kv[1];
        if (k && v) params[k] = decodeURIComponent(v);
      });
      const label = uri.split('/totp/')[1]?.split('?')[0] ?? '';
      const dec = decodeURIComponent(label);
      const b = params['issuer'] || (dec.includes(':') ? dec.split(':')[0] : dec);
      const a = dec.includes(':') ? dec.split(':')[1] : dec;
      const s = params['secret'] ?? '';

      if (s.trim()) {
        this.onAdd(b.trim(), a.trim(), s.trim().toUpperCase());
        this.onClose();
      } else {
        this.scanErrMsg = '无法识别二维码内容';
        setTimeout(() => { this.scanErrMsg = ''; }, 2200);
      }
    } catch (e) {
      this.scanErrMsg = '无法识别二维码内容';
      setTimeout(() => { this.scanErrMsg = ''; }, 2200);
    }
  }

  private async requestCameraPermission(ctx: common.UIAbilityContext): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    const permission: Permissions = 'ohos.permission.CAMERA';
    try {
      const result = await atManager.requestPermissionsFromUser(ctx, [permission]);
      return result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (e) {
      return false;
    }
  }

  private onSurfaceReady(surfaceId: string): void {
    this.surfaceId = surfaceId;
    if (this.isActive && this.tab === 0) {
      this.startEmbeddedCamera();
    }
  }

  private onSurfaceSize(widthVp: number, heightVp: number): void {
    try {
      const density = display.getDefaultDisplaySync().densityPixels;
      const w = Math.round(widthVp * density);
      const h = Math.round(heightVp * density);
      if (w > 0 && h > 0) {
        this.surfaceW = w;
        this.surfaceH = h;
      }
    } catch (_) {
      // Fallback filled in startEmbeddedCamera via display size
    }
  }

  /**
   * Full-frame customScan into the page-local XComponent.
   * Center frame is visual only; decode uses the whole camera stream.
   */
  private async startEmbeddedCamera(): Promise<void> {
    if (!this.isActive || this.tab !== 0) {
      return;
    }
    if (this.cameraRunning || this.cameraStarting) {
      return;
    }
    if (this.surfaceId.length === 0) {
      return;
    }

    this.cameraStarting = true;
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('context');
      if (!ctx) {
        this.scanErrMsg = '上下文错误，请重启应用';
        setTimeout(() => { this.scanErrMsg = ''; }, 2200);
        return;
      }
      const granted = await this.requestCameraPermission(ctx);
      if (!granted) {
        this.scanErrMsg = '需要相机权限才能扫码';
        setTimeout(() => { this.scanErrMsg = ''; }, 2200);
        return;
      }
      // User may have left while the permission dialog was open
      if (!this.isActive || this.tab !== 0 || this.surfaceId.length === 0) {
        return;
      }

      let w = this.surfaceW;
      let h = this.surfaceH;
      if (w <= 0 || h <= 0) {
        const d = display.getDefaultDisplaySync();
        w = d.width;
        h = d.height;
      }

      const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.QR_CODE],
        enableMultiMode: false,
        enableAlbum: false
      };
      try {
        customScan.init(options);
      } catch (e) {
        console.error('[ScanView] customScan.init failed:', (e as BusinessError).message);
      }

      const viewControl: customScan.ViewControl = {
        width: w,
        height: h,
        surfaceId: this.surfaceId
      };

      this.cameraRunning = true;
      this.scanning = true;

      customScan.start(viewControl, (err: BusinessError, result: Array<scanBarcode.ScanResult>) => {
        if (err) {
          // User leave / stop often surfaces as error; avoid noisy toast if we already stopped
          if (this.cameraRunning) {
            console.warn('[ScanView] customScan callback error:', err.code, err.message);
          }
          this.cameraRunning = false;
          this.scanning = false;
          return;
        }
        if (!result || result.length === 0) {
          return;
        }
        const value = result[0].originalValue;
        if (!value) {
          return;
        }
        // Success: close camera first, then add token
        this.stopEmbeddedCamera().then(() => {
          this.parseOtpUri(value);
        });
      });
    } catch (e) {
      console.error('[ScanView] startEmbeddedCamera failed:', (e as Error).message);
      this.scanErrMsg = '扫码启动失败，请重试';
      setTimeout(() => { this.scanErrMsg = ''; }, 2200);
      this.cameraRunning = false;
      this.scanning = false;
      try {
        await customScan.release();
      } catch (_) {
      }
    } finally {
      this.cameraStarting = false;
    }
  }

  private async stopEmbeddedCamera(): Promise<void> {
    const wasRunning = this.cameraRunning || this.cameraStarting;
    this.cameraRunning = false;
    this.cameraStarting = false;
    this.scanning = false;
    if (!wasRunning && this.surfaceId.length === 0) {
      return;
    }
    try {
      await customScan.stop();
    } catch (_) {
    }
    try {
      await customScan.release();
    } catch (_) {
    }
  }

  /** Album path: system scan UI with album enabled (camera preview embedded path is separate). */
  private async doAlbumScan(): Promise<void> {
    if (this.scanning && this.cameraRunning) {
      await this.stopEmbeddedCamera();
    }
    if (this.scanning) {
      return;
    }
    this.scanning = true;
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('context');
      if (!ctx) {
        this.scanErrMsg = '上下文错误，请重启应用';
        setTimeout(() => { this.scanErrMsg = ''; }, 2200);
        this.scanning = false;
        return;
      }
      const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.QR_CODE],
        enableMultiMode: false,
        enableAlbum: true
      };
      const result: scanBarcode.ScanResult = await scanBarcode.startScanForResult(ctx, options);
      if (result?.originalValue) {
        this.parseOtpUri(result.originalValue);
      } else {
        this.scanErrMsg = '未识别到二维码';
        setTimeout(() => { this.scanErrMsg = ''; }, 2200);
      }
    } catch (e) {
      this.scanErrMsg = '选择图片失败，请重试';
      setTimeout(() => { this.scanErrMsg = ''; }, 2200);
    }
    this.scanning = false;
  }

  @Builder
  scanCorners() {
    Stack() {
      Row()
        .width(22).height(3).backgroundColor(this.accentColor)
        .position({ x: 0, y: 0 }).borderRadius(2)
      Row()
        .width(3).height(22).backgroundColor(this.accentColor)
        .position({ x: 0, y: 0 }).borderRadius(2)
      Row()
        .width(22).height(3).backgroundColor(this.accentColor)
        .position({ x: '100%', y: 0 }).borderRadius(2)
        .translate({ x: '-100%' })
      Row()
        .width(3).height(22).backgroundColor(this.accentColor)
        .position({ x: '100%', y: 0 }).borderRadius(2)
        .translate({ x: '-100%' })
      Row()
        .width(22).height(3).backgroundColor(this.accentColor)
        .position({ x: 0, y: '100%' }).borderRadius(2)
        .translate({ y: '-100%' })
      Row()
        .width(3).height(22).backgroundColor(this.accentColor)
        .position({ x: 0, y: '100%' }).borderRadius(2)
        .translate({ y: '-100%' })
      Row()
        .width(22).height(3).backgroundColor(this.accentColor)
        .position({ x: '100%', y: '100%' }).borderRadius(2)
        .translate({ x: '-100%', y: '-100%' })
      Row()
        .width(3).height(22).backgroundColor(this.accentColor)
        .position({ x: '100%', y: '100%' }).borderRadius(2)
        .translate({ x: '-100%', y: '-100%' })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * Full-bleed camera under; square clear window in the center; masks on all four sides.
   * Sizes come from measured preview container (vp) so the hole stays square on tall screens.
   */
  @Builder
  cameraMaskAndFrame() {
    Column() {
      // Top mask
      Column()
        .width('100%')
        .height(this.maskTopBottomVp())
        .backgroundColor('rgba(0,0,0,0.55)')

      // Middle: left mask | square window | right mask
      Row() {
        Column()
          .width(this.maskLeftRightVp())
          .height(this.squareSideVp())
          .backgroundColor('rgba(0,0,0,0.55)')

        Stack({ alignContent: Alignment.Center }) {
          this.scanCorners()
        }
        .width(this.squareSideVp())
        .height(this.squareSideVp())

        Column()
          .width(this.maskLeftRightVp())
          .height(this.squareSideVp())
          .backgroundColor('rgba(0,0,0,0.55)')
      }
      .width('100%')
      .height(this.squareSideVp())

      // Bottom mask (absorb any 1vp rounding remainder with layoutWeight)
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.55)')
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Column() {
      // Header
      Row({ space: 12 }) {
        Button({ type: ButtonType.Normal }) {
          Text('×').fontSize(20).fontColor(this.c('rgba(238,238,245,0.75)', '#5C4F43'))
        }
        .backgroundColor(this.c('rgba(255,255,255,0.08)', 'rgba(0,0,0,0.06)')).borderRadius(11)
        .width(36).height(36)
        .onClick(() => {
          this.stopEmbeddedCamera();
          this.onClose();
        })

        Text('添加账号').fontSize(17).fontWeight(650).fontColor(this.c('#eeeef5', '#2C1810'))
      }
      .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 0 })

      // Sub-tabs
      Row({ space: 2 }) {
        ForEach(['扫二维码', '选相册', '手动输入'], (label: string, idx: number) => {
          Text(label)
            .flexGrow(1).textAlign(TextAlign.Center)
            .fontSize(12).fontWeight(this.tab === idx ? 650 : 400)
            .fontColor(this.tab === idx ? '#fff' : this.c('rgba(238,238,245,0.65)', '#6B5B50'))
            .backgroundColor(this.tab === idx ? this.accentColor : Color.Transparent)
            .borderRadius(10).padding({ top: 8, bottom: 8 })
            .onClick(() => { this.onSubTabChange(idx); })
        }, (label: string) => label)
      }
      .margin({ left: 16, right: 16, top: 14 })
      .padding(4).backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(13)
      .width('calc(100% - 32vp)')

      if (this.scanErrMsg) {
        Text(this.scanErrMsg)
          .fontSize(13).fontColor('#f87171').fontWeight(500)
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .backgroundColor('rgba(248,113,113,0.1)')
          .borderRadius(12).margin({ top: 8 })
      }

      if (this.tab === 0) {
        // Embedded camera: full-area preview + center viewfinder mask
        Column({ space: 12 }) {
          Stack() {
            // Only mount surface while scan tab is active to free camera when leaving
            if (this.isActive) {
              XComponent({
                id: 'arcane_scan_surface',
                type: XComponentType.SURFACE,
                controller: this.xController
              })
                .width('100%')
                .height('100%')
                .onLoad(() => {
                  try {
                    const sid = this.xController.getXComponentSurfaceId();
                    this.onSurfaceReady(sid);
                  } catch (e) {
                    console.error('[ScanView] getXComponentSurfaceId failed:', (e as Error).message);
                  }
                })
                .onDestroy(() => {
                  this.surfaceId = '';
                  this.stopEmbeddedCamera();
                })
                .onAreaChange((_oldVal: Area, newVal: Area) => {
                  const w = Number(newVal.width);
                  const h = Number(newVal.height);
                  if (w > 0 && h > 0) {
                    this.onSurfaceSize(w, h);
                  }
                })
            } else {
              Column()
                .width('100%').height('100%')
                .backgroundColor('#000')
            }

            this.cameraMaskAndFrame()
          }
          .width('100%')
          .layoutWeight(1)
          .borderRadius(22)
          .clip(true)
          .border({ width: 1, color: 'rgba(255,255,255,0.07)' })
          .margin({ left: 16, right: 16, top: 12 })
          .onAreaChange((_oldVal: Area, newVal: Area) => {
            const w = Number(newVal.width);
            const h = Number(newVal.height);
            if (w > 0 && h > 0) {
              this.onPreviewAreaChange(w, h);
            }
          })

          Text(this.scanning ? '将二维码对准框内，自动识别…' : '正在准备相机…')
            .fontSize(13)
            .fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
            .textAlign(TextAlign.Center)
            .padding({ bottom: 8 })
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.tab === 1) {
        Column({ space: 18 }) {
          Text('🖼️').fontSize(38)
            .width(88).height(88).textAlign(TextAlign.Center)
            .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(24)
            .border({ width: 1, color: this.c('rgba(255,255,255,0.07)', '#E8E2D9') })
          Text('从相册中选择含二维码的图片\n自动识别并添加账号')
            .fontSize(14).fontColor(this.c('rgba(238,238,245,0.5)', '#5C4F43')).textAlign(TextAlign.Center)
          Button('选择图片')
            .width('100%').height(50).borderRadius(15)
            .backgroundColor(this.accentColor).fontColor('#fff').fontSize(15).fontWeight(650)
            .onClick(() => { this.doAlbumScan(); })
        }
        .width('100%').padding({ top: 36, left: 16, right: 16 }).alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 14 }) {
            Column({ space: 6 }) {
              Row({ space: 4 }) {
                Text('品牌名称').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50')).fontWeight(500)
                Text('*').fontSize(12).fontColor(this.accentColor)
              }
              TextInput({ text: this.brand, placeholder: '如 Google、Microsoft…' })
                .onChange((v) => { this.brand = v; this.brandErr = ''; })
                .backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
                .border({ width: 1, color: this.brandErr ? '#f87171' : this.c('rgba(255,255,255,0.08)', '#E8E2D9') })
                .borderRadius(12).placeholderColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
                .height(44).padding({ left: 14, right: 14 })
              if (this.brandErr) { Text(this.brandErr).fontSize(11).fontColor('#f87171') }
            }.alignItems(HorizontalAlign.Start).width('100%')

            Column({ space: 6 }) {
              Text('账号信息').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50')).fontWeight(500)
              TextInput({ text: this.account, placeholder: '邮箱、用户名等' })
                .onChange((v) => { this.account = v; })
                .backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
                .border({ width: 1, color: this.c('rgba(255,255,255,0.08)', '#E8E2D9') })
                .borderRadius(12).placeholderColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
                .height(44).padding({ left: 14, right: 14 })
            }.alignItems(HorizontalAlign.Start).width('100%')

            Column({ space: 6 }) {
              Row({ space: 4 }) {
                Text('Secret Key').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50')).fontWeight(500)
                Text('*').fontSize(12).fontColor(this.accentColor)
              }
              TextInput({ text: this.secret, placeholder: 'Base32 密钥，如 JBSWY3DP…' })
                .onChange((v) => { this.secret = v; this.secretErr = ''; })
                .backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810')).fontFamily('monospace')
                .border({ width: 1, color: this.secretErr ? '#f87171' : this.c('rgba(255,255,255,0.08)', '#E8E2D9') })
                .borderRadius(12).placeholderColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
                .height(44).padding({ left: 14, right: 14 })
              if (this.secretErr) { Text(this.secretErr).fontSize(11).fontColor('#f87171') }
            }.alignItems(HorizontalAlign.Start).width('100%')

            if (this.brand.trim()) {
              Row({ space: 12 }) {
                Logo({ brand: this.brand, account: this.account, logoSize: 36, isDark: this.isDark, accentColor: this.accentColor })
                Column({ space: 2 }) {
                  Text(this.brand).fontSize(14).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(600)
                  if (this.account) { Text(this.account).fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50')) }
                }.alignItems(HorizontalAlign.Start).flexGrow(1)
                Text('预览').fontSize(11).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
              }
              .padding(12).backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(12)
              .border({ width: 1, color: this.c('rgba(255,255,255,0.06)', '#E8E2D9') }).width('100%')
            }

            Button('添加账号')
              .width('100%').height(50).borderRadius(15)
              .backgroundColor(this.accentColor).fontColor('#fff').fontSize(15).fontWeight(650)
              .onClick(() => {
                if (this.validate()) {
                  this.onAdd(this.brand.trim(), this.account.trim(), this.secret.trim().toUpperCase());
                  this.brand = '';
                  this.account = '';
                  this.secret = '';
                  this.brandErr = '';
                  this.secretErr = '';
                }
              })
            Column().height(40)
          }
          .padding({ left: 16, right: 16, top: 16 })
          .width('100%').constraintSize({ minHeight: '100%' })
        }
        .scrollBar(BarState.Off).flexGrow(1)
      }
    }
    .width('100%').height('100%').backgroundColor(this.c('#0d0d12', '#FAF7F2'))
    .padding({ bottom: this.navBottomPad })
    .clip(true)
  }
}
