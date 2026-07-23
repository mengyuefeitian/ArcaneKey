# HarmonyOS 双主题·我的重构·关于我们·Logo替换 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为鸿蒙 app 实现浅色/深色主题切换、重构我的页面、新增关于我们页面、替换全套 Logo 资源。

**Architecture:** 两套结构色系统（深色 Midnight Garden / 浅色 Warm Terracotta）通过 `isDark: boolean` prop 从 Index.ets 单向传递给所有子视图；每个视图用私有辅助方法 `c(dark, light)` 在 build() 中解析颜色。10 色主题（accent color）完全独立，不受影响。新增 `AboutView.ets` 以全屏覆盖层方式渲染，与 FeedbackView 同级。

**Tech Stack:** HarmonyOS 6.1 API 23 · ArkTS 严格模式 · `@kit.ArkData` · `@kit.BasicServicesKit` · `@kit.AbilityKit`

> **⚠️ ArkTS 关键规则**（全程遵守）
> - `build()` 方法内**不能**声明 `const`/`let` 变量，所有逻辑通过私有方法返回值在属性表达式中调用
> - `@State`/`@Prop` 字段必须有类型注释和初始值
> - 不允许匿名对象字面量类型用于装饰器字段
> - 每次改动后必须执行 build 验证；build 失败 = 任务未完成

---

## Build 命令（全程复用）

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey/harmonyos && \
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
--mode project -p product=default assembleApp --analyze=normal --parallel --incremental --daemon \
2>&1 | tail -30
```

成功标志：输出包含 `BUILD SUCCESSFUL`

---

## 文件清单

| 操作 | 路径 |
|------|------|
| **新建** | `harmonyos/entry/src/main/ets/model/ColorTokens.ets` |
| **新建** | `harmonyos/entry/src/main/ets/views/AboutView.ets` |
| **替换** | `harmonyos/AppScope/resources/base/media/app_icon.png` |
| **替换** | `harmonyos/entry/src/main/resources/base/media/icon.png` |
| **替换** | `harmonyos/entry/src/main/resources/base/media/logo_img.png` |
| **新增** | `harmonyos/entry/src/main/resources/base/media/foreground.png` |
| **新增** | `harmonyos/entry/src/main/resources/base/media/background.png` |
| **新增** | `harmonyos/entry/src/main/resources/base/media/layered_image.json` |
| **修改** | `harmonyos/entry/src/main/module.json5` |
| **修改** | `harmonyos/entry/src/main/ets/utils/StorageUtil.ets` |
| **修改** | `harmonyos/entry/src/main/ets/pages/Index.ets` |
| **修改** | `harmonyos/entry/src/main/ets/views/ProfileView.ets` |
| **修改** | `harmonyos/entry/src/main/ets/views/HomeView.ets` |
| **修改** | `harmonyos/entry/src/main/ets/views/ScanView.ets` |
| **修改** | `harmonyos/entry/src/main/ets/views/FeedbackView.ets` |

> 模态弹窗（loginModal、backupModal 等）保持深色不变，仅对主内容视图进行 token 化。

---

## Task 1: Logo 资源替换 + module.json5

**Files:**
- Replace: `harmonyos/AppScope/resources/base/media/app_icon.png`
- Replace: `harmonyos/entry/src/main/resources/base/media/icon.png`
- Replace: `harmonyos/entry/src/main/resources/base/media/logo_img.png`
- Create: `harmonyos/entry/src/main/resources/base/media/foreground.png`
- Create: `harmonyos/entry/src/main/resources/base/media/background.png`
- Create: `harmonyos/entry/src/main/resources/base/media/layered_image.json`
- Modify: `harmonyos/entry/src/main/module.json5`

- [ ] **Step 1.1: 复制图标资源文件**

```bash
SRC="/Users/xiaoan/Downloads/玄钥"
MEDIA="/Users/xiaoan/Documents/code/ArcaneKey/harmonyos/entry/src/main/resources/base/media"
APPSCOPE="/Users/xiaoan/Documents/code/ArcaneKey/harmonyos/AppScope/resources/base/media"

cp "$SRC/icon.png"                    "$APPSCOPE/app_icon.png"
cp "$SRC/icon.png"                    "$MEDIA/icon.png"
cp "$SRC/appgallery-icon-1024.png"    "$MEDIA/logo_img.png"
cp "$SRC/foreground.png"              "$MEDIA/foreground.png"
cp "$SRC/background.png"              "$MEDIA/background.png"
cp "$SRC/layered_image.json"          "$MEDIA/layered_image.json"
```

- [ ] **Step 1.2: 验证文件已复制**

```bash
ls -la /Users/xiaoan/Documents/code/ArcaneKey/harmonyos/entry/src/main/resources/base/media/
ls -la /Users/xiaoan/Documents/code/ArcaneKey/harmonyos/AppScope/resources/base/media/
```

预期：`foreground.png`、`background.png`、`layered_image.json` 出现在 media 目录；`app_icon.png` 更新。

- [ ] **Step 1.3: 更新 module.json5 中的图标引用**

文件：`harmonyos/entry/src/main/module.json5`

将：
```json5
"icon": "$media:icon",
"startWindowIcon": "$media:icon",
```

改为：
```json5
"icon": "$media:layered_image",
"startWindowIcon": "$media:icon",
```

（`startWindowIcon` 保持单层 PNG，只有启动器图标使用分层配置。）

- [ ] **Step 1.4: Build 验证**

运行上方 Build 命令。预期：`BUILD SUCCESSFUL`。如报错 `resource not found: layered_image`，将 `module.json5` 中的 `$media:layered_image` 回退为 `$media:icon`（分层配置问题不影响其他任务）。

- [ ] **Step 1.5: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/AppScope/resources/base/media/app_icon.png \
        harmonyos/entry/src/main/resources/base/media/icon.png \
        harmonyos/entry/src/main/resources/base/media/logo_img.png \
        harmonyos/entry/src/main/resources/base/media/foreground.png \
        harmonyos/entry/src/main/resources/base/media/background.png \
        harmonyos/entry/src/main/resources/base/media/layered_image.json \
        harmonyos/entry/src/main/module.json5
git commit -m "feat: 替换玄钥 logo 资源，配置自适应图标"
```

---

## Task 2: ColorTokens.ets — 颜色常量文件

**Files:**
- Create: `harmonyos/entry/src/main/ets/model/ColorTokens.ets`

- [ ] **Step 2.1: 创建 ColorTokens.ets**

新建文件 `harmonyos/entry/src/main/ets/model/ColorTokens.ets`，内容如下：

```typescript
// 深色调色板（Midnight Garden）
export const DARK_BG: string = '#0d0d12';
export const DARK_CARD: string = '#191920';
export const DARK_TX_P: string = '#eeeef5';
export const DARK_TX_S: string = 'rgba(238,238,245,0.55)';
export const DARK_TX_T: string = 'rgba(238,238,245,0.38)';
export const DARK_TX_D: string = 'rgba(238,238,245,0.2)';
export const DARK_DIV: string = 'rgba(255,255,255,0.05)';

// 浅色调色板（Warm Terracotta）
export const LIGHT_BG: string = '#FAF7F2';
export const LIGHT_CARD: string = '#FFFFFF';
export const LIGHT_TX_P: string = '#2C1810';
export const LIGHT_TX_S: string = '#5C4F43';
export const LIGHT_TX_T: string = '#8B7E74';
export const LIGHT_TX_D: string = '#A99E93';
export const LIGHT_DIV: string = '#E8E2D9';
```

> 各视图不直接引用这些常量；它们是文档化调色板，实际颜色通过各视图内的 `c(dark, light)` 辅助方法以内联方式传入。

- [ ] **Step 2.2: Build 验证**

运行 Build 命令。新文件无导入者，不影响构建，预期 `BUILD SUCCESSFUL`。

- [ ] **Step 2.3: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/ets/model/ColorTokens.ets
git commit -m "feat: 新增双主题颜色常量 ColorTokens"
```

---

## Task 3: StorageUtil.ets — 主题模式持久化

**Files:**
- Modify: `harmonyos/entry/src/main/ets/utils/StorageUtil.ets`

- [ ] **Step 3.1: 在 StorageUtil.ets 末尾追加两个函数**

在文件末尾（`saveLogin` 函数之后）追加：

```typescript
const DARK_MODE_KEY = 'ak_dark_mode';

export async function loadThemeMode(): Promise<boolean> {
  try {
    if (!pref) return true;
    const val = await pref.get(DARK_MODE_KEY, true);
    return typeof val === 'boolean' ? (val as boolean) : true;
  } catch (_) {
    return true;
  }
}

export async function saveThemeMode(isDark: boolean): Promise<void> {
  try {
    if (!pref) return;
    await pref.put(DARK_MODE_KEY, isDark);
    await pref.flush();
  } catch (_) {}
}
```

- [ ] **Step 3.2: Build 验证**

运行 Build 命令。预期 `BUILD SUCCESSFUL`。

- [ ] **Step 3.3: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/ets/utils/StorageUtil.ets
git commit -m "feat: StorageUtil 新增主题模式持久化函数"
```

---

## Task 4: ProfileView.ets — 完整重构

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/ProfileView.ets`

改动点：
1. 新增 `@Prop isDark: boolean = true`
2. 新增私有辅助方法 `c(dark, light)`
3. 新增回调 `onToggleMode` 和 `onAboutTap`
4. 删除顶部品牌区域（logo + 名称 + 简介）
5. 删除底部版本号文字
6. 所有结构色替换为 `this.c(...)` 调用
7. 新增"显示模式"菜单项（皮肤主题之后）
8. 新增"关于我们"菜单项（意见与建议之后，无 Divider）

- [ ] **Step 4.1: 用以下内容完整替换 ProfileView.ets**

```typescript
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

  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  build() {
    Scroll() {
      Column() {
        // Account / Login section (top)
        if (this.loggedIn) {
          Row({ space: 12 }) {
            if (this.userAvatar) {
              Image(this.userAvatar).width(40).height(40).borderRadius(12)
            } else {
              Stack() {
                Text(this.userName.length > 0 ? this.userName[0].toUpperCase() : 'U')
                  .fontSize(18).fontColor('#fff').fontWeight(700)
              }
              .width(40).height(40).borderRadius(12)
              .backgroundColor(this.accentColor)
            }
            Column({ space: 2 }) {
              Text(this.userName).fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(600)
              if (this.userPhone) {
                Text(this.userPhone).fontSize(12).fontColor(this.c('rgba(238,238,245,0.4)', '#8B7E74'))
              }
            }.alignItems(HorizontalAlign.Start).flexGrow(1)
          }
          .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(14)
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
                  .fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .border({ width: { left: this.isMember ? 3 : 0 }, color: { left: this.isMember ? this.accentColor : Color.Transparent } })
            .onClick(() => this.onMembershipTap())
            Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
          }
          // Account Management
          Column() {
            Row({ space: 0 }) {
              Stack() { Text('👤').fontSize(16) }
                .width(34).height(34).borderRadius(10)
                .backgroundColor(this.accentColor + '28')
                .margin({ right: 14 })
              Column({ space: 2 }) {
                Text('账号管理').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                Text(this.loggedIn ? '管理你的账号信息' : '登录后可用')
                  .fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .opacity(this.loggedIn ? 1 : 0.38)
            .onClick(() => {
              if (!this.loggedIn) this.onLoginTap();
              else this.onAccountTap();
            })
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
                  .fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .opacity(this.loggedIn ? 1 : 0.38)
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
                  .fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .opacity(this.loggedIn ? 1 : 0.38)
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
                Text(this.themeName).fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
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
                Text(this.isDark ? '深色' : '浅色').fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
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
                Text('向我们反馈问题或建议').fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
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
                Text('版本号·法律·联系方式').fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
              }.alignItems(HorizontalAlign.Start).flexGrow(1)
              Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .onClick(() => this.onAboutTap())
          }
        }
        .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(18)
        .border({ width: 1, color: this.c('rgba(255,255,255,0.05)', '#E8E2D9') })

        if (this.loggedIn) {
          Button('退出登录')
            .width('100%').backgroundColor(Color.Transparent)
            .border({ width: 1, color: this.c('rgba(255,255,255,0.08)', '#E8E2D9') })
            .borderRadius(14).fontColor(this.c('rgba(238,238,245,0.45)', '#5C4F43')).fontSize(14)
            .margin({ top: 16 })
            .onClick(() => this.onLogout())
        }

        Column().height(100)
      }
      .padding({ left: 20, right: 20, top: 16 })
    }
    .scrollBar(BarState.Off).width('100%').height('100%').backgroundColor(this.c('#0d0d12', '#FAF7F2'))
  }
}
```

- [ ] **Step 4.2: Build 验证**

运行 Build 命令。预期 `BUILD SUCCESSFUL`。如报 `isDark` 未传入错误，忽略（下一个任务 Index.ets 会传入，有默认值不影响编译）。

- [ ] **Step 4.3: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/ets/views/ProfileView.ets
git commit -m "feat: 重构我的页面，移除品牌区域，新增显示模式和关于我们入口"
```

---

## Task 5: AboutView.ets — 新文件

**Files:**
- Create: `harmonyos/entry/src/main/ets/views/AboutView.ets`

- [ ] **Step 5.1: 创建 AboutView.ets**

新建文件内容如下（完整文件）：

```typescript
import { common, Want } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';

const AGREEMENT_TEXT: string = '用户协议\n\n欢迎使用玄钥（ArcaneKey）身份验证器。\n\n一、服务说明\n本软件由小安工作室提供，仅供个人非商业用途使用。使用本软件即表示您同意本协议的所有条款。\n\n二、数据安全\n您的 TOTP 验证码密钥仅存储在您的本地设备中，不会在未经授权的情况下上传至服务器。开通会员后，您可选择将加密备份上传至云端，密钥经过本地加密后再传输，我们无法获取您的明文密钥。\n\n三、免责声明\n本软件按现状提供，不作任何明示或暗示的保证。对于因使用本软件导致的任何直接或间接损失，本工作室不承担法律责任。\n\n四、协议变更\n本协议如有修改，将通过应用更新方式通知用户。继续使用即视为接受最新协议。\n\n如有疑问，请联系：mengyuefeitian@live.cn';

const PRIVACY_TEXT: string = '隐私政策\n\n玄钥（ArcaneKey）尊重并保护用户的个人隐私权。\n\n一、信息收集\n本应用收集的信息：\n· 设备账号信息（用于会员校验，仅本地存储）\n· 您主动提交的反馈内容（通过邮件发送）\n\n本应用不收集：\n· 您的 TOTP 密钥或验证码\n· 您的位置信息\n· 浏览行为或使用统计数据\n\n二、信息使用\n收集的信息仅用于提供应用核心功能，不会出售、出租或分享给第三方。\n\n三、数据存储\n所有 TOTP 密钥存储在设备本地 Preferences 中。云备份数据经过 XOR 加密处理后存储。\n\n如您对隐私保护有任何疑问，请发送邮件至：mengyuefeitian@live.cn';

@Component
export struct AboutView {
  @Prop accentColor: string = '#4080D0';
  @Prop isDark: boolean = true;
  @State showAgreement: boolean = false;
  @State showPrivacy: boolean = false;
  @State emailCopied: boolean = false;
  onClose: () => void = () => {};

  private c(dark: string, light: string): string { return this.isDark ? dark : light; }

  private async openUrl(url: string): Promise<void> {
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('context');
      if (!ctx) return;
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: url,
      };
      await ctx.startAbility(want);
    } catch (_) {}
  }

  private async copyEmail(): Promise<void> {
    try {
      const pb = pasteboard.getSystemPasteboard();
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, 'mengyuefeitian@live.cn');
      await pb.setData(data);
      this.emailCopied = true;
      setTimeout(() => { this.emailCopied = false; }, 2000);
    } catch (_) {}
  }

  build() {
    Stack() {
      // Main about page
      Column() {
        Row({ space: 12 }) {
          Button({ type: ButtonType.Normal }) {
            Text('×').fontSize(20).fontColor(this.c('rgba(238,238,245,0.75)', '#5C4F43'))
          }
          .backgroundColor(this.c('rgba(255,255,255,0.08)', 'rgba(0,0,0,0.06)')).borderRadius(11)
          .width(36).height(36)
          .onClick(this.onClose)
          Text('关于我们').fontSize(17).fontWeight(650).fontColor(this.c('#eeeef5', '#2C1810'))
        }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 8 })

        Scroll() {
          Column({ space: 24 }) {
            // Brand block
            Column({ space: 10 }) {
              Image($r('app.media.logo_img'))
                .width(72).height(72).borderRadius(20)
                .shadow({ radius: 24, color: this.accentColor + '55', offsetX: 0, offsetY: 6 })
              Text('玄钥')
                .fontSize(22).fontWeight(800).fontColor(this.c('#eeeef5', '#2C1810')).letterSpacing(-0.5)
              Text('身份验证器 · 守护你的数字安全')
                .fontSize(13).fontColor(this.c('rgba(238,238,245,0.4)', '#8B7E74'))
            }.width('100%').alignItems(HorizontalAlign.Center).padding({ top: 16, bottom: 8 })

            // Info list
            Column() {
              // 用户协议
              Column() {
                Row({ space: 0 }) {
                  Stack() { Text('📄').fontSize(16) }
                    .width(34).height(34).borderRadius(10)
                    .backgroundColor(this.accentColor + '28').margin({ right: 14 })
                  Column({ space: 2 }) {
                    Text('用户协议').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                    Text('查看服务条款').fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
                }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => { this.showAgreement = true; })
                Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
              }
              // 隐私政策
              Column() {
                Row({ space: 0 }) {
                  Stack() { Text('🔒').fontSize(16) }
                    .width(34).height(34).borderRadius(10)
                    .backgroundColor(this.accentColor + '28').margin({ right: 14 })
                  Column({ space: 2 }) {
                    Text('隐私政策').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                    Text('了解数据保护').fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
                }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => { this.showPrivacy = true; })
                Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
              }
              // 邮箱
              Column() {
                Row({ space: 0 }) {
                  Stack() { Text('📧').fontSize(16) }
                    .width(34).height(34).borderRadius(10)
                    .backgroundColor(this.accentColor + '28').margin({ right: 14 })
                  Column({ space: 2 }) {
                    Text('邮箱').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                    Text('mengyuefeitian@live.cn').fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text(this.emailCopied ? '已复制 ✓' : '复制')
                    .fontSize(12).fontColor(this.emailCopied ? this.c('rgba(238,238,245,0.38)', '#8B7E74') : this.accentColor)
                }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => { this.copyEmail(); })
                Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
              }
              // 官网
              Column() {
                Row({ space: 0 }) {
                  Stack() { Text('🌐').fontSize(16) }
                    .width(34).height(34).borderRadius(10)
                    .backgroundColor(this.accentColor + '28').margin({ right: 14 })
                  Column({ space: 2 }) {
                    Text('官网').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                    Text('www.xiaoanhome.xyz').fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
                }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => { this.openUrl('https://www.xiaoanhome.xyz'); })
                Divider().color(this.c('rgba(255,255,255,0.05)', '#E8E2D9')).strokeWidth(1).margin({ left: 16, right: 16 })
              }
              // 备案
              Column() {
                Row({ space: 0 }) {
                  Stack() { Text('🏛️').fontSize(16) }
                    .width(34).height(34).borderRadius(10)
                    .backgroundColor(this.accentColor + '28').margin({ right: 14 })
                  Column({ space: 2 }) {
                    Text('备案').fontSize(15).fontColor(this.c('#eeeef5', '#2C1810')).fontWeight(520)
                    Text('京ICP备2026021298号-3A').fontSize(12).fontColor(this.c('rgba(238,238,245,0.38)', '#8B7E74'))
                  }.alignItems(HorizontalAlign.Start).flexGrow(1)
                  Text('›').fontSize(18).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
                }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => { this.openUrl('https://beian.miit.gov.cn/'); })
              }
            }
            .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(18)
            .border({ width: 1, color: this.c('rgba(255,255,255,0.05)', '#E8E2D9') })

            Text('玄钥 v1.0.0')
              .fontSize(12).fontColor(this.c('rgba(238,238,245,0.2)', '#A99E93'))
              .width('100%').textAlign(TextAlign.Center)
              .padding({ top: 8, bottom: 100 })
          }
          .padding({ left: 20, right: 20, top: 8 })
        }.scrollBar(BarState.Off).flexGrow(1)
      }
      .width('100%').height('100%')
      .backgroundColor(this.c('#0d0d12', '#FAF7F2'))
      .padding({ top: 44 })

      // Legal detail overlay (covers main content)
      if (this.showAgreement || this.showPrivacy) {
        Column() {
          Row({ space: 12 }) {
            Button({ type: ButtonType.Normal }) {
              Text('←').fontSize(18).fontColor(this.c('rgba(238,238,245,0.75)', '#5C4F43'))
            }
            .backgroundColor(this.c('rgba(255,255,255,0.08)', 'rgba(0,0,0,0.06)')).borderRadius(11)
            .width(36).height(36)
            .onClick(() => { this.showAgreement = false; this.showPrivacy = false; })
            Text(this.showAgreement ? '用户协议' : '隐私政策')
              .fontSize(17).fontWeight(650).fontColor(this.c('#eeeef5', '#2C1810'))
          }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 8 })

          Scroll() {
            Column() {
              Text(this.showAgreement ? AGREEMENT_TEXT : PRIVACY_TEXT)
                .fontSize(14)
                .fontColor(this.c('#eeeef5', '#2C1810'))
                .lineHeight(26)
                .width('100%')
            }.padding({ left: 20, right: 20, top: 8, bottom: 40 })
          }.scrollBar(BarState.Off).flexGrow(1)
        }
        .width('100%').height('100%')
        .backgroundColor(this.c('#0d0d12', '#FAF7F2'))
        .padding({ top: 44 })
      }
    }
    .width('100%').height('100%')
  }
}
```

- [ ] **Step 5.2: Build 验证**

运行 Build 命令。预期 `BUILD SUCCESSFUL`。Index.ets 尚未 import AboutView，不影响编译。

- [ ] **Step 5.3: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/ets/views/AboutView.ets
git commit -m "feat: 新增关于我们页面（用户协议、隐私政策、邮箱、官网、备案）"
```

---

## Task 6: Index.ets — 状态扩展 + 全局连线

**Files:**
- Modify: `harmonyos/entry/src/main/ets/pages/Index.ets`

- [ ] **Step 6.1: 添加 import**

**添加 AboutView import**：找到：
```typescript
import { FeedbackView } from '../views/FeedbackView';
```
在其后添加：
```typescript
import { AboutView } from '../views/AboutView';
```

**扩展现有 StorageUtil import**：找到（文件顶部已有的 StorageUtil 导入行）：
```typescript
import { initPreferences, loadTokens, saveTokens, loadTheme, saveTheme, loadMember, saveMember, MemberData, loadLogin, saveLogin, LoginData } from '../utils/StorageUtil';
```
替换为：
```typescript
import { initPreferences, loadTokens, saveTokens, loadTheme, saveTheme, loadMember, saveMember, MemberData, loadLogin, saveLogin, LoginData, loadThemeMode, saveThemeMode } from '../utils/StorageUtil';
```

- [ ] **Step 6.2: 添加 @State 字段**

找到：
```typescript
  @State navSafeBottom: number = 34;
```

在其后添加：
```typescript
  @State isDark: boolean = true;
  @State showAbout: boolean = false;
```

- [ ] **Step 6.3: 在 loadData() 中加载主题模式**

找到（在 loadData() 中）：
```typescript
      const theme = await loadTheme();
      if (theme) { this.accentColor = theme.color; this.currentTheme = theme; }
```

在其后追加：
```typescript
      this.isDark = await loadThemeMode();
```

- [ ] **Step 6.4: 为 ProfileView 添加新 props 和回调**

找到（build() 中 ProfileView 实例化内）：
```typescript
            onFeedbackTap: () => { this.showFeedback = true; },
```

在其后追加（ProfileView 的结束括号前）：
```typescript
            onToggleMode: () => {
              this.isDark = !this.isDark;
              saveThemeMode(this.isDark);
            },
            onAboutTap: () => { this.showAbout = true; },
            isDark: this.isDark,
```

- [ ] **Step 6.5: 为 HomeView 添加 isDark prop**

找到：
```typescript
            accentColor: this.accentColor,
            searching: $searching,
```

在 `accentColor` 行后追加：
```typescript
            isDark: this.isDark,
```

- [ ] **Step 6.6: 为 ScanView 添加 isDark prop**

找到：
```typescript
          ScanView({
            accentColor: this.accentColor,
            navBottomPad: 60 + this.navSafeBottom + 16,
```

在 `accentColor` 行后追加：
```typescript
            isDark: this.isDark,
```

- [ ] **Step 6.7: 为 FeedbackView 添加 isDark prop**

找到：
```typescript
        FeedbackView({
          accentColor: this.accentColor,
          onClose: () => { this.showFeedback = false; }
```

在 `accentColor` 行后追加：
```typescript
          isDark: this.isDark,
```

- [ ] **Step 6.8: 添加 AboutView 覆盖层**

找到（build() 末尾，FeedbackView 条件块之后）：
```typescript
      if (this.showFeedback) {
        FeedbackView({
          accentColor: this.accentColor,
          isDark: this.isDark,
          onClose: () => { this.showFeedback = false; }
        })
      }
```

在其后添加：
```typescript
      if (this.showAbout) {
        AboutView({
          accentColor: this.accentColor,
          isDark: this.isDark,
          onClose: () => { this.showAbout = false; }
        })
      }
```

- [ ] **Step 6.9: Build 验证**

运行 Build 命令。预期 `BUILD SUCCESSFUL`。此时 `isDark` 已全局连线，ProfileView 和 AboutView 均可响应切换。

- [ ] **Step 6.10: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/ets/pages/Index.ets
git commit -m "feat: Index.ets 连线双主题状态，传递 isDark 至所有子视图"
```

---

## Task 7: HomeView.ets — 颜色 Token 化

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/HomeView.ets`

- [ ] **Step 7.1: 添加 @Prop isDark 和辅助方法**

找到（`@Prop accentColor` 行后）：
```typescript
  @Prop accentColor: string = '#4080D0';
  @Link searching: boolean;
```

在两者之间插入：
```typescript
  @Prop isDark: boolean = true;
```

在 `private lastScrollY: number = 0;` 之后，`@Builder` 之前，添加私有方法：
```typescript
  private c(dark: string, light: string): string { return this.isDark ? dark : light; }
```

- [ ] **Step 7.2: 替换搜索栏颜色**

找到：
```typescript
        .backgroundColor('#191920')
        .borderRadius(10)
        .border({ width: 1, color: this.accentColor + '55' })
```

替换为：
```typescript
        .backgroundColor(this.c('#191920', '#FFFFFF'))
        .borderRadius(10)
        .border({ width: 1, color: this.accentColor + '55' })
```

找到（搜索栏内文字颜色）：
```typescript
            .fontColor('rgba(238,238,245,0.55)')
            .width(28).height(28)
```

替换为：
```typescript
            .fontColor(this.c('rgba(238,238,245,0.55)', '#5C4F43'))
            .width(28).height(28)
```

找到（SymbolGlyph 颜色）：
```typescript
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontColor(['rgba(238,238,245,0.55)'])
```

替换为：
```typescript
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontColor([this.c('rgba(238,238,245,0.55)', '#5C4F43')])
```

找到（TextInput 颜色）：
```typescript
            .fontColor('#eeeef5')
            .placeholderColor('rgba(238,238,245,0.25)')
```

替换为：
```typescript
            .fontColor(this.c('#eeeef5', '#2C1810'))
            .placeholderColor(this.c('rgba(238,238,245,0.25)', '#A99E93'))
```

找到（清除按钮颜色）：
```typescript
              .fontColor('rgba(238,238,245,0.5)')
```

替换为：
```typescript
              .fontColor(this.c('rgba(238,238,245,0.5)', '#5C4F43'))
```

- [ ] **Step 7.3: 替换空状态文字颜色**

找到：
```typescript
              Text(this.searchQ ? '未找到匹配账号' : '暂无验证码\n点击下方扫码添加')
                .fontSize(14).fontColor('rgba(238,238,245,0.25)').textAlign(TextAlign.Center)
```

替换为：
```typescript
              Text(this.searchQ ? '未找到匹配账号' : '暂无验证码\n点击下方扫码添加')
                .fontSize(14).fontColor(this.c('rgba(238,238,245,0.25)', '#A99E93')).textAlign(TextAlign.Center)
```

- [ ] **Step 7.4: 替换根 Column 背景色**

找到（build() 末尾）：
```typescript
    .width('100%')
    .height('100%')
    .backgroundColor('#0d0d12')
```

替换为：
```typescript
    .width('100%')
    .height('100%')
    .backgroundColor(this.c('#0d0d12', '#FAF7F2'))
```

- [ ] **Step 7.5: Build 验证**

运行 Build 命令。预期 `BUILD SUCCESSFUL`。

- [ ] **Step 7.6: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/ets/views/HomeView.ets
git commit -m "feat: HomeView 支持浅色/深色主题"
```

---

## Task 8: ScanView.ets — 颜色 Token 化

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/ScanView.ets`

> 注意：相机占位背景 `backgroundColor('#000')` 和扫描帧角落保持原样，这些是功能性深色，不随主题变化。

- [ ] **Step 8.1: 添加 @Prop isDark 和辅助方法**

找到：
```typescript
  @Prop accentColor: string = '#4080D0';
  @Prop navBottomPad: number = 110;
```

在两者之间插入：
```typescript
  @Prop isDark: boolean = true;
```

在 `@State scanning` 字段声明块结束后，`aboutToAppear()` 前，添加：
```typescript
  private c(dark: string, light: string): string { return this.isDark ? dark : light; }
```

- [ ] **Step 8.2: 替换 Header 文字颜色**

找到：
```typescript
          Text('×').fontSize(20).fontColor('rgba(238,238,245,0.75)')
```

替换为：
```typescript
          Text('×').fontSize(20).fontColor(this.c('rgba(238,238,245,0.75)', '#5C4F43'))
```

找到：
```typescript
        Text('添加账号').fontSize(17).fontWeight(650).fontColor('#eeeef5')
```

替换为：
```typescript
        Text('添加账号').fontSize(17).fontWeight(650).fontColor(this.c('#eeeef5', '#2C1810'))
```

找到（× 按钮背景）：
```typescript
        .backgroundColor('rgba(255,255,255,0.08)').borderRadius(11)
```

替换为：
```typescript
        .backgroundColor(this.c('rgba(255,255,255,0.08)', 'rgba(0,0,0,0.06)')).borderRadius(11)
```

- [ ] **Step 8.3: 替换 Tabs 容器背景**

找到：
```typescript
      .margin({ left: 16, right: 16, top: 14 })
      .padding(4).backgroundColor('#191920').borderRadius(13)
```

替换为：
```typescript
      .margin({ left: 16, right: 16, top: 14 })
      .padding(4).backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(13)
```

找到（tab 未选中文字颜色）：
```typescript
            .fontColor(this.tab === idx ? '#fff' : 'rgba(238,238,245,0.45)')
```

替换为：
```typescript
            .fontColor(this.tab === idx ? '#fff' : this.c('rgba(238,238,245,0.45)', '#8B7E74'))
```

- [ ] **Step 8.4: 替换相册 Tab 图标背景和文字**

找到：
```typescript
          Text('🖼️').fontSize(38)
            .width(88).height(88).textAlign(TextAlign.Center)
            .backgroundColor('#191920').borderRadius(24)
            .border({ width: 1, color: 'rgba(255,255,255,0.07)' })
          Text('从相册中选择含二维码的图片\n自动识别并添加账号')
            .fontSize(14).fontColor('rgba(238,238,245,0.5)').textAlign(TextAlign.Center)
```

替换为：
```typescript
          Text('🖼️').fontSize(38)
            .width(88).height(88).textAlign(TextAlign.Center)
            .backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(24)
            .border({ width: 1, color: this.c('rgba(255,255,255,0.07)', '#E8E2D9') })
          Text('从相册中选择含二维码的图片\n自动识别并添加账号')
            .fontSize(14).fontColor(this.c('rgba(238,238,245,0.5)', '#5C4F43')).textAlign(TextAlign.Center)
```

- [ ] **Step 8.5: 替换手动输入 Tab 中的 TextInput 背景和标签颜色**

找到（品牌名称标签）：
```typescript
              Text('品牌名称').fontSize(12).fontColor('rgba(238,238,245,0.45)').fontWeight(500)
```

替换为：
```typescript
              Text('品牌名称').fontSize(12).fontColor(this.c('rgba(238,238,245,0.45)', '#8B7E74')).fontWeight(500)
```

找到（品牌 TextInput）：
```typescript
                .backgroundColor('#191920').fontColor('#eeeef5')
                .border({ width: 1, color: this.brandErr ? '#f87171' : 'rgba(255,255,255,0.08)' })
                .borderRadius(12).placeholderColor('rgba(238,238,245,0.25)')
```

替换为：
```typescript
                .backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
                .border({ width: 1, color: this.brandErr ? '#f87171' : this.c('rgba(255,255,255,0.08)', '#E8E2D9') })
                .borderRadius(12).placeholderColor(this.c('rgba(238,238,245,0.25)', '#A99E93'))
```

找到（账号标签）：
```typescript
              Text('账号信息').fontSize(12).fontColor('rgba(238,238,245,0.45)').fontWeight(500)
```

替换为：
```typescript
              Text('账号信息').fontSize(12).fontColor(this.c('rgba(238,238,245,0.45)', '#8B7E74')).fontWeight(500)
```

找到（账号 TextInput）：
```typescript
                .backgroundColor('#191920').fontColor('#eeeef5')
                .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
                .borderRadius(12).placeholderColor('rgba(238,238,245,0.25)')
                .height(44).padding({ left: 14, right: 14 })
            }.alignItems(HorizontalAlign.Start).width('100%')

            Column({ space: 6 }) {
              Row({ space: 4 }) {
                Text('Secret Key').fontSize(12).fontColor('rgba(238,238,245,0.45)').fontWeight(500)
```

替换为：
```typescript
                .backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
                .border({ width: 1, color: this.c('rgba(255,255,255,0.08)', '#E8E2D9') })
                .borderRadius(12).placeholderColor(this.c('rgba(238,238,245,0.25)', '#A99E93'))
                .height(44).padding({ left: 14, right: 14 })
            }.alignItems(HorizontalAlign.Start).width('100%')

            Column({ space: 6 }) {
              Row({ space: 4 }) {
                Text('Secret Key').fontSize(12).fontColor(this.c('rgba(238,238,245,0.45)', '#8B7E74')).fontWeight(500)
```

找到（Secret TextInput）：
```typescript
                .backgroundColor('#191920').fontColor('#eeeef5').fontFamily('monospace')
                .border({ width: 1, color: this.secretErr ? '#f87171' : 'rgba(255,255,255,0.08)' })
                .borderRadius(12).placeholderColor('rgba(238,238,245,0.25)')
```

替换为：
```typescript
                .backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810')).fontFamily('monospace')
                .border({ width: 1, color: this.secretErr ? '#f87171' : this.c('rgba(255,255,255,0.08)', '#E8E2D9') })
                .borderRadius(12).placeholderColor(this.c('rgba(238,238,245,0.25)', '#A99E93'))
```

找到（预览卡片）：
```typescript
              .padding(12).backgroundColor('#191920').borderRadius(12)
              .border({ width: 1, color: 'rgba(255,255,255,0.06)' }).width('100%')
```

替换为：
```typescript
              .padding(12).backgroundColor(this.c('#191920', '#FFFFFF')).borderRadius(12)
              .border({ width: 1, color: this.c('rgba(255,255,255,0.06)', '#E8E2D9') }).width('100%')
```

找到（预览卡片内账号文字）：
```typescript
                  if (this.account) { Text(this.account).fontSize(12).fontColor('rgba(238,238,245,0.4)') }
```

替换为：
```typescript
                  if (this.account) { Text(this.account).fontSize(12).fontColor(this.c('rgba(238,238,245,0.4)', '#8B7E74')) }
```

找到（预览文字）：
```typescript
                Text('预览').fontSize(11).fontColor('rgba(238,238,245,0.3)')
```

替换为：
```typescript
                Text('预览').fontSize(11).fontColor(this.c('rgba(238,238,245,0.3)', '#A99E93'))
```

找到（扫码提示文字）：
```typescript
          Text(this.scanning ? '正在识别二维码…' : '点击下方按钮扫描二维码')
            .fontSize(13).fontColor('rgba(238,238,245,0.4)').textAlign(TextAlign.Center)
```

替换为：
```typescript
          Text(this.scanning ? '正在识别二维码…' : '点击下方按钮扫描二维码')
            .fontSize(13).fontColor(this.c('rgba(238,238,245,0.4)', '#8B7E74')).textAlign(TextAlign.Center)
```

- [ ] **Step 8.6: 替换根 Column 背景色**

找到（build() 末尾）：
```typescript
    .width('100%').height('100%').backgroundColor('#0d0d12')
```

替换为：
```typescript
    .width('100%').height('100%').backgroundColor(this.c('#0d0d12', '#FAF7F2'))
```

- [ ] **Step 8.7: Build 验证**

运行 Build 命令。预期 `BUILD SUCCESSFUL`。

- [ ] **Step 8.8: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/ets/views/ScanView.ets
git commit -m "feat: ScanView 支持浅色/深色主题"
```

---

## Task 9: FeedbackView.ets — 颜色 Token 化

**Files:**
- Modify: `harmonyos/entry/src/main/ets/views/FeedbackView.ets`

- [ ] **Step 9.1: 添加 @Prop isDark 和辅助方法**

找到：
```typescript
  @Prop accentColor: string = '#4080D0';
  @State type: string = '需求';
```

在两者之间插入：
```typescript
  @Prop isDark: boolean = true;
```

在 `onClose: () => void = () => {};` 行之后添加：
```typescript
  private c(dark: string, light: string): string { return this.isDark ? dark : light; }
```

- [ ] **Step 9.2: 替换 Header 颜色**

找到：
```typescript
          Text('×').fontSize(20).fontColor('rgba(238,238,245,0.75)')
```

替换为：
```typescript
          Text('×').fontSize(20).fontColor(this.c('rgba(238,238,245,0.75)', '#5C4F43'))
```

找到（× 按钮背景）：
```typescript
        .backgroundColor('rgba(255,255,255,0.08)').borderRadius(11).width(36).height(36)
```

替换为：
```typescript
        .backgroundColor(this.c('rgba(255,255,255,0.08)', 'rgba(0,0,0,0.06)')).borderRadius(11).width(36).height(36)
```

找到：
```typescript
        Text('意见与建议').fontSize(17).fontWeight(650).fontColor('#eeeef5')
```

替换为：
```typescript
        Text('意见与建议').fontSize(17).fontWeight(650).fontColor(this.c('#eeeef5', '#2C1810'))
```

- [ ] **Step 9.3: 替换反馈类型区域颜色**

找到（标签文字）：
```typescript
          Text('反馈类型').fontSize(12).fontColor('rgba(238,238,245,0.45)')
```

替换为：
```typescript
          Text('反馈类型').fontSize(12).fontColor(this.c('rgba(238,238,245,0.45)', '#8B7E74'))
```

找到（未选中 tab 按钮背景/颜色，两处格式相同）：
```typescript
              .backgroundColor(this.type === '需求' ? this.accentColor + '18' : Color.Transparent)
              .border({ width: 1, color: this.type === '需求' ? this.accentColor + '60' : 'rgba(255,255,255,0.08)' })
              .borderRadius(12).fontColor(this.type === '需求' ? this.accentColor : 'rgba(238,238,245,0.5)')
```

替换为：
```typescript
              .backgroundColor(this.type === '需求' ? this.accentColor + '18' : Color.Transparent)
              .border({ width: 1, color: this.type === '需求' ? this.accentColor + '60' : this.c('rgba(255,255,255,0.08)', '#E8E2D9') })
              .borderRadius(12).fontColor(this.type === '需求' ? this.accentColor : this.c('rgba(238,238,245,0.5)', '#5C4F43'))
```

同理替换 `'Bug'` 按钮的对应行：
```typescript
              .backgroundColor(this.type === 'Bug' ? this.accentColor + '18' : Color.Transparent)
              .border({ width: 1, color: this.type === 'Bug' ? this.accentColor + '60' : 'rgba(255,255,255,0.08)' })
              .borderRadius(12).fontColor(this.type === 'Bug' ? this.accentColor : 'rgba(238,238,245,0.5)')
```

替换为：
```typescript
              .backgroundColor(this.type === 'Bug' ? this.accentColor + '18' : Color.Transparent)
              .border({ width: 1, color: this.type === 'Bug' ? this.accentColor + '60' : this.c('rgba(255,255,255,0.08)', '#E8E2D9') })
              .borderRadius(12).fontColor(this.type === 'Bug' ? this.accentColor : this.c('rgba(238,238,245,0.5)', '#5C4F43'))
```

- [ ] **Step 9.4: 替换 TextArea 和 TextInput 颜色**

找到（反馈内容标签）：
```typescript
          Text('反馈内容 *').fontSize(12).fontColor('rgba(238,238,245,0.45)')
```

替换为：
```typescript
          Text('反馈内容 *').fontSize(12).fontColor(this.c('rgba(238,238,245,0.45)', '#8B7E74'))
```

找到（TextArea）：
```typescript
            .height(140).backgroundColor('#191920').fontColor('#eeeef5')
            .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
            .fontSize(14).placeholderColor('rgba(238,238,245,0.25)')
```

替换为：
```typescript
            .height(140).backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
            .border({ width: 1, color: this.c('rgba(255,255,255,0.08)', '#E8E2D9') }).borderRadius(12)
            .fontSize(14).placeholderColor(this.c('rgba(238,238,245,0.25)', '#A99E93'))
```

找到（字数显示）：
```typescript
          Text(`${this.content.length}/500`)
            .fontSize(11).fontColor(this.content.length > 500 ? '#f87171' : 'rgba(238,238,245,0.25)')
```

替换为：
```typescript
          Text(`${this.content.length}/500`)
            .fontSize(11).fontColor(this.content.length > 500 ? '#f87171' : this.c('rgba(238,238,245,0.25)', '#A99E93'))
```

找到（联系方式标签）：
```typescript
          Text('联系方式（选填，手机号或邮箱）').fontSize(12).fontColor('rgba(238,238,245,0.45)')
```

替换为：
```typescript
          Text('联系方式（选填，手机号或邮箱）').fontSize(12).fontColor(this.c('rgba(238,238,245,0.45)', '#8B7E74'))
```

找到（联系方式 TextInput）：
```typescript
            .backgroundColor('#191920').fontColor('#eeeef5')
            .border({ width: 1, color: 'rgba(255,255,255,0.08)' }).borderRadius(12)
```

替换为：
```typescript
            .backgroundColor(this.c('#191920', '#FFFFFF')).fontColor(this.c('#eeeef5', '#2C1810'))
            .border({ width: 1, color: this.c('rgba(255,255,255,0.08)', '#E8E2D9') }).borderRadius(12)
```

找到（提交按钮禁用背景色）：
```typescript
            .backgroundColor(this.canSubmit ? this.accentColor : '#191920')
            .fontColor(this.canSubmit ? '#fff' : 'rgba(238,238,245,0.3)')
```

替换为：
```typescript
            .backgroundColor(this.canSubmit ? this.accentColor : this.c('#191920', '#F5F0EA'))
            .fontColor(this.canSubmit ? '#fff' : this.c('rgba(238,238,245,0.3)', '#A99E93'))
```

找到（底部说明文字）：
```typescript
          Text('您的反馈将发送至开发团队，我们认真对待每一条建议')
            .fontSize(11).fontColor('rgba(238,238,245,0.2)').textAlign(TextAlign.Center)
```

替换为：
```typescript
          Text('您的反馈将发送至开发团队，我们认真对待每一条建议')
            .fontSize(11).fontColor(this.c('rgba(238,238,245,0.2)', '#A99E93')).textAlign(TextAlign.Center)
```

- [ ] **Step 9.5: 替换根 Column 背景色**

找到（build() 末尾）：
```typescript
    .width('100%').height('100%').backgroundColor('#0d0d12')
```

替换为：
```typescript
    .width('100%').height('100%').backgroundColor(this.c('#0d0d12', '#FAF7F2'))
```

- [ ] **Step 9.6: Build 验证**

运行 Build 命令。预期 `BUILD SUCCESSFUL`。

- [ ] **Step 9.7: Commit**

```bash
cd /Users/xiaoan/Documents/code/ArcaneKey
git add harmonyos/entry/src/main/ets/views/FeedbackView.ets
git commit -m "feat: FeedbackView 支持浅色/深色主题"
```

---

## 完成验证

- [ ] 所有 9 个任务已完成，每步 Build 均 `BUILD SUCCESSFUL`
- [ ] 深色模式下：所有视图背景 `#0d0d12`，卡片 `#191920`，文字 `#eeeef5`
- [ ] 浅色模式下：所有视图背景 `#FAF7F2`，卡片 `#FFFFFF`，文字 `#2C1810`
- [ ] 10 种主题色（accent color）切换正常，动画效果不受影响
- [ ] 关于我们页面：用户协议、隐私政策内嵌详情；邮箱可复制；官网和备案可跳转
- [ ] Logo 在启动器、启动屏（if layered icon works）、AboutView 三处均显示新图标
- [ ] `isDark` 状态在 preferences 中持久化，重启后恢复

---

## 已知限制

- **模态弹窗**（loginModal、backupModal、importModal、themeModal 等）保持深色，首期不 token 化。
- **底部导航栏**（bottomNav）保持原有玻璃效果，不随主题变化。
- **分层图标**（layered_image）如在 API 23 构建时报资源错误，回退至 `$media:icon`，不影响其他功能。
- **法律文本**为占位内容，后续由业务方提供正式版本。
