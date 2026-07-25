import { userAuth } from '@kit.UserAuthenticationKit';
import { SecurityMode } from './StorageUtil';

export interface AuthOutcome {
  ok: boolean;
  /** userAuth.UserAuthResultCode value, or -1 for local/NAPI failure */
  code: number;
}

function toAuthType(mode: SecurityMode): userAuth.UserAuthType | null {
  if (mode === 'face') {
    return userAuth.UserAuthType.FACE;
  }
  if (mode === 'fingerprint') {
    return userAuth.UserAuthType.FINGERPRINT;
  }
  if (mode === 'lock') {
    return userAuth.UserAuthType.PIN;
  }
  return null;
}

export function isSecurityTypeAvailable(mode: SecurityMode): boolean {
  const authType = toAuthType(mode);
  if (authType === null) {
    return false;
  }
  try {
    userAuth.getAvailableStatus(authType, userAuth.AuthTrustLevel.ATL1);
    return true;
  } catch (_) {
    return false;
  }
}

function buildChallenge(): Uint8Array {
  return new Uint8Array([
    0x41, 0x72, 0x63, 0x61, 0x6e, 0x65, 0x4b, 0x65,
    0x79, 0x53, 0x65, 0x63, 0x75, 0x72, 0x65, 0x00
  ]);
}

/** True when face/fingerprint failure should auto-route to lock-screen PIN. */
export function shouldAutoLockFallback(code: number): boolean {
  if (code === -1) {
    return true;
  }
  if (code === userAuth.UserAuthResultCode.BUSY) {
    return true;
  }
  if (code === userAuth.UserAuthResultCode.FAIL) {
    return true;
  }
  if (code === userAuth.UserAuthResultCode.GENERAL_ERROR) {
    return true;
  }
  if (code === userAuth.UserAuthResultCode.TIMEOUT) {
    return true;
  }
  return false;
}

export function authenticateSecurity(mode: SecurityMode): Promise<AuthOutcome> {
  return new Promise<AuthOutcome>((resolve: (value: AuthOutcome) => void) => {
    const authType = toAuthType(mode);
    if (authType === null) {
      resolve({ ok: true, code: userAuth.UserAuthResultCode.SUCCESS });
      return;
    }
    try {
      const authParam: userAuth.AuthParam = {
        challenge: buildChallenge(),
        authType: [authType],
        authTrustLevel: userAuth.AuthTrustLevel.ATL1
      };
      const widgetParam: userAuth.WidgetParam = {
        title: '验证以继续'
      };
      const instance: userAuth.UserAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
      const callback: userAuth.IAuthCallback = {
        onResult: (result: userAuth.UserAuthResult) => {
          const code: number = result.result;
          resolve({
            ok: code === userAuth.UserAuthResultCode.SUCCESS,
            code: code
          });
        }
      };
      instance.on('result', callback);
      instance.start();
    } catch (e) {
      console.error('[SecurityUtil] authenticateSecurity failed: ' +
        (e instanceof Error ? e.message : String(e)));
      resolve({ ok: false, code: -1 });
    }
  });
}
