import { common, Want } from '@kit.AbilityKit';

@Component
export struct FeedbackView {
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  @State type: string = '需求';
  @State content: string = '';
  @State contact: string = '';
  @State sending: boolean = false;
  @State submitError: string = '';
  onClose: () => void = () => {};
  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  private isValidEmail(email: string): boolean {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
  }

  get canSubmit(): boolean {
    return this.content.length >= 10 && this.content.length <= 500 && this.isValidEmail(this.contact);
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Button({ type: ButtonType.Normal }) {
          Text('×').fontSize(20).fontColor(this.c('rgba(238,238,245,0.75)', '#5C4F43'))
        }
        .backgroundColor(this.c('rgba(255,255,255,0.08)', 'rgba(0,0,0,0.06)')).borderRadius(11).width(36).height(36)
        .onClick(this.onClose)
        Text('意见与建议').fontSize(17).fontWeight(650).fontColor(this.c('#eeeef5', '#2C1810'))
      }.width('100%').padding({ left: 16, right: 16, top: 8, bottom: 0 })

      Scroll() {
        Column({ space: 16 }) {
          // Feedback type
          Text('反馈类型').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
          Row({ space: 8 }) {
            Button('需求').flexGrow(1)
              .backgroundColor(this.type === '需求' ? this.accentColor + '18' : Color.Transparent)
              .border({ width: 1, color: this.type === '需求' ? this.accentColor + '60' : this.c('rgba(255,255,255,0.08)', '#E8E2D9') })
              .borderRadius(12).fontColor(this.type === '需求' ? this.accentColor : this.c('rgba(238,238,245,0.5)', '#5C4F43'))
              .fontSize(14).fontWeight(600)
              .onClick(() => { this.type = '需求'; })
            Button('Bug').flexGrow(1)
              .backgroundColor(this.type === 'Bug' ? this.accentColor + '18' : Color.Transparent)
              .border({ width: 1, color: this.type === 'Bug' ? this.accentColor + '60' : this.c('rgba(255,255,255,0.08)', '#E8E2D9') })
              .borderRadius(12).fontColor(this.type === 'Bug' ? this.accentColor : this.c('rgba(238,238,245,0.5)', '#5C4F43'))
              .fontSize(14).fontWeight(600)
              .onClick(() => { this.type = 'Bug'; })
          }.width('100%')

          // Content
          Text('反馈内容 *').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
          TextArea({ text: this.content, placeholder: '请描述您的问题或建议（至少10个字，最多500字）' })
            .onChange((v: string) => { this.content = v; })
            .height(140).backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
            .border({ width: 1, color: this.c('rgba(255,255,255,0.08)', '#E8E2D9') }).borderRadius(12)
            .fontSize(14).placeholderColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))

          Text(`${this.content.length}/500`)
            .fontSize(11).fontColor(this.content.length > 500 ? '#f87171' : this.c('rgba(238,238,245,0.60)', '#6B5B50'))
            .textAlign(TextAlign.End).width('100%')

          // Contact
          Text('联系邮箱 *').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
          TextInput({ text: this.contact, placeholder: '请输入邮箱地址' })
            .onChange((v: string) => { this.contact = v; })
            .backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
            .border({ width: 1, color: (this.contact.length > 0 && !this.isValidEmail(this.contact)) ? '#f87171' : this.c('rgba(255,255,255,0.08)', '#E8E2D9') })
            .borderRadius(12).height(44).type(InputType.Email)
          if (this.contact.length > 0 && !this.isValidEmail(this.contact)) {
            Text('邮箱格式不正确').fontSize(11).fontColor('#f87171').width('100%')
          }

          // Submit
          Button(this.sending ? '提交中…' : '提交反馈')
            .width('100%').height(50).borderRadius(15)
            .backgroundColor(this.canSubmit ? this.accentColor : this.c('#191920', '#F5F0EA'))
            .fontColor(this.canSubmit ? '#fff' : this.c('rgba(238,238,245,0.60)', '#6B5B50'))
            .fontSize(15).fontWeight(650)
            .onClick(() => this.submitFeedback())

          if (this.submitError) {
            Text(this.submitError)
              .fontSize(12).fontColor('#f87171').textAlign(TextAlign.Center).width('100%')
          }
          Text('您的反馈将发送至开发团队，我们认真对待每一条建议')
            .fontSize(11).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50')).textAlign(TextAlign.Center)
        }
        .padding({ left: 20, right: 20, top: 4, bottom: 40 })
      }.scrollBar(BarState.Off).flexGrow(1)
    }
    .width('100%').height('100%').backgroundColor(this.c('#0d0d12', '#FAF7F2'))
    .padding({ top: 44 }) // Add status bar safe area padding
  }

  private async submitFeedback(): Promise<void> {
    if (!this.canSubmit) {
      if (this.content.length < 10) {
        this.submitError = '请至少输入10个字的反馈内容';
      } else if (this.content.length > 500) {
        this.submitError = '反馈内容不能超过500字';
      } else if (!this.isValidEmail(this.contact)) {
        this.submitError = this.contact.length === 0 ? '请输入联系邮箱' : '邮箱格式不正确';
      }
      return;
    }
    this.sending = true;
    const subject = `[星枢令][${this.type}]`;
    let body = `反馈类型: ${this.type}\n\n反馈内容:\n${this.content}\n\n`;
    if (this.contact) body += `联系方式: ${this.contact}\n`;
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('context');
      if (!ctx) throw new Error('no context');
      const uri = `mailto:mengyuefeitian@gmail.com?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: uri,
        entities: ['entity.system.browsable'],
      };
      await ctx.startAbility(want);
      this.sending = false;
      this.submitError = '';
      this.onClose();
    } catch (_) {
      this.sending = false;
      this.submitError = '发送失败，请确认已安装邮件应用';
    }
  }
}