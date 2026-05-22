import { Token, OtpPair } from '../model/Token';
import { TokenCard } from '../components/TokenCard';

@Component
export struct HomeView {
  @Prop tokens: Token[] = [];
  @Prop otpMap: Record<string, OtpPair> = {};
  @Prop timeLeft: number = 30;
  @Prop accentColor: string = '#4080D0';
  @Link searching: boolean;
  @Link searchQ: string;
  onEdit: (tok: Token) => void = () => {};
  onCopy: (code: string, brand: string) => void = () => {};
  onDelete: (tok: Token) => void = () => {};
  onNavHide: () => void = () => {};
  onNavShow: () => void = () => {};

  private lastScrollY: number = 0;
  private scroller: Scroller = new Scroller();

  private filtered(): Token[] {
    if (!this.searchQ) return this.tokens;
    const q = this.searchQ.toLowerCase();
    return this.tokens.filter(t =>
      t.brand.toLowerCase().includes(q) || t.account.toLowerCase().includes(q)
    );
  }

  build() {
    Column() {
      // Inline search bar (shown only when searching, takes one row at top)
      if (this.searching) {
        Row({ space: 6 }) {
          // Back arrow
          Text('←')
            .fontSize(16).fontColor('rgba(238,238,245,0.55)')
            .width(28).height(28)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.searching = false; this.searchQ = ''; })
          // Search icon
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontColor(['rgba(238,238,245,0.55)'])
            .fontSize(18)
          TextInput({ text: this.searchQ, placeholder: '搜索品牌或账号' })
            .flexGrow(1)
            .backgroundColor(Color.Transparent)
            .fontColor('#eeeef5')
            .placeholderColor('rgba(238,238,245,0.25)')
            .fontSize(13)
            .height(28)
            .padding(0)
            .onChange((v) => { this.searchQ = v; })
          // Clear button
          if (this.searchQ.length > 0) {
            Text('×')
              .fontSize(16).fontWeight(500).fontColor('rgba(238,238,245,0.5)')
              .width(20).height(20)
              .textAlign(TextAlign.Center)
              .onClick(() => { this.searchQ = ''; })
          }
        }
        .width('100%')
        .height(36)
        .padding({ left: 8, right: 8 })
        .margin({ left: 16, right: 16, top: 4, bottom: 4 })
        .backgroundColor('#191920')
        .borderRadius(10)
        .border({ width: 1, color: this.accentColor + '55' })
        .alignItems(VerticalAlign.Center)
      }

      // List
      List({ space: 0, scroller: this.scroller }) {
        if (this.filtered().length === 0) {
          ListItem() {
            Column({ space: 12 }) {
              Text('🔍').fontSize(36)
              Text(this.searchQ ? '未找到匹配账号' : '暂无验证码\n点击下方扫码添加')
                .fontSize(14).fontColor('rgba(238,238,245,0.25)').textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ top: 70, bottom: 70 })
            .justifyContent(FlexAlign.Center)
          }
        }
        ForEach(this.filtered(), (tok: Token) => {
          ListItem() {
            TokenCard({
              token: tok,
              otp: this.otpMap[tok.id] ?? { current: '------', next: '------' },
              timeLeft: this.timeLeft,
              accentColor: this.accentColor,
              onEdit: (t: Token) => this.onEdit(t),
              onCopy: (code: string, brand: string) => this.onCopy(code, brand),
              onDelete: (t: Token) => this.onDelete(t),
            })
          }
        }, (tok: Token) => tok.id)
        ListItem() { Column().height(96) }
      }
      .width('100%')
      .flexGrow(1)
      .padding({ left: 16, right: 16, top: this.searching ? 0 : 8 })
      .scrollBar(BarState.Off)
      .onScrollFrameBegin((offset: number) => {
        const y = this.scroller.currentOffset().yOffset + offset;
        if (y < 30) {
          this.onNavShow();
        } else if (y > this.lastScrollY) {
          this.onNavHide();
        } else {
          this.onNavShow();
        }
        this.lastScrollY = y;
        return { offsetRemain: offset };
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0d0d12')
  }
}
