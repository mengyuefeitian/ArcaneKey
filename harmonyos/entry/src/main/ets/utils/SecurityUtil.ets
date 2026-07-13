import { userAuth } from '@kit.UserAuthenticationKit';
import { SecurityMode } from './StorageUtil';

function toAuthType(mode: SecurityMode): userAuth.UserAuthType | null {
  if (mode === 'face') {
    return userAuth.UserAuthType.FACE;
  }
  if (mode === 'fingerprint') {
    return userAuth.UserAuthType.FINGERPRINT;
  }
  if (mode === 'lock') {
    // Lock-screen credential maps to PIN
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
    // Throws BusinessError if unsupported / not enrolled
    userAuth.getAvailableStatus(authType, userAuth.AuthTrustLevel.ATL1);
    return true;
  } catch (_) {
    return false;
  }
}

/**
 * UserAuth requires challenge as Uint8Array with length 0–32.
 * Empty array is rejected by NAPI on device (err 401: "length of challenge cannot exceed 32"
 * / GetUint8ArrayValue fail) — use a short fixed challenge instead.
 */
function buildChallenge(): Uint8Array {
  // 16 bytes is within the documented max (32) and accepted by UserAuth NAPI
  return new Uint8Array([
    0x41, 0x72, 0x63, 0x61, 0x6e, 0x65, 0x4b, 0x65,
    0x79, 0x53, 0x65, 0x63, 0x75, 0x72, 0x65, 0x00
  ]);
}

export function authenticateSecurity(mode: SecurityMode): Promise<boolean> {
  return new Promise<boolean>((resolve: (value: boolean) => void) => {
    const authType = toAuthType(mode);
    if (authType === null) {
      resolve(true);
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
          resolve(result.result === userAuth.UserAuthResultCode.SUCCESS);
        }
      };
      instance.on('result', callback);
      instance.start();
    } catch (e) {
      console.error('[SecurityUtil] authenticateSecurity failed: ' +
        (e instanceof Error ? e.message : String(e)));
      resolve(false);
    }
  });
}
