# 星枢令 Apple 风格 GitHub 发布页 — 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建单文件 `docs/release/index.html`，一个采用苹果官网风格、展示星枢令产品卖点并提供三个获取入口的发布页。

**Architecture:** 单个自包含 HTML 文件，内联 `<style>` 与 `<script>`，零外部依赖、零网络字体。逐章节增量构建，每一步产出可在浏览器打开查看的中间结果。产品展示用纯 CSS 渲染的手机模型还原星枢令深色界面。

**Tech Stack:** HTML5 + 内联 CSS（自定义属性/Flexbox/Grid/conic-gradient）+ 原生 JS（IntersectionObserver）。无构建、无库。

**验证说明:** 本仓库无测试框架，发布页为静态内容。每个任务的验证 = 在浏览器打开 `docs/release/index.html` 目视核对 + 控制台无报错。macOS 可用 `open docs/release/index.html`。

---

## 文件结构

- 创建：`docs/release/index.html` —— 唯一交付文件，包含全部结构、样式、脚本。

全部代码集中在这一个文件内，按章节顺序追加。CSS 写在 `<head>` 的单个 `<style>` 内（按章节分块、带注释）；JS 写在 `</body>` 前的单个 `<script>` 内。

---

### Task 1: 脚手架（head + 设计令牌 + reset + 空 body）

**Files:**
- Create: `docs/release/index.html`

- [ ] **Step 1: 创建文件，写入文档骨架、设计令牌与全局基样式**

写入以下完整内容：

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="description" content="星枢令 ArcaneKey —— 跨平台 TOTP 身份验证器。你的密钥，只属于这台设备。">
<title>星枢令 · ArcaneKey</title>
<style>
/* ===== 设计令牌 ===== */
:root{
  --accent:#4080D0;
  --accent-2:#5b9be0;
  --accent-glow:rgba(64,128,208,.40);
  --bg-dark:#0d0d12;
  --bg-dark-2:#191920;
  --bg-light:#fbfbfd;
  --text-dark:#1d1d1f;
  --text-light:#f5f5f7;
  --muted-dark:#6e6e73;
  --muted-light:#a1a1aa;
  --card-dark:#1c1c22;
  --maxw:1100px;
  --radius:28px;
  --font:-apple-system,BlinkMacSystemFont,"SF Pro Display","PingFang SC","Helvetica Neue",system-ui,sans-serif;
}
/* ===== reset ===== */
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{scroll-behavior:smooth}
body{
  font-family:var(--font);
  color:var(--text-dark);
  background:var(--bg-light);
  line-height:1.5;
  -webkit-font-smoothing:antialiased;
  overflow-x:hidden;
}
a{color:inherit;text-decoration:none}
img,svg{display:block;max-width:100%}
.wrap{max-width:var(--maxw);margin:0 auto;padding:0 24px}
section{padding:120px 0}
/* 章节明暗 */
.sec-dark{background:var(--bg-dark);color:var(--text-light)}
.sec-light{background:var(--bg-light);color:var(--text-dark)}
.sec-darker{background:#000;color:var(--text-light)}
/* 标题排版（苹果式超大粗体） */
.eyebrow{font-size:15px;font-weight:600;letter-spacing:.02em;color:var(--accent);margin-bottom:12px}
h1{font-size:clamp(44px,8vw,88px);font-weight:700;letter-spacing:-.02em;line-height:1.05}
h2{font-size:clamp(32px,5vw,56px);font-weight:700;letter-spacing:-.02em;line-height:1.1}
.lead{font-size:clamp(18px,2.4vw,26px);font-weight:400;color:var(--muted-dark)}
.sec-dark .lead{color:#aeaeb2}
/* 按钮 */
.btn{
  display:inline-flex;align-items:center;gap:8px;
  padding:14px 28px;border-radius:980px;
  font-size:17px;font-weight:600;cursor:pointer;border:none;
  transition:transform .2s ease,opacity .2s ease,background .2s ease;
}
.btn:hover{transform:scale(1.04)}
.btn-primary{background:var(--accent);color:#fff}
.btn-primary:hover{background:var(--accent-2)}
.btn-ghost{background:transparent;color:var(--accent);font-weight:500;padding:14px 8px}
.btn-light{background:#fff;color:var(--text-dark)}
</style>
</head>
<body>
<!-- 章节将按计划逐个加入此处 -->

<script>
/* 交互脚本将在最后任务加入 */
</script>
</body>
</html>
```

- [ ] **Step 2: 浏览器验证**

Run: `open docs/release/index.html`
Expected: 打开一个空白近白色页面，标题栏显示「星枢令 · ArcaneKey」，控制台无报错。

- [ ] **Step 3: Commit**

```bash
git add docs/release/index.html
git commit -m "feat(release): scaffold release page with design tokens"
```

---

### Task 2: 吸顶导航栏

**Files:**
- Modify: `docs/release/index.html`（在 `<style>` 末尾追加导航 CSS；在 `<!-- 章节将按计划逐个加入此处 -->` 处加入 `<header>`）

- [ ] **Step 1: 在 `<style>` 末尾（`</style>` 之前）追加导航样式**

```css
/* ===== 顶部导航 ===== */
.nav{
  position:fixed;top:0;left:0;right:0;z-index:100;
  height:52px;display:flex;align-items:center;
  background:rgba(251,251,253,.72);
  backdrop-filter:saturate(180%) blur(20px);
  -webkit-backdrop-filter:saturate(180%) blur(20px);
  border-bottom:1px solid rgba(0,0,0,.08);
}
.nav .wrap{display:flex;align-items:center;justify-content:space-between;width:100%}
.nav-brand{display:flex;align-items:center;gap:8px;font-weight:600;font-size:17px}
.nav-logo{width:24px;height:24px;border-radius:7px;background:linear-gradient(135deg,var(--accent),#7b4dd0);
  display:flex;align-items:center;justify-content:center;color:#fff;font-size:13px;font-weight:700}
.nav-links{display:flex;align-items:center;gap:28px;font-size:14px;color:var(--text-dark)}
.nav-links a{opacity:.85;transition:opacity .2s}
.nav-links a:hover{opacity:1}
.nav-cta{padding:6px 16px;border-radius:980px;background:var(--accent);color:#fff;font-size:13px}
.nav-cta:hover{background:var(--accent-2)}
body{padding-top:52px}
@media(max-width:680px){.nav-links a:not(.nav-cta){display:none}}
```

- [ ] **Step 2: 在 body 注释处加入导航 HTML**

替换 `<!-- 章节将按计划逐个加入此处 -->` 为：

```html
<header class="nav">
  <div class="wrap">
    <a class="nav-brand" href="#top"><span class="nav-logo">星</span>星枢令</a>
    <nav class="nav-links">
      <a href="#features">功能</a>
      <a href="#platforms">平台</a>
      <a href="#privacy">隐私</a>
      <a class="nav-cta" href="#get">获取</a>
    </nav>
  </div>
</header>
<!-- HERO -->
```

- [ ] **Step 3: 浏览器验证**

Run: `open docs/release/index.html`
Expected: 顶部出现毛玻璃半透明吸顶导航，左侧「星」图标+「星枢令」，右侧功能/平台/隐私链接 + 蓝色「获取」胶囊按钮。控制台无报错。

- [ ] **Step 4: Commit**

```bash
git add docs/release/index.html
git commit -m "feat(release): add sticky frosted nav bar"
```

---

### Task 3: 手机模型组件 CSS + Hero 章节

**Files:**
- Modify: `docs/release/index.html`（追加手机模型 + hero CSS；在 `<!-- HERO -->` 处加入章节）

- [ ] **Step 1: 在 `<style>` 末尾追加手机模型与 Hero 样式**

```css
/* ===== 手机模型组件 ===== */
.device{
  position:relative;width:300px;flex:0 0 300px;
  border-radius:54px;padding:12px;
  background:linear-gradient(160deg,#3a3a40,#15151a);
  box-shadow:0 40px 90px rgba(0,0,0,.55),0 0 80px var(--accent-glow);
}
.device-screen{
  position:relative;border-radius:44px;overflow:hidden;
  background:var(--bg-dark);height:600px;padding:54px 16px 16px;
}
.island{position:absolute;top:14px;left:50%;transform:translateX(-50%);
  width:96px;height:28px;background:#000;border-radius:20px}
.app-title{color:var(--text-light);font-size:22px;font-weight:700;margin:0 6px 18px}
/* 验证码卡片 */
.tk{display:flex;align-items:center;gap:12px;background:var(--card-dark);
  border-radius:18px;padding:14px;margin-bottom:12px}
.tk-avatar{width:42px;height:42px;border-radius:50%;flex:0 0 42px;
  display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:18px}
.tk-info{flex:1;min-width:0}
.tk-name{color:var(--text-light);font-size:15px;font-weight:600}
.tk-acct{color:#86868b;font-size:12px}
.tk-code{color:var(--accent-2);font-size:20px;font-weight:700;letter-spacing:.06em;
  font-variant-numeric:tabular-nums;margin-top:2px}
/* 倒计时环 */
.ring{width:34px;height:34px;border-radius:50%;flex:0 0 34px;
  background:conic-gradient(var(--accent) var(--p,75%),rgba(255,255,255,.12) 0);
  display:flex;align-items:center;justify-content:center}
.ring::after{content:"";width:26px;height:26px;border-radius:50%;background:var(--card-dark)}
/* 底部悬浮胶囊导航 */
.app-nav{position:absolute;left:50%;bottom:18px;transform:translateX(-50%);
  width:80%;height:52px;border-radius:26px;display:flex;align-items:center;justify-content:space-around;
  background:rgba(40,40,48,.6);backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);
  border:1px solid rgba(255,255,255,.08)}
.app-nav span{width:22px;height:22px;border-radius:6px;background:rgba(255,255,255,.25)}
.app-nav span.on{background:var(--accent)}
/* ===== Hero ===== */
.hero{background:radial-gradient(ellipse at 50% 0%,#16161d,#000 70%);color:var(--text-light);
  text-align:center;padding:140px 0 0;overflow:hidden}
.hero h1{margin-bottom:18px}
.hero .lead{max-width:640px;margin:0 auto 14px}
.hero-sub{color:#86868b;font-size:17px;margin-bottom:32px}
.hero-cta{display:flex;gap:18px;justify-content:center;align-items:center;margin-bottom:60px;flex-wrap:wrap}
.hero-device{display:flex;justify-content:center;padding-bottom:0;transform:translateY(40px)}
```

- [ ] **Step 2: 在 `<!-- HERO -->` 处加入 Hero 章节**

替换 `<!-- HERO -->` 为：

```html
<section class="hero" id="top">
  <div class="wrap">
    <p class="eyebrow">星枢令 · ArcaneKey</p>
    <h1>你的密钥<br>只属于这台设备</h1>
    <p class="lead">跨平台 TOTP 身份验证器。验证码每 30 秒自动刷新，密钥仅存于本地，从不上传服务器。</p>
    <p class="hero-sub">HarmonyOS App · 微信小程序</p>
    <div class="hero-cta">
      <a class="btn btn-primary" href="https://github.com/mengyuefeitian/ArcaneKey" target="_blank" rel="noopener">在 GitHub 获取</a>
      <a class="btn btn-ghost" href="#features">了解更多 ›</a>
    </div>
    <div class="hero-device">
      <div class="device">
        <div class="device-screen">
          <div class="island"></div>
          <div class="app-title">星枢令</div>
          <div class="tk">
            <div class="tk-avatar" style="background:#24292f">G</div>
            <div class="tk-info"><div class="tk-name">GitHub</div><div class="tk-acct">dev@arcanekey</div><div class="tk-code">428 913</div></div>
            <div class="ring" style="--p:78%"></div>
          </div>
          <div class="tk">
            <div class="tk-avatar" style="background:#4080D0">G</div>
            <div class="tk-info"><div class="tk-name">Google</div><div class="tk-acct">me@gmail.com</div><div class="tk-code">051 264</div></div>
            <div class="ring" style="--p:55%"></div>
          </div>
          <div class="tk">
            <div class="tk-avatar" style="background:#1677FF">支</div>
            <div class="tk-info"><div class="tk-name">支付宝</div><div class="tk-acct">138****8888</div><div class="tk-code">739 016</div></div>
            <div class="ring" style="--p:33%"></div>
          </div>
          <div class="app-nav"><span class="on"></span><span></span><span></span></div>
        </div>
      </div>
    </div>
  </div>
</section>
<!-- FEATURES -->
```

- [ ] **Step 3: 浏览器验证**

Run: `open docs/release/index.html`
Expected: Hero 黑色渐变背景，超大标题「你的密钥/只属于这台设备」，蓝色「在 GitHub 获取」按钮，下方一台深色手机模型展示 3 张验证码卡片（含倒计时环、底部悬浮导航）。「在 GitHub 获取」链接指向仓库。控制台无报错。

- [ ] **Step 4: Commit**

```bash
git add docs/release/index.html
git commit -m "feat(release): add phone mockup component and hero section"
```

---

### Task 4: 特性聚焦（图文交替行）

**Files:**
- Modify: `docs/release/index.html`（追加 CSS；在 `<!-- FEATURES -->` 处加入章节）

- [ ] **Step 1: 在 `<style>` 末尾追加特性聚焦样式**

```css
/* ===== 特性聚焦 ===== */
.spot{display:flex;align-items:center;gap:64px;margin-bottom:120px}
.spot:last-child{margin-bottom:0}
.spot.rev{flex-direction:row-reverse}
.spot-text{flex:1}
.spot-text h2{margin-bottom:18px}
.spot-visual{flex:0 0 360px;display:flex;justify-content:center}
.spot-head{text-align:center;margin-bottom:90px}
.spot-head h2{margin-bottom:14px}
/* 扫码取景框视觉 */
.scanbox{width:240px;height:240px;border-radius:28px;position:relative;
  background:repeating-linear-gradient(45deg,#16161d,#16161d 10px,#1c1c24 10px,#1c1c24 20px)}
.scanbox::before,.scanbox::after{content:"";position:absolute;width:46px;height:46px;border:3px solid var(--accent)}
.scanbox::before{top:16px;left:16px;border-right:0;border-bottom:0;border-radius:14px 0 0 0}
.scanbox::after{bottom:16px;right:16px;border-left:0;border-top:0;border-radius:0 0 14px 0}
.scanline{position:absolute;left:16px;right:16px;top:50%;height:2px;background:var(--accent);
  box-shadow:0 0 12px var(--accent)}
/* 主题色板 */
.swatches{display:flex;flex-wrap:wrap;gap:14px;max-width:300px}
.swatch{width:48px;height:48px;border-radius:14px;cursor:pointer;border:2px solid transparent;transition:transform .15s}
.swatch:hover{transform:scale(1.12)}
.swatch.sel{border-color:#fff}
/* 隐私图形 */
.privacy-gfx{width:200px;height:200px;border-radius:50%;
  background:radial-gradient(circle,var(--accent-glow),transparent 70%);
  display:flex;align-items:center;justify-content:center;font-size:90px}
@media(max-width:768px){
  .spot,.spot.rev{flex-direction:column;gap:36px;text-align:center;margin-bottom:80px}
  .spot-text h2{font-size:30px}
  .swatches{justify-content:center;margin:0 auto}
}
```

- [ ] **Step 2: 在 `<!-- FEATURES -->` 处加入特性聚焦章节**

替换 `<!-- FEATURES -->` 为：

```html
<section class="sec-dark" id="features">
  <div class="wrap">
    <div class="spot-head reveal">
      <p class="eyebrow">为什么选择星枢令</p>
      <h2>简单、安全、好看</h2>
      <p class="lead">把繁琐的两步验证，变成一件赏心悦目的小事。</p>
    </div>

    <div class="spot reveal">
      <div class="spot-text">
        <h2>动态验证码<br>一目了然</h2>
        <p class="lead">遵循 TOTP 标准，每 30 秒自动刷新。倒计时环实时可视化，验证码以分组大字呈现，一眼读取、一键复制。</p>
      </div>
      <div class="spot-visual">
        <div class="device" style="width:260px;flex-basis:260px">
          <div class="device-screen" style="height:520px">
            <div class="island"></div>
            <div class="app-title">星枢令</div>
            <div class="tk"><div class="tk-avatar" style="background:#24292f">G</div>
              <div class="tk-info"><div class="tk-name">GitHub</div><div class="tk-acct">dev@arcanekey</div><div class="tk-code">428 913</div></div>
              <div class="ring" style="--p:78%"></div></div>
            <div class="tk"><div class="tk-avatar" style="background:#EA4335">M</div>
              <div class="tk-info"><div class="tk-name">Microsoft</div><div class="tk-acct">work@out.com</div><div class="tk-code">662 540</div></div>
              <div class="ring" style="--p:60%"></div></div>
          </div>
        </div>
      </div>
    </div>

    <div class="spot rev reveal">
      <div class="spot-text">
        <h2>扫码即添加</h2>
        <p class="lead">相机扫码或相册识别二维码，账号一键导入，无需手动抄写密钥。也支持 Base32 手动输入。</p>
      </div>
      <div class="spot-visual">
        <div class="scanbox"><div class="scanline"></div></div>
      </div>
    </div>

    <div class="spot reveal">
      <div class="spot-text">
        <h2>10 款主题<br>随心切换</h2>
        <p class="lead">海洋蓝、皇室紫、极光绿……一键换上你喜欢的强调色，验证器也能有个性。</p>
        <div class="swatches" id="swatches" style="margin-top:24px"></div>
      </div>
      <div class="spot-visual">
        <div class="device" id="themeDevice" style="width:240px;flex-basis:240px">
          <div class="device-screen" style="height:480px">
            <div class="island"></div>
            <div class="app-title">星枢令</div>
            <div class="tk"><div class="tk-avatar" style="background:var(--accent)">A</div>
              <div class="tk-info"><div class="tk-name">Apple ID</div><div class="tk-acct">me@icloud.com</div><div class="tk-code">309 175</div></div>
              <div class="ring" style="--p:66%"></div></div>
            <div class="app-nav"><span class="on"></span><span></span><span></span></div>
          </div>
        </div>
      </div>
    </div>

    <div class="spot rev reveal" id="privacy">
      <div class="spot-text">
        <h2>本地优先<br>隐私安全</h2>
        <p class="lead">所有 TOTP 密钥仅存储在你的设备本地，从不上传任何服务器。备份采用加密导出，换机无忧。</p>
        <a class="btn btn-ghost" href="../privacy.html" style="margin-top:16px">查看隐私政策 ›</a>
      </div>
      <div class="spot-visual"><div class="privacy-gfx">🔒</div></div>
    </div>
  </div>
</section>
<!-- GRID -->
```

- [ ] **Step 3: 浏览器验证**

Run: `open docs/release/index.html`
Expected: 暗色「为什么选择星枢令」章节，4 个图文交替行：动态验证码（手机模型）/扫码（取景框带扫描线）/10 款主题（空色板容器，将在 JS 任务填充）/本地优先（🔒 光晕图形 + 隐私政策链接）。控制台无报错。注：色板此时为空，Task 9 填充。

- [ ] **Step 4: Commit**

```bash
git add docs/release/index.html
git commit -m "feat(release): add feature spotlight rows"
```

---

### Task 5: 特性网格（Bento）

**Files:**
- Modify: `docs/release/index.html`（追加 CSS；在 `<!-- GRID -->` 处加入章节）

- [ ] **Step 1: 在 `<style>` 末尾追加网格样式**

```css
/* ===== 特性网格 ===== */
.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin-top:60px}
.cell{background:#fff;border-radius:24px;padding:32px;border:1px solid rgba(0,0,0,.06);
  box-shadow:0 4px 24px rgba(0,0,0,.04)}
.cell-ico{width:48px;height:48px;border-radius:14px;background:var(--accent);color:#fff;
  display:flex;align-items:center;justify-content:center;font-size:24px;margin-bottom:18px}
.cell h3{font-size:20px;font-weight:600;margin-bottom:8px}
.cell p{color:var(--muted-dark);font-size:15px}
@media(max-width:768px){.grid{grid-template-columns:1fr}}
```

- [ ] **Step 2: 在 `<!-- GRID -->` 处加入网格章节**

替换 `<!-- GRID -->` 为：

```html
<section class="sec-light">
  <div class="wrap">
    <div class="spot-head reveal">
      <p class="eyebrow">更多细节</p>
      <h2>每个角落都顺手</h2>
    </div>
    <div class="grid">
      <div class="cell reveal"><div class="cell-ico">✍️</div><h3>手动输入</h3><p>支持手动填写 Base32 Secret Key，兼容所有标准 TOTP 服务。</p></div>
      <div class="cell reveal"><div class="cell-ico">💾</div><h3>加密备份</h3><p>加密导出 / 导入数据，换机迁移无忧，密钥不离开你的掌控。</p></div>
      <div class="cell reveal"><div class="cell-ico">🔍</div><h3>快速搜索</h3><p>按品牌名或账号名实时过滤，账号再多也能秒速定位。</p></div>
      <div class="cell reveal"><div class="cell-ico">👆</div><h3>手势操作</h3><p>长按菜单、左滑删除（鸿蒙版），操作流畅自然。</p></div>
      <div class="cell reveal"><div class="cell-ico">⏱️</div><h3>30 秒刷新</h3><p>标准 TOTP 周期，倒计时环可视化，绝不错过刷新时机。</p></div>
      <div class="cell reveal"><div class="cell-ico">🎯</div><h3>兼容广泛</h3><p>兼容 Google Authenticator 协议：Gmail、GitHub、微软、支付宝等。</p></div>
    </div>
  </div>
</section>
<!-- PLATFORMS -->
```

- [ ] **Step 3: 浏览器验证**

Run: `open docs/release/index.html`
Expected: 近白色章节「每个角落都顺手」，3×2 卡片网格，每张含彩色圆角图标 + 标题 + 描述。控制台无报错。

- [ ] **Step 4: Commit**

```bash
git add docs/release/index.html
git commit -m "feat(release): add bento feature grid"
```

---

### Task 6: 双平台章节

**Files:**
- Modify: `docs/release/index.html`（追加 CSS；在 `<!-- PLATFORMS -->` 处加入章节）

- [ ] **Step 1: 在 `<style>` 末尾追加平台样式**

```css
/* ===== 双平台 ===== */
.plats{display:grid;grid-template-columns:1fr 1fr;gap:24px;margin-top:60px}
.plat{background:var(--card-dark);border-radius:28px;padding:40px;border:1px solid rgba(255,255,255,.06)}
.plat-tag{display:inline-block;font-size:13px;font-weight:600;padding:5px 12px;border-radius:980px;
  background:rgba(64,128,208,.18);color:var(--accent-2);margin-bottom:18px}
.plat h3{font-size:26px;font-weight:700;color:var(--text-light);margin-bottom:16px}
.plat ul{list-style:none}
.plat li{color:#aeaeb2;font-size:16px;padding:8px 0 8px 26px;position:relative}
.plat li::before{content:"✓";position:absolute;left:0;color:var(--accent-2);font-weight:700}
@media(max-width:768px){.plats{grid-template-columns:1fr}}
```

- [ ] **Step 2: 在 `<!-- PLATFORMS -->` 处加入平台章节**

替换 `<!-- PLATFORMS -->` 为：

```html
<section class="sec-darker" id="platforms">
  <div class="wrap">
    <div class="spot-head reveal">
      <p class="eyebrow">双平台</p>
      <h2>原生体验，随处可用</h2>
    </div>
    <div class="plats">
      <div class="plat reveal">
        <span class="plat-tag">HarmonyOS 6.1</span>
        <h3>鸿蒙原生 App</h3>
        <ul>
          <li>ArkTS 原生开发，适配鸿蒙设计规范</li>
          <li>玻璃态悬浮导航，沉浸式光感界面</li>
          <li>ScanKit 系统级扫码</li>
          <li>长按 / 左滑手势操作</li>
        </ul>
      </div>
      <div class="plat reveal">
        <span class="plat-tag">微信小程序</span>
        <h3>免安装即用</h3>
        <ul>
          <li>无需下载安装，微信内随时打开</li>
          <li>扫码即添加，一步到位</li>
          <li>加密云备份，跨设备同步</li>
          <li>意见反馈直达开发者</li>
        </ul>
      </div>
    </div>
  </div>
</section>
<!-- GET -->
```

- [ ] **Step 3: 浏览器验证**

Run: `open docs/release/index.html`
Expected: 纯黑章节「原生体验，随处可用」，两张深色卡片（鸿蒙 / 微信小程序），各含标签 + 标题 + 带勾的特性列表。控制台无报错。

- [ ] **Step 4: Commit**

```bash
git add docs/release/index.html
git commit -m "feat(release): add dual-platform section"
```

---

### Task 7: 获取章节（三个 CTA）

**Files:**
- Modify: `docs/release/index.html`（追加 CSS；在 `<!-- GET -->` 处加入章节）

- [ ] **Step 1: 在 `<style>` 末尾追加获取章节样式**

```css
/* ===== 获取 ===== */
.get{text-align:center}
.get h2{margin-bottom:14px}
.get-cards{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin-top:56px;text-align:center}
.get-card{background:#fff;border-radius:24px;padding:36px 28px;border:1px solid rgba(0,0,0,.06);
  box-shadow:0 4px 24px rgba(0,0,0,.04);display:flex;flex-direction:column;align-items:center;gap:14px}
.get-card h3{font-size:19px;font-weight:600}
.get-card p{color:var(--muted-dark);font-size:14px;flex:1}
/* 二维码占位 */
.qr-ph{width:120px;height:120px;border-radius:16px;
  background:repeating-conic-gradient(#1d1d1f 0 25%,#fff 0 50%) 0/24px 24px;
  border:1px solid rgba(0,0,0,.1)}
.store-ph{width:120px;height:120px;border-radius:16px;background:#f0f0f3;
  display:flex;align-items:center;justify-content:center;font-size:48px}
@media(max-width:768px){.get-cards{grid-template-columns:1fr}}
```

- [ ] **Step 2: 在 `<!-- GET -->` 处加入获取章节**

替换 `<!-- GET -->` 为：

```html
<section class="sec-light get" id="get">
  <div class="wrap">
    <div class="reveal">
      <p class="eyebrow">现在开始</p>
      <h2>获取星枢令</h2>
      <p class="lead">开源、免费、本地优先。</p>
    </div>
    <div class="get-cards">
      <div class="get-card reveal">
        <div class="store-ph">🐙</div>
        <h3>GitHub</h3>
        <p>查看源码、下载发布版、参与共建。MIT 开源。</p>
        <a class="btn btn-primary" href="https://github.com/mengyuefeitian/ArcaneKey" target="_blank" rel="noopener">前往仓库</a>
      </div>
      <div class="get-card reveal">
        <!-- TODO: 替换为真实微信小程序码图片 -->
        <div class="qr-ph"></div>
        <h3>微信小程序</h3>
        <p>微信搜索「星枢令」，免安装即用。</p>
        <a class="btn btn-light" style="border:1px solid rgba(0,0,0,.1)" href="#">扫码进入</a>
      </div>
      <div class="get-card reveal">
        <div class="store-ph">📱</div>
        <h3>鸿蒙 App</h3>
        <p>HarmonyOS 应用市场（即将上架）。</p>
        <!-- TODO: 替换为真实鸿蒙应用市场链接 -->
        <a class="btn btn-light" style="border:1px solid rgba(0,0,0,.1)" href="#">应用市场</a>
      </div>
    </div>
  </div>
</section>
<!-- FOOTER -->
```

- [ ] **Step 3: 浏览器验证**

Run: `open docs/release/index.html`
Expected: 近白章节「获取星枢令」，三张卡片：GitHub（🐙，链接真实仓库）/微信小程序（棋盘格二维码占位）/鸿蒙 App（📱 占位）。GitHub「前往仓库」可跳转。控制台无报错。

- [ ] **Step 4: Commit**

```bash
git add docs/release/index.html
git commit -m "feat(release): add get/download section with three CTAs"
```

---

### Task 8: 页脚

**Files:**
- Modify: `docs/release/index.html`（追加 CSS；在 `<!-- FOOTER -->` 处加入页脚）

- [ ] **Step 1: 在 `<style>` 末尾追加页脚样式**

```css
/* ===== 页脚 ===== */
.footer{background:#f5f5f7;color:var(--muted-dark);padding:40px 0;font-size:13px}
.footer .wrap{display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:16px}
.footer-links{display:flex;gap:24px}
.footer-links a:hover{color:var(--text-dark)}
@media(max-width:680px){.footer .wrap{flex-direction:column;text-align:center}}
```

- [ ] **Step 2: 在 `<!-- FOOTER -->` 处加入页脚**

替换 `<!-- FOOTER -->` 为：

```html
<footer class="footer">
  <div class="wrap">
    <div>© 2026 星枢令 ArcaneKey · MIT License</div>
    <div class="footer-links">
      <a href="../privacy.html">隐私政策</a>
      <a href="https://github.com/mengyuefeitian/ArcaneKey" target="_blank" rel="noopener">GitHub</a>
    </div>
  </div>
</footer>
```

- [ ] **Step 3: 浏览器验证**

Run: `open docs/release/index.html`
Expected: 页面底部出现浅灰页脚，左侧版权 + MIT，右侧隐私政策 / GitHub 链接。控制台无报错。

- [ ] **Step 4: Commit**

```bash
git add docs/release/index.html
git commit -m "feat(release): add footer"
```

---

### Task 9: 交互脚本（滚动淡入 + 主题色板 + 降级动效）

**Files:**
- Modify: `docs/release/index.html`（追加 reveal/reduced-motion CSS；替换底部 `<script>`）

- [ ] **Step 1: 在 `<style>` 末尾追加淡入与降级动效样式**

```css
/* ===== 动效 ===== */
.reveal{opacity:0;transform:translateY(28px);transition:opacity .7s ease,transform .7s ease}
.reveal.in{opacity:1;transform:none}
.scanline{animation:scan 2.2s ease-in-out infinite}
@keyframes scan{0%,100%{top:18%}50%{top:82%}}
@media(prefers-reduced-motion:reduce){
  html{scroll-behavior:auto}
  .reveal{opacity:1;transform:none;transition:none}
  .scanline{animation:none;top:50%}
  .btn:hover,.swatch:hover{transform:none}
}
```

- [ ] **Step 2: 替换底部 `<script>` 块**

将 `<script>/* 交互脚本将在最后任务加入 */</script>` 替换为：

```html
<script>
// 滚动进入视口淡入
(function(){
  var els = document.querySelectorAll('.reveal');
  if(!('IntersectionObserver' in window)){els.forEach(function(e){e.classList.add('in')});return;}
  var io = new IntersectionObserver(function(entries){
    entries.forEach(function(en){ if(en.isIntersecting){ en.target.classList.add('in'); io.unobserve(en.target); } });
  },{threshold:.15});
  els.forEach(function(e){io.observe(e)});
})();

// 主题色板：渲染 10 个色块，点击切换手机模型强调色
(function(){
  var THEMES = [
    {name:'海洋蓝',c:'#4080D0'},{name:'皇室紫',c:'#7B4DD0'},{name:'极光绿',c:'#1FAE83'},
    {name:'日暮橙',c:'#E07B39'},{name:'樱花粉',c:'#E36B9E'},{name:'琥珀黄',c:'#D9A521'},
    {name:'青瓷',c:'#2BA6A6'},{name:'玫瑰红',c:'#D94A5A'},{name:'石墨灰',c:'#6E6E78'},{name:'靛蓝',c:'#3A56C0'}
  ];
  var box = document.getElementById('swatches');
  var dev = document.getElementById('themeDevice');
  if(!box) return;
  THEMES.forEach(function(t,i){
    var s = document.createElement('div');
    s.className = 'swatch' + (i===0?' sel':'');
    s.style.background = t.c;
    s.title = t.name;
    s.setAttribute('role','button');
    s.setAttribute('aria-label','主题 '+t.name);
    s.addEventListener('click', function(){
      box.querySelectorAll('.swatch').forEach(function(x){x.classList.remove('sel')});
      s.classList.add('sel');
      if(dev) dev.style.setProperty('--accent', t.c);
    });
    box.appendChild(s);
  });
})();
</script>
```

- [ ] **Step 3: 浏览器验证**

Run: `open docs/release/index.html`
Expected:
- 向下滚动时，各章节内容淡入上浮。
- 「10 款主题」章节出现 10 个彩色色块，第一个有白边选中；点击不同色块时，旁边手机模型的强调色（卡片头像、验证码、倒计时环）随之改变。
- 扫码取景框的扫描线上下移动。
- 控制台无报错。

- [ ] **Step 4: 移动端 + 离线验证**

- 在浏览器开发者工具切换到移动端宽度（≤414px）：各章节纵向堆叠，无横向滚动溢出，导航次要链接隐藏。
- 断网后刷新仍完整渲染（证明无外部依赖）。

- [ ] **Step 5: Commit**

```bash
git add docs/release/index.html
git commit -m "feat(release): add scroll-reveal, theme switcher, reduced-motion"
```

---

## 自检（Self-Review）

**Spec 覆盖核对：**
- 视觉语言（字体栈/强调色/明暗交替/动效/reduced-motion）→ Task 1、9 ✓
- 手机模型组件 → Task 3 ✓
- 7 个章节：导航(T2)/Hero(T3)/特性聚焦(T4)/Bento 网格(T5)/双平台(T6)/获取(T7)/页脚(T8) ✓
- 三个获取入口（GitHub 真实链接 + 微信小程序码占位 + 鸿蒙市场占位，均带 TODO）→ Task 7 ✓
- 隐私政策链接 → `../privacy.html`（Task 4 与 Task 8）✓
- 10 款主题色板交互 → Task 9 ✓
- 单文件、零依赖、无网络字体 → 全程 ✓
- 响应式与离线验证 → Task 9 Step 4 ✓
- 可访问性（语义标签、aria-label、reduced-motion）→ Task 9 ✓

**占位符扫描：** 无 TBD/TODO 式计划占位；页面内 `<!-- TODO -->` 为 spec 明确要求的「后续可替换占位」，非计划缺口。

**类型/命名一致性：** CSS 类名（`.device`/`.device-screen`/`.tk`/`.ring`/`.app-nav`/`.reveal`/`.swatch`）在各任务间一致；JS 引用的 `#swatches`、`#themeDevice` 均在 Task 4 的 HTML 中定义。

**图标策略说明：** 计划全程使用内联 emoji/CSS 图形，不引用 `../../image/*.svg`，避免子目录相对路径问题（符合 spec「优先内联」默认）。
