import { batteryInfo } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State level: number = 0;
  @State isCharging: boolean = false;

  aboutToAppear() {
    // 读取当前电量
    this.level = batteryInfo.batterySOC;
    // 读取充电状态
    this.isCharging =
      batteryInfo.chargingStatus === batteryInfo.BatteryChargeState.ENABLE ||
        batteryInfo.chargingStatus === batteryInfo.BatteryChargeState.FULL;
  }

  build() {
    Column() {
      Text(`${this.level}%`)
        .fontSize(64)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.level > 20 ? '#4CAF50' : '#F44336')

      Text(this.isCharging ? '⚡ 充电中' : '未充电')
        .fontSize(18)
        .fontColor('#999999')
        .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)   // 垂直居中
    .alignItems(HorizontalAlign.Center) // 水平居中
  }
}