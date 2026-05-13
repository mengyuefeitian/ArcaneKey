if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface TokenCard_Params {
    token?: Token;
    otp?: OtpPair;
    timeLeft?: number;
    accentColor?: string;
    onEdit?: (tok: Token) => void;
    onCopy?: (code: string, brand: string) => void;
}
import type { Token, OtpPair } from '../model/Token';
import { Logo } from "@bundle:com.example.arcankey/entry/ets/components/Logo";
import { CountdownRing } from "@bundle:com.example.arcankey/entry/ets/components/CountdownRing";
function fmt(s: string): string {
    if (!s || s.length < 6)
        return s || '------';
    return s.slice(0, 3) + ' ' + s.slice(3);
}
export class TokenCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__token = new SynchedPropertyObjectOneWayPU(params.token, this, "token");
        this.__otp = new SynchedPropertyObjectOneWayPU(params.otp, this, "otp");
        this.__timeLeft = new SynchedPropertySimpleOneWayPU(params.timeLeft, this, "timeLeft");
        this.__accentColor = new SynchedPropertySimpleOneWayPU(params.accentColor, this, "accentColor");
        this.onEdit = () => { };
        this.onCopy = () => { };
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: TokenCard_Params) {
        if (params.token === undefined) {
            this.__token.set({ id: '', brand: '', account: '', secret: '' });
        }
        if (params.otp === undefined) {
            this.__otp.set({ current: '------', next: '------' });
        }
        if (params.timeLeft === undefined) {
            this.__timeLeft.set(30);
        }
        if (params.accentColor === undefined) {
            this.__accentColor.set('#4080D0');
        }
        if (params.onEdit !== undefined) {
            this.onEdit = params.onEdit;
        }
        if (params.onCopy !== undefined) {
            this.onCopy = params.onCopy;
        }
    }
    updateStateVars(params: TokenCard_Params) {
        this.__token.reset(params.token);
        this.__otp.reset(params.otp);
        this.__timeLeft.reset(params.timeLeft);
        this.__accentColor.reset(params.accentColor);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__token.purgeDependencyOnElmtId(rmElmtId);
        this.__otp.purgeDependencyOnElmtId(rmElmtId);
        this.__timeLeft.purgeDependencyOnElmtId(rmElmtId);
        this.__accentColor.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__token.aboutToBeDeleted();
        this.__otp.aboutToBeDeleted();
        this.__timeLeft.aboutToBeDeleted();
        this.__accentColor.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __token: SynchedPropertySimpleOneWayPU<Token>;
    get token() {
        return this.__token.get();
    }
    set token(newValue: Token) {
        this.__token.set(newValue);
    }
    private __otp: SynchedPropertySimpleOneWayPU<OtpPair>;
    get otp() {
        return this.__otp.get();
    }
    set otp(newValue: OtpPair) {
        this.__otp.set(newValue);
    }
    private __timeLeft: SynchedPropertySimpleOneWayPU<number>;
    get timeLeft() {
        return this.__timeLeft.get();
    }
    set timeLeft(newValue: number) {
        this.__timeLeft.set(newValue);
    }
    private __accentColor: SynchedPropertySimpleOneWayPU<string>;
    get accentColor() {
        return this.__accentColor.get();
    }
    set accentColor(newValue: string) {
        this.__accentColor.set(newValue);
    }
    private onEdit: (tok: Token) => void;
    private onCopy: (code: string, brand: string) => void;
    private interpolateColor(hex: string, t: number): string {
        const r = parseInt(hex.slice(1, 3), 16);
        const g = parseInt(hex.slice(3, 5), 16);
        const b = parseInt(hex.slice(5, 7), 16);
        const mix = 0.4 * (1 - t);
        const nr = Math.round(r + (255 - r) * mix);
        const ng = Math.round(g + (255 - g) * mix);
        const nb = Math.round(b + (255 - b) * mix);
        const rs = nr.toString(16).padStart(2, '0');
        const gs = ng.toString(16).padStart(2, '0');
        const bs = nb.toString(16).padStart(2, '0');
        return '#' + rs + gs + bs;
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.borderRadius(18);
            Column.backgroundColor('#191920');
            Column.border({ width: 1, color: 'rgba(255,255,255,0.05)' });
            Column.margin({ bottom: 10 });
            Column.clip(true);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Upper row — edit
            Row.create({ space: 12 });
            // Upper row — edit
            Row.width('100%');
            // Upper row — edit
            Row.padding({ left: 16, right: 16, top: 14, bottom: 10 });
            // Upper row — edit
            Row.onClick(() => this.onEdit(ObservedObject.GetRawObject(this.token)));
        }, Row);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new Logo(this, { brand: this.token.brand, logoSize: 42 }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/components/TokenCard.ets", line: 37, col: 9 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            brand: this.token.brand,
                            logoSize: 42
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        brand: this.token.brand, logoSize: 42
                    });
                }
            }, { name: "Logo" });
        }
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 2 });
            Column.alignItems(HorizontalAlign.Start);
            Column.flexGrow(1);
            Column.flexShrink(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.token.brand);
            Text.fontSize(15);
            Text.fontWeight(650);
            Text.fontColor('#eeeef5');
            Text.maxLines(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.token.account);
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.42)');
            Text.maxLines(1);
            Text.textOverflow({ overflow: TextOverflow.Ellipsis });
        }, Text);
        Text.pop();
        Column.pop();
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new CountdownRing(this, { timeLeft: this.timeLeft, accentColor: this.accentColor }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/components/TokenCard.ets", line: 47, col: 9 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            timeLeft: this.timeLeft,
                            accentColor: this.accentColor
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        timeLeft: this.timeLeft, accentColor: this.accentColor
                    });
                }
            }, { name: "CountdownRing" });
        }
        // Upper row — edit
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.color('rgba(255,255,255,0.055)');
            Divider.strokeWidth(1);
            Divider.margin({ left: 16, right: 16 });
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Lower row — copy
            Row.create();
            // Lower row — copy
            Row.width('100%');
            // Lower row — copy
            Row.padding({ left: 16, right: 16, top: 11, bottom: 14 });
            // Lower row — copy
            Row.onClick(() => this.onCopy(this.otp.current, this.token.brand));
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 1 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(fmt(this.otp.current).charAt(0));
            Text.fontSize(30);
            Text.fontWeight(700);
            Text.fontFamily('monospace');
            Text.fontColor(this.interpolateColor(this.accentColor, 0));
            Text.letterSpacing(2);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(fmt(this.otp.current).charAt(1));
            Text.fontSize(30);
            Text.fontWeight(700);
            Text.fontFamily('monospace');
            Text.fontColor(this.interpolateColor(this.accentColor, 0.2));
            Text.letterSpacing(2);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(fmt(this.otp.current).charAt(2));
            Text.fontSize(30);
            Text.fontWeight(700);
            Text.fontFamily('monospace');
            Text.fontColor(this.interpolateColor(this.accentColor, 0.4));
            Text.letterSpacing(2);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(' ');
            Text.fontSize(30);
            Text.fontWeight(700);
            Text.fontFamily('monospace');
            Text.letterSpacing(8);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(fmt(this.otp.current).charAt(4));
            Text.fontSize(30);
            Text.fontWeight(700);
            Text.fontFamily('monospace');
            Text.fontColor(this.interpolateColor(this.accentColor, 0.6));
            Text.letterSpacing(2);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(fmt(this.otp.current).charAt(5));
            Text.fontSize(30);
            Text.fontWeight(700);
            Text.fontFamily('monospace');
            Text.fontColor(this.interpolateColor(this.accentColor, 0.8));
            Text.letterSpacing(2);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(fmt(this.otp.current).charAt(6));
            Text.fontSize(30);
            Text.fontWeight(700);
            Text.fontFamily('monospace');
            Text.fontColor(this.interpolateColor(this.accentColor, 1.0));
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 2 });
            Column.alignItems(HorizontalAlign.End);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 3 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('📋');
            Text.fontSize(10);
            Text.fontColor('rgba(238,238,245,0.28)');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('点击复制');
            Text.fontSize(10);
            Text.fontColor('rgba(238,238,245,0.28)');
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 5 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('下一个');
            Text.fontSize(10);
            Text.fontColor('rgba(238,238,245,0.28)');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(fmt(this.otp.next));
            Text.fontSize(13);
            Text.fontWeight(600);
            Text.fontColor('rgba(238,238,245,0.32)');
            Text.fontFamily('monospace');
            Text.letterSpacing(2);
        }, Text);
        Text.pop();
        Row.pop();
        Column.pop();
        // Lower row — copy
        Row.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
