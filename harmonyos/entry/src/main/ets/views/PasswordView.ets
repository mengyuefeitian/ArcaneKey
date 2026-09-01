import { PasswordEntry, PasswordGroup, groupByDomain, OTHER_DOMAIN, entryInDomain } from '../model/PasswordEntry';
import { extractDomain } from '../utils/DomainUtil';
import { FREE_PASSWORD_LIMIT } from '../model/Token';
import { Logo } from '../components/Logo';
import { pasteboard } from '@kit.BasicServicesKit';
import { generatePassword } from '../utils/PasswordGen';

@Component
export struct PasswordView {
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  @Prop isMember: boolean = false;
  @Prop loggedIn: boolean = false;
  @Link passwords: PasswordEntry[];
  @Link openDomain: string;
  onChange: (list: PasswordEntry[]) => void = () => {};
  onNavHide: () => void = () => {};
  onNavShow: () => void = () => {};

  @Link formOpen: boolean;

  @State query: string = '';
  @State private formId: string = '';
  @State private fName: string = '';
  @State private fUrl: string = '';
  @State private fUser: string = '';
  @State private fPass: string = '';
  @State private fPassShow: boolean = false;
  @State private fNote: string = '';
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

  private flatMatches(): PasswordEntry[] {
    const q: string = this.query.trim().toLowerCase();
    if (!q) return [];
    return this.passwords.filter((e: PasswordEntry) =>
      e.name.toLowerCase().indexOf(q) >= 0 ||
      e.url.toLowerCase().indexOf(q) >= 0 ||
      e.username.toLowerCase().indexOf(q) >= 0 ||
      extractDomain(e.url).indexOf(q) >= 0
    );
  }

  private beginAdd(): void {
    this.formId = '';
    this.fName = '';
    this.fUrl = (this.openDomain && this.openDomain !== OTHER_DOMAIN) ? 'https://' + this.openDomain : '';
    this.fUser = '';
    this.fPass = '';
    this.fPassShow = false;
    this.fNote = '';
    this.formOpen = true;
    this.onNavHide();
  }

  private beginEdit(e: PasswordEntry): void {
    this.formId = e.id;
    this.fName = e.name;
    this.fUrl = e.url;
    this.fUser = e.username;
    this.fPass = e.password;
    this.fPassShow = false;
    this.fNote = e.note;
    this.formOpen = true;
    this.onNavHide();
  }

  private submitForm(): void {
    const url: string = this.fUrl.trim();
    const user: string = this.fUser.trim();
    const pass: string = this.fPass;
    if (!url && !user && !pass) { this.tip('请至少填写一项'); return; }
    if (this.formId === '') {
      if (!this.isMember && this.passwords.length >= FREE_PASSWORD_LIMIT) {
        this.tip(`免费用户最多保存 ${FREE_PASSWORD_LIMIT} 条密码`);
        return;
      }
      const entry: PasswordEntry = {
        id: Date.now().toString(),
        name: this.fName.trim() || extractDomain(url) || url || user,
        url: url, username: user, password: pass, note: this.fNote.trim(),
        timestamp: new Date().toISOString(),
      };
      const next: PasswordEntry[] = this.passwords.concat([entry]);
      this.passwords = next;
      this.onChange(next);
      this.tip('已保存');
    } else {
      const id: string = this.formId;
      const next: PasswordEntry[] = this.passwords.map((x: PasswordEntry): PasswordEntry => {
        if (x.id !== id) return x;
        const updated: PasswordEntry = {
          id: x.id,
          name: this.fName.trim() || extractDomain(url) || url || user,
          url: url, username: user, password: pass, note: this.fNote.trim(),
          timestamp: new Date().toISOString(),
        };
        return updated;
      });
      this.passwords = next;
      this.onChange(next);
      this.tip('已更新');
    }
    this.formOpen = false;
    this.onNavShow();
    if (this.openDomain !== '' && this.openDomain !== OTHER_DOMAIN && extractDomain(url) !== this.openDomain) {
      this.openDomain = '';
    }
  }

  private removeEntry(e: PasswordEntry): void {
    const next: PasswordEntry[] = this.passwords.filter((x: PasswordEntry) => x.id !== e.id);
    this.passwords = next;
    if (this.openDomain !== '' && next.filter((x: PasswordEntry) => entryInDomain(x, this.openDomain)).length === 0) {
      this.openDomain = '';
      this.revealId = '';
    }
    this.onChange(next);
    this.tip('已删除');
  }

  private visibleGroups(): PasswordGroup[] {
    const groups: PasswordGroup[] = groupByDomain(this.passwords);
    return groups;
  }

  aboutToDisappear(): void { clearTimeout(this.toastTimer); }

  @Builder
  cardDivider() {
    Divider().color(this.c('rgba(255,255,255,0.08)', '#E8E2D9')).strokeWidth(1)
  }

  @Builder
  entryCard(e: PasswordEntry) {
    Column({ space: 14 }) {
      // 标题行 —— 编辑图标在右上角，与标题同行
      Row({ space: 8 }) {
        Column({ space: 3 }) {
          Text(e.name || e.url || '(未命名)')
            .fontSize(16).fontWeight(600).fontColor(this.c('#eeeef5', '#2C1810')).width('100%')
          if (e.url) {
            Text(e.url).fontSize(12).fontColor(this.c('rgba(238,238,245,0.5)', '#9B8B80'))
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
          }
        }.alignItems(HorizontalAlign.Start).flexGrow(1)
        Button({ type: ButtonType.Normal }) {
          Image($r('app.media.icon_edit'))
            .width(17).height(17).fillColor(this.accentColor)
        }
        .width(32).height(32).borderRadius(9)
        .backgroundColor(this.c('rgba(255,255,255,0.06)', 'rgba(0,0,0,0.04)'))
        .onClick(() => { this.beginEdit(e); })
      }.width('100%').alignItems(VerticalAlign.Top)

      this.cardDivider()

      // 账号行 —— 长按复制
      Row({ space: 10 }) {
        Text('账号').fontSize(13).fontColor(this.c('rgba(238,238,245,0.45)', '#9B8B80')).width(44)
        Text(e.username || '—').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).flexGrow(1)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%').alignItems(VerticalAlign.Center)
      .priorityGesture(LongPressGesture().onAction((event: GestureEvent) => { this.copy(e.username, '账号'); }))

      this.cardDivider()

      // 密码行 —— 长按复制，眼睛图标切换显隐
      Row({ space: 10 }) {
        Text('密码').fontSize(13).fontColor(this.c('rgba(238,238,245,0.45)', '#9B8B80')).width(44)
        Text(this.revealId === e.id ? (e.password || '—') : '••••••••')
          .fontSize(15).fontFamily('monospace').fontColor(this.c('#eeeef5', '#2C1810')).flexGrow(1)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        SymbolGlyph(this.revealId === e.id ? $r('sys.symbol.eye_slash') : $r('sys.symbol.eye'))
          .fontSize(18).fontColor([this.accentColor])
          .onClick(() => { this.revealId = this.revealId === e.id ? '' : e.id; })
      }
      .width('100%').alignItems(VerticalAlign.Center)
      .priorityGesture(LongPressGesture().onAction((event: GestureEvent) => { this.copy(e.password, '密码'); }))

      if (e.note) {
        this.cardDivider()
        Text(e.note).fontSize(13).fontColor(this.c('rgba(238,238,245,0.55)', '#6B5B50')).width('100%')
      }
    }
    .width('100%').padding(16)
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

  @Builder
  formField(label: string, value: string, onCh: (v: string) => void, isPass: boolean) {
    Column({ space: 6 }) {
      Text(label).fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50'))
      TextInput({ text: value, placeholder: '' })
        .type(isPass ? InputType.Password : InputType.Normal)
        .onChange(onCh)
        .backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
        .border({ width: 1, color: this.c('rgba(255,255,255,0.08)', '#E8E2D9') }).borderRadius(12)
        .height(44).padding({ left: 14, right: 14 })
    }.alignItems(HorizontalAlign.Start).width('100%')
  }

  @Builder
  pwField() {
    Column({ space: 6 }) {
      Row({ space: 12 }) {
        Text('密码').fontSize(12).fontColor(this.c('rgba(238,238,245,0.65)', '#6B5B50')).flexGrow(1)
        Text('生成').fontSize(12).fontColor(this.accentColor)
          .onClick(() => { this.fPass = generatePassword(); this.fPassShow = true; this.tip('已生成强密码'); })
        if (this.fPass.length > 0) {
          Text(this.fPassShow ? '隐藏' : '显示').fontSize(12).fontColor(this.accentColor)
            .onClick(() => { this.fPassShow = !this.fPassShow; })
          Text('复制').fontSize(12).fontColor(this.accentColor)
            .onClick(() => { this.copy(this.fPass, '密码'); })
        }
      }.width('100%').alignItems(VerticalAlign.Center)
      TextInput({ text: this.fPass, placeholder: '' })
        .type(this.fPassShow ? InputType.Normal : InputType.Password)
        .onChange((v: string) => { this.fPass = v; })
        .backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
        .border({ width: 1, color: this.c('rgba(255,255,255,0.08)', '#E8E2D9') }).borderRadius(12)
        .height(44).padding({ left: 14, right: 14 })
    }.alignItems(HorizontalAlign.Start).width('100%')
  }

  @Builder
  formOverlay() {
    Column() {
      // Header — 左对齐，与设置页备份/导入弹窗一致
      Row({ space: 12 }) {
        Button({ type: ButtonType.Normal }) {
          Text('×').fontSize(20).fontColor(this.c('rgba(238,238,245,0.75)', '#5C4F43'))
        }
        .backgroundColor(this.c('rgba(255,255,255,0.08)', 'rgba(0,0,0,0.06)')).borderRadius(11).width(36).height(36)
        .onClick(() => { this.formOpen = false; this.onNavShow(); })
        Text(this.formId === '' ? '新增密码' : '编辑密码')
          .fontSize(17).fontWeight(650).fontColor(this.c('#eeeef5', '#2C1810'))
      }
      .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 0 })
      .alignItems(VerticalAlign.Center)

      Column({ space: 14 }) {
        this.formField('名称', this.fName, (v: string) => { this.fName = v; }, false)
        this.formField('站点 URL', this.fUrl, (v: string) => { this.fUrl = v; }, false)
        this.formField('用户名', this.fUser, (v: string) => { this.fUser = v; }, false)
        this.pwField()
        this.formField('备注', this.fNote, (v: string) => { this.fNote = v; }, false)
        Button('保存')
          .width('100%').height(50).borderRadius(15)
          .backgroundColor(this.accentColor).fontColor('#fff').fontSize(15).fontWeight(650)
          .margin({ top: 'auto' })
          .onClick(() => { this.submitForm(); })
      }
      .width('100%').flexGrow(1)
      .padding({ left: 20, right: 20, top: 16, bottom: 20 })
    }
    .width('100%').height('100%').backgroundColor(this.c('#0d0d12', '#FAF7F2'))
    .padding({ top: 44 })
    .position({ x: 0, y: 0 }).zIndex(500)
  }

  // 详情作为叠加层（而非替换分组列表），使分组列表不被卸载、返回时保留滚动位置
  @Builder
  detailView() {
    Column() {
      Row({ space: 8 }) {
        Text('‹ 返回').fontSize(14).fontColor(this.accentColor)
          .onClick(() => { this.openDomain = ''; this.revealId = ''; })
        Text(this.domainLabel(this.openDomain))
          .fontSize(16).fontWeight(700).fontColor(this.c('#eeeef5', '#2C1810')).flexGrow(1)
          .textAlign(TextAlign.Center)
        Text('+ 添加').fontSize(14).fontColor(this.accentColor)
          .onClick(() => { this.beginAdd(); })
      }
      .width('100%').padding({ left: 16, right: 16, top: 4, bottom: 8 }).alignItems(VerticalAlign.Center)

      List({ space: 10 }) {
        ForEach(this.currentEntries(), (e: PasswordEntry) => {
          ListItem() { this.entryCard(e) }
          .swipeAction({ end: () => { this.deleteAction(e) } })
        }, (e: PasswordEntry) => e.id + '_' + e.name + '_' + e.username + '_' + e.password)
        ListItem() { Column().height(96) }
      }
      .width('100%').flexGrow(1).padding({ left: 16, right: 16 }).scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor(this.c('#0d0d12', '#FAF7F2'))
    .padding({ top: 44 })
    .position({ x: 0, y: 0 }).zIndex(400)
  }

  build() {
    Stack() {
      Column() {
        // 顶部常驻搜索框 + 独立的清空 / 添加按钮
        Row({ space: 8 }) {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.magnifyingglass'))
              .fontColor([this.c('rgba(238,238,245,0.55)', '#5C4F43')]).fontSize(18)
            TextInput({ text: $$this.query, placeholder: '搜索域名、站点或用户名' })
              .flexGrow(1).backgroundColor(Color.Transparent)
              .fontColor(this.c('#eeeef5', '#2C1810'))
              .placeholderColor(this.c('rgba(238,238,245,0.55)', '#6B5B50'))
              .fontSize(13).height(28).padding(0)
              .onChange((v: string) => { this.query = v; })
            if (this.query.length > 0) {
              Text('×').fontSize(18).fontColor(this.c('rgba(238,238,245,0.55)', '#5C4F43'))
                .width(24).height(24).textAlign(TextAlign.Center)
                .onClick(() => { this.query = ''; })
            }
          }
          .layoutWeight(1)
          .height(36).padding({ left: 16, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(10)
          .border({ width: 1, color: this.accentColor + '55' })
          .alignItems(VerticalAlign.Center)

          if (this.openDomain === '') {
            Button({ type: ButtonType.Normal }) {
              Image($r('app.media.icon_add'))
                .width(20).height(20).fillColor(this.accentColor)
            }
            .width(36).height(36).borderRadius(10)
            .backgroundColor(this.c('rgba(255,255,255,0.06)', 'rgba(0,0,0,0.04)'))
            .onClick(() => { this.beginAdd(); })
          }
        }
        .margin({ left: 16, right: 16, top: 8, bottom: 8 })
        .alignItems(VerticalAlign.Center)

        if (this.query.trim() !== '') {
          // 全局扁平搜索结果
          List({ space: 10 }) {
            if (this.flatMatches().length === 0) {
              ListItem() {
                Column({ space: 12 }) {
                  Text('🔍').fontSize(36)
                  Text('未找到匹配的密码').fontSize(14)
                    .fontColor(this.c('rgba(238,238,245,0.60)', '#6B5B50'))
                }
                .width('100%').padding({ top: 70, bottom: 70 }).justifyContent(FlexAlign.Center)
              }
            }
            ForEach(this.flatMatches(), (e: PasswordEntry) => {
              ListItem() { this.entryCard(e) }
              .swipeAction({ end: () => { this.deleteAction(e) } })
            }, (e: PasswordEntry) => e.id + '_' + e.name + '_' + e.username + '_' + e.password)
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
                  Text('暂无密码\n点上方 + 添加，或在设置里导入')
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
            }, (g: PasswordGroup) => g.domain + '_' + g.entries.length)
            ListItem() { Column().height(96) }
          }
          .width('100%').flexGrow(1).padding({ left: 16, right: 16 }).scrollBar(BarState.Off)
        }
      }
      .width('100%').height('100%')
      .backgroundColor(this.c('#0d0d12', '#FAF7F2'))

      if (this.openDomain !== '') { this.detailView() }

      if (this.formOpen) { this.formOverlay() }

      if (this.toastShow) {
        Text(this.toastMsg)
          .fontSize(13).fontColor('#f0f0f5')
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .backgroundColor('rgba(22,22,30,0.96)').borderRadius(20)
          .position({ x: '50%', y: '90%' }).translate({ x: '-50%', y: 0 })
          .zIndex(600)
      }
    }
    .width('100%').height('100%')
  }
}
