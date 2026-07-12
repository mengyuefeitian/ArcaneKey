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

export function authenticateSecurity(mode: SecurityMode): Promise<boolean> {
  return new Promise<boolean>((resolve: (value: boolean) => void) => {
    const authType = toAuthType(mode);
    if (authType === null) {
      resolve(true);
      return;
    }
    try {
      const authParam: userAuth.AuthParam = {
        challenge: new Uint8Array(0),
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
    } catch (_) {
      resolve(false);
    }
  });
}
