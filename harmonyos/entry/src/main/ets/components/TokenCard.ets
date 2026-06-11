import { Token, OtpPair } from '../model/Token';
import { Logo } from './Logo';
import { CountdownRing } from './CountdownRing';

function fmt(s: string): string {
  if (!s || s.length < 6) return s || '------';
  return s.slice(0, 3) + ' ' + s.slice(3);
}

@Component
export struct TokenCard {
  @Prop token: Token = { id: '', brand: '', account: '', secret: '' };
  @Prop otp: OtpPair = { current: '------', next: '------' };
  @Prop timeLeft: number = 30;
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  onEdit: (tok: Token) => void = () => {};
  onCopy: (code: string, brand: string) => void = () => {};
  onDelete: (tok: Token) => void = () => {};
  private c(dark: string, light: string): string { return this.isDark ? dark : light; }
  private interpolateColor(hex: string, t: number): string {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    const mix = 0.4 * (1 - t);
    const nr = Math.round(r + (255 - r) * mix);
    const ng = Math.round(g + (255 - g) * mix);
    const nb = Math.round(b + (255 - b) * mix);
    const rs = nr.toString(16).padStart(2, '0');
    const gs = ng.toString(16).padStart(2, '0');
    const bs = nb.toString(16).padStart(2, '0');
    return '#' + rs + gs + bs;
  }

  @Builder
  contextMenu() {
    Menu() {
      MenuItem({ content: '复制口令' })
        .onClick(() => this.onCopy(this.otp.current, this.token.brand))
      MenuItem({ content: '复制下一个口令' })
        .onClick(() => this.onCopy(this.otp.next, this.token.brand))
      MenuItem({ content: '编辑' })
        .onClick(() => this.onEdit(this.token))
      MenuItem({ content: '删除' })
        .onClick(() => this.onDelete(this.token))
    }
  }

  build() {
    Column() {
        // Upper row — edit
        Row({ space: 12 }) {
          Logo({ brand: this.token.brand, logoSize: 42, isDark: this.isDark, accentColor: this.accentColor })
          Column({ space: 2 }) {
            Text(this.token.brand)
              .fontSize(15).fontWeight(650).fontColor(this.c('#eeeef5', '#2C1810')).maxLines(1)
            Text(this.token.account)
              .fontSize(12).fontColor(this.c('rgba(238,238,245,0.42)', '#8B7E74')).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .flexGrow(1)
          .flexShrink(1)
          CountdownRing({ timeLeft: this.timeLeft, accentColor: this.accentColor })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 10 })
        .onClick(() => this.onEdit(this.token))

        Divider().color(this.c('rgba(255,255,255,0.055)', 'rgba(0,0,0,0.07)')).strokeWidth(1).margin({ left: 16, right: 16 })

        // Lower row — copy
        Row() {
          Row({ space: 1 }) {
            Text(fmt(this.otp.current).charAt(0)).fontSize(30).fontWeight(700).fontFamily('monospace')
              .fontColor(this.interpolateColor(this.accentColor, 0))
              .letterSpacing(2)
            Text(fmt(this.otp.current).charAt(1)).fontSize(30).fontWeight(700).fontFamily('monospace')
              .fontColor(this.interpolateColor(this.accentColor, 0.2))
              .letterSpacing(2)
            Text(fmt(this.otp.current).charAt(2)).fontSize(30).fontWeight(700).fontFamily('monospace')
              .fontColor(this.interpolateColor(this.accentColor, 0.4))
              .letterSpacing(2)
            Text(' ').fontSize(30).fontWeight(700).fontFamily('monospace')
              .letterSpacing(8)
            Text(fmt(this.otp.current).charAt(4)).fontSize(30).fontWeight(700).fontFamily('monospace')
              .fontColor(this.interpolateColor(this.accentColor, 0.6))
              .letterSpacing(2)
            Text(fmt(this.otp.current).charAt(5)).fontSize(30).fontWeight(700).fontFamily('monospace')
              .fontColor(this.interpolateColor(this.accentColor, 0.8))
              .letterSpacing(2)
            Text(fmt(this.otp.current).charAt(6)).fontSize(30).fontWeight(700).fontFamily('monospace')
              .fontColor(this.interpolateColor(this.accentColor, 1.0))
          }
          Blank()
          Column({ space: 2 }) {
            Row({ space: 3 }) {
              Text('📋').fontSize(10).fontColor(this.c('rgba(238,238,245,0.28)', 'rgba(44,24,16,0.35)'))
              Text('点击复制').fontSize(10).fontColor(this.c('rgba(238,238,245,0.28)', 'rgba(44,24,16,0.35)'))
            }
            Row({ space: 5 }) {
              Text('下一个').fontSize(10).fontColor(this.c('rgba(238,238,245,0.28)', 'rgba(44,24,16,0.35)'))
              Text(fmt(this.otp.next))
                .fontSize(13).fontWeight(600)
                .fontColor(this.c('rgba(238,238,245,0.32)', 'rgba(44,24,16,0.42)'))
                .fontFamily('monospace').letterSpacing(2)
            }
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 11, bottom: 14 })
        .onClick(() => this.onCopy(this.otp.current, this.token.brand))
      }
      .width('100%')
      .borderRadius(18)
      .backgroundColor(this.c('#191920', '#FFFFFF'))
      .border({ width: 1, color: this.c('rgba(255,255,255,0.05)', '#E8E2D9') })
      .clip(true)
      .bindContextMenu(this.contextMenu(), ResponseType.LongPress)
      .margin({ bottom: 10 })
  }
}
