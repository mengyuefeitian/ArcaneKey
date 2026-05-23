# 星枢令 · ArcaneKey

> 双平台 TOTP 身份验证器 — HarmonyOS App + 微信小程序

<p align="center">
  <img src="harmonyos/AppScope/resources/base/media/app_icon.png" width="120" height="120" alt="星枢令" style="border-radius:24px"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/HarmonyOS-6.1%20(API%2023)-brightgreen" alt="HarmonyOS"/>
  <img src="https://img.shields.io/badge/WeChat-Mini%20Program-07C160" alt="WeChat"/>
  <img src="https://img.shields.io/badge/version-1.0.0-blue" alt="version"/>
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="license"/>
</p>

---

## 简介

**星枢令**是一款支持 TOTP 标准的双因素身份验证器，兼容所有支持 Google Authenticator 协议的平台（Gmail、GitHub、Microsoft、支付宝等）。验证码每 30 秒自动刷新，密钥仅存储在本地设备，从不上传服务器。

- **鸿蒙版**：原生 ArkTS 开发，适配鸿蒙系统设计规范，支持玻璃态悬浮导航
- **微信小程序版**：随时可用，无需安装，扫码即添加

---

## 功能特性

| 功能 | 说明 |
|------|------|
| 🔑 动态验证码 | TOTP 标准，每 30 秒刷新，倒计时环可视化 |
| 📷 扫码添加 | 相机扫码 / 相册识别二维码，一键导入 |
| ✍️ 手动输入 | 支持手动填写 Secret Key（Base32） |
| 🎨 10 款主题 | 海洋蓝、皇室紫、极光绿等，一键切换 |
| 💾 数据备份 | 加密导出 / 导入，换机无忧 |
| 🔒 本地优先 | 密钥不上传任何服务器，隐私安全 |
| 👆 手势操作 | 长按菜单、左滑删除（鸿蒙版） |
| 🔍 快速搜索 | 按品牌名 / 账号名实时过滤 |

---

## 平台架构

```
ArcaneKey/
├── harmonyos/          # 鸿蒙原生 App（ArkTS, HarmonyOS 6.1, API 23）
│   └── entry/src/main/ets/
│       ├── pages/      # 入口页（单页 + 所有 Modal Builder）
│       ├── views/      # HomeView / ScanView / ProfileView / FeedbackView
│       ├── components/ # TokenCard / CountdownRing / Logo
│       ├── model/      # Token 类型 + THEMES + BRAND_COLORS 常量
│       └── utils/      # TOTP / StorageUtil / CryptoUtil
│
├── miniprogram/        # 微信小程序
│   ├── pages/index/    # 单页架构，所有视图条件渲染
│   ├── components/     # bottom-nav / token-card / logo 等
│   └── utils/          # totp.js / storage.js / crypto.js
│
├── docs/               # GitHub Pages（隐私政策）
└── PRIVACY_POLICY.md   # 隐私政策原文
```

---

## 技术栈

### 鸿蒙版
- **语言**：ArkTS（HarmonyOS 6.1, API 23）
- **UI**：ArkUI 声明式框架，Tabs + Column + List
- **存储**：`@kit.ArkData` Preferences
- **扫码**：`@kit.ScanKit`
- **文件**：`@kit.CoreFileKit` picker + `@ohos.file.fs`
- **TOTP**：纯 TS 实现 HMAC-SHA1，无第三方依赖

### 微信小程序
- **语言**：JavaScript (ES6+)
- **存储**：`wx.getStorageSync` / `wx.setStorageSync`
- **扫码**：`wx.scanCode()`
- **云函数**：`sendFeedback`（nodemailer → 开发者邮箱）
- **TOTP**：纯 JS 实现 HMAC-SHA1

---

## 本地开发

### 鸿蒙版

1. 安装 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)
2. 打开 `harmonyos/` 目录
3. 连接鸿蒙真机或启动模拟器
4. 点击 Run

```bash
# 构建发布包（需配置签名）
Build → Build Hap(s)/APP(s) → Build APP(s)
```

### 微信小程序

1. 安装 [微信开发者工具](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)
2. 打开 `miniprogram/` 目录
3. 填入自己的 AppID（`project.config.json`）

---

## 隐私政策

所有 TOTP 密钥仅存储在用户设备本地，不上传任何服务器。

📄 [查看完整隐私政策](https://mengyuefeitian.github.io/ArcaneKey/privacy.html)

---

## 许可证

MIT License © 2026 ArcaneKey
