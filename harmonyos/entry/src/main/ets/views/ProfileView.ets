@Component
export struct ProfileView {
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  @Prop loggedIn: boolean = false;
  @Prop userName: string = '';
  @Prop userPhone: string = '';
  @Prop userAvatar: string = '';
  @Prop themeName: string = '海洋蓝';
  @Prop harmonyLogin: boolean = false;
  @Prop isMember: boolean = false;
  @Prop boundAccount: string = '';
  onLoginTap: () => void = () => {};
  onBindPhone: () => void = () => {};
  onLogout: () => void = () => {};
  onBackupTap: () => void = () => {};
  onImportTap: () => void = () => {};
  onThemeTap: () => void = () => {};
  onAccountTap: () => void = () => {};
  onMembershipTap: () => void = () => {};
  onFeedbackTap: () => void = () => {};
  onToggleMode: () => void = () => {};
  onAboutTap: () => void = () => {};
  onNavHide: () => void = () => {};
  onNavShow: () => void = () => {};

  private scroller: Scroller = new Scroller();
  private lastScrollY: number = 0;
  private scrollTimer: number = -1;

  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  build() {
    Scroll(this.scroller) {
      Column() {
        // Account / Login section (top)
        if (this.loggedIn) {
          Row({ space: 16 }) {
            // Avatar — large, prominent
            if (this.userAvatar) {
              Image(this.userAvatar)
                .width(72).height(72).borderRadius(18)
                .border({ width: 1, color: this.c('rgba(255,255,255,0.10)', 'rgba(0,0,0,0.06)') })
            } else {
              Stack() {
                Text(this.userName.length > 0 ? this.userName[0].toUpperCase() : 'U')
                  .fontSize(28).fontColor('#fff').fontWeight(700)
              }
              .width(72).height(72).borderRadius(18)
              .backgroundColor(this.accentColor)
              .shadow({ radius: 18, color: this.accentColor + '55', offsetX: 0, offsetY: 4 })
            }
            // Info column
            Column({ space: 6 }) {
              Text(this.userName || '华为用户')
                .fontSize(20).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(700).maxLines(1)
              Text(this.harmonyLogin ? '华为账号 · 星枢令' : (this.userPhone || '玄钥账号'))
                .fontSize(13).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
              // Status chips
              Row({ space: 6 }) {
                Text('已登录')
                  .fontSize(11).fontColor(this.c('#fff', '#2C1810'))
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .borderRadius(8)
                  .backgroundColor(this.c(this.accentColor + '55', this.accentColor + '25'))
                  .border({ width: 1, color: this.c(this.accentColor + '77', this.accentColor + '55') })
                if (this.isMember) {
                  Text('会员')
                    .fontSize(11).fontColor('#C8993A')
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .borderRadius(8)
                    .backgroundColor('#C8993A18')
                    .border({ width: 1, color: '#C8993A44' })
                }
              }
            }.alignItems(HorizontalAlign.Start).flexGrow(1)
            // Logout button — circular, right side
            Button({ type: ButtonType.Normal }) {
              Image($r('app.media.quit'))
                .width(18).height(18)
                .fillColor('#fff')
            }
            .width(38).height(38).borderRadius(19)
            .backgroundColor(this.accentColor)
            .onClick(() => this.onLogout())
          }
          .alignItems(VerticalAlign.Center)
          .width('100%').padding(16)
          .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(16)
          .border({ width: 1, color: this.accentColor + '30' })
          .margin({ bottom: 20 })
        } else {
          Row() {
            Text('登录后解锁更多功能')
              .fontSize(14).fontColor(this.c('rgba(238,238,245,0.55)', '#5C4F43'))
            Button('登录账号')
              .backgroundColor(this.accentColor).fontColor('#fff')
              .fontSize(14).fontWeight(600).borderRadius(18)
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .shadow({ radius: 20, color: this.accentColor + '55', offsetX: 0, offsetY: 4 })
              .onClick(() => this.onLoginTap())
          }
          .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(14)
          .border({ width: 1, color: this.c('rgba(255,255,255,0.05)', '#E8E2D9') })
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 20 })
        }

        // Menu
        Column() {
          // Membership
          Column() {
            Row({ space: 0 }) {
              Stack() { Text('👑').fontSize(16) }
                .width(34).height(34).borderRadius(10)
                .backgroundColor(this.accentColor + '28')
                .margin({ right: 14 })
              Column({ space: 2 }) {
                Text(this.isMember ? '会员特权' : '开通会员').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                Text(this.isMember ? '永久会员 · 永久有效' : '¥19.90 · 永久会员，无限制添加')
                  .fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .onClick(() => this.onMembershipTap())
            Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
          }
          // Backup
          Column() {
            Row({ space: 0 }) {
              Stack() { Text('☁️').fontSize(16) }
                .width(34).height(34).borderRadius(10)
                .backgroundColor(this.accentColor + '28')
                .margin({ right: 14 })
              Column({ space: 2 }) {
                Text('备份数据').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                Text(this.isMember ? '加密备份到云端' : '会员专属')
                  .fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .opacity(this.loggedIn ? 1 : 0.65)
            .onClick(() => { if (this.loggedIn) this.onBackupTap(); })
            Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
          }
          // Import
          Column() {
            Row({ space: 0 }) {
              Stack() { Text('📥').fontSize(16) }
                .width(34).height(34).borderRadius(10)
                .backgroundColor(this.accentColor + '28')
                .margin({ right: 14 })
              Column({ space: 2 }) {
                Text('导入备份').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                Text(this.isMember ? '从云端恢复' : '会员专属')
                  .fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .opacity(this.loggedIn ? 1 : 0.65)
            .onClick(() => { if (this.loggedIn) this.onImportTap(); })
            Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
          }
          // Theme
          Column() {
            Row({ space: 0 }) {
              Stack() { Text('🎨').fontSize(16) }
                .width(34).height(34).borderRadius(10)
                .backgroundColor(this.accentColor + '28')
                .margin({ right: 14 })
              Column({ space: 2 }) {
                Text('皮肤主题').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                Text(this.themeName).fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .onClick(() => this.onThemeTap())
            Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
          }
          // Display Mode
          Column() {
            Row({ space: 0 }) {
              Stack() { Text(this.isDark ? '🌙' : '☀️').fontSize(16) }
                .width(34).height(34).borderRadius(10)
                .backgroundColor(this.accentColor + '28')
                .margin({ right: 14 })
              Column({ space: 2 }) {
                Text('显示模式').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                Text(this.isDark ? '深色' : '浅色').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .onClick(() => this.onToggleMode())
            Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
          }
          // Feedback
          Column() {
            Row({ space: 0 }) {
              Stack() { Text('💬').fontSize(16) }
                .width(34).height(34).borderRadius(10)
                .backgroundColor(this.accentColor + '28')
                .margin({ right: 14 })
              Column({ space: 2 }) {
                Text('意见与建议').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                Text('向我们反馈问题或建议').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .onClick(() => this.onFeedbackTap())
            Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
          }
          // About Us
          Column() {
            Row({ space: 0 }) {
              Stack() { Text('ℹ️').fontSize(16) }
                .width(34).height(34).borderRadius(10)
                .backgroundColor(this.accentColor + '28')
                .margin({ right: 14 })
              Column({ space: 2 }) {
                Text('关于我们').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                Text('版本号·法律·联系方式').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .onClick(() => this.onAboutTap())
          }
        }
        .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(18)
        .border({ width: 1, color: this.c('rgba(255,255,255,0.05)', '#E8E2D9') })

        Column().height(100)
      }
      .padding({ left: 20, right: 20, top: 16 })
    }
    .scrollBar(BarState.Off).width('100%').height('100%').backgroundColor(this.c('#0d0d12', '#FAF7F2'))
    .onScrollFrameBegin((offset: number) => {
      const y = this.scroller.currentOffset().yOffset + offset;
      if (y < 30 || y < this.lastScrollY) {
        clearTimeout(this.scrollTimer);
        this.onNavShow();
      } else if (y > this.lastScrollY) {
        clearTimeout(this.scrollTimer);
        this.onNavHide();
      }
      this.lastScrollY = y;
      return { offsetRemain: offset };
    })
    .onScrollStop(() => {
      clearTimeout(this.scrollTimer);
      this.scrollTimer = setTimeout(() => { this.onNavShow(); }, 400);
    })
  }
}
