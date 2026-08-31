import { PasswordEntry, PasswordGroup, groupByDomain } from '../model/PasswordEntry';

@Component
export struct PasswordView {
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  @Prop isMember: boolean = false;
  @Prop loggedIn: boolean = false;
  @Link passwords: PasswordEntry[];
  @Link openDomain: string;
  onChange: (list: PasswordEntry[]) => void = () => {};
  onImport: () => void = () => {};
  onExport: () => void = () => {};
  onNavHide: () => void = () => {};
  onNavShow: () => void = () => {};

  @State query: string = '';

  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  build() {
    Column() {
      // 顶部常驻搜索框
      Row({ space: 6 }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontColor([this.c('rgba(238,238,245,0.55)', '#5C4F43')]).fontSize(18)
        TextInput({ text: this.query, placeholder: '搜索域名、站点或用户名' })
          .flexGrow(1).backgroundColor(Color.Transparent)
          .fontColor(this.c('#eeeef5', '#2C1810'))
          .placeholderColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
          .fontSize(13).height(28).padding(0)
          .onChange((v: string) => { this.query = v; })
        if (this.query.length > 0) {
          Text('×').fontSize(16).fontColor(this.c('rgba(238,238,245,0.5)', '#5C4F43'))
            .width(20).height(20).textAlign(TextAlign.Center)
            .onClick(() => { this.query = ''; })
        }
      }
      .height(36).padding({ left: 16, right: 16, top: 6, bottom: 6 })
      .margin({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(10)
      .border({ width: 1, color: this.accentColor + '55' })
      .alignItems(VerticalAlign.Center)

      // 占位内容（Task 6 替换）
      Column() {
        Text('密码库').fontSize(14).fontColor(this.c('rgba(238,238,245,0.6)', '#6B5B50'))
      }
      .width('100%').flexGrow(1).justifyContent(FlexAlign.Center)
    }
    .width('100%').height('100%')
    .backgroundColor(this.c('#0d0d12', '#FAF7F2'))
  }
}
