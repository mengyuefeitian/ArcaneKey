@Component
export struct CountdownRing {
  @Prop @Watch('redraw') timeLeft: number = 30;
  @Prop @Watch('redraw') accentColor: string = '#4080D0';

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private canvasReady: boolean = false;

  redraw(): void {
    this.drawRing();
  }

  private drawRing(): void {
    if (!this.canvasReady) return;
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

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Canvas(this.ctx)
        .width(34)
        .height(34)
        .onReady(() => { this.canvasReady = true; this.drawRing(); })
      Text(this.timeLeft.toString())
        .fontSize(9)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.accentColor)
    }
    .width(34)
    .height(34)
  }
}
