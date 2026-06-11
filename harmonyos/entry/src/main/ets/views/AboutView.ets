import { common, Want } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';

const AGREEMENT_TEXT: string = '用户协议\n\n欢迎使用星枢令（ArcaneKey）身份验证器。\n\n一、服务说明\n本软件由小安工作室提供，仅供个人非商业用途使用。使用本软件即表示您同意本协议的所有条款。\n\n二、数据安全\n您的 TOTP 验证码密钥仅存储在您的本地设备中，不会在未经授权的情况下上传至服务器。开通会员后，您可选择将加密备份上传至云端，密钥经过本地加密后再传输，我们无法获取您的明文密钥。\n\n三、免责声明\n本软件按现状提供，不作任何明示或暗示的保证。对于因使用本软件导致的任何直接或间接损失，本工作室不承担法律责任。\n\n四、协议变更\n本协议如有修改，将通过应用更新方式通知用户。继续使用即视为接受最新协议。\n\n如有疑问，请联系：mengyuefeitian@live.cn';

const PRIVACY_TEXT: string = '隐私政策\n\n星枢令（ArcaneKey）尊重并保护用户的个人隐私权。\n\n一、信息收集\n本应用收集的信息：\n· 设备账号信息（用于会员校验，仅本地存储）\n· 您主动提交的反馈内容（通过邮件发送）\n\n本应用不收集：\n· 您的 TOTP 密钥或验证码\n· 您的位置信息\n· 浏览行为或使用统计数据\n\n二、信息使用\n收集的信息仅用于提供应用核心功能，不会出售、出租或分享给第三方。\n\n三、数据存储\n所有 TOTP 密钥存储在设备本地 Preferences 中。云备份数据经过 XOR 加密处理后存储。\n\n如您对隐私保护有任何疑问，请发送邮件至：mengyuefeitian@live.cn';

@Component
export struct AboutView {
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  @State showAgreement: boolean = false;
  @State showPrivacy: boolean = false;
  @State emailCopied: boolean = false;
  onClose: () => void = () => {};

  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  private async openUrl(url: string): Promise<void> {
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('context');
      if (!ctx) return;
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: url,
      };
      await ctx.startAbility(want);
    } catch (_) {}
  }

  private async copyEmail(): Promise<void> {
    try {
      const pb = pasteboard.getSystemPasteboard();
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, 'mengyuefeitian@live.cn');
      await pb.setData(data);
      this.emailCopied = true;
      setTimeout(() => { this.emailCopied = false; }, 2000);
    } catch (_) {}
  }

  build() {
    Stack() {
      // Main about page
      Column() {
        Row({ space: 12 }) {
          Button({ type: ButtonType.Normal }) {
            Text('×').fontSize(20).fontColor(this.c('rgba(238,238,245,0.75)', '#5C4F43'))
          }
          .backgroundColor(this.c('rgba(255,255,255,0.08)', 'rgba(0,0,0,0.06)')).borderRadius(11)
          .width(36).height(36)
          .onClick(this.onClose)
          Text('关于我们').fontSize(17).fontWeight(650).fontColor(this.c('#eeeef5', '#2C1810'))
        }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 8 })

        Scroll() {
          Column({ space: 24 }) {
            // Brand block
            Column({ space: 10 }) {
              Image($r('app.media.logo_img'))
                .width(72).height(72).borderRadius(20)
                .shadow({ radius: 24, color: this.accentColor + '55', offsetX: 0, offsetY: 6 })
              Text('星枢令')
                .fontSize(22).fontWeight(800).fontColor(this.c('#eeeef5', '#2C1810')).letterSpacing(-0.5)
              Text('身份验证器 · 守护你的数字安全')
                .fontSize(13).fontColor(this.c('rgba(238,238,245,0.4)', '#8B7E74'))
            }.width('100%').alignItems(HorizontalAlign.Center).padding({ top: 16, bottom: 8 })

            // Info list
            Column() {
              // 用户协议
              Column() {
                Row({ space: 0 }) {
                  Stack() { Text('📄').fontSize(16) }
                    .width(34).height(34).borderRadius(10)
                    .backgroundColor(this.accentColor + '28').margin({ right: 14 })
                  Column({ space: 2 }) {
                    Text('用户协议').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                    Text('查看服务条款').fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
                }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => { this.showAgreement = true; })
                Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
              }
              // 隐私政策
              Column() {
                Row({ space: 0 }) {
                  Stack() { Text('🔒').fontSize(16) }
                    .width(34).height(34).borderRadius(10)
                    .backgroundColor(this.accentColor + '28').margin({ right: 14 })
                  Column({ space: 2 }) {
                    Text('隐私政策').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                    Text('了解数据保护').fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
                }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => { this.showPrivacy = true; })
                Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
              }
              // 邮箱
              Column() {
                Row({ space: 0 }) {
                  Stack() { Text('📧').fontSize(16) }
                    .width(34).height(34).borderRadius(10)
                    .backgroundColor(this.accentColor + '28').margin({ right: 14 })
                  Column({ space: 2 }) {
                    Text('邮箱').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                    Text('mengyuefeitian@live.cn').fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text(this.emailCopied ? '已复制 ✓' : '复制')
                    .fontSize(12).fontColor(this.emailCopied ? this.c('rgba(238,238,245,0.38)', '#8B7E74') : this.accentColor)
                }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => { this.copyEmail(); })
                Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
              }
              // 官网
              Column() {
                Row({ space: 0 }) {
                  Stack() { Text('🌐').fontSize(16) }
                    .width(34).height(34).borderRadius(10)
                    .backgroundColor(this.accentColor + '28').margin({ right: 14 })
                  Column({ space: 2 }) {
                    Text('官网').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                    Text('www.xiaoanhome.xyz').fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
                }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => { this.openUrl('https://www.xiaoanhome.xyz'); })
                Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
              }
              // 备案
              Column() {
                Row({ space: 0 }) {
                  Stack() { Text('🏛️').fontSize(16) }
                    .width(34).height(34).borderRadius(10)
                    .backgroundColor(this.accentColor + '28').margin({ right: 14 })
                  Column({ space: 2 }) {
                    Text('备案').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                    Text('京ICP备2026021298号-3A').fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
                }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => { this.openUrl('https://beian.miit.gov.cn/'); })
              }
            }
            .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(18)
            .border({ width: 1, color: this.c('rgba(255,255,255,0.05)', '#E8E2D9') })

            Text('星枢令 v1.0.0')
              .fontSize(12).fontColor(this.c('rgba(238,238,245,0.2)', '#A99E93'))
              .width('100%').textAlign(TextAlign.Center)
              .padding({ top: 8, bottom: 100 })
          }
          .padding({ left: 20, right: 20, top: 8 })
        }.scrollBar(BarState.Off).flexGrow(1)
      }
      .width('100%').height('100%')
      .backgroundColor(this.c('#0d0d12', '#FAF7F2'))
      .padding({ top: 44 })

      // Legal detail overlay (covers main content)
      if (this.showAgreement || this.showPrivacy) {
        Column() {
          Row({ space: 12 }) {
            Button({ type: ButtonType.Normal }) {
              Text('←').fontSize(18).fontColor(this.c('rgba(238,238,245,0.75)', '#5C4F43'))
            }
            .backgroundColor(this.c('rgba(255,255,255,0.08)', 'rgba(0,0,0,0.06)')).borderRadius(11)
            .width(36).height(36)
            .onClick(() => { this.showAgreement = false; this.showPrivacy = false; })
            Text(this.showAgreement ? '用户协议' : '隐私政策')
              .fontSize(17).fontWeight(650).fontColor(this.c('#eeeef5', '#2C1810'))
          }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 8 })

          Scroll() {
            Column() {
              Text(this.showAgreement ? AGREEMENT_TEXT : PRIVACY_TEXT)
                .fontSize(14)
                .fontColor(this.c('#eeeef5', '#2C1810'))
                .lineHeight(26)
                .width('100%')
            }.padding({ left: 20, right: 20, top: 8, bottom: 40 })
          }.scrollBar(BarState.Off).flexGrow(1)
        }
        .width('100%').height('100%')
        .backgroundColor(this.c('#0d0d12', '#FAF7F2'))
        .padding({ top: 44 })
      }
    }
    .width('100%').height('100%')
  }
}
