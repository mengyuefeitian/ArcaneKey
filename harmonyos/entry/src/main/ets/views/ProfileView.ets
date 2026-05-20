interface MenuItem {
  id: string;
  icon: string;
  label: string;
  desc: string;
  locked: boolean;
}

@Component
export struct ProfileView {
  @Prop accentColor: string = '#4080D0';
  @Prop loggedIn: boolean = false;
  @Prop userName: string = '';
  @Prop userPhone: string = '';
  @Prop userAvatar: string = '';
  @Prop themeName: string = '海洋蓝';
  @Prop harmonyLogin: boolean = false;
  @Prop isMember: boolean = false;
  @Prop memberExpiry: string = '';
  onLoginTap: () => void = () => {};
  onBindPhone: () => void = () => {};
  onLogout: () => void = () => {};
  onBackupTap: () => void = () => {};
  onImportTap: () => void = () => {};
  onThemeTap: () => void = () => {};
  onAccountTap: () => void = () => {};
  onMembershipTap: () => void = () => {};
  onFeedbackTap: () => void = () => {};

  build() {
    Scroll() {
      Column() {
        // Product branding
        Column({ space: 0 }) {
          Stack() {
            Text('玄').fontSize(32).fontColor('#fff').fontWeight(800)
          }
          .width(64).height(64).borderRadius(20)
          .backgroundColor(this.accentColor)
          .shadow({ radius: 32, color: this.accentColor + '55', offsetX: 0, offsetY: 8 })
          .margin({ bottom: 12 })

          Text('玄钥').fontSize(24).fontWeight(800).fontColor('#eeeef5').letterSpacing(-0.5)
          Text('玄钥：身份验证器')
            .fontSize(13).fontColor('rgba(238,238,245,0.4)').margin({ top: 4 })
          Text('为你所有的重要账号（如腾讯云、阿里云、AI账号、游戏等）配备了一把"动态的、每30秒换一次的数字钥匙"')
            .fontSize(12).fontColor('rgba(238,238,245,0.3)').textAlign(TextAlign.Center)
            .lineHeight(21).margin({ top: 8 }).padding({ left: 20, right: 20 })
        }
        .width('100%').alignItems(HorizontalAlign.Center).padding({ top: 16, bottom: 20 })

        // Account section
        if (this.loggedIn) {
          Row({ space: 12 }) {
            if (this.userAvatar) {
              Image(this.userAvatar).width(40).height(40).borderRadius(20)
            } else {
              Stack() {
                Text(this.userName.length > 0 ? this.userName[0].toUpperCase() : 'U')
                  .fontSize(18).fontColor('#fff').fontWeight(700)
              }
              .width(40).height(40).borderRadius(20)
              .backgroundColor(this.accentColor)
            }
            Column({ space: 2 }) {
              Text(this.userName).fontSize(15).fontColor('#eeeef5').fontWeight(600)
              if (this.userPhone) {
                Text(this.userPhone).fontSize(12).fontColor('rgba(238,238,245,0.4)')
              }
            }.alignItems(HorizontalAlign.Start).flexGrow(1)
          }
          .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor('#191920').borderRadius(14)
          .border({ width: 1, color: this.accentColor + '30' })
          .margin({ bottom: 20 })
        } else {
          Row() {
            Text('登录后解锁更多功能')
              .fontSize(14).fontColor('rgba(238,238,245,0.55)')
            Button('登录账号')
              .backgroundColor(this.accentColor).fontColor('#fff')
              .fontSize(14).fontWeight(600).borderRadius(18)
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .shadow({ radius: 20, color: this.accentColor + '55', offsetX: 0, offsetY: 4 })
              .onClick(() => this.onLoginTap())
          }
          .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor('#191920').borderRadius(14)
          .border({ width: 1, color: 'rgba(255,255,255,0.05)' })
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 20 })
        }

        // Menu — inline items to ensure reactive themeName updates
        Column() {
          // Membership
          Column() {
            Row({ space: 0 }) {
              Text('👑').fontSize(22).margin({ right: 14 })
              Column({ space: 2 }) {
                Text(this.isMember ? '会员特权' : '开通会员').fontSize(15).fontColor('#eeeef5').fontWeight(520)
                Text(this.isMember ? `有效期至 ${this.memberExpiry}` : '¥19.90/年，无限制添加')
                  .fontSize(12).fontColor('rgba(238,238,245,0.38)')
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor('rgba(238,238,245,0.3)')
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .border({ width: { left: this.isMember ? 3 : 0 }, color: { left: this.isMember ? this.accentColor : Color.Transparent } })
            .onClick(() => this.onMembershipTap())
            Divider().color('rgba(255,255,255,0.05)').strokeWidth(1).margin({ left: 16, right: 16 })
          }
          // Account
          Column() {
            Row({ space: 0 }) {
              Text('👤').fontSize(22).margin({ right: 14 })
              Column({ space: 2 }) {
                Text('账号管理').fontSize(15).fontColor('#eeeef5').fontWeight(520)
                Text(this.loggedIn ? '管理你的账号信息' : '登录后可用')
                  .fontSize(12).fontColor('rgba(238,238,245,0.38)')
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor('rgba(238,238,245,0.3)')
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .opacity(this.loggedIn ? 1 : 0.38)
            .onClick(() => {
              if (!this.loggedIn) this.onLoginTap();
              else this.onAccountTap();
            })
            Divider().color('rgba(255,255,255,0.05)').strokeWidth(1).margin({ left: 16, right: 16 })
          }
          // Backup
          Column() {
            Row({ space: 0 }) {
              Text('☁️').fontSize(22).margin({ right: 14 })
              Column({ space: 2 }) {
                Text('备份数据').fontSize(15).fontColor('#eeeef5').fontWeight(520)
                Text(this.isMember ? '加密备份到云端' : '会员专属')
                  .fontSize(12).fontColor('rgba(238,238,245,0.38)')
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor('rgba(238,238,245,0.3)')
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .opacity(this.loggedIn ? 1 : 0.38)
            .onClick(() => { if (this.loggedIn) this.onBackupTap(); })
            Divider().color('rgba(255,255,255,0.05)').strokeWidth(1).margin({ left: 16, right: 16 })
          }
          // Import
          Column() {
            Row({ space: 0 }) {
              Text('📥').fontSize(22).margin({ right: 14 })
              Column({ space: 2 }) {
                Text('导入备份').fontSize(15).fontColor('#eeeef5').fontWeight(520)
                Text(this.isMember ? '从云端恢复' : '会员专属')
                  .fontSize(12).fontColor('rgba(238,238,245,0.38)')
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor('rgba(238,238,245,0.3)')
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .opacity(this.loggedIn ? 1 : 0.38)
            .onClick(() => { if (this.loggedIn) this.onImportTap(); })
            Divider().color('rgba(255,255,255,0.05)').strokeWidth(1).margin({ left: 16, right: 16 })
          }
          // Theme
          Column() {
            Row({ space: 0 }) {
              Text('🎨').fontSize(22).margin({ right: 14 })
              Column({ space: 2 }) {
                Text('皮肤主题').fontSize(15).fontColor('#eeeef5').fontWeight(520)
                Text(this.themeName)
                  .fontSize(12).fontColor('rgba(238,238,245,0.38)')
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor('rgba(238,238,245,0.3)')
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .onClick(() => this.onThemeTap())
            Divider().color('rgba(255,255,255,0.05)').strokeWidth(1).margin({ left: 16, right: 16 })
          }
          // Feedback
          Column() {
            Row({ space: 0 }) {
              Text('💬').fontSize(22).margin({ right: 14 })
              Column({ space: 2 }) {
                Text('意见与建议').fontSize(15).fontColor('#eeeef5').fontWeight(520)
                Text('向我们反馈问题或建议')
                  .fontSize(12).fontColor('rgba(238,238,245,0.38)')
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor('rgba(238,238,245,0.3)')
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .onClick(() => this.onFeedbackTap())
          }
        }
        .backgroundColor('#191920').borderRadius(18)
        .border({ width: 1, color: 'rgba(255,255,255,0.05)' })

        if (this.loggedIn) {
          Button('退出登录')
            .width('100%').backgroundColor(Color.Transparent)
            .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
            .borderRadius(14).fontColor('rgba(238,238,245,0.45)').fontSize(14)
            .margin({ top: 16 })
            .onClick(() => this.onLogout())
        }

        Text('玄钥 v1.0.0')
          .fontSize(12).fontColor('rgba(238,238,245,0.2)')
          .width('100%').textAlign(TextAlign.Center)
          .padding({ top: 24, bottom: 100 })
      }
      .padding({ left: 20, right: 20 })
    }
    .scrollBar(BarState.Off).width('100%').height('100%').backgroundColor('#0d0d12')
  }
}
