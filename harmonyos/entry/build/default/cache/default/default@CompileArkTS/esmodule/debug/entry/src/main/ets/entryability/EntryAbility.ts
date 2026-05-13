import type AbilityConstant from "@ohos:app.ability.AbilityConstant";
import UIAbility from "@ohos:app.ability.UIAbility";
import type Want from "@ohos:app.ability.Want";
import hilog from "@ohos:hilog";
import type window from "@ohos:window";
export default class EntryAbility extends UIAbility {
    private windowStage: window.WindowStage | null = null;
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        hilog.info(0x0000, 'ArcaneKey', '%{public}s', 'Ability onCreate');
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
        }
        catch (err) {
            hilog.error(0x0000, 'ArcaneKey', 'Failed to setup immersive window: %{public}s', JSON.stringify(err));
        }
    }
    onForeground(): void { }
    onBackground(): void { }
}
