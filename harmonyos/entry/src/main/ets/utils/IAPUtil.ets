import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';

export const MEMBER_PRODUCT_ID = 'com.arcanekey.authenticator.member_lifetime';

interface PurchasePayload {
  productId?: string;
  purchaseToken?: string;
  orderId?: string;
}

export interface PurchaseTokenResult {
  purchaseToken: string;
  purchaseOrderId: string;
}


// 沙盒自检：Debug 签名包 + AGC 沙盒测试账号登录时返回 true，用于真机测试排查"是否走了真实扣费"
export async function checkSandboxStatus(context: common.UIAbilityContext): Promise<void> {
  try {
    const isSandbox = await iap.isSandboxActivated(context);
    console.info(`[IAPUtil] sandbox activated: ${isSandbox}`);
  } catch (error) {
    console.error('[IAPUtil] isSandboxActivated failed:', error);
  }
}

export async function launchPurchase(context: common.UIAbilityContext): Promise<PurchaseTokenResult> {
  try {
    const result = await iap.createPurchase(context, {
      productType: iap.ProductType.NONCONSUMABLE,
      productId: MEMBER_PRODUCT_ID,
    });
    const payload = JSON.parse(result.purchaseData) as PurchasePayload;
    const token: PurchaseTokenResult = {
      purchaseToken: payload.purchaseToken ?? '',
      purchaseOrderId: payload.orderId ?? '',
    };
    return token;
  } catch (error) {
    console.error('IAP launchPurchase failed:', error);
    throw error as Error;
  }
}

export async function acknowledgePurchase(
  context: common.UIAbilityContext,
  purchaseToken: string,
  purchaseOrderId: string
): Promise<void> {
  if (!purchaseToken || !purchaseOrderId) {
    throw new Error('acknowledgePurchase: missing purchaseToken or purchaseOrderId');
  }
  try {
    await iap.finishPurchase(context, {
      productType: iap.ProductType.NONCONSUMABLE,
      purchaseToken: purchaseToken,
      purchaseOrderId: purchaseOrderId,
    });
  } catch (error) {
    console.error('IAP acknowledgePurchase failed:', error);
    throw error as Error;
  }
}

async function findPurchase(
  context: common.UIAbilityContext,
  queryType: iap.PurchaseQueryType
): Promise<PurchaseTokenResult | null> {
  const result = await iap.queryPurchases(context, {
    productType: iap.ProductType.NONCONSUMABLE,
    queryType: queryType,
  });
  if (!result.purchaseDataList || result.purchaseDataList.length === 0) {
    return null;
  }
  for (const data of result.purchaseDataList) {
    const payload = JSON.parse(data) as PurchasePayload;
    if (payload.productId === MEMBER_PRODUCT_ID) {
      return { purchaseToken: payload.purchaseToken ?? '', purchaseOrderId: payload.orderId ?? '' };
    }
  }
  return null;
}

export async function restoreOwnedPurchases(
  context: common.UIAbilityContext
): Promise<PurchaseTokenResult | null> {
  try {
    const entitled = await findPurchase(context, iap.PurchaseQueryType.CURRENT_ENTITLEMENT);
    if (entitled) {
      return entitled;
    }
    // A purchase can be PRODUCT_OWNED at AGC but never show up as a CURRENT_ENTITLEMENT
    // if finishPurchase() was never successfully called on it (e.g. an earlier
    // acknowledgePurchase attempt failed silently). Finish it here so it becomes a
    // real entitlement, then return its token.
    const unfinished = await findPurchase(context, iap.PurchaseQueryType.UNFINISHED);
    if (unfinished) {
      await acknowledgePurchase(context, unfinished.purchaseToken, unfinished.purchaseOrderId);
      return unfinished;
    }
    return null;
  } catch (error) {
    console.error('IAP restoreOwnedPurchases failed:', error);
    return null; // 恢复失败时返回 null，不抛出异常
  }
}
