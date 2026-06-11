# Spec: HarmonyOS 浅色/深色主题 · 我的页面重构 · 关于我们 · Logo替换

Date: 2026-06-11  
Branch: dev-harmonyos  
Platform: HarmonyOS 6.1 (API 23 / ArkTS)

---

## Objective

四项并行交付：

1. **双主题系统**：在【我的】页面新增"显示模式"开关，支持深色（Midnight Garden）与浅色（Warm Terracotta）两套结构色，与现有10色主题完全独立。
2. **我的页面重构**：移除顶部品牌区域（logo + 名称 + 简介），账号/登录卡片上升为第一内容区；菜单底部新增"显示模式"和"关于我们"两个入口。
3. **关于我们页面**：全屏覆盖视图，展示品牌标识 + 信息列表（用户协议、隐私政策、邮箱、官网、备案）。
4. **Logo资源替换**：用新设计资源替换所有图标文件，并配置自适应图标（前景/背景分层）。

---

## 两套独立系统说明

| 系统 | 控制范围 | 状态字段 | 持久化 key |
|------|---------|---------|-----------|
| 10色主题（现有） | 强调色、动画、渐变、光晕 | `accentColor: string` | `ak_theme`（不变） |
| 深色/浅色模式（新增） | 页面背景、卡片、文字、分割线 | `isDark: boolean` | `ak_dark_mode` |

两套系统**互不干涉**。强调色叠加在当前结构色调色板之上，不受明暗模式影响。

---

## 1. ColorTokens 模型

### 文件

新增 `harmonyos/entry/src/main/ets/model/ColorTokens.ets`

### 接口

```typescript
export interface ColorTokens {
  bgPrimary: string;      // 页面底色
  bgCard: string;         // 卡片/区块背景
  textPrimary: string;    // 主文字
  textSecondary: string;  // 辅助文字
  textTertiary: string;   // 提示/标签文字
  textDisabled: string;   // 禁用文字
  divider: string;        // 分割线
  borderSubtle: string;   // 细边框
}
```

### 调色板

| Token | 深色（Midnight Garden） | 浅色（Warm Terracotta） |
|-------|----------------------|----------------------|
| `bgPrimary` | `#0d0d12` | `#FAF7F2` |
| `bgCard` | `#191920` | `#FFFFFF` |
| `textPrimary` | `#eeeef5` | `#2C1810` |
| `textSecondary` | `rgba(238,238,245,0.55)` | `#5C4F43` |
| `textTertiary` | `rgba(238,238,245,0.38)` | `#8B7E74` |
| `textDisabled` | `rgba(238,238,245,0.2)` | `#A99E93` |
| `divider` | `rgba(255,255,255,0.05)` | `#E8E2D9` |
| `borderSubtle` | `rgba(255,255,255,0.05)` | `#E8E2D9` |

### 工厂函数

```typescript
export function makeTokens(isDark: boolean): ColorTokens
```

每个视图在 `build()` 顶部调用一次，得到本次渲染用的 token 集合。`accentColor` 继续独立传递，不进入 ColorTokens。

---

## 2. Index.ets 变更

### 新增状态

```typescript
@State isDark: boolean = true
@State showAbout: boolean = false
```

### 持久化

在 `StorageUtil.ets` 中新增两个函数：

```typescript
export async function loadThemeMode(): Promise<boolean>  // 读 ak_dark_mode，默认 true
export async function saveThemeMode(isDark: boolean): Promise<void>
```

在 `loadData()` 中调用 `loadThemeMode()` 初始化 `isDark`。  
切换时调用 `saveThemeMode(this.isDark)` 写入 preferences。

### Props 传递

所有子视图新增 `isDark` prop：`HomeView`、`ScanView`、`ProfileView`、`FeedbackView`。

### 覆盖层渲染

在 `build()` 末尾叠加（与 FeedbackView 同级，同样模式）：

```typescript
if (this.showAbout) {
  AboutView({
    accentColor: this.accentColor,
    isDark: this.isDark,
    onClose: () => { this.showAbout = false; }
  })
}
```

### ProfileView 回调新增

```typescript
onToggleMode: () => { this.isDark = !this.isDark; /* + save */ },
onAboutTap: () => { this.showAbout = true; },
```

---

## 3. ProfileView 重构

### 移除

顶部品牌区域整块删除：
- `Image($r('app.media.logo_img'))` 64px 圆形
- `Text('星枢令')` 标题
- `Text('星枢令：身份验证器')` 副标题
- 描述段落文字

底部版本号文字也删除（`Text('星枢令 v1.0.0')`），版本信息移至 AboutView 展示。

### 保留并上移

账号/登录卡片成为第一内容区（`padding({ top: 16 })`）。

### 菜单新增（两条）

**显示模式**（紧接皮肤主题之后）：

```
☀️/🌙  显示模式
        浅色 / 深色        ›
```

emoji 根据 `isDark` 切换：深色时 🌙，浅色时 ☀️；副标题显示当前模式名。点击调用 `onToggleMode()`。

**关于我们**（意见与建议之后，菜单最后一条）：

```
ℹ️  关于我们
    版本号·法律·联系方式    ›
```

点击调用 `onAboutTap()`。

### 颜色 Token 化

ProfileView 内所有硬编码结构色替换为 `makeTokens(this.isDark)` 返回的 token：

- 页面背景 `#0d0d12` → `t.bgPrimary`
- 卡片背景 `#191920` → `t.bgCard`
- 主文字 `#eeeef5` → `t.textPrimary`
- 辅助文字 `rgba(238,238,245,0.55)` → `t.textSecondary`
- 提示文字 `rgba(238,238,245,0.38)` → `t.textTertiary`
- 禁用文字 `rgba(238,238,245,0.2)` → `t.textDisabled`
- 分割线 / 细边框 → `t.divider` / `t.borderSubtle`

强调色（`accentColor`）用法不变。

### 新增 Props

```typescript
@Prop isDark: boolean = true
onToggleMode: () => void = () => {}
onAboutTap: () => void = () => {}
```

---

## 4. HomeView / ScanView / FeedbackView 颜色 Token 化

三个视图各自：

1. 新增 `@Prop isDark: boolean = true`
2. 在 `build()` 顶部：`const t = makeTokens(this.isDark)`
3. 将所有硬编码结构色替换为对应 token

强调色和动画相关颜色（`accentColor`、`+ '55'`、`+ '28'` 等）不变。

---

## 5. AboutView — 新文件

`harmonyos/entry/src/main/ets/views/AboutView.ets`

### Props

```typescript
@Prop accentColor: string = '#4080D0'
@Prop isDark: boolean = true
onClose: () => void = () => {}
```

### 内部状态

```typescript
@State showAgreement: boolean = false
@State showPrivacy: boolean = false
```

### 布局结构

```
Column (全屏, bgPrimary 背景)
  ├─ Header Row
  │    ├─ × 关闭按钮
  │    └─ "关于我们" 标题
  └─ Scroll
       └─ Column
            ├─ 品牌区块 (居中)
            │    ├─ Image(logo_img) 64px 圆形 + 阴影(accentColor)
            │    ├─ Text "玄钥"  fontSize 22 fontWeight 800
            │    └─ Text "身份验证器 · 守护你的数字安全"  fontSize 13
            ├─ 信息列表卡片 (bgCard, borderRadius 18)
            │    ├─ 用户协议  ›  → showAgreement = true
            │    ├─ Divider
            │    ├─ 隐私政策  ›  → showPrivacy = true
            │    ├─ Divider
            │    ├─ 邮箱  mengyuefeitian@live.cn  (点击复制)
            │    ├─ Divider
            │    ├─ 官网  www.xiaoanhome.xyz  (点击打开浏览器)
            │    └─ 备案  京ICP备2026021298号-3A  (点击打开 beian.miit.gov.cn)
            └─ 版本号  "玄钥 v1.0.0"  textDisabled  居中
```

### 法律详情视图（内嵌）

当 `showAgreement` 或 `showPrivacy` 为 true 时，在 AboutView 内用条件渲染覆盖：

```
Column (全屏, bgPrimary)
  ├─ Header: ← 返回  "用户协议" / "隐私政策"
  └─ Scroll: 法律条款文本（静态文字，预置占位内容）
```

点击返回 → 对应 boolean 置 false，回到 AboutView 主体。

### 外部链接实现

官网和备案页通过系统 Want 打开浏览器：

```typescript
const want: Want = {
  action: 'ohos.want.action.viewData',
  entities: ['entity.system.browsable'],
  uri: 'https://beian.miit.gov.cn/'
}
ctx.startAbility(want)
```

邮箱复制使用 `pasteboard.createData` + `getSystemPasteboard().setData()`，并弹出 toast 提示。

---

## 6. Logo 资源替换

### 资源文件映射

| 目标路径 | 来源文件 | 用途 |
|---------|---------|------|
| `AppScope/resources/base/media/app_icon.png` | `玄钥/icon.png` | AppGallery 应用图标 |
| `entry/.../resources/base/media/icon.png` | `玄钥/icon.png` | Ability 单层图标 / 启动屏 |
| `entry/.../resources/base/media/logo_img.png` | `玄钥/appgallery-icon-1024.png` | 应用内 Logo 展示（AboutView） |
| `entry/.../resources/base/media/foreground.png` | `玄钥/foreground.png` | 自适应图标前景层（新增） |
| `entry/.../resources/base/media/background.png` | `玄钥/background.png` | 自适应图标背景层（新增） |
| `entry/.../resources/base/media/layered_image.json` | `玄钥/layered_image.json` | 自适应图标配置（新增） |

### module.json5 变更

```json5
"icon": "$media:layered_image",      // 改为分层图标（启动器自适应）
"startWindowIcon": "$media:icon",    // 保持单层 PNG（启动屏）
```

---

## 实现顺序

1. **Logo 资源**：纯文件操作，无 ArkTS 风险，最先完成
2. **ColorTokens 模型**：无依赖的新文件
3. **Index.ets 状态扩展**：新增字段 + 加载/保存逻辑
4. **ProfileView 重构**：最核心的可见变化
5. **AboutView**：新文件，与 Index 联动
6. **HomeView / ScanView / FeedbackView Token 化**：批量替换，逐文件验证

每一步完成后执行 build，确认无编译错误后再继续。

---

## 完成标准

- [ ] 深色 / 浅色切换覆盖所有四个视图，无颜色残留
- [ ] 10种主题色在两种模式下均正常显示，动画效果不受影响
- [ ] 关于我们页面所有链接/复制功能可用
- [ ] Logo 在启动器、启动屏、应用内三处均显示新图标
- [ ] 编译成功，无 ArkTS 错误
- [ ] `isDark` 状态持久化，重启后恢复

---

## 边界说明

- **不修改**：TOTP 计算、存储结构、会员逻辑、QR 扫描、云备份
- **不引入**：新的外部依赖、新的导航路由、HarmonyOS API 24+ 专有 API
- **法律文本**：用户协议和隐私政策暂用占位文字，留空待业务方提供
