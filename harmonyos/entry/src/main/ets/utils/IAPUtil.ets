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

export async function restoreOwnedPurchases(
  context: common.UIAbilityContext
): Promise<PurchaseTokenResult | null> {
  try {
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
  } catch (error) {
    console.error('IAP restoreOwnedPurchases failed:', error);
    return null; // 恢复失败时返回 null，不抛出异常
  }
}
