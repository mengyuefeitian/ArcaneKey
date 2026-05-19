# Codebase Concerns

**Analysis Date:** 2026-05-19
**Focus:** HarmonyOS development (branch: dev-harmonyos)

---

## Code Health

**Monolithic Index.ets (1,090 lines):**
- Issue: `harmonyos/entry/src/main/ets/pages/Index.ets` is the single entry component and contains 9 `@Builder` modal functions inline (editModal, loginModal, backupModal, importModal, themeModal, deleteConfirmModal, membershipModal, accountInfoModal, toast), all lifecycle logic, all cloud sync methods, and the root `build()` UI tree.
- Files: `harmonyos/entry/src/main/ets/pages/Index.ets`
- Impact: Any new modal or feature requires editing this file. ArkTS `@Builder` functions inside a struct cannot easily access parent `@State` when split to a separate file without prop drilling or `@Link`. The 1090-line count will grow linearly with every new feature.
- Fix approach: Extract each modal into a standalone `@CustomDialog` using `CustomDialogController`, which is the ArkTS-idiomatic pattern. Each dialog struct owns its own state and calls back via closure parameters. This avoids the `@Link` vs inline tradeoff.

**Cross-platform constant duplication:**
- Issue: `THEMES`, `INITIAL_TOKENS`, `FREE_TOKEN_LIMIT`, `MEMBERSHIP_PRICE`, and `APP_NAME` are duplicated between `miniprogram/app.js` (lines 3–27) and `harmonyos/entry/src/main/ets/model/Token.ets`. Any change to theme names, colors, or demo tokens requires editing both files.
- Files: `miniprogram/app.js`, `harmonyos/entry/src/main/ets/model/Token.ets`
- Impact: Silent drift — themes added to one platform but not the other produce an inconsistent user experience. The `BRAND_COLORS` map only exists in `Token.ets`; it is inlined in the WeChat side.
- Fix approach: There is no shared build system, so the only mitigation is a comment in both files pointing to each other with the sync obligation, and treating these blocks as a checklist item on every relevant PR.

**SHA-1 / HMAC-SHA1 implementation duplicated:**
- Issue: The `sha1()` and `hmacSha1()` functions are copy-pasted verbatim between `harmonyos/entry/src/main/ets/utils/TOTP.ets` (lines 1–59) and `harmonyos/entry/src/main/ets/utils/CryptoUtil.ets` (lines 51–110). The comment in `CryptoUtil.ets` at line 50 even acknowledges this: `// SHA-1 (copied from TOTP.ets for key derivation)`.
- Files: `harmonyos/entry/src/main/ets/utils/TOTP.ets`, `harmonyos/entry/src/main/ets/utils/CryptoUtil.ets`
- Impact: If a bug is found in the SHA-1 implementation (e.g., the 32-bit integer overflow behavior on line 81), it must be fixed in two places. A fix to one without the other leaves a silent inconsistency.
- Fix approach: Extract `sha1` and `hmacSha1` into a shared `harmonyos/entry/src/main/ets/utils/Sha1.ets` module and import it in both `TOTP.ets` and `CryptoUtil.ets`.

**No tests:**
- Issue: Zero test files exist. The `@ohos/hypium` 1.0.18 dev dependency is declared in `harmonyos/oh-package.json5` but no test directory or spec files are present.
- Files: `harmonyos/oh-package.json5` (dependency declared but unused)
- Impact: Any change to `TOTP.ets`, `CryptoUtil.ets`, or `StorageUtil.ets` has no automated regression guard. TOTP correctness and the encryption round-trip are critical correctness properties with no test coverage.
- Fix approach: Minimum viable tests are unit tests for `totp()` in `TOTP.ets` (known OTP values from RFC 6238 test vectors) and a round-trip test for `encryptData`/`decryptData` in `CryptoUtil.ets`.

**No linter or formatter:**
- Issue: No ESLint, Prettier, Biome, or ArkTS-specific linter config exists at the repo root or in either platform directory.
- Impact: Code style divergence over time. No automated catch of common ArkTS anti-patterns (e.g., unguarded `as` casts, ignored Promise rejections).
- Fix approach: DevEco Studio ships with an ArkTS linter; enable it in project settings and add a `.editorconfig` for formatting baseline.

---

## Security

**Encryption is PBKDF2-XOR, not AES:**
- Risk: `harmonyos/entry/src/main/ets/utils/CryptoUtil.ets` uses PBKDF2-HMAC-SHA1 key derivation (10,000 iterations) followed by XOR stream cipher. The key stream is exactly as long as the plaintext (no IV, no authentication tag). XOR with a keystream has no ciphertext integrity — a bit-flip attack silently corrupts data without detection.
- Files: `harmonyos/entry/src/main/ets/utils/CryptoUtil.ets`
- Current mitigation: PBKDF2 slows brute-force password attacks; the `ENC2` magic header enables format detection. There is no MAC or AEAD.
- Recommendation: For production, replace with AES-256-GCM using `@kit.CryptoArchitectureKit` (`cryptoFramework`), which is available in HarmonyOS API 9+. The GCM mode provides authenticated encryption and rejects tampered ciphertext.

**Client-side-only login — no backend verification:**
- Risk: Login in both platforms is entirely client-side UI state. In HarmonyOS, `harmonyos/entry/src/main/ets/pages/Index.ets` sets `this.loggedIn = true` and `this.harmonyLogin = true` after a device account lookup; no token is issued or verified by a server.
- Files: `harmonyos/entry/src/main/ets/pages/Index.ets` (login modal builder, ~line 619)
- Current mitigation: The app is local-only; there is no server to bypass. Membership (`isMember`) is also set client-side with no cryptographic proof.
- Recommendation: Acceptable for the current demo scope. Before shipping real IAP, membership state must be server-verified.

**Cloud environment ID hardcoded in app.js:**
- Risk: `miniprogram/app.js` line 47 hardcodes `wx.cloud.init({ env: 'cloud1-d6gxlvduza77569eb' })`. This is committed to git and publicly readable.
- Files: `miniprogram/app.js`
- Current mitigation: WeChat Cloud environment IDs are not secret (API access requires user authentication), but hardcoded IDs make environment switching (dev vs prod) impossible without a code edit.
- Recommendation: Move to a build-time constant or `app.json` configuration field so dev/staging/prod can be switched without touching `app.js`.

**Sensitive data stored unencrypted in preferences:**
- Risk: `harmonyos/entry/src/main/ets/utils/StorageUtil.ets` stores the full token array (including TOTP secret keys) as plaintext JSON under `TOKENS_KEY = 'auth_tokens'` in the `arcankey_prefs` preferences store. TOTP secrets are high-value credentials — if the device is rooted or backed up, they are exposed in cleartext.
- Files: `harmonyos/entry/src/main/ets/utils/StorageUtil.ets`
- Current mitigation: HarmonyOS preferences files are in the app's sandboxed data directory, inaccessible without root or ADB backup on non-debug builds.
- Recommendation: Use `@kit.UniversalKeystoreKit` to store secrets, or at minimum encrypt the token JSON before writing to preferences.

**SYSTEM_FLOAT_WINDOW permission declared but not exercised:**
- Risk: `harmonyos/entry/src/main/module.json5` previously declared `ohos.permission.SYSTEM_FLOAT_WINDOW` per CLAUDE.md, but the current `module.json5` has no `requestPermissions` block at all. ScanKit implicitly requests camera permission at runtime via the SDK.
- Files: `harmonyos/entry/src/main/module.json5`
- Impact: If the float window permission was removed during cleanup but the capability is still needed by some future feature, it will silently fail on-device.
- Fix approach: Audit whether any current feature path still requires `SYSTEM_FLOAT_WINDOW`. If not, leave as-is. If yes, add it back with a rationale comment.

---

## Architecture

**"Cloud backup" is local preferences, not real cloud sync:**
- Issue: `cloudBackup()`, `cloudRestore()`, and `cloudDelete()` in `harmonyos/entry/src/main/ets/pages/Index.ets` (lines 308–369) write to a second preferences store named `arcankey_cloud` on the same device. This is local storage masquerading as cloud storage.
- Files: `harmonyos/entry/src/main/ets/pages/Index.ets`
- Impact: "Sync" only works on the same device. Uninstalling the app destroys both preferences stores simultaneously, defeating the backup purpose entirely.
- Fix approach: Replace with a real cloud backend. For HarmonyOS, `@kit.CloudFoundationKit` (Huawei AGC Cloud DB) or a custom REST API with JWT auth are the production paths. The `cloudBackup`/`cloudRestore` interface is already isolated enough to swap the implementation.

**Membership is demo-only — payment not wired:**
- Issue: `buyMembership()` in `harmonyos/entry/src/main/ets/pages/Index.ets` (line 361) sets `isMember = true` directly. The `// TODO: 生产环境接入微信支付/华为支付` comment on line 362 documents this.
- Files: `harmonyos/entry/src/main/ets/pages/Index.ets`, `miniprogram/pages/membership/membership.js` (same TODO at line 29)
- Impact: Any user can tap "开通会员" and become a member with no payment. Shipping to production with this code enables unauthorized feature access.
- Fix approach: Integrate Huawei IAP (`@kit.IAPKit`) for HarmonyOS. Membership state must be server-verified, not just persisted locally.

**Single-page conditional rendering limits scalability:**
- Issue: All screens (Home, Scan, Profile, Feedback) and all modals are rendered conditionally within one `@Entry` struct in `harmonyos/entry/src/main/ets/pages/Index.ets`. Adding a new top-level screen requires modifying `Index.ets`.
- Files: `harmonyos/entry/src/main/ets/pages/Index.ets`
- Impact: The `@State` count is already 30+ variables at the top of `Index.ets`. Each new feature adds more variables to this single namespace, making it harder to reason about which state belongs to which modal.
- Fix approach: ArkTS supports multi-page navigation via `router.pushUrl()`. Future screens (e.g., settings, detailed token history) should be real pages in `src/main/ets/pages/`, not more conditional blocks. Existing views are already extracted as `@Component` structs; modals are the remaining concentration risk.

**All modal state lives in the root component:**
- Issue: 30+ `@State` variables in `Index.ets` include state for every modal (e.g., `backupPw`, `backupPw2`, `importText`, `importFileUri`, `loginPhone`, `loginCode`, `loginCodeCd`). This state is only used inside the corresponding `@Builder` but is declared at the root level.
- Files: `harmonyos/entry/src/main/ets/pages/Index.ets` (lines 37–94)
- Impact: Re-renders triggered by any `@State` mutation in the root struct may cascade to all child builders. In ArkTS, `@Builder` functions without `@Link` bindings re-evaluate their captures on parent re-render.
- Fix approach: Extract modals to `@CustomDialog` structs with their own internal `@State`. This is the canonical ArkTS pattern and removes the state from the root component.

---

## Platform-Specific Risks

**HarmonyOS API 23 (SDK 6.1.0) is recent and subject to change:**
- Risk: The project targets `compileSdkVersion: "6.1.0(23)"` per `harmonyos/build-profile.json5`. HarmonyOS 6.1 is a relatively new release. APIs like `@kit.ScanKit`, `@kit.CoreFileKit`, and `preferences.getPreferencesSync` may have breaking changes in upcoming SDK versions.
- Files: `harmonyos/build-profile.json5`, `harmonyos/entry/src/main/ets/pages/Index.ets`
- Impact: `@ohos.file.fs` (imported via `import fs from '@ohos.file.fs'` in `Index.ets` line 5) uses the older `@ohos.*` namespace rather than `@kit.*`. Huawei has been migrating APIs to the `@kit.*` namespace; `@ohos.*` imports may be deprecated.
- Fix approach: Monitor Huawei developer release notes. Run `hvigor` build warnings periodically to catch deprecation notices. Replace `@ohos.file.fs` with the `@kit.CoreFileKit` equivalent when stable.

**Camera permission for ScanKit is not explicitly declared:**
- Risk: `ScanView.ets` imports `@kit.ScanKit` and calls `scanBarcode.startScanForResult()`. ScanKit requires `ohos.permission.CAMERA`. The current `module.json5` has no `requestPermissions` array — no permissions are declared.
- Files: `harmonyos/entry/src/main/ets/views/ScanView.ets`, `harmonyos/entry/src/main/module.json5`
- Impact: On real devices, scanning may silently fail or throw a permission-denied error that is caught by the generic `try/catch` in `doScan()`. The user sees no error, and the scan never completes.
- Fix approach: Add `ohos.permission.CAMERA` to `module.json5` under `requestPermissions` and call `abilityAccessCtrl.requestPermissionsFromUser()` before invoking the scanner.

**Immersive full-screen layout and safe areas:**
- Risk: `EntryAbility.ets` calls `setWindowLayoutFullScreen(true)` and `setWindowBackgroundColor('#00000000')`. The floating nav bar uses a fixed `translate({ y: navVisible ? -20 : 80 })` offset. On devices with non-standard notch heights, punch-hole cameras, or foldable form factors (which HarmonyOS targets), this fixed offset may clip the nav bar under system UI.
- Files: `harmonyos/entry/src/main/ets/entryability/EntryAbility.ets`, `harmonyos/entry/src/main/ets/pages/Index.ets`
- Impact: Nav bar may be partially obscured or content may overlap the status bar on some device models.
- Fix approach: Use `window.on('avoidAreaChange')` to dynamically read safe area insets and apply them as padding rather than using fixed pixel offsets.

---

## Technical Debt

**Missing .gitignore:**
- Issue: No `.gitignore` file exists at the repo root (`ls /Users/xiaoan/Documents/code/ArcaneKey/.gitignore` → not found).
- Impact: Build artifacts, IDE files (`.hvigor/`, `oh_modules/`, `node_modules/`, `build/`, `.DS_Store`) are potentially committed or will appear as untracked noise. The `oh_modules/` directory is already present in the tree.
- Fix approach: Add a `.gitignore` that excludes `oh_modules/`, `harmonyos/.hvigor/`, `harmonyos/build/`, `miniprogram/miniprogram_npm/`, `.DS_Store`, `*.hap`, `*.app`.

**No README:**
- Issue: No `README.md` exists in the repository root.
- Impact: A new contributor (or a future AI agent) has no documented entry point for setup, build commands, or architecture overview beyond `CLAUDE.md`.
- Fix approach: Add a minimal `README.md` with platform setup requirements (WeChat DevTools version, DevEco Studio version, HarmonyOS SDK version), build commands, and a link to the planning docs.

**No CI/CD:**
- Issue: No pipeline configuration exists (no `.github/workflows/`, no `Jenkinsfile`, no CI config of any kind).
- Impact: No automated build verification on push. Broken HarmonyOS builds (`hvigor build`) are only caught when a developer manually builds in DevEco Studio.
- Fix approach: A minimal GitHub Actions workflow running `hvigor assembleHap` on push to `main` would catch build regressions. WeChat Mini Program linting via `miniprogram-ci` is also available as a GitHub Action.

**`bundleName` uses `com.example.*` namespace:**
- Issue: `harmonyos/AppScope/app.json5` declares `bundleName: "com.example.arcankey"`. The `com.example` namespace is for development/testing only and is rejected by HarmonyOS app store submissions.
- Files: `harmonyos/AppScope/app.json5`
- Impact: Blocks any app store release until changed to a registered domain-based bundle name.
- Fix approach: Change to a real bundle name (e.g., `com.arcanekey.authenticator`) registered in the Huawei AppGallery Connect console. This is a one-time change that must be coordinated with signing config.

---

*Concerns audit: 2026-05-19*
