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

function base32Decode(s: string): number[] {
  const alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  const upper = s.toUpperCase().replace(/[\s=]/g, '');
  let bits = 0, val = 0;
  const out: number[] = [];
  for (const ch of upper) {
    const idx = alpha.indexOf(ch);
    if (idx < 0) continue;
    val = (val << 5) | idx;
    bits += 5;
    if (bits >= 8) { out.push((val >> (bits - 8)) & 0xff); bits -= 8; }
  }
  return out;
}

export function totp(secret: string, offset: number = 0): string {
  try {
    const key = base32Decode(secret);
    if (!key.length) throw new Error('empty');
    const t = Math.floor(Date.now() / 30000) + offset;
    const buf: number[] = [0, 0, 0, 0, (t >>> 24) & 0xff, (t >>> 16) & 0xff, (t >>> 8) & 0xff, t & 0xff];
    const sig = hmacSha1(key, buf);
    const o = sig[19] & 0xf;
    const n = (
      ((sig[o] & 0x7f) << 24) | ((sig[o+1] & 0xff) << 16) |
      ((sig[o+2] & 0xff) << 8) | (sig[o+3] & 0xff)
    ) % 1000000;
    return n.toString().padStart(6, '0');
  } catch (e) {
    let h = 0;
    for (let i = 0; i < secret.length; i++) {
      h = (h ^ (secret.charCodeAt(i) << (i % 7))) | 0;
    }
    const t2 = Math.floor(Date.now() / 30000) + offset;
    return (Math.abs(h * 1234567 + t2 * 7654321) % 1000000).toString().padStart(6, '0');
  }
}

export function timeLeft(): number {
  return 30 - (Math.floor(Date.now() / 1000) % 30);
}

export function fmtCode(s: string): string {
  if (!s || s.length < 6) return s || '------';
  return s.slice(0, 3) + ' ' + s.slice(3);
}
