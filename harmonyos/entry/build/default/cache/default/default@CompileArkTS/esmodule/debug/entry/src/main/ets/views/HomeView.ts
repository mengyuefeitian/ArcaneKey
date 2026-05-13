if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface HomeView_Params {
    tokens?: Token[];
    otpMap?: Record<string, OtpPair>;
    timeLeft?: number;
    accentColor?: string;
    searching?: boolean;
    searchQ?: string;
    onEdit?: (tok: Token) => void;
    onCopy?: (code: string, brand: string) => void;
    onNavHide?: () => void;
    onNavShow?: () => void;
    lastScrollY?: number;
    scroller?: Scroller;
}
import type { Token, OtpPair } from '../model/Token';
import { TokenCard } from "@bundle:com.example.arcankey/entry/ets/components/TokenCard";
export class HomeView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__tokens = new SynchedPropertyObjectOneWayPU(params.tokens, this, "tokens");
        this.__otpMap = new SynchedPropertyObjectOneWayPU(params.otpMap, this, "otpMap");
        this.__timeLeft = new SynchedPropertySimpleOneWayPU(params.timeLeft, this, "timeLeft");
        this.__accentColor = new SynchedPropertySimpleOneWayPU(params.accentColor, this, "accentColor");
        this.__searching = new SynchedPropertySimpleTwoWayPU(params.searching, this, "searching");
        this.__searchQ = new SynchedPropertySimpleTwoWayPU(params.searchQ, this, "searchQ");
        this.onEdit = () => { };
        this.onCopy = () => { };
        this.onNavHide = () => { };
        this.onNavShow = () => { };
        this.lastScrollY = 0;
        this.scroller = new Scroller();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: HomeView_Params) {
        if (params.tokens === undefined) {
            this.__tokens.set([]);
        }
        if (params.otpMap === undefined) {
            this.__otpMap.set({});
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
        if (params.onNavHide !== undefined) {
            this.onNavHide = params.onNavHide;
        }
        if (params.onNavShow !== undefined) {
            this.onNavShow = params.onNavShow;
        }
        if (params.lastScrollY !== undefined) {
            this.lastScrollY = params.lastScrollY;
        }
        if (params.scroller !== undefined) {
            this.scroller = params.scroller;
        }
    }
    updateStateVars(params: HomeView_Params) {
        this.__tokens.reset(params.tokens);
        this.__otpMap.reset(params.otpMap);
        this.__timeLeft.reset(params.timeLeft);
        this.__accentColor.reset(params.accentColor);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__tokens.purgeDependencyOnElmtId(rmElmtId);
        this.__otpMap.purgeDependencyOnElmtId(rmElmtId);
        this.__timeLeft.purgeDependencyOnElmtId(rmElmtId);
        this.__accentColor.purgeDependencyOnElmtId(rmElmtId);
        this.__searching.purgeDependencyOnElmtId(rmElmtId);
        this.__searchQ.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__tokens.aboutToBeDeleted();
        this.__otpMap.aboutToBeDeleted();
        this.__timeLeft.aboutToBeDeleted();
        this.__accentColor.aboutToBeDeleted();
        this.__searching.aboutToBeDeleted();
        this.__searchQ.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __tokens: SynchedPropertySimpleOneWayPU<Token[]>;
    get tokens() {
        return this.__tokens.get();
    }
    set tokens(newValue: Token[]) {
        this.__tokens.set(newValue);
    }
    private __otpMap: SynchedPropertySimpleOneWayPU<Record<string, OtpPair>>;
    get otpMap() {
        return this.__otpMap.get();
    }
    set otpMap(newValue: Record<string, OtpPair>) {
        this.__otpMap.set(newValue);
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
    private __searching: SynchedPropertySimpleTwoWayPU<boolean>;
    get searching() {
        return this.__searching.get();
    }
    set searching(newValue: boolean) {
        this.__searching.set(newValue);
    }
    private __searchQ: SynchedPropertySimpleTwoWayPU<string>;
    get searchQ() {
        return this.__searchQ.get();
    }
    set searchQ(newValue: string) {
        this.__searchQ.set(newValue);
    }
    private onEdit: (tok: Token) => void;
    private onCopy: (code: string, brand: string) => void;
    private onNavHide: () => void;
    private onNavShow: () => void;
    private lastScrollY: number;
    private scroller: Scroller;
    private filtered(): Token[] {
        if (!this.searchQ)
            return this.tokens;
        const q = this.searchQ.toLowerCase();
        return this.tokens.filter(t => t.brand.toLowerCase().includes(q) || t.account.toLowerCase().includes(q));
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#0d0d12');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // Inline search bar (shown only when searching, takes one row at top)
            if (this.searching) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 6 });
                        Row.width('100%');
                        Row.height(36);
                        Row.padding({ left: 8, right: 8 });
                        Row.margin({ left: 16, right: 16, top: 4, bottom: 4 });
                        Row.backgroundColor('#191920');
                        Row.borderRadius(10);
                        Row.border({ width: 1, color: this.accentColor + '55' });
                        Row.alignItems(VerticalAlign.Center);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Back arrow
                        Text.create('←');
                        // Back arrow
                        Text.fontSize(16);
                        // Back arrow
                        Text.fontColor('rgba(238,238,245,0.55)');
                        // Back arrow
                        Text.width(28);
                        // Back arrow
                        Text.height(28);
                        // Back arrow
                        Text.textAlign(TextAlign.Center);
                        // Back arrow
                        Text.onClick(() => { this.searching = false; this.searchQ = ''; });
                    }, Text);
                    // Back arrow
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Search icon
                        SymbolGlyph.create({ "id": 125831500, "type": 40000, params: [], "bundleName": "com.example.arcankey", "moduleName": "entry" });
                        // Search icon
                        SymbolGlyph.fontColor(['rgba(238,238,245,0.55)']);
                        // Search icon
                        SymbolGlyph.fontSize(18);
                    }, SymbolGlyph);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        TextInput.create({ text: this.searchQ, placeholder: '搜索品牌或账号' });
                        TextInput.flexGrow(1);
                        TextInput.backgroundColor(Color.Transparent);
                        TextInput.fontColor('#eeeef5');
                        TextInput.placeholderColor('rgba(238,238,245,0.25)');
                        TextInput.fontSize(13);
                        TextInput.height(28);
                        TextInput.padding(0);
                        TextInput.onChange((v) => { this.searchQ = v; });
                    }, TextInput);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // Clear button
                        if (this.searchQ.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('×');
                                    Text.fontSize(16);
                                    Text.fontWeight(500);
                                    Text.fontColor('rgba(238,238,245,0.5)');
                                    Text.width(20);
                                    Text.height(20);
                                    Text.textAlign(TextAlign.Center);
                                    Text.onClick(() => { this.searchQ = ''; });
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
                    Row.pop();
                });
            }
            // List
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // List
            List.create({ space: 0, scroller: this.scroller });
            // List
            List.width('100%');
            // List
            List.flexGrow(1);
            // List
            List.padding({ left: 16, right: 16, top: this.searching ? 0 : 8 });
            // List
            List.scrollBar(BarState.Off);
            // List
            List.onScrollFrameBegin((offset: number) => {
                const y = this.scroller.currentOffset().yOffset + offset;
                if (y < 30) {
                    this.onNavShow();
                }
                else if (y > this.lastScrollY) {
                    this.onNavHide();
                }
                else {
                    this.onNavShow();
                }
                this.lastScrollY = y;
                return { offsetRemain: offset };
            });
        }, List);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.filtered().length === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    {
                        const itemCreation = (elmtId, isInitialRender) => {
                            ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                            ListItem.create(deepRenderFunction, true);
                            if (!isInitialRender) {
                                ListItem.pop();
                            }
                            ViewStackProcessor.StopGetAccessRecording();
                        };
                        const itemCreation2 = (elmtId, isInitialRender) => {
                            ListItem.create(deepRenderFunction, true);
                        };
                        const deepRenderFunction = (elmtId, isInitialRender) => {
                            itemCreation(elmtId, isInitialRender);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Column.create({ space: 12 });
                                Column.width('100%');
                                Column.padding({ top: 70, bottom: 70 });
                                Column.justifyContent(FlexAlign.Center);
                            }, Column);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('🔍');
                                Text.fontSize(36);
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(this.searchQ ? '未找到匹配账号' : '暂无验证码\n点击下方扫码添加');
                                Text.fontSize(14);
                                Text.fontColor('rgba(238,238,245,0.25)');
                                Text.textAlign(TextAlign.Center);
                            }, Text);
                            Text.pop();
                            Column.pop();
                            ListItem.pop();
                        };
                        this.observeComponentCreation2(itemCreation2, ListItem);
                        ListItem.pop();
                    }
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const tok = _item;
                {
                    const itemCreation = (elmtId, isInitialRender) => {
                        ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                        ListItem.create(deepRenderFunction, true);
                        if (!isInitialRender) {
                            ListItem.pop();
                        }
                        ViewStackProcessor.StopGetAccessRecording();
                    };
                    const itemCreation2 = (elmtId, isInitialRender) => {
                        ListItem.create(deepRenderFunction, true);
                    };
                    const deepRenderFunction = (elmtId, isInitialRender) => {
                        itemCreation(elmtId, isInitialRender);
                        {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                if (isInitialRender) {
                                    let componentCall = new TokenCard(this, {
                                        token: tok,
                                        otp: this.otpMap[tok.id] ?? { current: '------', next: '------' },
                                        timeLeft: this.timeLeft,
                                        accentColor: this.accentColor,
                                        onEdit: (t: Token) => this.onEdit(t),
                                        onCopy: (code: string, brand: string) => this.onCopy(code, brand),
                                    }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/views/HomeView.ets", line: 87, col: 13 });
                                    ViewPU.create(componentCall);
                                    let paramsLambda = () => {
                                        return {
                                            token: tok,
                                            otp: this.otpMap[tok.id] ?? { current: '------', next: '------' },
                                            timeLeft: this.timeLeft,
                                            accentColor: this.accentColor,
                                            onEdit: (t: Token) => this.onEdit(t),
                                            onCopy: (code: string, brand: string) => this.onCopy(code, brand)
                                        };
                                    };
                                    componentCall.paramsGenerator_ = paramsLambda;
                                }
                                else {
                                    this.updateStateVarsOfChildByElmtId(elmtId, {
                                        token: tok,
                                        otp: this.otpMap[tok.id] ?? { current: '------', next: '------' },
                                        timeLeft: this.timeLeft,
                                        accentColor: this.accentColor
                                    });
                                }
                            }, { name: "TokenCard" });
                        }
                        ListItem.pop();
                    };
                    this.observeComponentCreation2(itemCreation2, ListItem);
                    ListItem.pop();
                }
            };
            this.forEachUpdateFunction(elmtId, this.filtered(), forEachItemGenFunction, (tok: Token) => tok.id, false, false);
        }, ForEach);
        ForEach.pop();
        {
            const itemCreation = (elmtId, isInitialRender) => {
                ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                ListItem.create(deepRenderFunction, true);
                if (!isInitialRender) {
                    ListItem.pop();
                }
                ViewStackProcessor.StopGetAccessRecording();
            };
            const itemCreation2 = (elmtId, isInitialRender) => {
                ListItem.create(deepRenderFunction, true);
            };
            const deepRenderFunction = (elmtId, isInitialRender) => {
                itemCreation(elmtId, isInitialRender);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.height(96);
                }, Column);
                Column.pop();
                ListItem.pop();
            };
            this.observeComponentCreation2(itemCreation2, ListItem);
            ListItem.pop();
        }
        // List
        List.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
