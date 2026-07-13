# HarmonyOS 内嵌扫码（全屏预览 + 中间可视窗）

## Goal

扫码 Tab 内嵌相机预览，不再跳转系统全屏扫码页。App UI 为前景；相机全屏铺在扫码内容区底层；中间镂空框为视觉瞄准区；**整帧识别**二维码，成功或离开即关相机。

## Non-goals

- 不计算 ROI / 框内裁剪识别
- 不实现可拖拽浮动相机窗
- 相册选图仍可用系统/现有路径，不强制 customScan

## Architecture

```
ScanView (tab===0 && isActive)
  Stack
    XComponent SURFACE 100%   ← customScan 预览
    遮罩（四周半透明，中间透明）
    四角装饰框
    状态文案
  上层：标题 / 子 Tab / 底部栏
```

| API | 用途 |
|-----|------|
| `customScan.init(options)` | 初始化，仅 QR |
| `customScan.start(viewControl, cb)` | surfaceId + 宽高(px) 开流识码 |
| `customScan.stop` / `release` | 关流 |

## Lifecycle

| 事件 | 行为 |
|------|------|
| 进入扫码 Tab 且子 Tab=相机 | 申请权限 → XComponent onLoad → init+start |
| 识别成功 | stop+release → parse otpauth → 添加 → 回首页 |
| 离开扫码 Tab / 切相册·手动 | stop+release |
| 权限拒绝 | toast，不启流 |

## ViewControl 尺寸

XComponent 铺满内容区；`width`/`height` 取组件 `onAreaChange` 的 px（vp × density）。中间框只做 UI，不参与 ViewControl。

## Album

`scanBarcode.startScanForResult` + `enableAlbum: true`（或等价选图识码），与内嵌预览互斥（先 stop 相机）。

## Acceptance

1. 扫码 Tab 内可见实时预览，四周 App UI 不消失  
2. 整帧识别成功即添加并关相机  
3. 离开 Tab 立刻关相机（无后台占摄像头）  
4. 首次进入弹出相机权限  
5. `assembleApp` 通过  
