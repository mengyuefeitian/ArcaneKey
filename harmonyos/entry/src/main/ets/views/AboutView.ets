import { common, Want, bundleManager } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';

const AGREEMENT_TEXT: string = `用户协议

更新日期：2026年6月18日
生效日期：2026年6月18日

欢迎使用星枢令（ArcaneKey）身份验证器（以下简称"本应用"或"我们"）。本协议由安卫宁（以下简称"开发者"）制定，请您在使用本应用前仔细阅读以下条款。使用本应用即表示您已阅读、理解并同意受本协议约束。

一、服务说明

1.1 本应用是一款基于 TOTP（基于时间的一次性密码）标准的身份验证器应用，适用于 HarmonyOS 平台，帮助用户管理双因素身份验证（2FA）账户。

1.2 本应用由安卫宁开发并通过华为应用市场（AppGallery）分发，仅供个人非商业用途使用。

1.3 您须年满14周岁方可使用本应用；未满14周岁的未成年人须在法定监护人同意下使用。

二、账号与登录

2.1 本应用支持使用华为账号登录。您的华为账号信息由华为账号服务管理，本应用仅在您授权后获取昵称及头像等基本信息用于展示。

2.2 您对账号安全负责，请妥善保管您的登录凭据，不得将账号分享给他人。

三、会员服务与应用内购买

3.1 会员服务内容
本应用提供可选的付费会员服务（"永久会员"），会员可享有以下专属功能：
· 无限添加 TOTP 账户（非会员限5个）
· 云端加密备份与恢复
· 自动云同步（每小时一次）
· 查看密钥明文功能
· 区分本地与云端的高级删除选项

3.2 购买方式
会员服务通过华为应用市场应用内购买（IAP）服务提供。购买时，您需要使用已绑定支付方式的华为账号完成支付。具体售价以华为应用市场展示页面为准。

3.3 购买规则
· 购买完成后，会员资格立即生效。
· 永久会员无有效期限制，一次购买终身有效。
· 购买前请确认您的设备已登录华为账号，并绑定有效支付方式。
· 如您已在其他设备购买，可通过本应用"恢复购买"功能恢复会员资格。

3.4 退款政策
购买完成后，如需申请退款，请通过华为应用市场官方渠道提交退款申请。退款政策以华为应用市场相关规则为准。成功退款后，会员权益将随即终止。

3.5 禁止行为
禁止通过非正规渠道绕过购买流程获取会员功能，违者有权终止相关服务。

四、数据安全

4.1 您的 TOTP 验证码密钥仅加密存储在您的本地设备中，本应用不会未经授权将密钥上传至任何服务器。

4.2 开通会员后，您可选择将账户数据加密备份至本地存储区域（作为云端备份代理）。备份数据经过加密处理，我们无法获取您的明文密钥。

4.3 请妥善保管您的备份密码，遗失后无法恢复加密数据，本应用不承担因密码遗失导致的数据丢失责任。

五、权限说明

本应用在您明确授权后使用以下设备权限：
· 摄像头（扫描 QR 码添加账户）：仅在扫码功能激活时使用
· 系统悬浮窗（界面显示优化）：用于全屏沉浸式显示效果
· 剪贴板（复制验证码）：仅在您主动触发复制操作时使用

本应用不申请麦克风、位置、通讯录等与核心功能无关的权限。

六、用户义务

6.1 您不得将本应用用于任何违法或未经授权的目的。
6.2 不得尝试反向工程、破解、修改本应用。
6.3 不得通过技术手段绕过付费机制。
6.4 不得将本应用用于存储或管理他人账户（在未经对方授权的情况下）。

七、知识产权

本应用及其相关代码、设计、文档等内容的知识产权归安卫宁所有。本协议不向您转让任何知识产权。

八、免责声明

8.1 本应用按"现状"提供，不作任何明示或暗示的质量保证。
8.2 对于因使用本应用、设备故障、系统错误或不可抗力导致的数据丢失或其他损失，本应用不承担法律责任。
8.3 请定期通过本应用的备份功能备份您的账户数据，以防数据丢失。

九、协议变更

本协议如有重大修改，将通过应用内通知或版本更新说明告知用户。继续使用本应用即视为您接受最新版本协议。

十、适用法律

本协议适用中华人民共和国法律。如发生争议，双方应友好协商解决；协商不成的，提交开发者所在地有管辖权的人民法院裁决。

联系我们：mengyuefeitian@live.cn`;

const PRIVACY_TEXT: string = `隐私政策

更新日期：2026年6月18日
生效日期：2026年6月18日

安卫宁（以下简称"我们"）非常重视用户的隐私权。本隐私政策说明我们在您使用星枢令（ArcaneKey）应用（以下简称"本应用"）时如何收集、使用、存储和保护您的个人信息。

请在使用本应用前仔细阅读本政策。使用本应用即表示您同意本隐私政策的内容。

一、我们收集的信息

1.1 您主动提供的信息
· 华为账号基本信息（昵称、头像）：仅在您使用华为账号登录时，经您授权后获取，用于显示个人信息，不上传至我们的服务器。
· 反馈内容：您通过反馈功能提交的文字、图片及联系邮箱，用于问题处理，通过邮件发送至开发者邮箱。

1.2 应用运行产生的信息
· TOTP 账户数据（账户名、密钥、发行方等）：仅存储在您设备本地，不会自动上传，我们无法访问。
· 备份数据：开通会员后，您主动发起备份时，加密后的账户数据存储于设备本地专用存储区。

1.3 我们不收集的信息
· 我们不收集您的地理位置信息
· 我们不收集您的通讯录信息
· 我们不收集设备唯一标识符用于追踪
· 我们不收集您的浏览行为或使用习惯数据
· 我们不收集您的支付卡号等完整支付信息（支付由华为IAP服务处理）

二、信息使用目的

我们收集的信息仅用于以下目的：
· 提供 TOTP 身份验证核心功能
· 验证会员身份（通过华为IAP服务）
· 展示您的账号信息
· 回复您的反馈与建议
· 故障排查与服务改进

三、信息共享

3.1 我们不会将您的个人信息出售、出租或以其他方式提供给任何第三方用于商业目的。

3.2 以下情况除外：
· 华为账号服务（AccountKit）：用于账号登录认证，受华为隐私政策约束
· 华为应用内购买服务（IAPKit）：用于处理会员购买，受华为隐私政策约束
· 法律要求：在法律法规要求时依法披露

3.3 第三方SDK说明：
本应用集成以下华为官方SDK，如需了解其隐私处理方式，请参阅华为开发者文档：
· HarmonyOS AccountKit（账号服务）
· HarmonyOS IAPKit（应用内购买）
· HarmonyOS ScanKit（扫描服务，仅在扫码时激活）
· HarmonyOS ArkData（本地数据存储）

四、数据安全

4.1 您的 TOTP 密钥存储于设备本地的 Preferences 数据库，仅限本应用访问。
4.2 会员备份数据在存储前经过加密处理，我们无法获取您的明文密钥。
4.3 我们采取合理技术措施保护您的本地数据，但无法保证绝对安全，请您定期备份重要数据。

五、用户权利

5.1 访问与修改：您可以在应用内查看和管理您的 TOTP 账户数据。
5.2 删除：您可以在应用内删除单个账户数据，或通过登出账号清除会员绑定信息。
5.3 注销：如需完整删除您的数据，您可在应用内删除所有账户后卸载应用。
5.4 投诉：如对隐私处理有异议，可发送邮件至我们的联系邮箱。

六、儿童隐私

本应用不面向14周岁以下未成年人。我们不会故意收集14周岁以下儿童的个人信息。如发现误收集，请联系我们删除。

七、数据存储与跨境

您的所有数据存储在您的本地设备上。我们不建立自有服务器，不进行数据跨境传输。华为相关服务（账号、IAP、云服务）的数据处理遵循华为的数据存储政策。

八、本政策的更新

当本政策发生重大变更时，我们将通过应用内通知或版本更新说明告知您。继续使用本应用视为接受更新后的政策。

九、联系我们

如您对本隐私政策有任何疑问或建议，请通过以下方式联系我们：
· 邮箱：mengyuefeitian@live.cn
· 官网：www.xiaoanhome.xyz

备案号：京ICP备2026021298号-4A`;

@Component
export struct AboutView {
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  @Link showAgreement: boolean;
  @Link showPrivacy: boolean;
  @State emailCopied: boolean = false;
  @State versionText: string = '星枢令';
  onClose: () => void = () => {};

  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  aboutToAppear(): void {
    try {
      const info = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      this.versionText = `星枢令 v${info.versionName}`;
    } catch (_) {}
  }

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
                .fontSize(13).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
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
                    Text('查看服务条款').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
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
                    Text('了解数据保护').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
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
                    Text('mengyuefeitian@live.cn').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text(this.emailCopied ? '已复制 ✓' : '复制')
                    .fontSize(12).fontColor(this.emailCopied ? this.c('rgba(238,238,245,0.65)', '#6B5B50') : this.accentColor)
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
                    Text('www.xiaoanhome.xyz').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
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
                    Text('京ICP备2026021298号-4A').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
                }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => { this.openUrl('https://beian.miit.gov.cn/'); })
              }
            }
            .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(18)
            .border({ width: 1, color: this.c('rgba(255,255,255,0.05)', '#E8E2D9') })

            Text(this.versionText)
              .fontSize(12).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
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
