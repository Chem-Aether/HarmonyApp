const storageLocal = new LocalStorage();
storageLocal.setOrCreate('level', 0);
storageLocal.setOrCreate('isCharging', false);
storageLocal.setOrCreate('statusText', '获取中');
storageLocal.setOrCreate('updateTime', '--:--');

@Entry(storageLocal)
@Component
struct WidgetCard {
  @LocalStorageProp('level') level: number = 0;
  @LocalStorageProp('isCharging') isCharging: boolean = false;
  @LocalStorageProp('statusText') statusText: string = '获取中';
  @LocalStorageProp('updateTime') updateTime: string = '--:--';

  readonly actionType: string = 'message';
  readonly message: string = 'refreshBattery';
  readonly fullWidthPercent: string = '100%';
  readonly fullHeightPercent: string = '100%';

  private getLevelColor(): string {
    if (this.level <= 20) {
      return '#E5484D';
    }
    if (this.isCharging) {
      return '#2EAD5B';
    }
    return '#1677D2';
  }

  private getTrackColor(): string {
    if (this.level <= 20) {
      return '#FFE5E5';
    }
    if (this.isCharging) {
      return '#DDF7E6';
    }
    return '#DDEEFF';
  }

  build() {
    Row() {
      Column() {
        Text(`${this.level}%`)
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getLevelColor())
          .textAlign(TextAlign.Center)

        Text('电量')
          .fontSize(10)
          .fontColor('#7C8794')
          .margin({ top: 1 })
      }
      .width('42%')
      .height(this.fullHeightPercent)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Row() {
          Text(this.statusText)
            .fontSize(12)
            .fontColor('#4F5965')
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.isCharging ? '充' : '')
            .width(20)
            .height(20)
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .backgroundColor(this.isCharging ? this.getLevelColor() : '#00000000')
            .borderRadius(10)
        }
        .width(this.fullWidthPercent)

        Stack({ alignContent: Alignment.Start }) {
          Row()
            .width(this.fullWidthPercent)
            .height(8)
            .backgroundColor(this.getTrackColor())
            .borderRadius(4)

          Row()
            .width(`${this.level}%`)
            .height(8)
            .backgroundColor(this.getLevelColor())
            .borderRadius(4)
        }
        .width(this.fullWidthPercent)
        .height(8)
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .height(this.fullHeightPercent)
      .justifyContent(FlexAlign.Center)
      .padding({ right: 2 })
    }
    .width(this.fullWidthPercent)
    .height(this.fullHeightPercent)
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      postCardAction(this, {
        action: this.actionType,
        params: {
          message: this.message
        }
      });
    })
  }
}
