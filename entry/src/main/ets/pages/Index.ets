import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { TrackRecord } from '../model/TrackModels';
import { TrackRecorder } from '../model/TrackRecorder';

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'TrackRecorder';

@Entry
@Component
struct Index {
  @State recording: boolean = false;
  @State status: string = '准备就绪';
  @State latitude: string = '--';
  @State longitude: string = '--';
  @State accuracy: string = '--';
  @State pointCount: number = 0;
  @State distance: number = 0;
  @State elapsedSeconds: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    TrackRecorder.initialize(context);
    this.bindRecorderListener();
    this.startElapsedTimer();
  }

  onPageShow(): void {
    this.bindRecorderListener();
    this.startElapsedTimer();
  }

  private bindRecorderListener(): void {
    TrackRecorder.setListener((record: TrackRecord | undefined, message: string) => {
      this.recording = TrackRecorder.isRunning;
      this.status = message;
      if (record && record.points.length > 0) {
        const last = record.points[record.points.length - 1];
        this.latitude = last.latitude.toFixed(6);
        this.longitude = last.longitude.toFixed(6);
        this.accuracy = `${last.accuracy.toFixed(0)} 米`;
        this.pointCount = record.points.length;
        this.distance = record.distance;
      } else if (!this.recording) {
        this.pointCount = 0;
        this.distance = 0;
        this.elapsedSeconds = 0;
      }
    });
  }

  private startElapsedTimer(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
    }
    this.timerId = setInterval(() => {
      const record = TrackRecorder.currentRecord;
      if (record && TrackRecorder.isRunning) {
        this.elapsedSeconds = Math.floor((Date.now() - record.startedAt) / 1000);
      }
    }, 1000);
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    // Navigation to history must not stop an active recording.
    TrackRecorder.setListener(() => {});
  }

  private async toggleRecording(): Promise<void> {
    if (TrackRecorder.isRunning) {
      await TrackRecorder.stop();
      return;
    }
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const permissions: Array<Permissions> = [
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION'
    ];
    try {
      const result = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, permissions);
      if (result.authResults.some((status: number) => status !== 0)) {
        this.status = '需要授予定位权限后才能开始记录';
        return;
      }
      await TrackRecorder.start(context);
      this.recording = true;
      this.status = TrackRecorder.currentStatus;
    } catch (error) {
      const businessError = error as BusinessError;
      const message = businessError.message ?? String(error);
      this.status = message;
      hilog.error(LOG_DOMAIN, LOG_TAG, '启动轨迹记录失败 code=%{public}d message=%{public}s',
        businessError.code ?? -1, message);
    }
  }

  private openHistory(): void {
    router.pushUrl({ url: 'pages/History' });
  }

  private formatDistance(value: number): string {
    return value >= 1000 ? `${(value / 1000).toFixed(2)} 公里` : `${value.toFixed(0)} 米`;
  }

  private formatDuration(): string {
    const hours = Math.floor(this.elapsedSeconds / 3600);
    const minutes = Math.floor((this.elapsedSeconds % 3600) / 60);
    const seconds = this.elapsedSeconds % 60;
    return hours > 0 ? `${hours}小时 ${minutes}分` : `${minutes}分 ${seconds}秒`;
  }

  build() {
    Column({ space: 18 }) {
      Row() {
        Column({ space: 5 }) {
          Text('轨迹记录')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor('#142033')
          Text('记录行程，保存并导出 GPX / CSV')
            .fontSize(15)
            .fontColor('#667085')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Button('历史轨迹 ›')
          .fontSize(14)
          .fontColor('#2563EB')
          .backgroundColor('#EAF0FF')
          .onClick(() => this.openHistory())
      }
      .width('100%')

      Column({ space: 12 }) {
        Row() {
          Text('●')
            .fontSize(12)
            .fontColor(this.recording ? '#16A34A' : '#98A2B3')
          Text(this.recording ? '正在记录' : '当前状态')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#344054')
            .margin({ left: 9 })
          Blank()
          Text(this.formatDuration())
            .fontSize(14)
            .fontColor('#667085')
        }
        .width('100%')

        Row({ space: 12 }) {
          this.metricCard('纬度', this.latitude)
          this.metricCard('经度', this.longitude)
        }
        .width('100%')

        Row({ space: 12 }) {
          this.metricCard('累计距离', this.formatDistance(this.distance))
          this.metricCard('定位精度', this.accuracy)
        }
        .width('100%')

        Text(`已采集 ${this.pointCount} 个定位点`)
          .fontSize(14)
          .fontColor('#667085')
          .width('100%')
      }
      .width('100%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(22)

      Text(this.status)
        .width('100%')
        .fontSize(14)
        .fontColor(this.status.includes('失败') || this.status.includes('需要') || this.status.includes('异常') ? '#B42318' : '#475467')
        .padding({ left: 4, right: 4 })

      Button(this.recording ? '结束并保存轨迹' : '开始记录')
        .width('100%')
        .height(58)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor(this.recording ? '#DC2626' : '#2563EB')
        .onClick(() => this.toggleRecording())

      Column({ space: 8 }) {
        Text('后台记录说明')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#344054')
        Text('开始后会申请系统定位连续任务。若系统没有授予“始终允许”，请到设置 > 应用 > 本应用 > 位置中开启。记录期间会显示系统后台任务通知。')
          .fontSize(13)
          .fontColor('#667085')
          .lineHeight(21)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#EEF2FF')
      .borderRadius(16)

      Blank()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, top: 32, bottom: 20 })
    .backgroundColor('#F5F8FC')
  }

  @Builder
  private metricCard(label: string, value: string) {
    Column({ space: 8 }) {
      Text(label).fontSize(13).fontColor('#667085')
      Text(value).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#182230')
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding(14)
    .backgroundColor('#F8FAFC')
    .borderRadius(14)
  }
}
