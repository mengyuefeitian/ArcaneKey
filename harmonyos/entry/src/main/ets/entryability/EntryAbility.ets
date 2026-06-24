import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { initialize } from '@hw-agconnect/hmcore';
import { util } from '@kit.ArkTS';

export default class EntryAbility extends UIAbility {
  private windowStage: window.WindowStage | null = null;

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(0x0000, 'ArcaneKey', '%{public}s', 'Ability onCreate');
    AppStorage.setOrCreate('context', this.context);
    try {
      const cfgBytes = await this.context.resourceManager.getRawFileContent('agconnect-services.json');
      const decoder = new util.TextDecoder('utf-8');
      initialize(this.context, JSON.parse(decoder.decode(cfgBytes)));
      hilog.info(0x0000, 'ArcaneKey', '%{public}s', 'AGC SDK initialized');
    } catch (e) {
      hilog.error(0x0000, 'ArcaneKey', 'AGC init failed: %{public}s', JSON.stringify(e));
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'ArcaneKey', '%{public}s', 'Ability onWindowStageCreate');
    this.windowStage = windowStage;
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'ArcaneKey', 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      this.setupImmersiveWindow(windowStage);
    });
  }

  private async setupImmersiveWindow(windowStage: window.WindowStage): Promise<void> {
    try {
      const mainWindow = windowStage.getMainWindowSync();
      // Content extends into status bar and navigation bar area
      await mainWindow.setWindowLayoutFullScreen(true);
      // Transparent window background so system light effects can penetrate
      await mainWindow.setWindowBackgroundColor('#00000000');
      // Use white icons on the dark background so time/battery are visible
      await mainWindow.setWindowSystemBarProperties({
        statusBarContentColor: '#FFFFFF',
        navigationBarContentColor: '#FFFFFF'
      });
    } catch (err) {
      hilog.error(0x0000, 'ArcaneKey', 'Failed to setup immersive window: %{public}s', JSON.stringify(err));
    }
  }

  onForeground(): void {}
  onBackground(): void {}
}
