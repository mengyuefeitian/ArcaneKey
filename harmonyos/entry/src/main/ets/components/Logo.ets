import display from '@ohos.display';

@Component
export struct Logo {
  @Watch('redraw') @Prop brand: string = '';
  @Watch('redraw') @Prop accentColor: string = '#4080D0';
  @Prop logoSize: number = 40;
  @Prop isDark: boolean = true;

  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private ready: boolean = false;

  private lightColor(): string {
    const r = parseInt(this.accentColor.slice(1, 3), 16);
    const g = parseInt(this.accentColor.slice(3, 5), 16);
    const b = parseInt(this.accentColor.slice(5, 7), 16);
    const lr = Math.min(255, Math.round(r + (255 - r) * 0.60));
    const lg = Math.min(255, Math.round(g + (255 - g) * 0.60));
    const lb = Math.min(255, Math.round(b + (255 - b) * 0.60));
    return '#' + lr.toString(16).padStart(2, '0') + lg.toString(16).padStart(2, '0') + lb.toString(16).padStart(2, '0');
  }

  private draw(): void {
    const s = this.logoSize;
    const density = display.getDefaultDisplaySync().densityPixels;
    const letter = (this.brand || '?')[0].toUpperCase();
    this.ctx.clearRect(0, 0, s, s);
    const grad = this.ctx.createLinearGradient(0, s, s, 0);
    grad.addColorStop(0, this.accentColor);
    grad.addColorStop(1, this.lightColor());
    this.ctx.fillStyle = grad;
    // ctx.font px = physical pixels; multiply by density to match vp coordinate space
    this.ctx.font = `bold ${Math.round(s * 0.46 * density)}px sans-serif`;
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'middle';
    this.ctx.fillText(letter, s / 2, s / 2);
  }

  redraw(): void {
    if (this.ready) this.draw();
  }

  build() {
    Stack() {
      Canvas(this.ctx)
        .width(this.logoSize)
        .height(this.logoSize)
        .onReady(() => {
          this.ready = true;
          this.draw();
        })
    }
    .width(this.logoSize)
    .height(this.logoSize)
    .borderRadius(this.logoSize * 0.28)
    .backgroundColor(this.accentColor + (this.isDark ? '1a' : '28'))
    .border({ width: 1.5, color: this.accentColor + (this.isDark ? '44' : '55') })
  }
}
