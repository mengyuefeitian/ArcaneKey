const { useState, useEffect, useRef, useCallback } = React;

// ─── Constants ────────────────────────────────────────────────────────────────

const THEMES = [
  { name: '海洋蓝', color: 'oklch(0.62 0.20 250)' },
  { name: '皇室紫', color: 'oklch(0.62 0.20 300)' },
  { name: '玫瑰粉', color: 'oklch(0.62 0.20 340)' },
  { name: '热情红', color: 'oklch(0.58 0.22 15)'  },
  { name: '暖橙色', color: 'oklch(0.65 0.18 47)'  },
  { name: '琥珀金', color: 'oklch(0.70 0.15 82)'  },
  { name: '森林绿', color: 'oklch(0.60 0.18 148)' },
  { name: '青绿色', color: 'oklch(0.60 0.16 188)' },
  { name: '天空蓝', color: 'oklch(0.62 0.18 222)' },
  { name: '深靛蓝', color: 'oklch(0.58 0.20 278)' },
];

const BRAND_COLORS = {
  Google: '#EA4335', Microsoft: '#00A4EF', GitHub: '#e6edf3',
  Apple: '#aaaaaa', Twitter: '#1DA1F2', 'X (Twitter)': '#e7e9ea',
  Dropbox: '#0061FF', Facebook: '#1877F2', Amazon: '#FF9900',
  Slack: '#4A154B', Discord: '#5865F2', Notion: '#ffffff',
  Stripe: '#635BFF', Figma: '#F24E1E', LinkedIn: '#0A66C2',
  Steam: '#c6d4df', Netflix: '#E50914', Spotify: '#1DB954',
};

const INITIAL_TOKENS = [
  { id: '1', brand: 'Google',    account: 'alice@gmail.com',    secret: 'JBSWY3DPEHPK3PXP' },
  { id: '2', brand: 'Microsoft', account: 'alice@outlook.com',  secret: 'MFRA22LDNRSXG5AP' },
  { id: '3', brand: 'GitHub',    account: 'alicedev',           secret: 'NZXSAYLBNFXWY3DP' },
  { id: '4', brand: 'Apple',     account: 'alice@icloud.com',   secret: 'OJSXI33PNZQXE5LN' },
  { id: '5', brand: 'Stripe',    account: 'alice@company.com',  secret: 'KRUGS4TANFXGK4TF' },
  { id: '6', brand: 'Discord',   account: 'alice#0042',         secret: 'LBSWY3DPEHPK3PXP' },
];

// ─── Utils ────────────────────────────────────────────────────────────────────

function showToast(setToast, msg) {
  setToast(msg);
  setTimeout(() => setToast(null), 2200);
}

async function copyText(text) {
  try { await navigator.clipboard.writeText(text); return true; }
  catch (_) { return false; }
}

function encryptData(data, pass) {
  const json = JSON.stringify(data);
  const key = [...pass].map(c => c.charCodeAt(0));
  return btoa([...json].map((c, i) =>
    String.fromCharCode(c.charCodeAt(0) ^ key[i % key.length])
  ).join(''));
}

function decryptData(enc, pass) {
  const raw = atob(enc);
  const key = [...pass].map(c => c.charCodeAt(0));
  return JSON.parse([...raw].map((c, i) =>
    String.fromCharCode(c.charCodeAt(0) ^ key[i % key.length])
  ).join(''));
}

function fmtCode(s) { return s.slice(0, 3) + ' ' + s.slice(3); }

// ─── Icons ────────────────────────────────────────────────────────────────────

const HomeIcon = ({ s = 22 }) => (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="currentColor">
    <path d="M11.03 2.59a1.5 1.5 0 011.94 0l7.5 6.363A1.5 1.5 0 0121 10.097V19.5A1.5 1.5 0 0119.5 21h-4a1.5 1.5 0 01-1.5-1.5v-4h-4v4A1.5 1.5 0 018.5 21h-4A1.5 1.5 0 013 19.5v-9.403a1.5 1.5 0 01.53-1.144l7.5-6.363z"/>
  </svg>
);
const ScanIcon = ({ s = 22 }) => (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M3 7V5a2 2 0 012-2h2M17 3h2a2 2 0 012 2v2M21 17v2a2 2 0 01-2 2h-2M7 21H5a2 2 0 01-2-2v-2"/>
    <rect x="7" y="7" width="10" height="10" rx="1.5"/>
  </svg>
);
const MeIcon = ({ s = 22 }) => (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="currentColor">
    <path d="M12 12a5 5 0 100-10 5 5 0 000 10zm-7 9a7 7 0 1114 0H5z"/>
  </svg>
);
const SearchIcon = ({ s = 17 }) => (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
    <circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/>
  </svg>
);
const XIcon = ({ s = 16 }) => (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
    <path d="M18 6L6 18M6 6l12 12"/>
  </svg>
);
const ChevronR = ({ s = 15 }) => (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
    <path d="M9 18l6-6-6-6"/>
  </svg>
);
const CheckIcon = ({ s = 16 }) => (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
    <path d="M20 6L9 17l-5-5"/>
  </svg>
);
const CopyIcon = ({ s = 14 }) => (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
    <rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/>
  </svg>
);

// ─── Logo ─────────────────────────────────────────────────────────────────────

function Logo({ brand, size = 40 }) {
  const col = BRAND_COLORS[brand] || 'oklch(0.6 0.12 250)';
  const letter = (brand || '?')[0].toUpperCase();
  const bg = col === '#ffffff' || col === '#e7e9ea' || col === '#e6edf3'
    ? 'rgba(255,255,255,0.08)' : col + '1a';
  const border = col === '#ffffff' || col === '#e7e9ea' || col === '#e6edf3'
    ? 'rgba(255,255,255,0.15)' : col + '44';
  return (
    <div style={{
      width: size, height: size, borderRadius: Math.round(size * 0.28),
      background: bg, border: `1.5px solid ${border}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      flexShrink: 0, color: col,
      fontSize: Math.round(size * 0.42), fontWeight: 800, fontFamily: 'system-ui',
      letterSpacing: -0.5,
    }}>
      {letter}
    </div>
  );
}

// ─── CountdownRing ────────────────────────────────────────────────────────────

function CountdownRing({ timeLeft, accent }) {
  const r = 12, circ = 2 * Math.PI * r;
  const col = accent;
  return (
    <div style={{ position: 'relative', width: 34, height: 34, flexShrink: 0 }}>
      <svg width="34" height="34" style={{ position: 'absolute', top: 0, left: 0, transform: 'rotate(-90deg)' }}>
        <circle cx="17" cy="17" r={r} fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth="2.5"/>
        <circle cx="17" cy="17" r={r} fill="none" stroke={col} strokeWidth="2.5"
          strokeDasharray={`${circ * timeLeft / 30} ${circ}`} strokeLinecap="round"/>
      </svg>
      <span style={{
        position: 'absolute', inset: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 9, fontWeight: 700, color: accent, fontFamily: 'system-ui',
      }}>
        {timeLeft}
      </span>
    </div>
  );
}

// ─── Toast ────────────────────────────────────────────────────────────────────

function Toast({ msg }) {
  if (!msg) return null;
  return (
    <div style={{
      position: 'absolute', bottom: 96, left: '50%', transform: 'translateX(-50%)',
      background: 'rgba(22,22,30,0.96)', color: '#f0f0f5', padding: '9px 20px',
      borderRadius: 22, fontSize: 13, whiteSpace: 'nowrap', fontWeight: 500,
      boxShadow: '0 4px 24px rgba(0,0,0,0.55)', zIndex: 9999,
      backdropFilter: 'blur(16px)',
      border: '1px solid rgba(255,255,255,0.08)',
      display: 'flex', alignItems: 'center', gap: 7,
    }}>
      <CheckIcon s={13}/> {msg}
    </div>
  );
}

// ─── TokenCard ────────────────────────────────────────────────────────────────

function TokenCard({ token, otp, timeLeft, accent, onEdit, onCopy }) {
  const [pressed, setPressed] = useState(false);
  const cur = (otp && otp.current) ? otp.current : '------';
  const nxt = (otp && otp.next) ? otp.next : '------';

  return (
    <div style={{
      background: '#191920', borderRadius: 18, marginBottom: 10,
      overflow: 'hidden', border: '1px solid rgba(255,255,255,0.05)',
    }}>
      {/* Upper row → edit */}
      <div
        onClick={onEdit}
        style={{ display: 'flex', alignItems: 'center', padding: '14px 16px 10px', cursor: 'pointer', gap: 12, userSelect: 'none' }}
      >
        <Logo brand={token.brand} size={42}/>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 15, fontWeight: 650, color: '#eeeef5', letterSpacing: 0.1 }}>{token.brand}</div>
          <div style={{ fontSize: 12, color: 'rgba(238,238,245,0.42)', marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {token.account}
          </div>
        </div>
        <CountdownRing timeLeft={timeLeft} accent={accent}/>
      </div>

      <div style={{ height: 1, background: 'rgba(255,255,255,0.055)', margin: '0 16px' }}/>

      {/* Lower row → copy */}
      <div
        onMouseDown={() => setPressed(true)}
        onMouseUp={() => setPressed(false)}
        onMouseLeave={() => setPressed(false)}
        onClick={onCopy}
        style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '11px 16px 14px', cursor: 'pointer', userSelect: 'none',
          background: pressed ? 'rgba(255,255,255,0.04)' : 'transparent',
          transition: 'background 0.12s',
        }}
      >
        <div style={{
          fontSize: 30, fontWeight: 700, letterSpacing: 5,
          color: '#eeeef5',
          fontFamily: '"SF Mono", "Fira Code", monospace',
        }}>
          {fmtCode(cur)}
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 2 }}>
          <div style={{ fontSize: 10, color: 'rgba(238,238,245,0.28)', display: 'flex', alignItems: 'center', gap: 3 }}>
            <CopyIcon s={10}/> 点击复制
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
            <span style={{ fontSize: 10, color: 'rgba(238,238,245,0.28)' }}>下一个</span>
            <span style={{ fontSize: 13, fontWeight: 600, color: 'rgba(238,238,245,0.32)', fontFamily: '"SF Mono", monospace', letterSpacing: 2 }}>
              {fmtCode(nxt)}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── BottomNav ────────────────────────────────────────────────────────────────

function BottomNav({ screen, onNav, visible, accent, searching, onSearch, onHome }) {
  const tabs = [
    { key: 'home', label: '首页', Icon: HomeIcon },
    { key: 'search', label: '搜索', Icon: SearchIcon },
    { key: 'scan', label: '扫码', Icon: ScanIcon },
    { key: 'profile', label: '我', Icon: MeIcon },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 200,
      display: 'flex', justifyContent: 'center',
      padding: '0 16px 24px',
      transform: visible ? 'translateY(0)' : 'translateY(120%)',
      transition: 'transform 0.35s cubic-bezier(0.32, 0.72, 0, 1)',
    }}>
      <div style={{
        display: 'flex', alignItems: 'center',
        background: 'rgba(18,18,24,0.85)', backdropFilter: 'blur(24px) saturate(180%)',
        borderRadius: 36, padding: '4px 5px',
        boxShadow: '0 8px 40px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.07)',
        border: '1px solid rgba(255,255,255,0.07)',
        gap: 2,
      }}>
        {tabs.map(({ key, label, Icon }) => {
          const active = (key === 'search') ? searching : (screen === key);
          const isSearch = key === 'search';
          const isHome = key === 'home';
          return (
            <button key={key} type="button" onClick={() => {
              if (isSearch) { onSearch(); return; }
              if (isHome && searching) { onHome(); return; }
              onNav(key);
            }} style={{
              display: 'flex', flexDirection: 'column', alignItems: 'center',
              justifyContent: 'center', gap: 3,
              background: active ? 'rgba(255,255,255,0.1)' : 'transparent',
              border: 'none', outline: 'none',
              color: active ? accent : 'rgba(238,238,245,0.38)',
              borderRadius: 28,
              cursor: 'pointer',
              padding: '8px 20px',
              transition: 'all 0.22s',
              minWidth: 66,
              minHeight: 46,
              userSelect: 'none',
              WebkitTapHighlightColor: 'transparent',
              touchAction: 'manipulation',
            }}>
              <Icon s={isSearch ? 16 : 20}/>
              <span style={{ fontSize: 10, fontWeight: active ? 650 : 400, letterSpacing: 0.2, lineHeight: 1.2 }}>{label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ─── HomeScreen ───────────────────────────────────────────────────────────────

function HomeScreen({ tokens, otpMap, timeLeft, accent, onEdit, onCopy, searching, setSearching, searchQ, setSearchQ, scrollRef, setNavVisible }) {
  const lastY = useRef(0);

  const filtered = tokens.filter(t => {
    if (!searchQ) return true;
    const q = searchQ.toLowerCase();
    return t.brand.toLowerCase().includes(q) || t.account.toLowerCase().includes(q);
  });

  const handleScroll = useCallback(e => {
    const y = e.target.scrollTop;
    if (y < 30) { setNavVisible(true); lastY.current = y; return; }
    setNavVisible(y <= lastY.current);
    lastY.current = y;
  }, [setNavVisible]);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Header */}
      <div style={{ padding: '12px 16px 0', flexShrink: 0 }}>
        {searching && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, paddingBottom: 8 }}>
            <button type="button" onClick={() => { setSearching(false); setSearchQ(''); }}
              style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'rgba(238,238,245,0.55)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2px 4px', fontSize: 16, flexShrink: 0 }}>
              ←
            </button>
            <div style={{
              flex: 1,
              display: 'flex', alignItems: 'center',
              background: '#191920', borderRadius: 8, padding: '0 8px', gap: 6,
              border: `1px solid ${accent}55`, height: 28,
            }}>
              <SearchIcon s={12}/>
              <input
                autoFocus value={searchQ}
                onChange={e => setSearchQ(e.target.value)}
                placeholder="搜索"
                style={{ flex: 1, background: 'none', border: 'none', outline: 'none', color: '#eeeef5', fontSize: 12, fontFamily: 'inherit', padding: 0 }}
              />
              {searchQ && (
                <button type="button" onClick={() => setSearchQ('')}
                  style={{ background: 'rgba(255,255,255,0.08)', border: 'none', borderRadius: 5, width: 18, height: 18, cursor: 'pointer', color: 'rgba(238,238,245,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <XIcon s={10}/>
                </button>
              )}
            </div>
          </div>
        )}
      </div>

      {/* List */}
      <div ref={scrollRef} onScroll={handleScroll}
        style={{ flex: 1, overflowY: 'auto', padding: searching ? '0 16px 120px' : '8px 16px 120px', scrollbarWidth: 'none' }}>
        {filtered.length === 0 && (
          <div style={{ textAlign: 'center', padding: '70px 20px', color: 'rgba(238,238,245,0.25)', fontSize: 14, lineHeight: 2 }}>
            <div style={{ fontSize: 36, marginBottom: 12 }}>🔍</div>
            {searchQ ? '未找到匹配账号' : '暂无验证码\n点击下方扫码添加'}
          </div>
        )}
        {filtered.map(token => (
          <TokenCard key={token.id} token={token} otp={otpMap[token.id]}
            timeLeft={timeLeft} accent={accent}
            onEdit={() => onEdit(token)}
            onCopy={() => onCopy(token, (otpMap[token.id] || {}).current)}
          />
        ))}
      </div>
    </div>
  );
}

// ─── ScanScreen ───────────────────────────────────────────────────────────────

function ScanScreen({ accent, onAdd, onClose }) {
  const [tab, setTab] = useState('camera');
  const [scanning, setScanning] = useState(false);
  const [scanned, setScanned] = useState(false);
  const [form, setForm] = useState({ brand: '', account: '', secret: '' });
  const [errors, setErrors] = useState({});

  const simulateScan = () => {
    setScanning(true);
    setTimeout(() => {
      setScanned(true);
      setScanning(false);
      setForm({ brand: 'Notion', account: 'alice@notion.so', secret: 'JBSWY3DPEHPK3PXP' });
      setTab('manual');
    }, 2400);
  };

  const handleFile = () => {
    // Simulate reading QR from album image
    setTimeout(() => {
      setForm({ brand: 'Spotify', account: 'alice@music.com', secret: 'KRUGS4TANFXGK4TF' });
      setTab('manual');
      setScanned(true);
    }, 600);
  };

  const validate = () => {
    const e = {};
    if (!form.brand.trim()) e.brand = '请输入品牌名称';
    if (!form.secret.trim()) e.secret = '请输入 Secret Key';
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleAdd = () => {
    if (!validate()) return;
    onAdd({ ...form });
  };

  const tabLabels = { camera: '扫二维码', album: '选相册', manual: '手动输入' };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: '#0d0d12' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', padding: '12px 16px 0', gap: 12 }}>
        <button onClick={onClose}
          style={{ background: 'rgba(255,255,255,0.08)', border: 'none', borderRadius: 11, padding: '8px', cursor: 'pointer', color: 'rgba(238,238,245,0.75)', display: 'flex' }}>
          <XIcon s={17}/>
        </button>
        <div style={{ fontSize: 17, fontWeight: 650, color: '#eeeef5' }}>添加账号</div>
        {scanned && <span style={{ marginLeft: 'auto', fontSize: 12, color: accent, fontWeight: 600 }}>✓ 已识别</span>}
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', margin: '14px 16px 0', background: '#191920', borderRadius: 13, padding: 4, gap: 2 }}>
        {['camera', 'album', 'manual'].map(t => (
          <button key={t} onClick={() => setTab(t)} style={{
            flex: 1, padding: '8px 0', border: 'none', cursor: 'pointer', borderRadius: 10,
            background: tab === t ? accent : 'transparent',
            color: tab === t ? '#fff' : 'rgba(238,238,245,0.45)',
            fontSize: 12, fontWeight: tab === t ? 650 : 400, transition: 'all 0.2s',
          }}>
            {tabLabels[t]}
          </button>
        ))}
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '16px', scrollbarWidth: 'none' }}>

        {/* ── Camera tab ── */}
        {tab === 'camera' && (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16 }}>
            <div style={{
              width: '100%', maxWidth: 310, aspectRatio: '1',
              background: '#000', borderRadius: 22, position: 'relative', overflow: 'hidden',
              boxShadow: '0 0 0 1px rgba(255,255,255,0.07)',
            }}>
              {/* Simulated camera bg */}
              <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(160deg,#080810 0%,#0c0c18 100%)' }}>
                {/* Noise grain effect */}
                <div style={{ position: 'absolute', inset: 0, opacity: 0.04,
                  backgroundImage: 'url("data:image/svg+xml,%3Csvg viewBox=\'0 0 256 256\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cfilter id=\'n\'%3E%3CfeTurbulence type=\'fractalNoise\' baseFrequency=\'0.9\'/%3E%3C/filter%3E%3Crect width=\'100%25\' height=\'100%25\' filter=\'url(%23n)\'/%3E%3C/svg%3E")',
                }}/>
              </div>
              {/* Dark overlay outside scan area */}
              <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.55)' }}/>
              {/* Scan box */}
              <div style={{
                position: 'absolute', top: '18%', left: '18%', right: '18%', bottom: '18%',
                background: 'transparent',
              }}>
                {/* Corners */}
                {[{t:0,l:0},{t:0,r:0},{b:0,l:0},{b:0,r:0}].map((pos, i) => (
                  <div key={i} style={{
                    position: 'absolute', width: 22, height: 22,
                    borderColor: accent, borderStyle: 'solid',
                    borderWidth: 0,
                    ...(pos.t === 0 ? {borderTopWidth: 3, top: -1} : {borderBottomWidth: 3, bottom: -1}),
                    ...(pos.l === 0 ? {borderLeftWidth: 3, left: -1} : {borderRightWidth: 3, right: -1}),
                    borderRadius: pos.t === 0 && pos.l === 0 ? '4px 0 0 0' : pos.t === 0 ? '0 4px 0 0' : pos.l === 0 ? '0 0 0 4px' : '0 0 4px 0',
                  }}/>
                ))}
                {/* Scan line */}
                {scanning && (
                  <div style={{
                    position: 'absolute', left: 0, right: 0, height: 2,
                    background: `linear-gradient(90deg, transparent, ${accent}, transparent)`,
                    animation: 'scanLine 1.8s ease-in-out infinite',
                    boxShadow: `0 0 10px ${accent}`,
                  }}/>
                )}
              </div>
            </div>

            <div style={{ fontSize: 13, color: 'rgba(238,238,245,0.4)', textAlign: 'center' }}>
              {scanning ? '正在识别二维码…' : '将二维码置于框内自动识别'}
            </div>

            <button onClick={simulateScan} disabled={scanning} style={{
              width: '100%', maxWidth: 310, padding: '14px', borderRadius: 15, border: 'none',
              background: scanning ? 'rgba(255,255,255,0.07)' : accent,
              color: scanning ? 'rgba(238,238,245,0.4)' : '#fff',
              fontSize: 15, fontWeight: 650, cursor: scanning ? 'default' : 'pointer',
              transition: 'all 0.2s',
            }}>
              {scanning ? '识别中…' : '模拟扫描'}
            </button>
          </div>
        )}

        {/* ── Album tab ── */}
        {tab === 'album' && (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18, paddingTop: 36 }}>
            <div style={{
              width: 88, height: 88, borderRadius: 24, background: '#191920',
              display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 38,
              border: '1px solid rgba(255,255,255,0.07)',
            }}>🖼️</div>
            <div style={{ color: 'rgba(238,238,245,0.5)', fontSize: 14, textAlign: 'center', lineHeight: 1.6 }}>
              从相册中选择含二维码的图片<br/>自动识别并添加账号
            </div>
            <label style={{
              width: '100%', maxWidth: 320, padding: '14px', borderRadius: 15,
              background: accent, color: '#fff', fontSize: 15, fontWeight: 650,
              textAlign: 'center', cursor: 'pointer', display: 'block',
            }}>
              选择图片
              <input type="file" accept="image/*" style={{ display: 'none' }} onChange={handleFile}/>
            </label>
          </div>
        )}

        {/* ── Manual tab ── */}
        {tab === 'manual' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            {scanned && (
              <div style={{ padding: '10px 14px', background: `${accent}18`, borderRadius: 12, border: `1px solid ${accent}30`, fontSize: 13, color: accent, fontWeight: 500 }}>
                ✓ 已从二维码读取信息，请确认或修改
              </div>
            )}

            {[
              { k: 'brand',   label: '品牌名称', ph: '如 Google、Microsoft…', required: true },
              { k: 'account', label: '账号信息', ph: '邮箱、用户名等' },
              { k: 'secret',  label: 'Secret Key', ph: 'Base32 密钥，如 JBSWY3DP…', required: true, mono: true },
            ].map(({ k, label, ph, required, mono }) => (
              <div key={k}>
                <div style={{ fontSize: 12, color: 'rgba(238,238,245,0.45)', marginBottom: 6, fontWeight: 500 }}>
                  {label}{required && <span style={{ color: accent }}> *</span>}
                </div>
                <input
                  value={form[k]}
                  onChange={e => { setForm(f => ({ ...f, [k]: e.target.value })); setErrors(er => ({ ...er, [k]: null })); }}
                  placeholder={ph}
                  style={{
                    width: '100%', padding: '12px 14px', boxSizing: 'border-box',
                    background: '#191920',
                    border: `1px solid ${errors[k] ? '#f87171' : 'rgba(255,255,255,0.08)'}`,
                    borderRadius: 12, color: '#eeeef5', fontSize: 14,
                    fontFamily: mono ? '"SF Mono", monospace' : 'inherit',
                    outline: 'none',
                  }}
                />
                {errors[k] && <div style={{ fontSize: 11, color: '#f87171', marginTop: 4 }}>{errors[k]}</div>}
              </div>
            ))}

            {/* Logo preview */}
            {form.brand.trim() && (
              <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', background: '#191920', borderRadius: 12, border: '1px solid rgba(255,255,255,0.06)' }}>
                <Logo brand={form.brand} size={36}/>
                <div>
                  <div style={{ fontSize: 14, color: '#eeeef5', fontWeight: 600 }}>{form.brand}</div>
                  {form.account && <div style={{ fontSize: 12, color: 'rgba(238,238,245,0.4)', marginTop: 2 }}>{form.account}</div>}
                </div>
                <span style={{ marginLeft: 'auto', fontSize: 11, color: 'rgba(238,238,245,0.3)' }}>预览</span>
              </div>
            )}

            <button onClick={handleAdd} style={{
              width: '100%', padding: '14px', marginTop: 4, borderRadius: 15, border: 'none',
              background: accent, color: '#fff', fontSize: 15, fontWeight: 650, cursor: 'pointer',
            }}>
              添加账号
            </button>
          </div>
        )}
      </div>

      <style>{`
        @keyframes scanLine {
          0%   { top: 5%; }
          50%  { top: 88%; }
          100% { top: 5%; }
        }
      `}</style>
    </div>
  );
}

// ─── EditModal ────────────────────────────────────────────────────────────────

function EditModal({ token, accent, onSave, onDelete, onClose }) {
  const [form, setForm] = useState({ brand: token.brand, account: token.account });
  const [confirmDelete, setConfirmDelete] = useState(false);

  return (
    <div style={{ position: 'absolute', inset: 0, background: '#0d0d12', zIndex: 300, display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', gap: 12 }}>
        <button onClick={onClose}
          style={{ background: 'rgba(255,255,255,0.08)', border: 'none', borderRadius: 11, padding: 8, cursor: 'pointer', color: 'rgba(238,238,245,0.75)', display: 'flex' }}>
          <XIcon s={17}/>
        </button>
        <div style={{ flex: 1, fontSize: 17, fontWeight: 650, color: '#eeeef5', textAlign: 'center', marginRight: 33 }}>编辑账号</div>
      </div>

      <div style={{ padding: '0 20px', display: 'flex', flexDirection: 'column', gap: 14, flex: 1, overflowY: 'auto' }}>
        <div style={{ display: 'flex', justifyContent: 'center', padding: '20px 0 8px' }}>
          <Logo brand={form.brand || token.brand} size={64}/>
        </div>

        {[{ k: 'brand', label: '品牌名称' }, { k: 'account', label: '账号信息' }].map(({ k, label }) => (
          <div key={k}>
            <div style={{ fontSize: 12, color: 'rgba(238,238,245,0.45)', marginBottom: 6 }}>{label}</div>
            <input value={form[k]} onChange={e => setForm(f => ({ ...f, [k]: e.target.value }))}
              style={{ width: '100%', boxSizing: 'border-box', padding: '12px 14px', background: '#191920', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, color: '#eeeef5', fontSize: 14, fontFamily: 'inherit', outline: 'none' }}/>
          </div>
        ))}

        <div>
          <div style={{ fontSize: 12, color: 'rgba(238,238,245,0.45)', marginBottom: 6 }}>Secret Key（只读）</div>
          <div style={{ padding: '12px 14px', background: '#191920', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, fontSize: 13, color: 'rgba(238,238,245,0.4)', fontFamily: '"SF Mono", monospace', letterSpacing: 1 }}>
            {'*'.repeat(Math.min(token.secret.length, 20))}
          </div>
        </div>

        <button onClick={() => onSave(form)} style={{
          marginTop: 8, width: '100%', padding: 14, borderRadius: 14,
          border: 'none', background: accent,
          color: '#fff', fontSize: 15, fontWeight: 650, cursor: 'pointer',
        }}>
          保存
        </button>

        {!confirmDelete ? (
          <button onClick={() => setConfirmDelete(true)} style={{
            marginTop: 'auto', width: '100%', padding: 14, borderRadius: 14,
            border: '1px solid rgba(248,113,113,0.25)', background: 'rgba(248,113,113,0.08)',
            color: '#f87171', fontSize: 15, fontWeight: 600, cursor: 'pointer',
          }}>
            删除账号
          </button>
        ) : (
          <div style={{ display: 'flex', gap: 10, marginTop: 'auto' }}>
            <button onClick={() => setConfirmDelete(false)} style={{ flex: 1, padding: 14, borderRadius: 14, border: '1px solid rgba(255,255,255,0.1)', background: 'transparent', color: 'rgba(238,238,245,0.6)', fontSize: 14, cursor: 'pointer' }}>取消</button>
            <button onClick={() => onDelete(token.id)} style={{ flex: 1, padding: 14, borderRadius: 14, border: 'none', background: '#ef4444', color: '#fff', fontSize: 14, fontWeight: 650, cursor: 'pointer' }}>确认删除</button>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── LoginModal ───────────────────────────────────────────────────────────────

function LoginModal({ accent, onLogin, onClose }) {
  const [tab, setTab] = useState('phone');
  const [phone, setPhone] = useState('');
  const [code, setCode] = useState('');
  const [sent, setSent] = useState(false);
  const [cd, setCd] = useState(0);

  const sendCode = () => {
    setSent(true); setCd(60);
    const iv = setInterval(() => setCd(c => { if (c <= 1) { clearInterval(iv); return 0; } return c - 1; }), 1000);
  };

  const canLogin = tab === 'phone' ? (phone.length >= 11 && code.length >= 4) : true;

  return (
    <div style={{ position: 'absolute', inset: 0, background: '#0d0d12', zIndex: 400, display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', gap: 12 }}>
        <button onClick={onClose} style={{ background: 'rgba(255,255,255,0.08)', border: 'none', borderRadius: 11, padding: 8, cursor: 'pointer', color: 'rgba(238,238,245,0.75)', display: 'flex' }}>
          <XIcon s={17}/>
        </button>
        <div style={{ fontSize: 17, fontWeight: 650, color: '#eeeef5' }}>登录账号</div>
      </div>

      <div style={{ padding: '0 20px', flex: 1, display: 'flex', flexDirection: 'column', gap: 16 }}>
        <div style={{ display: 'flex', background: '#191920', borderRadius: 13, padding: 4, gap: 2 }}>
          {['phone', 'wechat'].map(t => (
            <button key={t} onClick={() => setTab(t)} style={{
              flex: 1, padding: '9px', border: 'none', cursor: 'pointer', borderRadius: 10,
              background: tab === t ? accent : 'transparent',
              color: tab === t ? '#fff' : 'rgba(238,238,245,0.45)',
              fontSize: 13, fontWeight: tab === t ? 650 : 400, transition: 'all 0.2s',
            }}>
              {t === 'phone' ? '手机验证码' : '微信登录'}
            </button>
          ))}
        </div>

        {tab === 'phone' && (
          <>
            <div>
              <div style={{ fontSize: 12, color: 'rgba(238,238,245,0.45)', marginBottom: 6 }}>手机号</div>
              <input value={phone} onChange={e => setPhone(e.target.value)} placeholder="+86 手机号码" type="tel"
                style={{ width: '100%', boxSizing: 'border-box', padding: '13px 14px', background: '#191920', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, color: '#eeeef5', fontSize: 15, fontFamily: 'inherit', outline: 'none' }}/>
            </div>
            <div>
              <div style={{ fontSize: 12, color: 'rgba(238,238,245,0.45)', marginBottom: 6 }}>验证码</div>
              <div style={{ display: 'flex', gap: 8 }}>
                <input value={code} onChange={e => setCode(e.target.value)} placeholder="6位验证码" maxLength={6}
                  style={{ flex: 1, padding: '13px 14px', background: '#191920', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, color: '#eeeef5', fontSize: 15, fontFamily: 'inherit', outline: 'none' }}/>
                <button onClick={sendCode} disabled={cd > 0 || phone.length < 11} style={{
                  padding: '13px 14px', borderRadius: 12, border: 'none', whiteSpace: 'nowrap',
                  background: cd > 0 || phone.length < 11 ? '#191920' : accent,
                  color: cd > 0 || phone.length < 11 ? 'rgba(238,238,245,0.3)' : '#fff',
                  fontSize: 13, fontWeight: 600, cursor: cd > 0 || phone.length < 11 ? 'default' : 'pointer',
                }}>
                  {cd > 0 ? `${cd}s` : sent ? '重发' : '发送'}
                </button>
              </div>
              {sent && <div style={{ fontSize: 11, color: 'rgba(238,238,245,0.35)', marginTop: 6 }}>验证码已发送（演示：输入任意内容）</div>}
            </div>
          </>
        )}

        {tab === 'wechat' && (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20, paddingTop: 20 }}>
            <div style={{
              width: 140, height: 140, background: '#fff', borderRadius: 18,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 8px 32px rgba(0,0,0,0.4)',
            }}>
              {/* QR placeholder */}
              <svg width="100" height="100" viewBox="0 0 10 10" style={{ imageRendering: 'pixelated' }}>
                {[0,1,2,3,4,5,6].flatMap(r => [0,1,2,3,4,5,6].map(c => {
                  const q = [[1,1,1,1,1,1,1],[1,0,1,0,1,0,1],[1,1,0,1,0,1,1],[1,0,1,0,1,0,1],[1,1,0,0,0,1,1],[1,0,1,0,1,0,1],[1,1,1,1,1,1,1]];
                  return q[r] && q[r][c] ? <rect key={`${r}-${c}`} x={c + 1.5} y={r + 1.5} width="1" height="1" fill="#111"/> : null;
                }))}
              </svg>
            </div>
            <div style={{ color: 'rgba(238,238,245,0.5)', fontSize: 13, textAlign: 'center', lineHeight: 1.7 }}>
              使用微信扫描上方二维码登录<br/>
              <span style={{ fontSize: 11, color: 'rgba(238,238,245,0.3)' }}>二维码有效期 3 分钟</span>
            </div>
          </div>
        )}

        <button onClick={() => onLogin({ name: tab === 'phone' ? `用户${phone.slice(-4) || '****'}` : '微信用户', phone })}
          disabled={!canLogin}
          style={{
            width: '100%', padding: 14, marginTop: 'auto', borderRadius: 15, border: 'none',
            background: canLogin ? accent : '#191920',
            color: canLogin ? '#fff' : 'rgba(238,238,245,0.3)',
            fontSize: 15, fontWeight: 650, cursor: canLogin ? 'pointer' : 'default', transition: 'all 0.2s',
          }}>
          {tab === 'phone' ? '登录' : '微信登录（演示）'}
        </button>
      </div>
    </div>
  );
}

// ─── BackupModal ──────────────────────────────────────────────────────────────

function BackupModal({ accent, tokens, onClose, setToast }) {
  const [pw, setPw] = useState('');
  const [pw2, setPw2] = useState('');
  const match = pw && pw === pw2;

  const doBackup = () => {
    const data = encryptData(tokens, pw);
    const blob = new Blob([data], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = `auth_backup_${Date.now()}.atbk`; a.click();
    URL.revokeObjectURL(url);
    showToast(setToast, `已备份 ${tokens.length} 个账号`);
    onClose();
  };

  return (
    <div style={{ position: 'absolute', inset: 0, background: '#0d0d12', zIndex: 400, display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', gap: 12 }}>
        <button onClick={onClose} style={{ background: 'rgba(255,255,255,0.08)', border: 'none', borderRadius: 11, padding: 8, cursor: 'pointer', color: 'rgba(238,238,245,0.75)', display: 'flex' }}><XIcon s={17}/></button>
        <div style={{ fontSize: 17, fontWeight: 650, color: '#eeeef5' }}>备份数据</div>
      </div>
      <div style={{ padding: '0 20px', display: 'flex', flexDirection: 'column', gap: 14, flex: 1 }}>
        <div style={{ padding: '12px 14px', background: 'rgba(59,130,246,0.1)', borderRadius: 12, border: '1px solid rgba(59,130,246,0.2)', fontSize: 13, color: 'rgba(238,238,245,0.65)', lineHeight: 1.65 }}>
          ℹ️ 备份文件将使用您设置的密码加密。请牢记密码，忘记密码将无法恢复数据。
        </div>
        {[{ v: pw, sv: setPw, label: '加密密码', ph: '设置备份密码' }, { v: pw2, sv: setPw2, label: '确认密码', ph: '再次输入密码' }].map(({ v, sv, label, ph }) => (
          <div key={label}>
            <div style={{ fontSize: 12, color: 'rgba(238,238,245,0.45)', marginBottom: 6 }}>{label}</div>
            <input type="password" value={v} onChange={e => sv(e.target.value)} placeholder={ph}
              style={{ width: '100%', boxSizing: 'border-box', padding: '12px 14px', background: '#191920', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, color: '#eeeef5', fontSize: 14, fontFamily: 'inherit', outline: 'none' }}/>
          </div>
        ))}
        {pw && pw2 && !match && <div style={{ fontSize: 12, color: '#f87171' }}>两次密码不一致</div>}
        <div style={{ fontSize: 13, color: 'rgba(238,238,245,0.35)', marginTop: 4 }}>将备份 {tokens.length} 个账号</div>
        <button onClick={doBackup} disabled={!match} style={{
          width: '100%', padding: 14, marginTop: 'auto', borderRadius: 15, border: 'none',
          background: match ? accent : '#191920', color: match ? '#fff' : 'rgba(238,238,245,0.3)',
          fontSize: 15, fontWeight: 650, cursor: match ? 'pointer' : 'default',
        }}>
          加密备份并下载
        </button>
      </div>
    </div>
  );
}

// ─── ImportModal ──────────────────────────────────────────────────────────────

function ImportModal({ accent, onImport, onClose, setToast }) {
  const [pw, setPw] = useState('');
  const [file, setFile] = useState(null);
  const canImport = file && pw;

  const doImport = async () => {
    try {
      const text = await file.text();
      const data = decryptData(text, pw);
      onImport(data);
      showToast(setToast, `成功导入 ${data.length} 个账号`);
      onClose();
    } catch (_) {
      showToast(setToast, '解密失败，请检查密码');
    }
  };

  return (
    <div style={{ position: 'absolute', inset: 0, background: '#0d0d12', zIndex: 400, display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', gap: 12 }}>
        <button onClick={onClose} style={{ background: 'rgba(255,255,255,0.08)', border: 'none', borderRadius: 11, padding: 8, cursor: 'pointer', color: 'rgba(238,238,245,0.75)', display: 'flex' }}><XIcon s={17}/></button>
        <div style={{ fontSize: 17, fontWeight: 650, color: '#eeeef5' }}>导入备份</div>
      </div>
      <div style={{ padding: '0 20px', display: 'flex', flexDirection: 'column', gap: 14, flex: 1 }}>
        <div>
          <div style={{ fontSize: 12, color: 'rgba(238,238,245,0.45)', marginBottom: 6 }}>选择备份文件</div>
          <label style={{
            display: 'flex', alignItems: 'center', gap: 12, padding: '13px 14px',
            background: '#191920', borderRadius: 12, cursor: 'pointer',
            border: `1px solid ${file ? accent + '50' : 'rgba(255,255,255,0.08)'}`,
            transition: 'border-color 0.2s',
          }}>
            <span style={{ fontSize: 22 }}>📁</span>
            <span style={{ fontSize: 13, color: file ? '#eeeef5' : 'rgba(238,238,245,0.35)' }}>
              {file ? file.name : '选择 .atbk 备份文件'}
            </span>
            <input type="file" accept=".atbk,.txt" style={{ display: 'none' }} onChange={e => setFile(e.target.files[0])}/>
          </label>
        </div>
        <div>
          <div style={{ fontSize: 12, color: 'rgba(238,238,245,0.45)', marginBottom: 6 }}>解密密码</div>
          <input type="password" value={pw} onChange={e => setPw(e.target.value)} placeholder="输入备份时设置的密码"
            style={{ width: '100%', boxSizing: 'border-box', padding: '12px 14px', background: '#191920', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, color: '#eeeef5', fontSize: 14, fontFamily: 'inherit', outline: 'none' }}/>
        </div>
        <button onClick={doImport} disabled={!canImport} style={{
          width: '100%', padding: 14, marginTop: 'auto', borderRadius: 15, border: 'none',
          background: canImport ? accent : '#191920', color: canImport ? '#fff' : 'rgba(238,238,245,0.3)',
          fontSize: 15, fontWeight: 650, cursor: canImport ? 'pointer' : 'default',
        }}>
          解密并导入
        </button>
      </div>
    </div>
  );
}

// ─── ThemePickerModal ─────────────────────────────────────────────────────────

function ThemePickerModal({ currentTheme, setTheme, onClose }) {
  return (
    <div style={{ position: 'absolute', inset: 0, background: '#0d0d12', zIndex: 400, display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', gap: 12 }}>
        <button onClick={onClose} style={{ background: 'rgba(255,255,255,0.08)', border: 'none', borderRadius: 11, padding: 8, cursor: 'pointer', color: 'rgba(238,238,245,0.75)', display: 'flex' }}><XIcon s={17}/></button>
        <div style={{ fontSize: 17, fontWeight: 650, color: '#eeeef5' }}>皮肤主题</div>
      </div>
      <div style={{ padding: '8px 16px', display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 14 }}>
        {THEMES.map(t => {
          const active = currentTheme.name === t.name;
          return (
            <button key={t.name} onClick={() => { setTheme(t); onClose(); }}
              style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 7, background: 'none', border: 'none', cursor: 'pointer', padding: '8px 0' }}>
              <div style={{
                width: 50, height: 50, borderRadius: 16,
                background: t.color,
                border: active ? '3px solid #fff' : '3px solid transparent',
                boxSizing: 'border-box',
                boxShadow: active ? `0 0 18px ${t.color}` : `0 4px 12px ${t.color}55`,
                transition: 'all 0.2s',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {active && <CheckIcon s={18}/>}
              </div>
              <span style={{ fontSize: 10, color: active ? '#eeeef5' : 'rgba(238,238,245,0.45)', textAlign: 'center', lineHeight: 1.3, fontWeight: active ? 600 : 400 }}>
                {t.name}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ─── ProfileScreen ────────────────────────────────────────────────────────────

function ProfileScreen({ accent, loggedIn, setLoggedIn, userInfo, setUserInfo, theme, setTheme, tokens, setTokens, setToast }) {
  const [modal, setModal] = useState(null); // 'login'|'backup'|'import'|'theme'

  const menuItems = [
    { id: 'backup', icon: '☁️', label: '备份数据', desc: '加密导出所有验证码', locked: true },
    { id: 'import', icon: '📥', label: '导入备份', desc: '从加密文件恢复', locked: true },
    { id: 'theme',  icon: '🎨', label: '皮肤主题', desc: theme.name, locked: false },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', overflowY: 'auto', scrollbarWidth: 'none' }}>
      <div style={{ padding: '20px 20px 0', flex: 1 }}>
        {/* Avatar */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', paddingBottom: 28 }}>
          <div style={{
            width: 78, height: 78, borderRadius: 39, marginBottom: 14,
            background: loggedIn ? accent : '#191920',
            border: loggedIn ? 'none' : '2px dashed rgba(255,255,255,0.12)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: loggedIn ? 30 : 36, color: loggedIn ? '#fff' : 'rgba(238,238,245,0.2)',
            boxShadow: loggedIn ? `0 8px 32px ${accent}55` : 'none',
          }}>
            {loggedIn ? (userInfo?.name?.[0]?.toUpperCase() || 'U') : '👤'}
          </div>
          {loggedIn ? (
            <>
              <div style={{ fontSize: 18, fontWeight: 700, color: '#eeeef5' }}>{userInfo?.name}</div>
              {userInfo?.phone && <div style={{ fontSize: 13, color: 'rgba(238,238,245,0.4)', marginTop: 4 }}>{userInfo.phone}</div>}
            </>
          ) : (
            <>
              <div style={{ fontSize: 15, color: 'rgba(238,238,245,0.55)', marginBottom: 14 }}>登录后解锁更多功能</div>
              <button onClick={() => setModal('login')} style={{
                padding: '10px 32px', background: accent, border: 'none', borderRadius: 22,
                color: '#fff', fontSize: 15, fontWeight: 650, cursor: 'pointer',
                boxShadow: `0 4px 20px ${accent}55`,
              }}>
                登录账号
              </button>
            </>
          )}
        </div>

        {/* Menu */}
        <div style={{ background: '#191920', borderRadius: 18, overflow: 'hidden', border: '1px solid rgba(255,255,255,0.05)' }}>
          {menuItems.map((item, i) => {
            const disabled = item.locked && !loggedIn;
            return (
              <div key={item.id}>
                {i > 0 && <div style={{ height: 1, background: 'rgba(255,255,255,0.05)', margin: '0 16px' }}/>}
                <div onClick={() => !disabled && setModal(item.id)} style={{
                  display: 'flex', alignItems: 'center', padding: '14px 16px',
                  cursor: disabled ? 'default' : 'pointer', opacity: disabled ? 0.38 : 1,
                  transition: 'opacity 0.2s',
                }}>
                  <span style={{ fontSize: 22, marginRight: 14 }}>{item.icon}</span>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 15, color: '#eeeef5', fontWeight: 520 }}>{item.label}</div>
                    <div style={{ fontSize: 12, color: 'rgba(238,238,245,0.38)', marginTop: 2 }}>
                      {disabled ? '登录后可用' : item.desc}
                    </div>
                  </div>
                  <ChevronR s={15}/>
                </div>
              </div>
            );
          })}
        </div>

        {loggedIn && (
          <button onClick={() => { setLoggedIn(false); setUserInfo(null); showToast(setToast, '已退出登录'); }}
            style={{ marginTop: 16, width: '100%', padding: 13, borderRadius: 14, border: '1px solid rgba(255,255,255,0.08)', background: 'transparent', color: 'rgba(238,238,245,0.45)', fontSize: 14, cursor: 'pointer' }}>
            退出登录
          </button>
        )}

        {/* App version */}
        <div style={{ textAlign: 'center', padding: '24px 0 100px', fontSize: 12, color: 'rgba(238,238,245,0.2)' }}>
          Authenticator v1.0.0
        </div>
      </div>

      {/* Modals */}
      {modal === 'login' && <LoginModal accent={accent} onLogin={info => { setLoggedIn(true); setUserInfo(info); setModal(null); showToast(setToast, '登录成功 🎉'); }} onClose={() => setModal(null)}/>}
      {modal === 'backup' && <BackupModal accent={accent} tokens={tokens} onClose={() => setModal(null)} setToast={setToast}/>}
      {modal === 'import' && <ImportModal accent={accent} onImport={data => setTokens(ts => { const ids = new Set(ts.map(t=>t.id)); return [...ts, ...data.filter(t=>!ids.has(t.id))]; })} onClose={() => setModal(null)} setToast={setToast}/>}
      {modal === 'theme' && <ThemePickerModal currentTheme={theme} setTheme={setTheme} onClose={() => setModal(null)}/>}
    </div>
  );
}

// ─── App ──────────────────────────────────────────────────────────────────────

function App() {
  const [screen, setScreen]       = useState('home');
  const [tokens, setTokens]       = useState(INITIAL_TOKENS);
  const [otpMap, setOtpMap]       = useState({});
  const [timeLeft, setTimeLeft]   = useState(30);
  const [searching, setSearching] = useState(false);
  const [searchQ, setSearchQ]     = useState('');
  const [toast, setToast]         = useState(null);
  const [editTok, setEditTok]     = useState(null);
  const [theme, setTheme]         = useState(THEMES[0]);
  const [loggedIn, setLoggedIn]   = useState(false);
  const [userInfo, setUserInfo]   = useState(null);
  const [navVisible, setNavVisible] = useState(true);
  const [clockStr, setClockStr]   = useState('');
  const scrollRef = useRef(null);

  const accent = theme.color;

  // Clock
  useEffect(() => {
    const tick = () => setClockStr(new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit', hour12: false }));
    tick();
    const iv = setInterval(tick, 10000);
    return () => clearInterval(iv);
  }, []);

  // TOTP engine
  useEffect(() => {
    const update = async () => {
      const map = {};
      for (const t of tokens) {
        map[t.id] = {
          current: await window.TOTP.totp(t.secret, 0),
          next:    await window.TOTP.totp(t.secret, 1),
        };
      }
      setOtpMap(map);
    };
    update();
    const iv = setInterval(() => {
      const tl = window.TOTP.timeLeft();
      setTimeLeft(tl);
      if (tl === 30) update();
    }, 1000);
    return () => clearInterval(iv);
  }, [tokens]);

  const addToken = useCallback(data => {
    const tok = { id: Date.now().toString(), brand: data.brand.trim(), account: data.account || '', secret: data.secret.replace(/\s/g, '').toUpperCase() };
    setTokens(ts => [...ts, tok]);
    setScreen('home');
    showToast(setToast, `已添加 ${tok.brand}`);
  }, []);

  const saveToken = useCallback((id, form) => {
    setTokens(ts => ts.map(t => t.id === id ? { ...t, ...form } : t));
    setEditTok(null);
    showToast(setToast, '已保存');
  }, []);

  const deleteToken = useCallback(id => {
    setTokens(ts => ts.filter(t => t.id !== id));
    setEditTok(null);
    showToast(setToast, '已删除');
  }, []);

  const handleCopy = useCallback(async (token, code) => {
    if (!code || code === '------') return;
    const ok = await copyText(code);
    showToast(setToast, ok ? `已复制 ${token.brand} 验证码` : '复制失败');
  }, []);

  const handleNav = useCallback(key => {
    if (key === screen) return;
    setSearching(false); setSearchQ('');
    setScreen(key); setNavVisible(true);
  }, [screen]);

  return (
    <div style={{
      width: '100vw', height: '100vh',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'radial-gradient(ellipse at 50% 0%, #1a1a2e 0%, #000 70%)',
      fontFamily: '-apple-system, "SF Pro Display", "Helvetica Neue", sans-serif',
    }}>
      {/* Phone bezel */}
      <div style={{
        width: 393, height: 852,
        background: '#0d0d12', borderRadius: 52,
        overflow: 'hidden', position: 'relative',
        boxShadow: '0 50px 100px rgba(0,0,0,0.85), 0 0 0 1px rgba(255,255,255,0.06), inset 0 0 0 1px rgba(255,255,255,0.04)',
      }}>
        {/* Dynamic island */}
        <div style={{
          position: 'absolute', top: 12, left: '50%', transform: 'translateX(-50%)',
          width: 120, height: 34, background: '#000', borderRadius: 20, zIndex: 10,
        }}/>

        {/* Status bar */}
        <div style={{
          height: 54, display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between',
          padding: '0 28px 8px', flexShrink: 0, position: 'relative', zIndex: 5,
        }}>
          <span style={{ fontSize: 16, fontWeight: 650, color: '#eeeef5' }}>{clockStr}</span>
          <div style={{ display: 'flex', gap: 5, alignItems: 'center', color: '#eeeef5', fontSize: 13, fontWeight: 600 }}>
            <span>●●●●</span>
            <svg width="16" height="12" viewBox="0 0 16 12" fill="currentColor"><path d="M8 2C10.8 2 13.3 3.1 15.1 4.9L16 4C13.9 1.9 11.1.8 8 .8S2.1 1.9 0 4L.9 4.9C2.7 3.1 5.2 2 8 2zm0 4c1.7 0 3.2.7 4.3 1.8l.9-.9C11.8 5.5 10 4.8 8 4.8S4.2 5.5 2.8 6.9l.9.9C4.8 6.7 6.3 6 8 6zm0 4a2 2 0 100 4 2 2 0 000-4z"/></svg>
            <span>100%</span>
          </div>
        </div>

        {/* Content */}
        <div style={{ height: 'calc(100% - 54px)', position: 'relative', overflow: 'hidden' }}>
          {screen === 'home' && (
            <HomeScreen
              tokens={tokens} otpMap={otpMap} timeLeft={timeLeft} accent={accent}
              onEdit={setEditTok} onCopy={handleCopy}
              searching={searching} setSearching={setSearching}
              searchQ={searchQ} setSearchQ={setSearchQ}
              scrollRef={scrollRef} setNavVisible={setNavVisible}
            />
          )}
          {screen === 'scan' && (
            <ScanScreen accent={accent} onAdd={addToken} onClose={() => setScreen('home')}/>
          )}
          {screen === 'profile' && (
            <ProfileScreen
              accent={accent} loggedIn={loggedIn} setLoggedIn={setLoggedIn}
              userInfo={userInfo} setUserInfo={setUserInfo}
              theme={theme} setTheme={setTheme}
              tokens={tokens} setTokens={setTokens} setToast={setToast}
            />
          )}

          {editTok && (
            <EditModal token={editTok} accent={accent}
              onSave={form => saveToken(editTok.id, form)}
              onDelete={deleteToken}
              onClose={() => setEditTok(null)}
            />
          )}

          <BottomNav screen={screen} onNav={handleNav} visible={navVisible} accent={accent} searching={searching} onSearch={() => { if (screen !== 'home') handleNav('home'); setSearching(!searching); if (searching) setSearchQ(''); }} onHome={() => { setSearching(false); setSearchQ(''); }}/>
          <Toast msg={toast}/>
        </div>
      </div>

      <style>{`
        * { -webkit-tap-highlight-color: transparent; box-sizing: border-box; }
        ::-webkit-scrollbar { display: none; }
        input::placeholder { color: rgba(238,238,245,0.25); }
      `}</style>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
