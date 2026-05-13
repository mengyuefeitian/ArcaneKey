if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ProfileView_Params {
    accentColor?: string;
    loggedIn?: boolean;
    userName?: string;
    userPhone?: string;
    userAvatar?: string;
    themeName?: string;
    harmonyLogin?: boolean;
    onLoginTap?: () => void;
    onBindPhone?: () => void;
    onLogout?: () => void;
    onBackupTap?: () => void;
    onImportTap?: () => void;
    onThemeTap?: () => void;
    onAccountTap?: () => void;
}
interface MenuItem {
    id: string;
    icon: string;
    label: string;
    desc: string;
    locked: boolean;
}
export class ProfileView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__accentColor = new SynchedPropertySimpleOneWayPU(params.accentColor, this, "accentColor");
        this.__loggedIn = new SynchedPropertySimpleOneWayPU(params.loggedIn, this, "loggedIn");
        this.__userName = new SynchedPropertySimpleOneWayPU(params.userName, this, "userName");
        this.__userPhone = new SynchedPropertySimpleOneWayPU(params.userPhone, this, "userPhone");
        this.__userAvatar = new SynchedPropertySimpleOneWayPU(params.userAvatar, this, "userAvatar");
        this.__themeName = new SynchedPropertySimpleOneWayPU(params.themeName, this, "themeName");
        this.__harmonyLogin = new SynchedPropertySimpleOneWayPU(params.harmonyLogin, this, "harmonyLogin");
        this.onLoginTap = () => { };
        this.onBindPhone = () => { };
        this.onLogout = () => { };
        this.onBackupTap = () => { };
        this.onImportTap = () => { };
        this.onThemeTap = () => { };
        this.onAccountTap = () => { };
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ProfileView_Params) {
        if (params.accentColor === undefined) {
            this.__accentColor.set('#4080D0');
        }
        if (params.loggedIn === undefined) {
            this.__loggedIn.set(false);
        }
        if (params.userName === undefined) {
            this.__userName.set('');
        }
        if (params.userPhone === undefined) {
            this.__userPhone.set('');
        }
        if (params.userAvatar === undefined) {
            this.__userAvatar.set('');
        }
        if (params.themeName === undefined) {
            this.__themeName.set('海洋蓝');
        }
        if (params.harmonyLogin === undefined) {
            this.__harmonyLogin.set(false);
        }
        if (params.onLoginTap !== undefined) {
            this.onLoginTap = params.onLoginTap;
        }
        if (params.onBindPhone !== undefined) {
            this.onBindPhone = params.onBindPhone;
        }
        if (params.onLogout !== undefined) {
            this.onLogout = params.onLogout;
        }
        if (params.onBackupTap !== undefined) {
            this.onBackupTap = params.onBackupTap;
        }
        if (params.onImportTap !== undefined) {
            this.onImportTap = params.onImportTap;
        }
        if (params.onThemeTap !== undefined) {
            this.onThemeTap = params.onThemeTap;
        }
        if (params.onAccountTap !== undefined) {
            this.onAccountTap = params.onAccountTap;
        }
    }
    updateStateVars(params: ProfileView_Params) {
        this.__accentColor.reset(params.accentColor);
        this.__loggedIn.reset(params.loggedIn);
        this.__userName.reset(params.userName);
        this.__userPhone.reset(params.userPhone);
        this.__userAvatar.reset(params.userAvatar);
        this.__themeName.reset(params.themeName);
        this.__harmonyLogin.reset(params.harmonyLogin);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__accentColor.purgeDependencyOnElmtId(rmElmtId);
        this.__loggedIn.purgeDependencyOnElmtId(rmElmtId);
        this.__userName.purgeDependencyOnElmtId(rmElmtId);
        this.__userPhone.purgeDependencyOnElmtId(rmElmtId);
        this.__userAvatar.purgeDependencyOnElmtId(rmElmtId);
        this.__themeName.purgeDependencyOnElmtId(rmElmtId);
        this.__harmonyLogin.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__accentColor.aboutToBeDeleted();
        this.__loggedIn.aboutToBeDeleted();
        this.__userName.aboutToBeDeleted();
        this.__userPhone.aboutToBeDeleted();
        this.__userAvatar.aboutToBeDeleted();
        this.__themeName.aboutToBeDeleted();
        this.__harmonyLogin.aboutToBeDeleted();
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
    private __loggedIn: SynchedPropertySimpleOneWayPU<boolean>;
    get loggedIn() {
        return this.__loggedIn.get();
    }
    set loggedIn(newValue: boolean) {
        this.__loggedIn.set(newValue);
    }
    private __userName: SynchedPropertySimpleOneWayPU<string>;
    get userName() {
        return this.__userName.get();
    }
    set userName(newValue: string) {
        this.__userName.set(newValue);
    }
    private __userPhone: SynchedPropertySimpleOneWayPU<string>;
    get userPhone() {
        return this.__userPhone.get();
    }
    set userPhone(newValue: string) {
        this.__userPhone.set(newValue);
    }
    private __userAvatar: SynchedPropertySimpleOneWayPU<string>;
    get userAvatar() {
        return this.__userAvatar.get();
    }
    set userAvatar(newValue: string) {
        this.__userAvatar.set(newValue);
    }
    private __themeName: SynchedPropertySimpleOneWayPU<string>;
    get themeName() {
        return this.__themeName.get();
    }
    set themeName(newValue: string) {
        this.__themeName.set(newValue);
    }
    private __harmonyLogin: SynchedPropertySimpleOneWayPU<boolean>;
    get harmonyLogin() {
        return this.__harmonyLogin.get();
    }
    set harmonyLogin(newValue: boolean) {
        this.__harmonyLogin.set(newValue);
    }
    private onLoginTap: () => void;
    private onBindPhone: () => void;
    private onLogout: () => void;
    private onBackupTap: () => void;
    private onImportTap: () => void;
    private onThemeTap: () => void;
    private onAccountTap: () => void;
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.scrollBar(BarState.Off);
            Scroll.width('100%');
            Scroll.height('100%');
            Scroll.backgroundColor('#0d0d12');
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.padding({ left: 20, right: 20 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Product branding
            Column.create({ space: 0 });
            // Product branding
            Column.width('100%');
            // Product branding
            Column.alignItems(HorizontalAlign.Center);
            // Product branding
            Column.padding({ top: 16, bottom: 20 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.width(64);
            Stack.height(64);
            Stack.borderRadius(20);
            Stack.backgroundColor(this.accentColor);
            Stack.shadow({ radius: 32, color: this.accentColor + '55', offsetX: 0, offsetY: 8 });
            Stack.margin({ bottom: 12 });
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('玄');
            Text.fontSize(32);
            Text.fontColor('#fff');
            Text.fontWeight(800);
        }, Text);
        Text.pop();
        Stack.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('玄钥');
            Text.fontSize(24);
            Text.fontWeight(800);
            Text.fontColor('#eeeef5');
            Text.letterSpacing(-0.5);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('玄钥：身份验证器');
            Text.fontSize(13);
            Text.fontColor('rgba(238,238,245,0.4)');
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('为你所有的重要账号（如腾讯云、阿里云、AI账号、游戏等）配备了一把"动态的、每30秒换一次的数字钥匙"');
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.3)');
            Text.textAlign(TextAlign.Center);
            Text.lineHeight(21);
            Text.margin({ top: 8 });
            Text.padding({ left: 20, right: 20 });
        }, Text);
        Text.pop();
        // Product branding
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // Account section
            if (this.loggedIn) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 12 });
                        Row.width('100%');
                        Row.padding({ left: 16, right: 16, top: 14, bottom: 14 });
                        Row.backgroundColor('#191920');
                        Row.borderRadius(14);
                        Row.border({ width: 1, color: this.accentColor + '30' });
                        Row.margin({ bottom: 20 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.userAvatar) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Image.create(this.userAvatar);
                                    Image.width(40);
                                    Image.height(40);
                                    Image.borderRadius(20);
                                }, Image);
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Stack.create();
                                    Stack.width(40);
                                    Stack.height(40);
                                    Stack.borderRadius(20);
                                    Stack.backgroundColor(this.accentColor);
                                }, Stack);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(this.userName.length > 0 ? this.userName[0].toUpperCase() : 'U');
                                    Text.fontSize(18);
                                    Text.fontColor('#fff');
                                    Text.fontWeight(700);
                                }, Text);
                                Text.pop();
                                Stack.pop();
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 2 });
                        Column.alignItems(HorizontalAlign.Start);
                        Column.flexGrow(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.userName);
                        Text.fontSize(15);
                        Text.fontColor('#eeeef5');
                        Text.fontWeight(600);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.userPhone) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(this.userPhone);
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
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.padding({ left: 16, right: 16, top: 14, bottom: 14 });
                        Row.backgroundColor('#191920');
                        Row.borderRadius(14);
                        Row.border({ width: 1, color: 'rgba(255,255,255,0.05)' });
                        Row.justifyContent(FlexAlign.SpaceBetween);
                        Row.margin({ bottom: 20 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('登录后解锁更多功能');
                        Text.fontSize(14);
                        Text.fontColor('rgba(238,238,245,0.55)');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('登录账号');
                        Button.backgroundColor(this.accentColor);
                        Button.fontColor('#fff');
                        Button.fontSize(14);
                        Button.fontWeight(600);
                        Button.borderRadius(18);
                        Button.padding({ left: 20, right: 20, top: 8, bottom: 8 });
                        Button.shadow({ radius: 20, color: this.accentColor + '55', offsetX: 0, offsetY: 4 });
                        Button.onClick(() => this.onLoginTap());
                    }, Button);
                    Button.pop();
                    Row.pop();
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Menu — inline items to ensure reactive themeName updates
            Column.create();
            // Menu — inline items to ensure reactive themeName updates
            Column.backgroundColor('#191920');
            // Menu — inline items to ensure reactive themeName updates
            Column.borderRadius(18);
            // Menu — inline items to ensure reactive themeName updates
            Column.border({ width: 1, color: 'rgba(255,255,255,0.05)' });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Account
            Column.create();
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 0 });
            Row.width('100%');
            Row.padding({ left: 16, right: 16, top: 14, bottom: 14 });
            Row.opacity(this.loggedIn ? 1 : 0.38);
            Row.onClick(() => {
                if (!this.loggedIn)
                    this.onLoginTap();
                else
                    this.onAccountTap();
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('👤');
            Text.fontSize(22);
            Text.margin({ right: 14 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 2 });
            Column.alignItems(HorizontalAlign.Start);
            Column.flexGrow(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('账号管理');
            Text.fontSize(15);
            Text.fontColor('#eeeef5');
            Text.fontWeight(520);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.loggedIn ? '管理你的账号信息' : '登录后可用');
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.38)');
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('›');
            Text.fontSize(18);
            Text.fontColor('rgba(238,238,245,0.3)');
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.color('rgba(255,255,255,0.05)');
            Divider.strokeWidth(1);
            Divider.margin({ left: 16, right: 16 });
        }, Divider);
        // Account
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Backup
            Column.create();
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 0 });
            Row.width('100%');
            Row.padding({ left: 16, right: 16, top: 14, bottom: 14 });
            Row.opacity(this.loggedIn ? 1 : 0.38);
            Row.onClick(() => { if (this.loggedIn)
                this.onBackupTap(); });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('☁️');
            Text.fontSize(22);
            Text.margin({ right: 14 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 2 });
            Column.alignItems(HorizontalAlign.Start);
            Column.flexGrow(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('备份数据');
            Text.fontSize(15);
            Text.fontColor('#eeeef5');
            Text.fontWeight(520);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('加密导出所有验证码');
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.38)');
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('›');
            Text.fontSize(18);
            Text.fontColor('rgba(238,238,245,0.3)');
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.color('rgba(255,255,255,0.05)');
            Divider.strokeWidth(1);
            Divider.margin({ left: 16, right: 16 });
        }, Divider);
        // Backup
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Import
            Column.create();
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 0 });
            Row.width('100%');
            Row.padding({ left: 16, right: 16, top: 14, bottom: 14 });
            Row.opacity(this.loggedIn ? 1 : 0.38);
            Row.onClick(() => { if (this.loggedIn)
                this.onImportTap(); });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('📥');
            Text.fontSize(22);
            Text.margin({ right: 14 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 2 });
            Column.alignItems(HorizontalAlign.Start);
            Column.flexGrow(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('导入备份');
            Text.fontSize(15);
            Text.fontColor('#eeeef5');
            Text.fontWeight(520);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('从加密文件恢复');
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.38)');
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('›');
            Text.fontSize(18);
            Text.fontColor('rgba(238,238,245,0.3)');
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.color('rgba(255,255,255,0.05)');
            Divider.strokeWidth(1);
            Divider.margin({ left: 16, right: 16 });
        }, Divider);
        // Import
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Theme
            Column.create();
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 0 });
            Row.width('100%');
            Row.padding({ left: 16, right: 16, top: 14, bottom: 14 });
            Row.onClick(() => this.onThemeTap());
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('🎨');
            Text.fontSize(22);
            Text.margin({ right: 14 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 2 });
            Column.alignItems(HorizontalAlign.Start);
            Column.flexGrow(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('皮肤主题');
            Text.fontSize(15);
            Text.fontColor('#eeeef5');
            Text.fontWeight(520);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.themeName);
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.38)');
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('›');
            Text.fontSize(18);
            Text.fontColor('rgba(238,238,245,0.3)');
        }, Text);
        Text.pop();
        Row.pop();
        // Theme
        Column.pop();
        // Menu — inline items to ensure reactive themeName updates
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.loggedIn) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('退出登录');
                        Button.width('100%');
                        Button.backgroundColor(Color.Transparent);
                        Button.border({ width: 1, color: 'rgba(255,255,255,0.08)' });
                        Button.borderRadius(14);
                        Button.fontColor('rgba(238,238,245,0.45)');
                        Button.fontSize(14);
                        Button.margin({ top: 16 });
                        Button.onClick(() => this.onLogout());
                    }, Button);
                    Button.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('玄钥 v1.0.0');
            Text.fontSize(12);
            Text.fontColor('rgba(238,238,245,0.2)');
            Text.width('100%');
            Text.textAlign(TextAlign.Center);
            Text.padding({ top: 24, bottom: 100 });
        }, Text);
        Text.pop();
        Column.pop();
        Scroll.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
