if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface CountdownRing_Params {
    timeLeft?: number;
    accentColor?: string;
    settings?: RenderingContextSettings;
    ctx?: CanvasRenderingContext2D;
    canvasReady?: boolean;
}
export class CountdownRing extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__timeLeft = new SynchedPropertySimpleOneWayPU(params.timeLeft, this, "timeLeft");
        this.__accentColor = new SynchedPropertySimpleOneWayPU(params.accentColor, this, "accentColor");
        this.settings = new RenderingContextSettings(true);
        this.ctx = new CanvasRenderingContext2D(this.settings);
        this.canvasReady = false;
        this.setInitiallyProvidedValue(params);
        this.declareWatch("timeLeft", this.redraw);
        this.declareWatch("accentColor", this.redraw);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: CountdownRing_Params) {
        if (params.timeLeft === undefined) {
            this.__timeLeft.set(30);
        }
        if (params.accentColor === undefined) {
            this.__accentColor.set('#4080D0');
        }
        if (params.settings !== undefined) {
            this.settings = params.settings;
        }
        if (params.ctx !== undefined) {
            this.ctx = params.ctx;
        }
        if (params.canvasReady !== undefined) {
            this.canvasReady = params.canvasReady;
        }
    }
    updateStateVars(params: CountdownRing_Params) {
        this.__timeLeft.reset(params.timeLeft);
        this.__accentColor.reset(params.accentColor);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__timeLeft.purgeDependencyOnElmtId(rmElmtId);
        this.__accentColor.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__timeLeft.aboutToBeDeleted();
        this.__accentColor.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
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
    private settings: RenderingContextSettings;
    private ctx: CanvasRenderingContext2D;
    private canvasReady: boolean;
    redraw(): void {
        this.drawRing();
    }
    private drawRing(): void {
        if (!this.canvasReady)
            return;
        const w = 34, cx = 17, cy = 17, r = 12;
        this.ctx.clearRect(0, 0, w, w);
        this.ctx.beginPath();
        this.ctx.arc(cx, cy, r, 0, 2 * Math.PI);
        this.ctx.strokeStyle = 'rgba(255,255,255,0.08)';
        this.ctx.lineWidth = 2.5;
        this.ctx.stroke();
        const col = this.accentColor;
        const frac = this.timeLeft / 30;
        this.ctx.beginPath();
        this.ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * frac);
        this.ctx.strokeStyle = col;
        this.ctx.lineWidth = 2.5;
        this.ctx.lineCap = 'round';
        this.ctx.stroke();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create({ alignContent: Alignment.Center });
            Stack.width(34);
            Stack.height(34);
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Canvas.create(this.ctx);
            Canvas.width(34);
            Canvas.height(34);
            Canvas.onReady(() => { this.canvasReady = true; this.drawRing(); });
        }, Canvas);
        Canvas.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.timeLeft.toString());
            Text.fontSize(9);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.accentColor);
        }, Text);
        Text.pop();
        Stack.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
