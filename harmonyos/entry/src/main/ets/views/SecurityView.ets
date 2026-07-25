import { SecurityMode, saveSecurityMode } from '../utils/StorageUtil';
import { isSecurityTypeAvailable, authenticateSecurity } from '../utils/SecurityUtil';

@Component
export struct SecurityView {
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  // Parent-owned mode; local faceOn/fingerprintOn/lockOn drive Toggle visuals.
  // Toggle flips ON immediately on click; if enable fails we must remount with isOn=false
  // (bumping toggleEpoch via ForEach key) because isOn:false→false does not re-sync the switch.
  @Prop @Watch('onModePropChanged') mode: SecurityMode = 'off';
  @State private toggleEpoch: number = 0;
  @State private faceOn: boolean = false;
  @State private fingerprintOn: boolean = false;
  @State private lockOn: boolean = false;
  @Prop lockFallbackEnabled: boolean = true;
  @State private fallbackOn: boolean = true;
  // Ignore onChange while we programmatically remount/sync Toggle visuals
  private syncingVisual: boolean = false;
  onModeChange: (mode: SecurityMode) => void = (_m: SecurityMode) => {};
  onClose: () => void = () => {};
  onUnavailable: (msg: string) => void = (_msg: string) => {};
  onLockFallbackChange: (enabled: boolean) => void = (_e: boolean) => {};

  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  aboutToAppear(): void {
    this.applyModeVisual(this.mode);
    this.fallbackOn = this.lockFallbackEnabled;
  }

  private onModePropChanged(): void {
    if (this.syncingVisual) {
      return;
    }
    this.applyModeVisual(this.mode);
  }

  /** Set local switch visuals from mode and force Toggle remount so internal state matches. */
  private applyModeVisual(mode: SecurityMode): void {
    this.syncingVisual = true;
    this.faceOn = mode === 'face';
    this.fingerprintOn = mode === 'fingerprint';
    this.lockOn = mode === 'lock';
    this.toggleEpoch = this.toggleEpoch + 1;
    // Clear flag on next macrotask so remount-triggered onChange (if any) is ignored
    setTimeout((): void => {
      this.syncingVisual = false;
    }, 0);
  }

  private async tryEnable(target: SecurityMode): Promise<void> {
    // Already on → turn off
    if (this.mode === target) {
      this.onModeChange('off');
      await saveSecurityMode('off');
      this.applyModeVisual('off');
      return;
    }

    // User tried to turn ON: snap UI off immediately; only show ON after checks + auth pass
    this.applyModeVisual('off');

    // System capability / enrollment check
    if (!isSecurityTypeAvailable(target)) {
      if (target === 'face') {
        this.onUnavailable('请先在系统设置中录入人脸');
      } else if (target === 'fingerprint') {
        this.onUnavailable('请先在系统设置中录入指纹');
      } else if (target === 'lock') {
        this.onUnavailable('请先在系统设置中设置锁屏密码');
      }
      return;
    }

    // Require successful auth before enabling
    const outcome = await authenticateSecurity(target);
    if (!outcome.ok) {
      this.onUnavailable('验证失败，未能开启');
      this.applyModeVisual('off');
      return;
    }

    this.onModeChange(target);
    await saveSecurityMode(target);
    this.applyModeVisual(target);
  }

  private onToggleChange(target: SecurityMode, on: boolean): void {
    if (this.syncingVisual) {
      return;
    }
    if (on) {
      // Only attempt enable when not already the active mode
      if (this.mode !== target) {
        this.tryEnable(target);
      }
    } else {
      // Turn off only if this mode is currently active
      if (this.mode === target) {
        this.tryEnable(target);
      }
    }
  }

  private onFallbackToggleChange(on: boolean): void {
    this.fallbackOn = on;
    this.onLockFallbackChange(on);
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
        // ForEach key = toggleEpoch forces Toggle remount when enable fails (stays off until auth OK)
        ForEach([this.toggleEpoch], (_epoch: number) => {
          Column() {
            // 人脸识别
            Column() {
              Row() {
                Text('人脸识别')
                  .fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                  .layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.faceOn })
                  .selectedColor(this.accentColor)
                  .onChange((on: boolean) => {
                    this.onToggleChange('face', on);
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
                Toggle({ type: ToggleType.Switch, isOn: this.fingerprintOn })
                  .selectedColor(this.accentColor)
                  .onChange((on: boolean) => {
                    this.onToggleChange('fingerprint', on);
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
                Toggle({ type: ToggleType.Switch, isOn: this.lockOn })
                  .selectedColor(this.accentColor)
                  .onChange((on: boolean) => {
                    this.onToggleChange('lock', on);
                  })
              }
              .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .alignItems(VerticalAlign.Center)
              if (this.mode === 'face' || this.mode === 'fingerprint') {
                Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1)
                  .margin({ left: 16, right: 16 })
              }
            }
            // 解锁失败时启用锁屏密码解锁 (only when primary mode is face/fingerprint)
            if (this.mode === 'face' || this.mode === 'fingerprint') {
              Column() {
                Row() {
                  Text('解锁失败时启用锁屏密码解锁')
                    .fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                    .layoutWeight(1)
                  Toggle({ type: ToggleType.Switch, isOn: this.fallbackOn })
                    .selectedColor(this.accentColor)
                    .enabled(isSecurityTypeAvailable('lock'))
                    .onChange((on: boolean) => {
                      this.onFallbackToggleChange(on);
                    })
                }
                .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .alignItems(VerticalAlign.Center)
                .opacity(isSecurityTypeAvailable('lock') ? 1 : 0.5)
              }
            }
          }
          .width('100%')
          .backgroundColor(this.c('#191920', '#FFFFFF'))
          .borderRadius(18)
          .border({ width: 1, color: this.c('rgba(255,255,255,0.05)', '#E8E2D9') })
        }, (epoch: number) => `security-toggles-${epoch}`)

        // Footer tip
        Text('三种互斥，仅可开启一种。依赖系统设置；未录入则无法开启。')
          .fontSize(12)
          .fontColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
          .width('100%')
          .padding({ left: 4, right: 4 })
          .lineHeight(18)
        if ((this.mode === 'face' || this.mode === 'fingerprint') && !isSecurityTypeAvailable('lock')) {
          Text('锁屏密码未设置')
            .fontSize(12)
            .fontColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
            .width('100%')
            .padding({ left: 4, right: 4 })
            .lineHeight(18)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20 })
    }
    .width('100%').height('100%').backgroundColor(this.c('#0d0d12', '#FAF7F2'))
    .padding({ top: 44 })
    .alignItems(HorizontalAlign.Start)
  }
}
