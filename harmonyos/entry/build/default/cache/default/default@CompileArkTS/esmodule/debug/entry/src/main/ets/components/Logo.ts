if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface Logo_Params {
    brand?: string;
    logoSize?: number;
}
import { BRAND_COLORS } from "@bundle:com.example.arcankey/entry/ets/model/Token";
export class Logo extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__brand = new SynchedPropertySimpleOneWayPU(params.brand, this, "brand");
        this.__logoSize = new SynchedPropertySimpleOneWayPU(params.logoSize, this, "logoSize");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: Logo_Params) {
        if (params.brand === undefined) {
            this.__brand.set('');
        }
        if (params.logoSize === undefined) {
            this.__logoSize.set(40);
        }
    }
    updateStateVars(params: Logo_Params) {
        this.__brand.reset(params.brand);
        this.__logoSize.reset(params.logoSize);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__brand.purgeDependencyOnElmtId(rmElmtId);
        this.__logoSize.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__brand.aboutToBeDeleted();
        this.__logoSize.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __brand: SynchedPropertySimpleOneWayPU<string>;
    get brand() {
        return this.__brand.get();
    }
    set brand(newValue: string) {
        this.__brand.set(newValue);
    }
    private __logoSize: SynchedPropertySimpleOneWayPU<number>;
    get logoSize() {
        return this.__logoSize.get();
    }
    set logoSize(newValue: number) {
        this.__logoSize.set(newValue);
    }
    private getColor(): string {
        return BRAND_COLORS[this.brand] ?? '#4080D0';
    }
    private getBg(): string {
        const c = this.getColor();
        const light = c === '#ffffff' || c === '#e7e9ea' || c === '#e6edf3';
        return light ? 'rgba(255,255,255,0.08)' : c + '1a';
    }
    private getBorder(): string {
        const c = this.getColor();
        const light = c === '#ffffff' || c === '#e7e9ea' || c === '#e6edf3';
        return light ? 'rgba(255,255,255,0.15)' : c + '44';
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.width(this.logoSize);
            Stack.height(this.logoSize);
            Stack.borderRadius(this.logoSize * 0.28);
            Stack.backgroundColor(this.getBg());
            Stack.border({ width: 1.5, color: this.getBorder() });
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create((this.brand || '?')[0].toUpperCase());
            Text.fontSize(this.logoSize * 0.42);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.getColor());
            Text.fontFamily('sans-serif');
        }, Text);
        Text.pop();
        Stack.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
