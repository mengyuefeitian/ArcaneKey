(function () {
  function base32Decode(s) {
    const alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    s = s.toUpperCase().replace(/\s|=/g, '');
    let bits = 0, val = 0;
    const out = [];
    for (const c of s) {
      const i = alpha.indexOf(c);
      if (i < 0) continue;
      val = (val << 5) | i;
      bits += 5;
      if (bits >= 8) { out.push((val >> (bits - 8)) & 0xff); bits -= 8; }
    }
    return new Uint8Array(out);
  }

  async function totp(secret, offset) {
    offset = offset || 0;
    try {
      const key = base32Decode(secret);
      if (!key.length) throw new Error('empty');
      const t = Math.floor(Date.now() / 30000) + offset;
      const buf = new ArrayBuffer(8);
      new DataView(buf).setUint32(4, t >>> 0, false);
      const ck = await crypto.subtle.importKey(
        'raw', key.buffer, { name: 'HMAC', hash: 'SHA-1' }, false, ['sign']
      );
      const sig = new Uint8Array(await crypto.subtle.sign('HMAC', ck, buf));
      const o = sig[19] & 0xf;
      const n = (
        ((sig[o] & 0x7f) << 24) | ((sig[o + 1] & 0xff) << 16) |
        ((sig[o + 2] & 0xff) << 8) | (sig[o + 3] & 0xff)
      ) % 1000000;
      return n.toString().padStart(6, '0');
    } catch (_) {
      // Fallback deterministic code for invalid secrets (demo purposes)
      const h = [...secret].reduce((a, c, i) => (a ^ (c.charCodeAt(0) << (i % 7))) | 0, 0);
      const t = Math.floor(Date.now() / 30000) + offset;
      return (Math.abs(h * 1234567 + t * 7654321) % 1000000).toString().padStart(6, '0');
    }
  }

  function timeLeft() {
    return 30 - (Math.floor(Date.now() / 1000) % 30);
  }

  window.TOTP = { totp, timeLeft };
})();
