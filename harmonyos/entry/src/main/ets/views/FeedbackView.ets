import { pasteboard } from '@kit.BasicServicesKit';
import promptAction from '@ohos.promptAction';
import cloud from '@hw-agconnect/cloud';

// 云函数返回值接口
interface CloudResultValue {
  success: boolean;
  error?: string;
}

// 通过 AGC 云函数发送反馈（推荐方式）
async function cloudSendFeedback(type: string, content: string, contactInfo: string): Promise<void> {
  const result = await cloud.callFunction({
    name: 'send-feedback',
    version: '$latest',
    params: { type: type, content: content, contactInfo: contactInfo },
    timeout: 30000
  });
  const value: CloudResultValue = result.getValue() as CloudResultValue;
  if (value !== null && value !== undefined && value.success === true) {
    return;
  }
  const errMsg: string = (value !== null && value !== undefined && value.error !== undefined)
    ? value.error : '云函数返回失败';
  throw new Error(errMsg);
}

@Component
export struct FeedbackView {
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  @State type: string = '需求';
  @State content: string = '';
  @State contact: string = '';
  @State sending: boolean = false;
  onClose: () => void = () => {};
  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  // 规范化邮箱：去空白 + 把中文键盘常打出的全角符号转成 ASCII，再校验
  private normalizeEmail(email: string): string {
    return email
      .replace(/\s/g, '')        // 去掉所有空白/换行
      .replace(/[＠]/g, '@')      // 全角 ＠ → @
      .replace(/[。．｡]/g, '.');  // 中文/全角句号 → .
  }

  // 用确定性字符串判断，不用正则 .test()
  // —— ArkTS 下正则 .test() 会保留 lastIndex 状态，同一输入连续调用会交替返回 true/false
  private isValidEmail(email: string): boolean {
    const e = this.normalizeEmail(email);
    const at = e.indexOf('@');
    if (at <= 0) return false;                          // 必须有 @，且 @ 前有内容
    if (e.indexOf('@', at + 1) !== -1) return false;    // 只能有一个 @
    const domain = e.substring(at + 1);
    const dot = domain.indexOf('.');
    if (dot <= 0) return false;                         // 域名里要有 . 且 . 前有内容
    if (dot === domain.length - 1) return false;        // . 后要有内容（顶级域名）
    return true;
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
          Text('反馈类型').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50')).width('100%')
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
          // 邮箱框：非受控（不绑定 text），避免 onChange 回写重置 IME 光标导致新字符前插；
          // 关闭自动填充，防止输入法往空框注入幽灵字符（日志中的 InsertText length:8）
          TextInput({ placeholder: '请输入邮箱地址' })
            .onChange((v: string) => { this.contact = v; })
            .enableAutoFill(false)
            .enablePreviewText(false)  // 关闭预上屏区，每个字符立即上屏，防止失焦时末尾文本丢失
            .backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
            .placeholderColor(this.c('rgba(238,238,245,0.45)', '#9B8B80'))
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

          Text('您的反馈将发送至开发团队，我们认真对待每一条建议')
            .fontSize(11).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50')).textAlign(TextAlign.Center)
        }
        .padding({ left: 20, right: 20, top: 12, bottom: 40 })
        .width('100%').constraintSize({ minHeight: '100%' })
      }.scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(this.c('#0d0d12', '#FAF7F2'))
    .padding({ top: 44 })
  }

  private toast(msg: string): void {
    promptAction.showToast({ message: msg, duration: 2500 });
  }

  private async submitFeedback(): Promise<void> {
    const contentLen: number = this.content.length;
    const contactLen: number = this.contact.length;
    const emailOk: boolean = this.isValidEmail(this.contact);

    if (contentLen < 10) {
      this.toast('请至少输入10个字的反馈内容');
      return;
    }
    if (contentLen > 500) {
      this.toast('反馈内容不能超过500字');
      return;
    }
    if (contactLen === 0) {
      this.toast('请输入联系邮箱');
      return;
    }
    if (!emailOk) {
      this.toast('邮箱格式不正确');
      return;
    }
    this.sending = true;
    const cleanContact = this.normalizeEmail(this.contact);
    try {
      await cloudSendFeedback(this.type, this.content, cleanContact);
      this.sending = false;
      this.content = '';
      this.contact = '';
      this.toast('反馈已提交，感谢您的建议！');
      this.onClose();
    } catch (_cloudErr) {
      this.sending = false;
      await this.fallbackCopy(cleanContact);
    }
  }

  private async fallbackCopy(cleanContact: string): Promise<void> {
    const target = 'mengyuefeitian@gmail.com';
    const text =
      `【星枢令反馈】请发送至 ${target}\n\n反馈类型: ${this.type}\n\n反馈内容:\n${this.content}\n\n联系方式: ${cleanContact}\n`;
    try {
      const pb = pasteboard.getSystemPasteboard();
      const pbData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      await pb.setData(pbData);
      this.toast(`提交失败，反馈已复制到剪贴板，请粘贴至 ${target}`);
    } catch (_) {
      this.toast(`提交失败，请手动发送反馈至 ${target}`);
    }
  }
}
