import { SecurityMode, saveSecurityMode } from '../utils/StorageUtil';
import { isSecurityTypeAvailable, authenticateSecurity } from '../utils/SecurityUtil';

@Component
export struct SecurityView {
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  @Prop mode: SecurityMode = 'off';
  // Bumps after failed enable so controlled Toggle re-reads isOn from mode
  @State private toggleEpoch: number = 0;
  onModeChange: (mode: SecurityMode) => void = (_m: SecurityMode) => {};
  onClose: () => void = () => {};
  onUnavailable: (msg: string) => void = (_msg: string) => {};

  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  private resetToggles(): void {
    this.toggleEpoch = this.toggleEpoch + 1;
  }

  private async tryEnable(target: SecurityMode): Promise<void> {
    // Already on → turn off
    if (this.mode === target) {
      this.onModeChange('off');
      await saveSecurityMode('off');
      return;
    }
    // System capability / enrollment check
    if (!isSecurityTypeAvailable(target)) {
      if (target === 'face') {
        this.onUnavailable('请先在系统设置中录入人脸');
      } else if (target === 'fingerprint') {
        this.onUnavailable('请先在系统设置中录入指纹');
      } else if (target === 'lock') {
        this.onUnavailable('请先在系统设置中设置锁屏密码');
      }
      this.resetToggles();
      return;
    }
    // Require successful auth before enabling
    const ok: boolean = await authenticateSecurity(target);
    if (!ok) {
      this.onUnavailable('验证失败，未能开启');
      this.resetToggles();
      return;
    }
    this.onModeChange(target);
    await saveSecurityMode(target);
  }

  build() {
    Column() {
      // Header
      Row({ space: 12 }) {
        Button({ type: ButtonType.Normal }) {
          Text('×').fontSize(20).fontColor(this.c('rgba(238,238,245,0.75)', '#5C4F43'))
        }
        .backgroundColor(this.c('rgba(255,255,255,0.08)', 'rgba(0,0,0,0.06)'))
        .borderRadius(11).width(36).height(36)
        .onClick(this.onClose)
        Text('安全').fontSize(17).fontWeight(650).fontColor(this.c('#eeeef5', '#2C1810'))
      }.width('100%').padding({ left: 16, right: 16, top: 8, bottom: 0 })

      Column({ space: 14 }) {
        // Toggle rows — toggleEpoch referenced so failed enable forces rebuild
        Column() {
          // 人脸识别
          Column() {
            Row() {
              Text('人脸识别')
                .fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.mode === 'face' && this.toggleEpoch >= 0 })
                .selectedColor(this.accentColor)
                .onChange((on: boolean) => {
                  if (on || this.mode === 'face') {
                    this.tryEnable('face');
                  }
                })
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Center)
            Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1)
              .margin({ left: 16, right: 16 })
          }
          // 指纹识别
          Column() {
            Row() {
              Text('指纹识别')
                .fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.mode === 'fingerprint' && this.toggleEpoch >= 0 })
                .selectedColor(this.accentColor)
                .onChange((on: boolean) => {
                  if (on || this.mode === 'fingerprint') {
                    this.tryEnable('fingerprint');
                  }
                })
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Center)
            Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1)
              .margin({ left: 16, right: 16 })
          }
          // 锁屏密码
          Column() {
            Row() {
              Text('锁屏密码')
                .fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.mode === 'lock' && this.toggleEpoch >= 0 })
                .selectedColor(this.accentColor)
                .onChange((on: boolean) => {
                  if (on || this.mode === 'lock') {
                    this.tryEnable('lock');
                  }
                })
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .alignItems(VerticalAlign.Center)
          }
        }
        .width('100%')
        .backgroundColor(this.c('#191920', '#FFFFFF'))
        .borderRadius(18)
        .border({ width: 1, color: this.c('rgba(255,255,255,0.05)', '#E8E2D9') })

        // Footer tip
        Text('三种互斥，仅可开启一种。依赖系统设置；未录入则无法开启。')
          .fontSize(12)
          .fontColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
          .width('100%')
          .padding({ left: 4, right: 4 })
          .lineHeight(18)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20 })
    }
    .width('100%').height('100%').backgroundColor(this.c('#0d0d12', '#FAF7F2'))
    .padding({ top: 44 })
    .alignItems(HorizontalAlign.Start)
  }
}
