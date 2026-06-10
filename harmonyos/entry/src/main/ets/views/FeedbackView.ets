import { common, Want } from '@kit.AbilityKit';

@Component
export struct FeedbackView {
  @Prop accentColor: string = '#4080D0';
  @State type: string = '需求';
  @State content: string = '';
  @State contact: string = '';
  @State sending: boolean = false;
  onClose: () => void = () => {};

  get canSubmit(): boolean {
    return this.content.length >= 10 && this.content.length <= 500;
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Button({ type: ButtonType.Normal }) {
          Text('×').fontSize(20).fontColor('rgba(238,238,245,0.75)')
        }
        .backgroundColor('rgba(255,255,255,0.08)').borderRadius(11).width(36).height(36)
        .onClick(this.onClose)
        Text('意见与建议').fontSize(17).fontWeight(650).fontColor('#eeeef5')
      }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 8 })

      Scroll() {
        Column({ space: 16 }) {
          // Feedback type
          Text('反馈类型').fontSize(12).fontColor('rgba(238,238,245,0.45)')
          Row({ space: 8 }) {
            Button('需求').flexGrow(1)
              .backgroundColor(this.type === '需求' ? this.accentColor + '18' : Color.Transparent)
              .border({ width: 1, color: this.type === '需求' ? this.accentColor + '60' : 'rgba(255,255,255,0.08)' })
              .borderRadius(12).fontColor(this.type === '需求' ? this.accentColor : 'rgba(238,238,245,0.5)')
              .fontSize(14).fontWeight(600)
              .onClick(() => { this.type = '需求'; })
            Button('Bug').flexGrow(1)
              .backgroundColor(this.type === 'Bug' ? this.accentColor + '18' : Color.Transparent)
              .border({ width: 1, color: this.type === 'Bug' ? this.accentColor + '60' : 'rgba(255,255,255,0.08)' })
              .borderRadius(12).fontColor(this.type === 'Bug' ? this.accentColor : 'rgba(238,238,245,0.5)')
              .fontSize(14).fontWeight(600)
              .onClick(() => { this.type = 'Bug'; })
          }.width('100%')

          // Content
          Text('反馈内容 *').fontSize(12).fontColor('rgba(238,238,245,0.45)')
          TextArea({ text: this.content, placeholder: '请描述您的问题或建议（至少10个字，最多500字）' })
            .onChange((v: string) => { this.content = v; })
            .height(140).backgroundColor('#191920').fontColor('#eeeef5')
            .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
            .fontSize(14).placeholderColor('rgba(238,238,245,0.25)')

          Text(`${this.content.length}/500`)
            .fontSize(11).fontColor(this.content.length > 500 ? '#f87171' : 'rgba(238,238,245,0.25)')
            .textAlign(TextAlign.End).width('100%')

          // Contact
          Text('联系方式（选填，手机号或邮箱）').fontSize(12).fontColor('rgba(238,238,245,0.45)')
          TextInput({ text: this.contact, placeholder: '手机号或邮箱' })
            .onChange((v: string) => { this.contact = v; })
            .backgroundColor('#191920').fontColor('#eeeef5')
            .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
            .height(44)

          // Submit
          Button(this.sending ? '提交中…' : '提交反馈')
            .width('100%').height(50).borderRadius(15)
            .backgroundColor(this.canSubmit ? this.accentColor : '#191920')
            .fontColor(this.canSubmit ? '#fff' : 'rgba(238,238,245,0.3)')
            .fontSize(15).fontWeight(650)
            .onClick(() => this.submitFeedback())

          Text('您的反馈将发送至开发团队，我们认真对待每一条建议')
            .fontSize(11).fontColor('rgba(238,238,245,0.2)').textAlign(TextAlign.Center)
        }
        .padding({ left: 20, right: 20, top: 8, bottom: 40 })
      }.scrollBar(BarState.Off).flexGrow(1)
    }
    .width('100%').height('100%').backgroundColor('#0d0d12')
    .padding({ top: 44 }) // Add status bar safe area padding
  }

  private async submitFeedback(): Promise<void> {
    if (!this.canSubmit) return;
    this.sending = true;
    const subject = `[星枢令][${this.type}]`;
    let body = `反馈类型: ${this.type}\n\n反馈内容:\n${this.content}\n\n`;
    if (this.contact) body += `联系方式: ${this.contact}\n`;
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('context');
      if (!ctx) throw new Error('no context');
      const uri = `mailto:mengyuefeitian@gmail.com?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
      const want: Want = {
        action: 'ohos.want.action.sendData',
        uri: uri,
      };
      await ctx.startAbility(want);
      this.sending = false;
      this.onClose();
    } catch (_) {
      this.sending = false;
    }
  }
}