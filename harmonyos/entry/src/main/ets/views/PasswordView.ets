import { PasswordEntry, PasswordGroup, groupByDomain, OTHER_DOMAIN, entryInDomain } from '../model/PasswordEntry';
import { Logo } from '../components/Logo';

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

  private domainLabel(key: string): string { return key === OTHER_DOMAIN ? '其他' : key; }

  private visibleGroups(): PasswordGroup[] {
    const groups: PasswordGroup[] = groupByDomain(this.passwords);
    const q: string = this.query.trim().toLowerCase();
    if (!q) return groups;
    const out: PasswordGroup[] = [];
    for (const g of groups) {
      if (g.domain.toLowerCase().indexOf(q) >= 0) { out.push(g); continue; }
      const matched: PasswordEntry[] = g.entries.filter((e: PasswordEntry) =>
        e.name.toLowerCase().indexOf(q) >= 0 ||
        e.url.toLowerCase().indexOf(q) >= 0 ||
        e.username.toLowerCase().indexOf(q) >= 0
      );
      if (matched.length > 0) out.push({ domain: g.domain, entries: matched });
    }
    return out;
  }

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

      // 域名分组列表
      List({ space: 0 }) {
        if (this.visibleGroups().length === 0) {
          ListItem() {
            Column({ space: 12 }) {
              Text('🔐').fontSize(36)
              Text(this.query ? '未找到匹配的密码' : '暂无密码\n点右上角 + 添加，或导入 CSV')
                .fontSize(14).fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50')).textAlign(TextAlign.Center)
            }
            .width('100%').padding({ top: 70, bottom: 70 }).justifyContent(FlexAlign.Center)
          }
        }
        ForEach(this.visibleGroups(), (g: PasswordGroup) => {
          ListItem() {
            Row({ space: 12 }) {
              Logo({ brand: this.domainLabel(g.domain), account: '', logoSize: 40, isDark: this.isDark, accentColor: this.accentColor })
              Column({ space: 3 }) {
                Text(this.domainLabel(g.domain))
                  .fontSize(15).fontWeight(600).fontColor(this.c('#eeeef5', '#2C1810'))
                Text(`${g.entries.length} 个账号`)
                  .fontSize(12).fontColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.4)', '#9B8B80'))
            }
            .width('100%').padding({ left: 14, right: 14, top: 12, bottom: 12 })
            .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(14)
            .alignItems(VerticalAlign.Center)
            .onClick(() => { this.openDomain = g.domain; })
          }
          .padding({ bottom: 10 })
        }, (g: PasswordGroup) => g.domain)
        ListItem() { Column().height(96) }
      }
      .width('100%').flexGrow(1).padding({ left: 16, right: 16 }).scrollBar(BarState.Off)
    }
    .width('100%').height('100%')
    .backgroundColor(this.c('#0d0d12', '#FAF7F2'))
  }
}
