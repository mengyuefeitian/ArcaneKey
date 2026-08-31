import { PasswordEntry, PasswordGroup, groupByDomain, OTHER_DOMAIN, entryInDomain } from '../model/PasswordEntry';
import { extractDomain } from '../utils/DomainUtil';
import { Logo } from '../components/Logo';
import { pasteboard } from '@kit.BasicServicesKit';

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
  @State private revealId: string = '';
  @State private toastMsg: string = '';
  @State private toastShow: boolean = false;
  private toastTimer: number = -1;

  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  private domainLabel(key: string): string { return key === OTHER_DOMAIN ? '其他' : key; }

  private tip(msg: string): void {
    clearTimeout(this.toastTimer);
    this.toastMsg = msg;
    this.toastShow = true;
    this.toastTimer = setTimeout(() => { this.toastShow = false; }, 1800) as number;
  }

  private copy(text: string, label: string): void {
    try {
      const d = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      pasteboard.getSystemPasteboard().setData(d);
      this.tip(`已复制${label}`);
    } catch (_) { this.tip('复制失败'); }
  }

  private currentEntries(): PasswordEntry[] {
    return this.passwords.filter((e: PasswordEntry) => entryInDomain(e, this.openDomain));
  }

  private beginEdit(e: PasswordEntry): void {}

  private removeEntry(e: PasswordEntry): void {
    const next: PasswordEntry[] = this.passwords.filter((x: PasswordEntry) => x.id !== e.id);
    this.passwords = next;
    this.onChange(next);
    this.tip('已删除');
  }

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

  aboutToDisappear(): void { clearTimeout(this.toastTimer); }

  @Builder
  entryCard(e: PasswordEntry) {
    Column({ space: 8 }) {
      Text(e.name || e.url || '(未命名)')
        .fontSize(14).fontWeight(600).fontColor(this.c('#eeeef5', '#2C1810')).width('100%')
      if (e.url) {
        Text(e.url).fontSize(11).fontColor(this.c('rgba(238,238,245,0.5)', '#9B8B80'))
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
      }
      Row({ space: 6 }) {
        Text('账号').fontSize(11).fontColor(this.c('rgba(238,238,245,0.45)', '#9B8B80')).width(40)
        Text(e.username || '—').fontSize(13).fontColor(this.c('#eeeef5', '#2C1810')).flexGrow(1)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('复制').fontSize(12).fontColor(this.accentColor)
          .onClick(() => { this.copy(e.username, '账号'); })
      }.width('100%').alignItems(VerticalAlign.Center)
      Row({ space: 6 }) {
        Text('密码').fontSize(11).fontColor(this.c('rgba(238,238,245,0.45)', '#9B8B80')).width(40)
        Text(this.revealId === e.id ? (e.password || '—') : '••••••••')
          .fontSize(13).fontFamily('monospace').fontColor(this.c('#eeeef5', '#2C1810')).flexGrow(1)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.revealId === e.id ? '隐藏' : '显示').fontSize(12).fontColor(this.accentColor)
          .onClick(() => { this.revealId = this.revealId === e.id ? '' : e.id; })
        Text('复制').fontSize(12).fontColor(this.accentColor)
          .onClick(() => { this.copy(e.password, '密码'); })
      }.width('100%').alignItems(VerticalAlign.Center)
      if (e.note) {
        Text(e.note).fontSize(11).fontColor(this.c('rgba(238,238,245,0.5)', '#6B5B50')).width('100%')
      }
      Row() {
        Text('编辑').fontSize(12).fontColor(this.c('rgba(238,238,245,0.6)', '#6B5B50'))
          .onClick(() => { this.beginEdit(e); })
      }.width('100%').justifyContent(FlexAlign.End)
    }
    .width('100%').padding(14)
    .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(14)
    .border({ width: 1, color: this.c('rgba(255,255,255,0.05)', '#E8E2D9') })
  }

  @Builder
  deleteAction(e: PasswordEntry) {
    Column() {
      Text('删除').fontSize(13).fontColor('#ff5a5a')
    }
    .width(64).height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .onClick(() => { this.removeEntry(e); })
  }

  build() {
    Stack() {
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

        if (this.openDomain !== '') {
          // 详情头
          Row({ space: 8 }) {
            Text('‹ 返回').fontSize(14).fontColor(this.accentColor)
              .onClick(() => { this.openDomain = ''; this.revealId = ''; })
            Text(this.domainLabel(this.openDomain))
              .fontSize(16).fontWeight(700).fontColor(this.c('#eeeef5', '#2C1810')).flexGrow(1)
              .textAlign(TextAlign.Center)
            Text('').width(44)
          }
          .width('100%').padding({ left: 16, right: 16, top: 4, bottom: 8 }).alignItems(VerticalAlign.Center)

          List({ space: 10 }) {
            ForEach(this.currentEntries(), (e: PasswordEntry) => {
              ListItem() { this.entryCard(e) }
              .swipeAction({ end: () => { this.deleteAction(e) } })
            }, (e: PasswordEntry) => e.id)
            ListItem() { Column().height(96) }
          }
          .width('100%').flexGrow(1).padding({ left: 16, right: 16 }).scrollBar(BarState.Off)
        } else {
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
      }
      .width('100%').height('100%')
      .backgroundColor(this.c('#0d0d12', '#FAF7F2'))

      if (this.toastShow) {
        Text(this.toastMsg)
          .fontSize(13).fontColor('#f0f0f5')
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .backgroundColor('rgba(22,22,30,0.96)').borderRadius(20)
          .position({ x: '50%', y: '90%' }).translate({ x: '-50%', y: 0 })
      }
    }
    .width('100%').height('100%')
  }
}
