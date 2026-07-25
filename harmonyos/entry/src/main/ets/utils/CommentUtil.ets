import { common, bundleManager } from '@kit.AbilityKit';
import { commentManager } from '@kit.AppGalleryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  loadCommentDoneVer,
  loadCommentPromptedVer,
  saveCommentDoneVer,
  saveCommentPromptedVer
} from './StorageUtil';

export function getAppVersionName(): string {
  try {
    const info = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
    return info.versionName || '0';
  } catch (_) {
    return '0';
  }
}

export function mapCommentError(code: number): string {
  if (code === 1021500006) {
    return '请先登录华为账号后再评价';
  }
  if (code === 1021500007) {
    return '您已评价过当前版本，感谢支持';
  }
  if (code === 1021500008) {
    return '评价次数已达上限';
  }
  if (code === 1021500009) {
    return '您近期已评价过，感谢支持';
  }
  if (code === 1021500003) {
    return '无法连接应用市场，请稍后重试';
  }
  return '暂时无法打开评价，请稍后重试';
}

export async function showAppComment(
  context: common.UIAbilityContext,
  markDoneOnSuccess: boolean
): Promise<string> {
  const ver = getAppVersionName();
  try {
    await commentManager.showCommentDialog(context);
    if (markDoneOnSuccess) {
      await saveCommentDoneVer(ver);
    }
    return '';
  } catch (e) {
    const err = e as BusinessError;
    const code: number = err.code !== undefined ? err.code : -1;
    console.warn('[CommentUtil] showCommentDialog failed:', code, err.message);
    if (code === 1021500007 || code === 1021500009) {
      await saveCommentDoneVer(ver);
    }
    return mapCommentError(code);
  }
}

export async function canSmartPromptComment(): Promise<boolean> {
  const ver = getAppVersionName();
  const done = await loadCommentDoneVer();
  if (done === ver) {
    return false;
  }
  const prompted = await loadCommentPromptedVer();
  if (prompted === ver) {
    return false;
  }
  return true;
}

export async function markCommentPrompted(): Promise<void> {
  await saveCommentPromptedVer(getAppVersionName());
}
