import { util } from '@kit.ArkTS';

// ── UTF-8 encode / decode ───────────────────────────────────────
function utf8Encode(str: string): number[] {
  const bytes: number[] = [];
  for (let i = 0; i < str.length; i++) {
    const code = str.charCodeAt(i);
    if (code >= 0xD800 && code <= 0xDBFF && i + 1 < str.length) {
      const low = str.charCodeAt(i + 1);
      if (low >= 0xDC00 && low <= 0xDFFF) {
        const cp = ((code - 0xD800) << 10) + (low - 0xDC00) + 0x10000;
        bytes.push(0xF0 | (cp >> 18), 0x80 | ((cp >> 12) & 0x3F), 0x80 | ((cp >> 6) & 0x3F), 0x80 | (cp & 0x3F));
        i++;
        continue;
      }
    }
    if (code < 0x80) {
      bytes.push(code);
    } else if (code < 0x800) {
      bytes.push(0xC0 | (code >> 6), 0x80 | (code & 0x3F));
    } else {
      bytes.push(0xE0 | (code >> 12), 0x80 | ((code >> 6) & 0x3F), 0x80 | (code & 0x3F));
    }
  }
  return bytes;
}

function utf8Decode(bytes: number[]): string {
  let str = '';
  for (let i = 0; i < bytes.length; i++) {
    const b = bytes[i];
    if (b < 0x80) {
      str += String.fromCharCode(b);
    } else if (b < 0xE0) {
      str += String.fromCharCode(((b & 0x1F) << 6) | (bytes[i + 1] & 0x3F));
      i++;
    } else if (b < 0xF0) {
      str += String.fromCharCode(((b & 0x0F) << 12) | ((bytes[i + 1] & 0x3F) << 6) | (bytes[i + 2] & 0x3F));
      i += 2;
    } else {
      const cp = ((b & 0x07) << 18) | ((bytes[i + 1] & 0x3F) << 12) | ((bytes[i + 2] & 0x3F) << 6) | (bytes[i + 3] & 0x3F);
      const offset = cp - 0x10000;
      str += String.fromCharCode(0xD800 + (offset >> 10), 0xDC00 + (offset & 0x3FF));
      i += 3;
    }
  }
  return str;
}

// ── SHA-1 (copied from TOTP.ets for key derivation) ─────────────
function sha1(data: number[]): number[] {
  const msg: number[] = data.slice();
  const ml = msg.length * 8;
  msg.push(0x80);
  while ((msg.length % 64) !== 56) msg.push(0);
  for (let i = 7; i >= 0; i--) {
    msg.push(Math.floor(ml / Math.pow(2, i * 8)) & 0xff);
  }

  let h0 = 0x67452301, h1 = 0xEFCDAB89, h2 = 0x98BADCFE,
      h3 = 0x10325476, h4 = 0xC3D2E1F0;

  for (let bi = 0; bi < msg.length; bi += 64) {
    const w: number[] = [];
    for (let k = 0; k < 80; k++) w.push(0);
    for (let j = 0; j < 16; j++) {
      w[j] = ((msg[bi + j * 4] << 24) | (msg[bi + j * 4 + 1] << 16) |
              (msg[bi + j * 4 + 2] << 8) | msg[bi + j * 4 + 3]);
    }
    for (let j = 16; j < 80; j++) {
      const n = w[j-3] ^ w[j-8] ^ w[j-14] ^ w[j-16];
      w[j] = (n << 1) | (n >>> 31);
    }
    let a = h0, b = h1, c = h2, d = h3, e = h4;
    for (let j = 0; j < 80; j++) {
      let f: number, k: number;
      if (j < 20)      { f = (b & c) | (~b & d);          k = 0x5A827999; }
      else if (j < 40) { f = b ^ c ^ d;                    k = 0x6ED9EBA1; }
      else if (j < 60) { f = (b & c) | (b & d) | (c & d); k = 0x8F1BBCDC; }
      else             { f = b ^ c ^ d;                    k = 0xCA62C1D6; }
      const temp = (((a << 5) | (a >>> 27)) + f + e + k + w[j]) | 0;
      e = d; d = c; c = (b << 30) | (b >>> 2); b = a; a = temp;
    }
    h0 = (h0 + a) | 0; h1 = (h1 + b) | 0; h2 = (h2 + c) | 0;
    h3 = (h3 + d) | 0; h4 = (h4 + e) | 0;
  }

  const result: number[] = [];
  const hVals: number[] = [h0, h1, h2, h3, h4];
  for (let i = 0; i < hVals.length; i++) {
    const h = hVals[i];
    result.push((h >>> 24) & 0xff, (h >>> 16) & 0xff, (h >>> 8) & 0xff, h & 0xff);
  }
  return result;
}

function hmacSha1(keyBytes: number[], dataBytes: number[]): number[] {
  const blockSize = 64;
  const key: number[] = keyBytes.slice();
  if (key.length > blockSize) {
    const hashed = sha1(key);
    key.length = 0;
    for (let i = 0; i < hashed.length; i++) key.push(hashed[i]);
  }
  while (key.length < blockSize) key.push(0);
  const ipad: number[] = key.map((b: number) => b ^ 0x36);
  const opad: number[] = key.map((b: number) => b ^ 0x5c);
  const inner = sha1(ipad.concat(dataBytes));
  return sha1(opad.concat(inner));
}

// ── PBKDF2-HMAC-SHA1 key derivation ─────────────────────────────
function pbkdf2(password: string, salt: number[], iterations: number, keyLen: number): number[] {
  const passBytes = utf8Encode(password);
  let key: number[] = [];
  let block = 1;
  while (key.length < keyLen) {
    const blockBytes = [
      (block >>> 24) & 0xff, (block >>> 16) & 0xff,
      (block >>> 8) & 0xff, block & 0xff
    ];
    let u = hmacSha1(passBytes, salt.concat(blockBytes));
    let t = u.slice();
    for (let i = 1; i < iterations; i++) {
      u = hmacSha1(passBytes, u);
      for (let j = 0; j < t.length; j++) t[j] ^= u[j];
    }
    key = key.concat(t);
    block++;
  }
  return key.slice(0, keyLen);
}

function generateSalt(length: number): number[] {
  const salt: number[] = [];
  for (let i = 0; i < length; i++) {
    salt.push(Math.floor(Math.random() * 256));
  }
  return salt;
}

// ── Public API ──────────────────────────────────────────────────
// ENC3: PBKDF2 derives a fixed 32-byte key, then repeating XOR (fast, O(1) PBKDF2 cost)
// ENC2: PBKDF2 derives key of length = plaintext (legacy, kept for decryption only)
const MAGIC_V3 = [0x45, 0x4E, 0x43, 0x33]; // "ENC3"
const MAGIC_V2 = [0x45, 0x4E, 0x43, 0x32]; // "ENC2"

export function encryptData(data: object[], pass: string): string {
  const json = JSON.stringify(data);
  const jsonBytes = utf8Encode(json);
  const salt = generateSalt(16);
  const key = pbkdf2(pass, salt, 10000, 32); // fixed 32-byte key — always 2 PBKDF2 blocks
  const xored: number[] = [];
  for (let i = 0; i < jsonBytes.length; i++) {
    xored.push(jsonBytes[i] ^ key[i % 32]);
  }
  const out = MAGIC_V3.concat(salt).concat(xored);
  const arr = new Uint8Array(out);
  const helper = new util.Base64Helper();
  return helper.encodeToStringSync(arr);
}

export function decryptData(enc: string, pass: string): object[] {
  const helper = new util.Base64Helper();
  const decoded: Uint8Array = helper.decodeSync(enc);
  const bytes: number[] = [];
  for (let i = 0; i < decoded.length; i++) bytes.push(decoded[i]);

  // ENC3: fixed 32-byte key, repeating XOR
  if (bytes.length >= 4 &&
      bytes[0] === MAGIC_V3[0] && bytes[1] === MAGIC_V3[1] &&
      bytes[2] === MAGIC_V3[2] && bytes[3] === MAGIC_V3[3]) {
    const salt = bytes.slice(4, 20);
    const cipher = bytes.slice(20);
    const key = pbkdf2(pass, salt, 10000, 32);
    const plain: number[] = [];
    for (let i = 0; i < cipher.length; i++) {
      plain.push(cipher[i] ^ key[i % 32]);
    }
    return JSON.parse(utf8Decode(plain)) as object[];
  }

  // ENC2 legacy: full-length PBKDF2 key (backward compat for old backups)
  if (bytes.length >= 4 &&
      bytes[0] === MAGIC_V2[0] && bytes[1] === MAGIC_V2[1] &&
      bytes[2] === MAGIC_V2[2] && bytes[3] === MAGIC_V2[3]) {
    const salt = bytes.slice(4, 20);
    const cipher = bytes.slice(20);
    const key = pbkdf2(pass, salt, 10000, cipher.length);
    const plain: number[] = [];
    for (let i = 0; i < cipher.length; i++) {
      plain.push(cipher[i] ^ key[i]);
    }
    return JSON.parse(utf8Decode(plain)) as object[];
  }

  // Fallback: old simple XOR (no salt, no PBKDF2)
  const keyBytes = utf8Encode(pass);
  const jsonBytes: number[] = [];
  for (let i = 0; i < bytes.length; i++) {
    jsonBytes.push(bytes[i] ^ keyBytes[i % keyBytes.length]);
  }
  return JSON.parse(utf8Decode(jsonBytes)) as object[];
}

// ── 云同步专用：按记录+字段派生密钥加密（unionID + recordId + fieldName，无随机 salt） ──
// 与 encryptData/decryptData 不同：同一账号对同一 (recordId, fieldName) 每次加密结果必须一致，
// 供 SyncUtil.sync() 按 secret 做本地/云端去重比对（比对时用解密后的明文）。
// recordId + fieldName 参与派生是为了避免同一账号下所有记录/字段共用同一个密钥流（多次一密弱点）。
export function encryptFieldForCloud(value: string, unionId: string, recordId: string, fieldName: string): string {
  const salt = utf8Encode('ArcaneKey-cloud-sync-v1:' + recordId + ':' + fieldName);
  const key = pbkdf2(unionId, salt, 10000, 32);
  const valueBytes = utf8Encode(value);
  const xored: number[] = [];
  for (let i = 0; i < valueBytes.length; i++) {
    xored.push(valueBytes[i] ^ key[i % 32]);
  }
  const arr = new Uint8Array(xored);
  const helper = new util.Base64Helper();
  return helper.encodeToStringSync(arr);
}

export function decryptFieldForCloud(enc: string, unionId: string, recordId: string, fieldName: string): string {
  const salt = utf8Encode('ArcaneKey-cloud-sync-v1:' + recordId + ':' + fieldName);
  const key = pbkdf2(unionId, salt, 10000, 32);
  const helper = new util.Base64Helper();
  const decoded: Uint8Array = helper.decodeSync(enc);
  const plain: number[] = [];
  for (let i = 0; i < decoded.length; i++) {
    plain.push(decoded[i] ^ key[i % 32]);
  }
  return utf8Decode(plain);
}
