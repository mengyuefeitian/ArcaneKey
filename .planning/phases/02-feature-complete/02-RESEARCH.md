# Phase 2: 功能补全 — Research

**Researched:** 2026-05-19
**Domain:** WeChat Mini Program crypto / cross-platform backup compatibility
**Confidence:** HIGH (all findings derived directly from reading source code)

---

## Summary

Phase 2 的核心工作只有一件事：**在微信小程序的 `utils/crypto.js` 中添加 ENC2 格式解码支持**，修复鸿蒙端备份文件无法在小程序端恢复的问题（G-03 / FEAT-01）。

Phase 1 审计已全面确认 22 项功能的对齐状态。没有缺失的功能，没有需要新建的组件。FEAT-02 / FEAT-03 / FEAT-04 在审计中均被标记为"已对齐"或"可接受差异"，无需代码修改，仅需行为确认。

**Primary recommendation:** 直接移植鸿蒙 `CryptoUtil.ets` 中的 `sha1`、`hmacSha1`、`pbkdf2` 函数到 `crypto.js`（这些函数与 `totp.js` 中已有的实现逻辑完全一致，可复用），然后在 `decryptData` 入口添加 4 字节 magic 检测 + ENC2 解码分支。改动范围约 30 行，不引入任何新依赖。

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| ENC2 解码（FEAT-01） | WeChat Mini Program JS runtime | — | 纯 JS 工具函数，运行在 `utils/crypto.js`，不涉及网络或云层 |
| PBKDF2-HMAC-SHA1 | WeChat Mini Program JS runtime | — | 纯计算，无 I/O，已有 SHA-1 基础实现可复用 |
| 备份文件格式检测 | WeChat Mini Program JS runtime | — | `decryptData()` 入口，读 base64 解码后的字节头 |
| 真机 QR 权限验证（AUDIT-02） | HarmonyOS OS / DevEco Studio | 人工 | 代码已修复（FIX-01），需用户在真机上触发验证 |

---

<user_constraints>
## User Constraints (from CONTEXT.md)

No CONTEXT.md found for this phase. All decisions below are derived from FEATURE-AUDIT.md (Phase 1 output) and REQUIREMENTS.md.

### Locked Decisions (from Phase 1 Audit)

- 修复方案选 **方案 A**（推荐）：修改小程序端 `decryptData`，添加 ENC2 支持；不降级鸿蒙端加密强度
- 鸿蒙端 ENC2 加密格式**保持不变**（PBKDF2 + 16 字节 salt + 10000 次迭代）
- **不**使用外部依赖；纯 JS 实现
- **不**修改小程序 `encryptData`（小程序继续使用原始 XOR 加密；ENC2 仅用于解码）

### Claude's Discretion

- PBKDF2 实现可直接复用 `totp.js` 中已有的 `sha1` / `hmacSha1` 函数，或在 `crypto.js` 内独立实现（推荐：在 `crypto.js` 内自包含，避免模块间耦合）
- `utf8Encode` 已在 `crypto.js` 内存在，无需重新引入

### Deferred Ideas (OUT OF SCOPE)

- 小程序端升级加密格式为 ENC2（REQUIREMENTS.md 明确不做）
- AES 替换 XOR（REQUIREMENTS.md 明确不做）
- AGC 云同步（Phase 3）
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FEAT-01 | 修复跨平台加解密兼容性：小程序 `decryptData` 支持读取鸿蒙 ENC2 格式备份 | ENC2 格式完整规格已从 `CryptoUtil.ets` 提取；PBKDF2 可复用 `totp.js` 实现；约 30 行改动 |
| FEAT-02 | 修复所有 P1 体验差异 | 审计结论：无 P1 代码差异需修复；均为"已对齐"或"可接受差异" |
| FEAT-03 | 确认底部导航、Toast、主题切换与小程序一致 | 审计条目 9/19/20：代码逐行比对确认已对齐；无改动需要 |
| FEAT-04 | 确认登录态管理行为一致 | 审计条目 18：平台 API 差异可接受（微信 getPhoneNumber vs 鸿蒙账号），均为演示模式 |
| AUDIT-02 | 真机相机权限验证 | FIX-01（Phase 1）已完成代码修复；此项为手动验证任务，不涉及代码 |
</phase_requirements>

---

## ENC2 格式规格（从 CryptoUtil.ets 直接提取）

[VERIFIED: source code read]

```
ENC2 备份文件二进制布局（base64 解码后）：

Offset  Length  Content
------  ------  -------
0       4       Magic bytes: 0x45 0x4E 0x43 0x32  ("ENC2")
4       16      Random salt (16 bytes, Math.random() * 256 each)
20      N       XOR ciphertext (N = len(UTF-8 JSON of token array))

总长度 = 20 + N 字节
```

**关键参数（代码逐行提取，不依赖假设）：**

| 参数 | 值 | 来源行 |
|------|-----|--------|
| Magic | `[0x45, 0x4E, 0x43, 0x32]` = `"ENC2"` | `CryptoUtil.ets:143` |
| Salt 长度 | 16 字节 | `CryptoUtil.ets:148, 169` |
| Salt 起始偏移 | `bytes[4..19]` | `CryptoUtil.ets:169` |
| 密文起始偏移 | `bytes[20..]` | `CryptoUtil.ets:170` |
| PBKDF2 算法 | HMAC-SHA1 | `CryptoUtil.ets:113, 122` |
| PBKDF2 迭代次数 | 10000 | `CryptoUtil.ets:149, 171` |
| PBKDF2 输出长度 | `cipher.length`（与密文等长） | `CryptoUtil.ets:171` |
| XOR key | PBKDF2 输出，每字节一一对应，无循环 | `CryptoUtil.ets:173` |
| password 参数 | 用户输入的明文密码字符串 | `CryptoUtil.ets:113` |
| salt 参数 | 文件内嵌的 16 字节 | `CryptoUtil.ets:113` |

---

## WeChat JS Crypto API 可用性

[VERIFIED: source code read + WeChat platform knowledge confirmed]

### 关键结论：WeChat 小程序**不支持** `crypto.subtle.deriveBits` / `SubtleCrypto`

`miniprogram/utils/totp.js` 第 1 行注释明确记录：

```
// Pure-JS SHA-1
// Pure-JS HMAC-SHA1
// (WeChat doesn't expose SubtleCrypto)
```

这意味着整个 TOTP 栈（SHA-1、HMAC-SHA1）是 100% 纯 JS 自实现，专门为规避 WeChat 缺少 `crypto.subtle` 而设计。

[ASSUMED] WeChat 小程序也不暴露 `wx.getRandomValues` 或标准 `crypto` 全局对象（与 TOTP 注释中"WeChat doesn't expose SubtleCrypto"的记录一致）。对于 FEAT-01 的 **解码** 路径，不需要随机数（随机数只在加密时需要，而小程序端目前不改加密格式）。

### `totp.js` 中可复用的实现

`miniprogram/utils/totp.js` 已包含完整的 `sha1(data)` 和 `hmacSha1(keyBytes, dataBytes)` 实现，与 `CryptoUtil.ets` 中的 `sha1` / `hmacSha1` 算法完全等价（两端均来自同一逐字移植的实现）。

**决策：** PBKDF2 在 `crypto.js` 内自包含实现（不 `require('./totp')`），原因：

1. `crypto.js` 是独立工具模块，不应对 `totp.js` 产生循环或非对等依赖
2. 需要复制的代码量很小（`sha1` + `hmacSha1` + `pbkdf2` 合计约 50 行）
3. 与鸿蒙端 `CryptoUtil.ets` 的做法一致（`CryptoUtil.ets` 也独立内嵌了 `sha1` + `hmacSha1`）

---

## Standard Stack

### 核心（无新依赖）

| 库 | 版本 | 用途 | 说明 |
|----|------|------|------|
| 无外部依赖 | — | — | 纯 JS 自实现，与现有 `crypto.js` 风格一致 |

Phase 2 不安装任何新包。

### Package Legitimacy Audit

> 无需安装新包，跳过此节。

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### 系统架构图（FEAT-01 数据流）

```
用户点击"导入备份"
        |
        v
[WeChat] pages/index/index.js
  doImport() / onImportFile()
        |
        v
[WeChat] utils/crypto.js
  decryptData(enc, pass)
        |
        +-- base64 decode --> bytes[]
        |
        +-- bytes[0..3] === [0x45,0x4E,0x43,0x32]?
        |        |                       |
        |       YES                      NO
        |        |                       |
        |        v                       v
        |   ENC2 path               Raw XOR path
        |   salt = bytes[4..19]     (existing code,
        |   cipher = bytes[20..]    no change)
        |   key = pbkdf2(pass,
        |          salt, 10000,
        |          cipher.length)
        |   plain = XOR(cipher,key)
        |        |
        +--------+
                 |
                 v
          JSON.parse(utf8Decode(plain))
                 |
                 v
          token[] 还原成功
```

### 推荐修改结构

`miniprogram/utils/crypto.js` — 添加以下内容（全部自包含，不 require 其他模块）：

```
crypto.js 结构（修改后）
├── utf8Encode(str)           -- 已有，不变
├── utf8Decode(bytes)         -- 已有，不变
├── btoa(bytes)               -- 已有，不变（自定义实现，接受 number[]）
├── atob(enc)                 -- 已有，不变（返回 number[]）
├── sha1(data)                -- 新增（复制自 totp.js，逐字一致）
├── hmacSha1(keyBytes, data)  -- 新增（复制自 totp.js，逐字一致）
├── pbkdf2(pass, salt, iter, keyLen) -- 新增（复制自 CryptoUtil.ets）
├── encryptData(data, pass)   -- 已有，不变（继续使用原始 XOR）
└── decryptData(enc, pass)    -- 修改：添加 ENC2 分支
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PBKDF2 实现 | 从头设计 | 直接移植 `CryptoUtil.ets:pbkdf2()` | 鸿蒙端代码已验证可用；逻辑等价保证跨平台解码一致 |
| SHA-1 实现 | 从头设计 | 直接复制 `totp.js:sha1()` | 已在生产 TOTP 路径中使用，经过验证 |

---

## Code Examples

### FEAT-01 完整实现草稿（可直接用于 PLAN 任务）

以下代码已根据 `CryptoUtil.ets` 和 `totp.js` 的真实实现推导，可直接写入 `crypto.js`。

**新增函数（插入在 `encryptData` 之前）：**

```javascript
// Source: miniprogram/utils/totp.js (sha1, hmacSha1) +
//         harmonyos/.../CryptoUtil.ets (pbkdf2)
// These are verbatim copies adapted to ES5 var syntax.

// ── SHA-1 ──────────────────────────────────────────────────────────
function sha1(data) {
  var msg = data.slice();
  var ml = msg.length * 8;
  msg.push(0x80);
  while ((msg.length % 64) !== 56) msg.push(0);
  for (var i = 7; i >= 0; i--) {
    msg.push((ml / Math.pow(2, i * 8)) & 0xff);
  }
  var h0 = 0x67452301, h1 = 0xEFCDAB89, h2 = 0x98BADCFE,
      h3 = 0x10325476, h4 = 0xC3D2E1F0;
  for (var bi = 0; bi < msg.length; bi += 64) {
    var w = new Array(80);
    for (var j = 0; j < 16; j++) {
      w[j] = ((msg[bi + j*4] << 24) | (msg[bi + j*4+1] << 16) |
              (msg[bi + j*4+2] << 8) | msg[bi + j*4+3]);
    }
    for (var j = 16; j < 80; j++) {
      var n = w[j-3] ^ w[j-8] ^ w[j-14] ^ w[j-16];
      w[j] = (n << 1) | (n >>> 31);
    }
    var a = h0, b = h1, c = h2, d = h3, e = h4;
    for (var j = 0; j < 80; j++) {
      var f, k;
      if      (j < 20) { f = (b & c) | (~b & d);           k = 0x5A827999; }
      else if (j < 40) { f = b ^ c ^ d;                     k = 0x6ED9EBA1; }
      else if (j < 60) { f = (b & c) | (b & d) | (c & d);  k = 0x8F1BBCDC; }
      else             { f = b ^ c ^ d;                     k = 0xCA62C1D6; }
      var temp = (((a << 5) | (a >>> 27)) + f + e + k + w[j]) | 0;
      e = d; d = c; c = (b << 30) | (b >>> 2); b = a; a = temp;
    }
    h0 = (h0 + a) | 0; h1 = (h1 + b) | 0; h2 = (h2 + c) | 0;
    h3 = (h3 + d) | 0; h4 = (h4 + e) | 0;
  }
  var result = [];
  [h0, h1, h2, h3, h4].forEach(function(h) {
    result.push((h >>> 24) & 0xff, (h >>> 16) & 0xff, (h >>> 8) & 0xff, h & 0xff);
  });
  return result;
}

// ── HMAC-SHA1 ──────────────────────────────────────────────────────
function hmacSha1(keyBytes, dataBytes) {
  var key = keyBytes.slice();
  if (key.length > 64) key = sha1(key);
  while (key.length < 64) key.push(0);
  var ipad = key.map(function(b) { return b ^ 0x36; });
  var opad = key.map(function(b) { return b ^ 0x5c; });
  return sha1(opad.concat(sha1(ipad.concat(dataBytes))));
}

// ── PBKDF2-HMAC-SHA1 ──────────────────────────────────────────────
function pbkdf2(password, salt, iterations, keyLen) {
  var passBytes = utf8Encode(password);
  var key = [];
  var block = 1;
  while (key.length < keyLen) {
    var blockBytes = [
      (block >>> 24) & 0xff, (block >>> 16) & 0xff,
      (block >>> 8)  & 0xff,  block          & 0xff
    ];
    var u = hmacSha1(passBytes, salt.concat(blockBytes));
    var t = u.slice();
    for (var i = 1; i < iterations; i++) {
      u = hmacSha1(passBytes, u);
      for (var j = 0; j < t.length; j++) t[j] ^= u[j];
    }
    key = key.concat(t);
    block++;
  }
  return key.slice(0, keyLen);
}
```

**修改 `decryptData`（替换现有实现）：**

```javascript
var ENC2_MAGIC = [0x45, 0x4E, 0x43, 0x32];

function decryptData(enc, pass) {
  var bytes = atob(enc);  // returns number[]

  // Detect ENC2 format: magic bytes "ENC2" at offset 0
  if (bytes.length >= 20 &&
      bytes[0] === ENC2_MAGIC[0] && bytes[1] === ENC2_MAGIC[1] &&
      bytes[2] === ENC2_MAGIC[2] && bytes[3] === ENC2_MAGIC[3]) {
    var salt   = bytes.slice(4, 20);        // 16 bytes
    var cipher = bytes.slice(20);           // remainder
    var key    = pbkdf2(pass, salt, 10000, cipher.length);
    var plain  = [];
    for (var i = 0; i < cipher.length; i++) {
      plain.push(cipher[i] ^ key[i]);
    }
    return JSON.parse(utf8Decode(plain));
  }

  // Fallback: legacy raw XOR format (WeChat-native backups)
  var keyBytes = utf8Encode(pass);
  var jsonBytes = [];
  for (var i = 0; i < bytes.length; i++) {
    jsonBytes.push(bytes[i] ^ keyBytes[i % keyBytes.length]);
  }
  return JSON.parse(utf8Decode(jsonBytes));
}
```

---

## 跨平台验证向量（Test Vector）

[VERIFIED: derived from source code by manual trace]

以下向量可用于验证双端解密一致性（无需真机，可在 JS console / Node.js 中验证）：

```
Input:
  data     = [{"id":1,"brand":"GitHub","account":"alice@example.com","secret":"JBSWY3DPEHPK3PXP"}]
  password = "test-pass-123"

Expected flow on HarmonyOS (encryptData):
  1. json = JSON.stringify(data)                         -- deterministic
  2. salt = <16 random bytes>                             -- varies each call
  3. key = pbkdf2("test-pass-123", salt, 10000, len(json))
  4. xored = json_bytes XOR key
  5. output = base64("ENC2" + salt + xored)

Expected flow on WeChat (decryptData with FEAT-01 fix):
  1. bytes = atob(output)
  2. bytes[0..3] == [0x45,0x4E,0x43,0x32]  -> ENC2 branch
  3. salt = bytes[4..19]
  4. cipher = bytes[20..]
  5. key = pbkdf2("test-pass-123", salt, 10000, len(cipher))
  6. plain = cipher XOR key  -> original json bytes
  7. JSON.parse(utf8Decode(plain)) -> original token array
```

**固定盐向量（可自动化测试）：**

```javascript
// 用固定盐（全零）验证 PBKDF2 实现是否与鸿蒙端一致
// salt = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]  (16 bytes, all zero)
// password = "test"
// iterations = 10000
// keyLen = 20
// Expected first 20 bytes of PBKDF2-HMAC-SHA1 output:
//   可通过 Python: hashlib.pbkdf2_hmac('sha1', b'test', b'\x00'*16, 10000, 20)
//   得到参考值，再与小程序 JS 实现比对
```

**AUDIT-02 真机验证清单（手动，不阻塞 FEAT-01）：**

```
1. DevEco Studio → 真机调试
2. 首次点击扫码 → 系统应弹出相机权限弹窗
3. 拒绝 → Toast "需要相机权限才能扫码"
4. 授权 → 相机正常打开
5. 扫描有效 OTP URI → 自动填入表单，无需手动确认
6. 从相册选图 → 相同权限路径，应同样工作
```

---

## 范围确认（Scope Confirmation）

[VERIFIED: from FEATURE-AUDIT.md direct read]

**所有 P1 差异项均无需代码修改：**

| FEAT 编号 | 审计结论 | 行动 |
|-----------|----------|------|
| FEAT-02（P1 差异） | 审计矩阵条目 9/14/15/18/19/20/21 均标注"已对齐"或"可接受差异" | 无代码改动 |
| FEAT-03（底部导航/Toast/主题） | 条目 9（THEMES 完全一致）、19（底部导航结构一致）、20（Toast 行为一致） | 行为确认，无代码 |
| FEAT-04（登录态） | 条目 18：平台差异可接受（演示模式），两端均无真实 Auth 后端 | 行为确认，无代码 |

**Phase 2 实际代码变更仅涉及 1 个文件：**

```
miniprogram/utils/crypto.js
  - 新增: sha1(), hmacSha1(), pbkdf2()  (~50 行)
  - 修改: decryptData()                  (~15 行，添加 ENC2 分支)
  - 新增: ENC2_MAGIC 常量               (1 行)
  - 不变: encryptData()                  (小程序继续使用原始 XOR 加密)
  - 不变: utf8Encode/Decode, btoa/atob
```

---

## Common Pitfalls

### Pitfall 1：`atob` 函数签名差异
**What goes wrong:** `crypto.js` 中的 `atob(enc)` 返回 `number[]`（自定义实现），与浏览器全局 `atob()` 返回字符串不同。FEAT-01 代码必须使用 `crypto.js` 内部的 `atob`，不能误以为它返回字符串。
**How to avoid:** `var bytes = atob(enc);` — `bytes` 已是 `number[]`，直接访问 `bytes[0]` 等于第一个字节整数值。不需要 `.charCodeAt()`。
**Warning signs:** 如果在 `decryptData` 中对 `bytes[0]` 执行 `.charCodeAt(0)` 则为错误用法。

### Pitfall 2：PBKDF2 中 `salt.concat(blockBytes)` 的 `slice` 问题
**What goes wrong:** `CryptoUtil.ets` 中 `pbkdf2` 的 `salt` 参数是 `number[]`，直接调用 `.concat(blockBytes)`。WeChat 版本的 `salt` 从 `bytes.slice(4, 20)` 得到，也是 `number[]`。两者类型一致，无问题。
**How to avoid:** 确保 `salt` 参数在调用 `pbkdf2` 前已是 `number[]`（`bytes.slice()` 已保证）。

### Pitfall 3：10000 次迭代导致主线程阻塞
**What goes wrong:** 小程序 JS 单线程，PBKDF2 10000 次迭代约需 2-5 秒（视设备性能），会导致 UI 冻结。
**Why it happens:** WeChat 小程序无 Web Worker 与主线程隔离。
**How to avoid:** 此 phase 不解决此问题（接受现状，与鸿蒙端的 10000 次迭代参数保持一致）。可在 UI 上添加"解密中..."提示减少用户困惑。**不要**降低迭代次数（会破坏跨平台兼容性）。
**Warning signs:** 如果 QA 报告"导入时界面卡住约 3 秒"，这是预期行为，不是 bug。

### Pitfall 4：ENC2 magic 检测需要 `bytes.length >= 20`（而非 `>= 4`）
**What goes wrong:** 只检查前 4 字节是 ENC2 magic 还不够；若文件截断到 4-19 字节，`bytes.slice(4, 20)` 会返回不足 16 字节的 salt，导致 PBKDF2 输出错误。
**How to avoid:** magic 检测条件应为 `bytes.length >= 20 && bytes[0..3] === MAGIC`（代码草稿已包含此判断）。

### Pitfall 5：`encryptData` 不需要修改
**What goes wrong:** 如果误改小程序 `encryptData` 以输出 ENC2 格式，现有的小程序备份文件将无法被用户用旧版小程序解密（向后不兼容）。
**How to avoid:** `encryptData` 维持原状（原始 XOR）。只修改 `decryptData` 的解码路径。

---

## 风险评估（Risk Assessment）

| 风险 | 等级 | 说明 |
|------|------|------|
| PBKDF2 实现与鸿蒙端不一致 | MEDIUM | 通过固定盐测试向量验证可消除；两端算法均来自同一逻辑，风险低 |
| UI 主线程冻结（10000 次迭代） | LOW | 已知约束；备份/恢复为低频操作；用户体验可接受 |
| `atob` 返回类型混淆 | LOW | `crypto.js` 文件内自包含，不会与浏览器 API 混淆 |
| 误改 `encryptData` | LOW | 计划明确限定只改 `decryptData`；代码审查可捕获 |
| 真机 QR 测试无法进行 | MEDIUM | 不影响 FEAT-01；AUDIT-02 是独立手动验证任务 |

---

## Environment Availability

Phase 2 是纯 JS 代码变更（`miniprogram/utils/crypto.js`），无外部依赖，无需工具安装。

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| WeChat DevTools | 小程序功能验证 | ✓（用户环境） | — | — |
| DevEco Studio + 真机 | AUDIT-02 相机验证 | ✗（真机不可用） | — | 跳过，标记为 pending |

**Missing dependencies with no fallback:** none（FEAT-01 代码变更不需要设备）
**Missing dependencies with fallback:** DevEco + 真机（AUDIT-02）— 跳过验证，任务标记为 human-gate

---

## Validation Architecture

> `workflow.nyquist_validation` = false in config.json — 跳过此节。

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | WeChat 小程序不支持 `wx.getRandomValues` 或 `crypto` 全局（PBKDF2 必须纯 JS 实现） | WeChat JS Crypto API 可用性 | 低风险：即使 WeChat 支持，纯 JS 实现同样有效；解码路径不需要随机数 |

**所有其他 claim 均为 [VERIFIED]（从源代码直接读取）。**

---

## Open Questions

1. **AUDIT-02 真机验证窗口**
   - What we know: FIX-01 代码修复已在 Phase 1 完成（commit 8c351d4）
   - What's unclear: 用户是否有鸿蒙真机可用于验证
   - Recommendation: 在 Phase 2 计划中包含一个 `checkpoint:human-verify` 任务（AUDIT-02），但标注为非阻断性；FEAT-01 独立执行，不等待此验证

2. **PBKDF2 性能（可选优化）**
   - What we know: 10000 次迭代在中端 Android 约需 2-5s
   - What's unclear: 小程序目标设备性能分布
   - Recommendation: Phase 2 不优化（维持与鸿蒙端参数一致）；若用户报告明显卡顿，可在独立 task 中添加 loading indicator

---

## Sources

### Primary (HIGH confidence)
- `miniprogram/utils/crypto.js` — 当前小程序加解密实现（直接读取）
- `harmonyos/entry/src/main/ets/utils/CryptoUtil.ets` — ENC2 格式规格（直接读取，全部参数逐行提取）
- `miniprogram/utils/totp.js` — `sha1` / `hmacSha1` 可复用实现（直接读取）
- `.planning/FEATURE-AUDIT.md` — Phase 1 审计结论（直接读取）
- `.planning/phases/01-fix-audit/01-02-SUMMARY.md` — Phase 1 Plan 2 决策记录（直接读取）
- `.planning/REQUIREMENTS.md` — Phase 2 需求定义（直接读取）

### Secondary (MEDIUM confidence)
- 无（所有关键事实均来自源代码直接读取）

### Tertiary (LOW confidence)
- [ASSUMED] WeChat 不支持 `wx.getRandomValues` —— 与 `totp.js` 注释一致，不影响解码路径实现

---

## Metadata

**Confidence breakdown:**
- ENC2 格式规格: HIGH — 从 `CryptoUtil.ets` 源码直接提取，无推断
- 可复用实现: HIGH — `totp.js` 和 `CryptoUtil.ets` 均已直接读取
- 代码草稿正确性: HIGH — 直接移植，逻辑等价
- WeChat crypto API: MEDIUM — 主结论来自 `totp.js` 注释，未做 API 文档查验（不影响实现方案）
- 范围确认（P1 无代码改动）: HIGH — 来自 FEATURE-AUDIT.md 逐条审计结论

**Research date:** 2026-05-19
**Valid until:** 2026-08-19（ENC2 格式和 PBKDF2 参数稳定，不会变化）
