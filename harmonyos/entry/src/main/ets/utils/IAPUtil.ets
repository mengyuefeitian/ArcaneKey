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


export async function launchPurchase(context: common.UIAbilityContext): Promise<PurchaseTokenResult> {
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
}

export async function acknowledgePurchase(
  context: common.UIAbilityContext,
  purchaseToken: string,
  purchaseOrderId: string
): Promise<void> {
  if (!purchaseToken || !purchaseOrderId) {
    throw new Error('acknowledgePurchase: missing purchaseToken or purchaseOrderId');
  }
  await iap.finishPurchase(context, {
    productType: iap.ProductType.NONCONSUMABLE,
    purchaseToken: purchaseToken,
    purchaseOrderId: purchaseOrderId,
  });
}

export async function restoreOwnedPurchases(
  context: common.UIAbilityContext
): Promise<PurchaseTokenResult | null> {
  const result = await iap.queryPurchases(context, {
    productType: iap.ProductType.NONCONSUMABLE,
    queryType: iap.PurchaseQueryType.CURRENT_ENTITLEMENT,
  });
  if (!result.purchaseDataList || result.purchaseDataList.length === 0) {
    return null;
  }
  for (const data of result.purchaseDataList) {
    const payload = JSON.parse(data) as PurchasePayload;
    if (payload.productId === MEMBER_PRODUCT_ID) {
      const token: PurchaseTokenResult = { purchaseToken: payload.purchaseToken ?? '', purchaseOrderId: payload.orderId ?? '' };
      return token;
    }
  }
  return null;
}
