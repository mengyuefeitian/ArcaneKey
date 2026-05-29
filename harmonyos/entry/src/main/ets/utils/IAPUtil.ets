import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';

export const MEMBER_PRODUCT_ID = 'com.arcanekey.authenticator.member_lifetime';

interface PurchasePayload {
  productId?: string;
  purchaseToken?: string;
  orderId?: string;
}

export async function queryProductInfo(context: common.UIAbilityContext): Promise<iap.Product> {
  const products = await iap.queryProducts(context, {
    productType: iap.ProductType.NONCONSUMABLE,
    productIds: [MEMBER_PRODUCT_ID],
  });
  if (!products || products.length === 0) {
    throw new Error('商品信息查询为空');
  }
  return products[0];
}

export async function launchPurchase(context: common.UIAbilityContext): Promise<{ purchaseToken: string }> {
  const result = await iap.createPurchase(context, {
    productType: iap.ProductType.NONCONSUMABLE,
    productId: MEMBER_PRODUCT_ID,
  });
  const payload = JSON.parse(result.purchaseData) as PurchasePayload;
  return { purchaseToken: payload.purchaseToken ?? '' };
}

export async function restoreOwnedPurchases(
  context: common.UIAbilityContext
): Promise<{ purchaseToken: string } | null> {
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
      return { purchaseToken: payload.purchaseToken ?? '' };
    }
  }
  return null;
}
