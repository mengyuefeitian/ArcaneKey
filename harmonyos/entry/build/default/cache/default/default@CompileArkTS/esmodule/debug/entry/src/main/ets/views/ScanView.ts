if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ScanView_Params {
    accentColor?: string;
    onAdd?: (brand: string, account: string, secret: string) => void;
    onClose?: () => void;
    tab?: number;
    brand?: string;
    account?: string;
    secret?: string;
    brandErr?: string;
    secretErr?: string;
    scanned?: boolean;
    scanning?: boolean;
    scanErrMsg?: string;
}
import { Logo } from "@bundle:com.example.arcankey/entry/ets/components/Logo";
import type common from "@ohos:app.ability.common";
import scanBarcode from "@hms:core.scan.scanBarcode";
import scanCore from "@hms:core.scan.scanCore";
export class ScanView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__accentColor = new SynchedPropertySimpleOneWayPU(params.accentColor, this, "accentColor");
        this.onAdd = () => { };
        this.onClose = () => { };
        this.__tab = new ObservedPropertySimplePU(0, this, "tab");
        this.__brand = new ObservedPropertySimplePU('', this, "brand");
        this.__account = new ObservedPropertySimplePU('', this, "account");
        this.__secret = new ObservedPropertySimplePU('', this, "secret");
        this.__brandErr = new ObservedPropertySimplePU('', this, "brandErr");
        this.__secretErr = new ObservedPropertySimplePU('', this, "secretErr");
        this.__scanned = new ObservedPropertySimplePU(false, this, "scanned");
        this.__scanning = new ObservedPropertySimplePU(false, this, "scanning");
        this.__scanErrMsg = new ObservedPropertySimplePU('', this, "scanErrMsg");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ScanView_Params) {
        if (params.accentColor === undefined) {
            this.__accentColor.set('#4080D0');
        }
        if (params.onAdd !== undefined) {
            this.onAdd = params.onAdd;
        }
        if (params.onClose !== undefined) {
            this.onClose = params.onClose;
        }
        if (params.tab !== undefined) {
            this.tab = params.tab;
        }
        if (params.brand !== undefined) {
            this.brand = params.brand;
        }
        if (params.account !== undefined) {
            this.account = params.account;
        }
        if (params.secret !== undefined) {
            this.secret = params.secret;
        }
        if (params.brandErr !== undefined) {
            this.brandErr = params.brandErr;
        }
        if (params.secretErr !== undefined) {
            this.secretErr = params.secretErr;
        }
        if (params.scanned !== undefined) {
            this.scanned = params.scanned;
        }
        if (params.scanning !== undefined) {
            this.scanning = params.scanning;
        }
        if (params.scanErrMsg !== undefined) {
            this.scanErrMsg = params.scanErrMsg;
        }
    }
    updateStateVars(params: ScanView_Params) {
        this.__accentColor.reset(params.accentColor);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__accentColor.purgeDependencyOnElmtId(rmElmtId);
        this.__tab.purgeDependencyOnElmtId(rmElmtId);
        this.__brand.purgeDependencyOnElmtId(rmElmtId);
        this.__account.purgeDependencyOnElmtId(rmElmtId);
        this.__secret.purgeDependencyOnElmtId(rmElmtId);
        this.__brandErr.purgeDependencyOnElmtId(rmElmtId);
        this.__secretErr.purgeDependencyOnElmtId(rmElmtId);
        this.__scanned.purgeDependencyOnElmtId(rmElmtId);
        this.__scanning.purgeDependencyOnElmtId(rmElmtId);
        this.__scanErrMsg.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__accentColor.aboutToBeDeleted();
        this.__tab.aboutToBeDeleted();
        this.__brand.aboutToBeDeleted();
        this.__account.aboutToBeDeleted();
        this.__secret.aboutToBeDeleted();
        this.__brandErr.aboutToBeDeleted();
        this.__secretErr.aboutToBeDeleted();
        this.__scanned.aboutToBeDeleted();
        this.__scanning.aboutToBeDeleted();
        this.__scanErrMsg.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __accentColor: SynchedPropertySimpleOneWayPU<string>;
    get accentColor() {
        return this.__accentColor.get();
    }
    set accentColor(newValue: string) {
        this.__accentColor.set(newValue);
    }
    private onAdd: (brand: string, account: string, secret: string) => void;
    private onClose: () => void;
    private __tab: ObservedPropertySimplePU<number>; // 0=camera,1=album,2=manual
    get tab() {
        return this.__tab.get();
    }
    set tab(newValue: number) {
        this.__tab.set(newValue);
    }
    private __brand: ObservedPropertySimplePU<string>;
    get brand() {
        return this.__brand.get();
    }
    set brand(newValue: string) {
        this.__brand.set(newValue);
    }
    private __account: ObservedPropertySimplePU<string>;
    get account() {
        return this.__account.get();
    }
    set account(newValue: string) {
        this.__account.set(newValue);
    }
    private __secret: ObservedPropertySimplePU<string>;
    get secret() {
        return this.__secret.get();
    }
    set secret(newValue: string) {
        this.__secret.set(newValue);
    }
    private __brandErr: ObservedPropertySimplePU<string>;
    get brandErr() {
        return this.__brandErr.get();
    }
    set brandErr(newValue: string) {
        this.__brandErr.set(newValue);
    }
    private __secretErr: ObservedPropertySimplePU<string>;
    get secretErr() {
        return this.__secretErr.get();
    }
    set secretErr(newValue: string) {
        this.__secretErr.set(newValue);
    }
    private __scanned: ObservedPropertySimplePU<boolean>;
    get scanned() {
        return this.__scanned.get();
    }
    set scanned(newValue: boolean) {
        this.__scanned.set(newValue);
    }
    private __scanning: ObservedPropertySimplePU<boolean>;
    get scanning() {
        return this.__scanning.get();
    }
    set scanning(newValue: boolean) {
        this.__scanning.set(newValue);
    }
    private __scanErrMsg: ObservedPropertySimplePU<string>;
    get scanErrMsg() {
        return this.__scanErrMsg.get();
    }
    set scanErrMsg(newValue: string) {
        this.__scanErrMsg.set(newValue);
    }
    private validate(): boolean {
        this.brandErr = this.brand.trim() ? '' : '请输入品牌名称';
        this.secretErr = this.secret.trim() ? '' : '请输入 Secret Key';
        return !this.brandErr && !this.secretErr;
    }
    private parseOtpUri(uri: string): void {
        try {
            const q = uri.split('?')[1] ?? '';
            const params: Record<string, string> = {};
            q.split('&').forEach((p: string) => {
                const kv = p.split('=');
                const k = kv[0];
                const v = kv[1];
                if (k && v)
                    params[k] = decodeURIComponent(v);
            });
            const label = uri.split('/totp/')[1]?.split('?')[0] ?? '';
            const dec = decodeURIComponent(label);
            const b = params['issuer'] || (dec.includes(':') ? dec.split(':')[0] : dec);
            const a = dec.includes(':') ? dec.split(':')[1] : dec;
            this.brand = b;
            this.account = a;
            this.secret = params['secret'] ?? '';
            this.scanned = true;
            this.tab = 2;
        }
        catch (e) {
            this.scanErrMsg = '无法识别二维码内容';
            setTimeout(() => { this.scanErrMsg = ''; }, 2200);
        }
    }
    private async doScan(enableAlbum: boolean): Promise<void> {
        this.scanning = true;
        try {
            const ctx = getContext(this) as common.UIAbilityContext;
            const options: scanBarcode.ScanOptions = {
                scanTypes: [scanCore.ScanType.QR_CODE],
                enableMultiMode: false,
                enableAlbum: enableAlbum
            };
            const result: scanBarcode.ScanResult = await scanBarcode.startScanForResult(ctx, options);
            if (result?.originalValue)
                this.parseOtpUri(result.originalValue);
            else {
                this.scanErrMsg = '未识别到二维码';
                setTimeout(() => { this.scanErrMsg = ''; }, 2200);
            }
        }
        catch (e) {
            this.scanErrMsg = enableAlbum ? '选择图片失败，请重试' : '扫码失败，请重试';
            setTimeout(() => { this.scanErrMsg = ''; }, 2200);
        }
        this.scanning = false;
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#0d0d12');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Header
            Row.create({ space: 12 });
            // Header
            Row.width('100%');
            // Header
            Row.padding({ left: 16, right: 16, top: 14, bottom: 0 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild({ type: ButtonType.Normal });
            Button.backgroundColor('rgba(255,255,255,0.08)');
            Button.borderRadius(11);
            Button.width(36);
            Button.height(36);
            Button.onClick(() => this.onClose());
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('×');
            Text.fontSize(20);
            Text.fontColor('rgba(238,238,245,0.75)');
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('添加账号');
            Text.fontSize(17);
            Text.fontWeight(650);
            Text.fontColor('#eeeef5');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.scanned) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                    }, Blank);
                    Blank.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('✓ 已识别');
                        Text.fontSize(12);
                        Text.fontColor(this.accentColor);
                        Text.fontWeight(600);
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        // Header
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Tabs
            Row.create({ space: 2 });
            // Tabs
            Row.margin({ left: 16, right: 16, top: 14 });
            // Tabs
            Row.padding(4);
            // Tabs
            Row.backgroundColor('#191920');
            // Tabs
            Row.borderRadius(13);
            // Tabs
            Row.width('calc(100% - 32vp)');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, idx: number) => {
                const label = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(label);
                    Text.flexGrow(1);
                    Text.textAlign(TextAlign.Center);
                    Text.fontSize(12);
                    Text.fontWeight(this.tab === idx ? 650 : 400);
                    Text.fontColor(this.tab === idx ? '#fff' : 'rgba(238,238,245,0.45)');
                    Text.backgroundColor(this.tab === idx ? this.accentColor : Color.Transparent);
                    Text.borderRadius(10);
                    Text.padding({ top: 8, bottom: 8 });
                    Text.onClick(() => { this.tab = idx; });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, ['扫二维码', '选相册', '手动输入'], forEachItemGenFunction, (label: string) => label, true, false);
        }, ForEach);
        ForEach.pop();
        // Tabs
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // Scan error toast
            if (this.scanErrMsg) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.scanErrMsg);
                        Text.fontSize(13);
                        Text.fontColor('#f87171');
                        Text.fontWeight(500);
                        Text.padding({ left: 14, right: 14, top: 8, bottom: 8 });
                        Text.backgroundColor('rgba(248,113,113,0.1)');
                        Text.borderRadius(12);
                        Text.margin({ top: 8 });
                    }, Text);
                    Text.pop();
                });
            }
            // Content
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // Content
            if (this.tab === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Camera
                        Column.create({ space: 16 });
                        // Camera
                        Column.width('100%');
                        // Camera
                        Column.padding(16);
                        // Camera
                        Column.flexGrow(1);
                        // Camera
                        Column.justifyContent(FlexAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Stack.create();
                        Stack.width('100%');
                        Stack.constraintSize({ maxWidth: 310 });
                        Stack.alignContent(Alignment.TopStart);
                    }, Stack);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                        Column.aspectRatio(1);
                        Column.backgroundColor('#000');
                        Column.borderRadius(22);
                        Column.border({ width: 1, color: 'rgba(255,255,255,0.07)' });
                    }, Column);
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Dark overlay
                        Column.create();
                        // Dark overlay
                        Column.width('100%');
                        // Dark overlay
                        Column.aspectRatio(1);
                        // Dark overlay
                        Column.backgroundColor('rgba(0,0,0,0.55)');
                        // Dark overlay
                        Column.borderRadius(22);
                    }, Column);
                    // Dark overlay
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Scan frame corners
                        Stack.create();
                        // Scan frame corners
                        Stack.width('64%');
                        // Scan frame corners
                        Stack.height('64%');
                        // Scan frame corners
                        Stack.position({ x: '18%', y: '18%' });
                    }, Stack);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Top-left
                        Row.create();
                        // Top-left
                        Row.width(22);
                        // Top-left
                        Row.height(3);
                        // Top-left
                        Row.backgroundColor(this.accentColor);
                        // Top-left
                        Row.position({ x: 0, y: 0 });
                        // Top-left
                        Row.borderRadius(2);
                    }, Row);
                    // Top-left
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width(3);
                        Row.height(22);
                        Row.backgroundColor(this.accentColor);
                        Row.position({ x: 0, y: 0 });
                        Row.borderRadius(2);
                    }, Row);
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Top-right
                        Row.create();
                        // Top-right
                        Row.width(22);
                        // Top-right
                        Row.height(3);
                        // Top-right
                        Row.backgroundColor(this.accentColor);
                        // Top-right
                        Row.position({ x: '100%', y: 0 });
                        // Top-right
                        Row.borderRadius(2);
                        // Top-right
                        Row.translate({ x: '-100%' });
                    }, Row);
                    // Top-right
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width(3);
                        Row.height(22);
                        Row.backgroundColor(this.accentColor);
                        Row.position({ x: '100%', y: 0 });
                        Row.borderRadius(2);
                        Row.translate({ x: '-100%' });
                    }, Row);
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Bottom-left
                        Row.create();
                        // Bottom-left
                        Row.width(22);
                        // Bottom-left
                        Row.height(3);
                        // Bottom-left
                        Row.backgroundColor(this.accentColor);
                        // Bottom-left
                        Row.position({ x: 0, y: '100%' });
                        // Bottom-left
                        Row.borderRadius(2);
                        // Bottom-left
                        Row.translate({ y: '-100%' });
                    }, Row);
                    // Bottom-left
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width(3);
                        Row.height(22);
                        Row.backgroundColor(this.accentColor);
                        Row.position({ x: 0, y: '100%' });
                        Row.borderRadius(2);
                        Row.translate({ y: '-100%' });
                    }, Row);
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Bottom-right
                        Row.create();
                        // Bottom-right
                        Row.width(22);
                        // Bottom-right
                        Row.height(3);
                        // Bottom-right
                        Row.backgroundColor(this.accentColor);
                        // Bottom-right
                        Row.position({ x: '100%', y: '100%' });
                        // Bottom-right
                        Row.borderRadius(2);
                        // Bottom-right
                        Row.translate({ x: '-100%', y: '-100%' });
                    }, Row);
                    // Bottom-right
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width(3);
                        Row.height(22);
                        Row.backgroundColor(this.accentColor);
                        Row.position({ x: '100%', y: '100%' });
                        Row.borderRadius(2);
                        Row.translate({ x: '-100%', y: '-100%' });
                    }, Row);
                    Row.pop();
                    // Scan frame corners
                    Stack.pop();
                    Stack.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.scanning ? '正在识别二维码…' : '点击下方按钮扫描二维码');
                        Text.fontSize(13);
                        Text.fontColor('rgba(238,238,245,0.4)');
                        Text.textAlign(TextAlign.Center);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel(this.scanning ? '识别中…' : '扫描二维码');
                        Button.width('100%');
                        Button.height(50);
                        Button.borderRadius(15);
                        Button.backgroundColor(this.scanning ? 'rgba(255,255,255,0.07)' : this.accentColor);
                        Button.fontColor(this.scanning ? 'rgba(238,238,245,0.4)' : '#fff');
                        Button.fontSize(15);
                        Button.fontWeight(650);
                        Button.enabled(!this.scanning);
                        Button.onClick(() => this.doScan(false));
                    }, Button);
                    Button.pop();
                    // Camera
                    Column.pop();
                });
            }
            else if (this.tab === 1) {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Album
                        Column.create({ space: 18 });
                        // Album
                        Column.width('100%');
                        // Album
                        Column.padding({ top: 36, left: 16, right: 16 });
                        // Album
                        Column.alignItems(HorizontalAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('🖼️');
                        Text.fontSize(38);
                        Text.width(88);
                        Text.height(88);
                        Text.textAlign(TextAlign.Center);
                        Text.backgroundColor('#191920');
                        Text.borderRadius(24);
                        Text.border({ width: 1, color: 'rgba(255,255,255,0.07)' });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('从相册中选择含二维码的图片\n自动识别并添加账号');
                        Text.fontSize(14);
                        Text.fontColor('rgba(238,238,245,0.5)');
                        Text.textAlign(TextAlign.Center);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('选择图片');
                        Button.width('100%');
                        Button.height(50);
                        Button.borderRadius(15);
                        Button.backgroundColor(this.accentColor);
                        Button.fontColor('#fff');
                        Button.fontSize(15);
                        Button.fontWeight(650);
                        Button.onClick(() => this.doScan(true));
                    }, Button);
                    Button.pop();
                    // Album
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(2, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Manual
                        Scroll.create();
                        // Manual
                        Scroll.scrollBar(BarState.Off);
                        // Manual
                        Scroll.flexGrow(1);
                    }, Scroll);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 14 });
                        Column.padding({ left: 16, right: 16, top: 16 });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.scanned) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('✓ 已从二维码读取信息，请确认或修改');
                                    Text.fontSize(13);
                                    Text.fontColor(this.accentColor);
                                    Text.fontWeight(500);
                                    Text.padding(12);
                                    Text.borderRadius(12);
                                    Text.backgroundColor(this.accentColor + '18');
                                    Text.border({ width: 1, color: this.accentColor + '30' });
                                    Text.width('100%');
                                }, Text);
                                Text.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 6 });
                        Column.alignItems(HorizontalAlign.Start);
                        Column.width('100%');
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 4 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('品牌名称');
                        Text.fontSize(12);
                        Text.fontColor('rgba(238,238,245,0.45)');
                        Text.fontWeight(500);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('*');
                        Text.fontSize(12);
                        Text.fontColor(this.accentColor);
                    }, Text);
                    Text.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        TextInput.create({ text: this.brand, placeholder: '如 Google、Microsoft…' });
                        TextInput.onChange((v) => { this.brand = v; this.brandErr = ''; });
                        TextInput.backgroundColor('#191920');
                        TextInput.fontColor('#eeeef5');
                        TextInput.border({ width: 1, color: this.brandErr ? '#f87171' : 'rgba(255,255,255,0.08)' });
                        TextInput.borderRadius(12);
                        TextInput.placeholderColor('rgba(238,238,245,0.25)');
                        TextInput.height(44);
                        TextInput.padding({ left: 14, right: 14 });
                    }, TextInput);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.brandErr) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(this.brandErr);
                                    Text.fontSize(11);
                                    Text.fontColor('#f87171');
                                }, Text);
                                Text.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 6 });
                        Column.alignItems(HorizontalAlign.Start);
                        Column.width('100%');
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('账号信息');
                        Text.fontSize(12);
                        Text.fontColor('rgba(238,238,245,0.45)');
                        Text.fontWeight(500);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        TextInput.create({ text: this.account, placeholder: '邮箱、用户名等' });
                        TextInput.onChange((v) => { this.account = v; });
                        TextInput.backgroundColor('#191920');
                        TextInput.fontColor('#eeeef5');
                        TextInput.border({ width: 1, color: 'rgba(255,255,255,0.08)' });
                        TextInput.borderRadius(12);
                        TextInput.placeholderColor('rgba(238,238,245,0.25)');
                        TextInput.height(44);
                        TextInput.padding({ left: 14, right: 14 });
                    }, TextInput);
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 6 });
                        Column.alignItems(HorizontalAlign.Start);
                        Column.width('100%');
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 4 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('Secret Key');
                        Text.fontSize(12);
                        Text.fontColor('rgba(238,238,245,0.45)');
                        Text.fontWeight(500);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('*');
                        Text.fontSize(12);
                        Text.fontColor(this.accentColor);
                    }, Text);
                    Text.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        TextInput.create({ text: this.secret, placeholder: 'Base32 密钥，如 JBSWY3DP…' });
                        TextInput.onChange((v) => { this.secret = v; this.secretErr = ''; });
                        TextInput.backgroundColor('#191920');
                        TextInput.fontColor('#eeeef5');
                        TextInput.fontFamily('monospace');
                        TextInput.border({ width: 1, color: this.secretErr ? '#f87171' : 'rgba(255,255,255,0.08)' });
                        TextInput.borderRadius(12);
                        TextInput.placeholderColor('rgba(238,238,245,0.25)');
                        TextInput.height(44);
                        TextInput.padding({ left: 14, right: 14 });
                    }, TextInput);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.secretErr) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(this.secretErr);
                                    Text.fontSize(11);
                                    Text.fontColor('#f87171');
                                }, Text);
                                Text.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.brand.trim()) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Row.create({ space: 12 });
                                    Row.padding(12);
                                    Row.backgroundColor('#191920');
                                    Row.borderRadius(12);
                                    Row.border({ width: 1, color: 'rgba(255,255,255,0.06)' });
                                    Row.width('100%');
                                }, Row);
                                {
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        if (isInitialRender) {
                                            let componentCall = new Logo(this, { brand: this.brand, logoSize: 36 }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/views/ScanView.ets", line: 245, col: 17 });
                                            ViewPU.create(componentCall);
                                            let paramsLambda = () => {
                                                return {
                                                    brand: this.brand,
                                                    logoSize: 36
                                                };
                                            };
                                            componentCall.paramsGenerator_ = paramsLambda;
                                        }
                                        else {
                                            this.updateStateVarsOfChildByElmtId(elmtId, {
                                                brand: this.brand, logoSize: 36
                                            });
                                        }
                                    }, { name: "Logo" });
                                }
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Column.create({ space: 2 });
                                    Column.alignItems(HorizontalAlign.Start);
                                    Column.flexGrow(1);
                                }, Column);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(this.brand);
                                    Text.fontSize(14);
                                    Text.fontColor('#eeeef5');
                                    Text.fontWeight(600);
                                }, Text);
                                Text.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    If.create();
                                    if (this.account) {
                                        this.ifElseBranchUpdateFunction(0, () => {
                                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                                Text.create(this.account);
                                                Text.fontSize(12);
                                                Text.fontColor('rgba(238,238,245,0.4)');
                                            }, Text);
                                            Text.pop();
                                        });
                                    }
                                    else {
                                        this.ifElseBranchUpdateFunction(1, () => {
                                        });
                                    }
                                }, If);
                                If.pop();
                                Column.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('预览');
                                    Text.fontSize(11);
                                    Text.fontColor('rgba(238,238,245,0.3)');
                                }, Text);
                                Text.pop();
                                Row.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('添加账号');
                        Button.width('100%');
                        Button.height(50);
                        Button.borderRadius(15);
                        Button.backgroundColor(this.accentColor);
                        Button.fontColor('#fff');
                        Button.fontSize(15);
                        Button.fontWeight(650);
                        Button.onClick(() => {
                            if (this.validate())
                                this.onAdd(this.brand.trim(), this.account.trim(), this.secret.trim().toUpperCase());
                        });
                    }, Button);
                    Button.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.height(40);
                    }, Column);
                    Column.pop();
                    Column.pop();
                    // Manual
                    Scroll.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
