import { BRAND_COLORS } from '../model/Token';

@Component
export struct Logo {
  @Prop brand: string = '';
  @Prop logoSize: number = 40;

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

  build() {
    Stack() {
      Text((this.brand || '?')[0].toUpperCase())
        .fontSize(this.logoSize * 0.42)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getColor())
        .fontFamily('sans-serif')
    }
    .width(this.logoSize)
    .height(this.logoSize)
    .borderRadius(this.logoSize * 0.28)
    .backgroundColor(this.getBg())
    .border({ width: 1.5, color: this.getBorder() })
  }
}
