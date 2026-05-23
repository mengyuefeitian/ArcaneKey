import { Logo } from '../components/Logo';
import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { scanBarcode, scanCore } from '@kit.ScanKit';

@Component
export struct ScanView {
  @Prop accentColor: string = '#4080D0';
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
      this.brand = b; this.account = a; this.secret = params['secret'] ?? '';
      this.scanned = true; this.tab = 2;
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

  private async doScan(enableAlbum: boolean): Promise<void> {
    this.scanning = true;
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('context');
      if (!ctx) {
        this.scanErrMsg = '上下文错误，请重启应用';
        setTimeout(() => { this.scanErrMsg = ''; }, 2200);
        this.scanning = false;
        return;
      }
      const granted = await this.requestCameraPermission(ctx);
      if (!granted) {
        this.scanErrMsg = '需要相机权限才能扫码';
        setTimeout(() => { this.scanErrMsg = ''; }, 2200);
        this.scanning = false;
        return;
      }
      const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.QR_CODE],
        enableMultiMode: false,
        enableAlbum: enableAlbum
      };
      const result: scanBarcode.ScanResult = await scanBarcode.startScanForResult(ctx, options);
      if (result?.originalValue) this.parseOtpUri(result.originalValue);
      else { this.scanErrMsg = '未识别到二维码'; setTimeout(() => { this.scanErrMsg = ''; }, 2200); }
    } catch (e) {
      this.scanErrMsg = enableAlbum ? '选择图片失败，请重试' : '扫码失败，请重试';
      setTimeout(() => { this.scanErrMsg = ''; }, 2200);
    }
    this.scanning = false;
  }

  build() {
    Column() {
      // Header
      Row({ space: 12 }) {
        Button({ type: ButtonType.Normal }) {
          Text('×').fontSize(20).fontColor('rgba(238,238,245,0.75)')
        }
        .backgroundColor('rgba(255,255,255,0.08)').borderRadius(11)
        .width(36).height(36)
        .onClick(() => this.onClose())

        Text('添加账号').fontSize(17).fontWeight(650).fontColor('#eeeef5')
        if (this.scanned) {
          Blank()
          Text('✓ 已识别').fontSize(12).fontColor(this.accentColor).fontWeight(600)
        }
      }
      .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 0 })

      // Tabs
      Row({ space: 2 }) {
        ForEach(['扫二维码', '选相册', '手动输入'], (label: string, idx: number) => {
          Text(label)
            .flexGrow(1).textAlign(TextAlign.Center)
            .fontSize(12).fontWeight(this.tab === idx ? 650 : 400)
            .fontColor(this.tab === idx ? '#fff' : 'rgba(238,238,245,0.45)')
            .backgroundColor(this.tab === idx ? this.accentColor : Color.Transparent)
            .borderRadius(10).padding({ top: 8, bottom: 8 })
            .onClick(() => { this.tab = idx; })
        }, (label: string) => label)
      }
      .margin({ left: 16, right: 16, top: 14 })
      .padding(4).backgroundColor('#191920').borderRadius(13)
      .width('calc(100% - 32vp)')

      // Scan error toast
      if (this.scanErrMsg) {
        Text(this.scanErrMsg)
          .fontSize(13).fontColor('#f87171').fontWeight(500)
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .backgroundColor('rgba(248,113,113,0.1)')
          .borderRadius(12).margin({ top: 8 })
      }

      // Content
      if (this.tab === 0) {
        // Camera
        Column({ space: 16 }) {
          Stack() {
            Column()
              .width('100%').aspectRatio(1).backgroundColor('#000')
              .borderRadius(22).border({ width: 1, color: 'rgba(255,255,255,0.07)' })
            // Dark overlay
            Column()
              .width('100%').aspectRatio(1).backgroundColor('rgba(0,0,0,0.55)')
              .borderRadius(22)
            // Scan frame corners
            Stack() {
              // Top-left
              Row()
                .width(22).height(3).backgroundColor(this.accentColor)
                .position({ x: 0, y: 0 }).borderRadius(2)
              Row()
                .width(3).height(22).backgroundColor(this.accentColor)
                .position({ x: 0, y: 0 }).borderRadius(2)
              // Top-right
              Row()
                .width(22).height(3).backgroundColor(this.accentColor)
                .position({ x: '100%', y: 0 }).borderRadius(2)
                .translate({ x: '-100%' })
              Row()
                .width(3).height(22).backgroundColor(this.accentColor)
                .position({ x: '100%', y: 0 }).borderRadius(2)
                .translate({ x: '-100%' })
              // Bottom-left
              Row()
                .width(22).height(3).backgroundColor(this.accentColor)
                .position({ x: 0, y: '100%' }).borderRadius(2)
                .translate({ y: '-100%' })
              Row()
                .width(3).height(22).backgroundColor(this.accentColor)
                .position({ x: 0, y: '100%' }).borderRadius(2)
                .translate({ y: '-100%' })
              // Bottom-right
              Row()
                .width(22).height(3).backgroundColor(this.accentColor)
                .position({ x: '100%', y: '100%' }).borderRadius(2)
                .translate({ x: '-100%', y: '-100%' })
              Row()
                .width(3).height(22).backgroundColor(this.accentColor)
                .position({ x: '100%', y: '100%' }).borderRadius(2)
                .translate({ x: '-100%', y: '-100%' })
            }
            .width('64%').height('64%')
            .position({ x: '18%', y: '18%' })
          }
          .width('100%').constraintSize({ maxWidth: 310 }).alignContent(Alignment.TopStart)

          Text(this.scanning ? '正在识别二维码…' : '点击下方按钮扫描二维码')
            .fontSize(13).fontColor('rgba(238,238,245,0.4)').textAlign(TextAlign.Center)

          Button(this.scanning ? '识别中…' : '扫描二维码')
            .width('100%').height(50).borderRadius(15)
            .backgroundColor(this.scanning ? 'rgba(255,255,255,0.07)' : this.accentColor)
            .fontColor(this.scanning ? 'rgba(238,238,245,0.4)' : '#fff')
            .fontSize(15).fontWeight(650)
            .enabled(!this.scanning)
            .onClick(() => this.doScan(false))
        }
        .width('100%').padding(16).flexGrow(1).justifyContent(FlexAlign.Center)
      } else if (this.tab === 1) {
        // Album
        Column({ space: 18 }) {
          Text('🖼️').fontSize(38)
            .width(88).height(88).textAlign(TextAlign.Center)
            .backgroundColor('#191920').borderRadius(24)
            .border({ width: 1, color: 'rgba(255,255,255,0.07)' })
          Text('从相册中选择含二维码的图片\n自动识别并添加账号')
            .fontSize(14).fontColor('rgba(238,238,245,0.5)').textAlign(TextAlign.Center)
          Button('选择图片')
            .width('100%').height(50).borderRadius(15)
            .backgroundColor(this.accentColor).fontColor('#fff').fontSize(15).fontWeight(650)
            .onClick(() => this.doScan(true))
        }
        .width('100%').padding({ top: 36, left: 16, right: 16 }).alignItems(HorizontalAlign.Center)
      } else {
        // Manual
        Scroll() {
          Column({ space: 14 }) {
            if (this.scanned) {
              Text('✓ 已从二维码读取信息，请确认或修改')
                .fontSize(13).fontColor(this.accentColor).fontWeight(500)
                .padding(12).borderRadius(12)
                .backgroundColor(this.accentColor + '18')
                .border({ width: 1, color: this.accentColor + '30' })
                .width('100%')
            }
            Column({ space: 6 }) {
              Row({ space: 4 }) {
                Text('品牌名称').fontSize(12).fontColor('rgba(238,238,245,0.45)').fontWeight(500)
                Text('*').fontSize(12).fontColor(this.accentColor)
              }
              TextInput({ text: this.brand, placeholder: '如 Google、Microsoft…' })
                .onChange((v) => { this.brand = v; this.brandErr = ''; })
                .backgroundColor('#191920').fontColor('#eeeef5')
                .border({ width: 1, color: this.brandErr ? '#f87171' : 'rgba(255,255,255,0.08)' })
                .borderRadius(12).placeholderColor('rgba(238,238,245,0.25)')
                .height(44).padding({ left: 14, right: 14 })
              if (this.brandErr) { Text(this.brandErr).fontSize(11).fontColor('#f87171') }
            }.alignItems(HorizontalAlign.Start).width('100%')

            Column({ space: 6 }) {
              Text('账号信息').fontSize(12).fontColor('rgba(238,238,245,0.45)').fontWeight(500)
              TextInput({ text: this.account, placeholder: '邮箱、用户名等' })
                .onChange((v) => { this.account = v; })
                .backgroundColor('#191920').fontColor('#eeeef5')
                .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
                .borderRadius(12).placeholderColor('rgba(238,238,245,0.25)')
                .height(44).padding({ left: 14, right: 14 })
            }.alignItems(HorizontalAlign.Start).width('100%')

            Column({ space: 6 }) {
              Row({ space: 4 }) {
                Text('Secret Key').fontSize(12).fontColor('rgba(238,238,245,0.45)').fontWeight(500)
                Text('*').fontSize(12).fontColor(this.accentColor)
              }
              TextInput({ text: this.secret, placeholder: 'Base32 密钥，如 JBSWY3DP…' })
                .onChange((v) => { this.secret = v; this.secretErr = ''; })
                .backgroundColor('#191920').fontColor('#eeeef5').fontFamily('monospace')
                .border({ width: 1, color: this.secretErr ? '#f87171' : 'rgba(255,255,255,0.08)' })
                .borderRadius(12).placeholderColor('rgba(238,238,245,0.25)')
                .height(44).padding({ left: 14, right: 14 })
              if (this.secretErr) { Text(this.secretErr).fontSize(11).fontColor('#f87171') }
            }.alignItems(HorizontalAlign.Start).width('100%')

            if (this.brand.trim()) {
              Row({ space: 12 }) {
                Logo({ brand: this.brand, logoSize: 36 })
                Column({ space: 2 }) {
                  Text(this.brand).fontSize(14).fontColor('#eeeef5').fontWeight(600)
                  if (this.account) { Text(this.account).fontSize(12).fontColor('rgba(238,238,245,0.4)') }
                }.alignItems(HorizontalAlign.Start).flexGrow(1)
                Text('预览').fontSize(11).fontColor('rgba(238,238,245,0.3)')
              }
              .padding(12).backgroundColor('#191920').borderRadius(12)
              .border({ width: 1, color: 'rgba(255,255,255,0.06)' }).width('100%')
            }

            Button('添加账号')
              .width('100%').height(50).borderRadius(15)
              .backgroundColor(this.accentColor).fontColor('#fff').fontSize(15).fontWeight(650)
              .onClick(() => {
                if (this.validate()) this.onAdd(this.brand.trim(), this.account.trim(), this.secret.trim().toUpperCase());
              })
            Column().height(40)
          }
          .padding({ left: 16, right: 16, top: 16 })
        }
        .scrollBar(BarState.Off).flexGrow(1)
      }
    }
    .width('100%').height('100%').backgroundColor('#0d0d12')
  }
}
