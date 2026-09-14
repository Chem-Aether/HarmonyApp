import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { batteryInfo, BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'EntryFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

interface BatteryFormData {
  level: number;
  isCharging: boolean;
  statusText: string;
  updateTime: string;
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData(this.createBatteryFormData());
  }

  onCastToNormalForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onCastToNormalForm: ${formId}`);
  }

  onUpdateForm(formId: string): void {
    this.updateBatteryForm(formId);
  }

  onFormEvent(formId: string, message: string): void {
    this.updateBatteryForm(formId);
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onRemoveForm: ${formId}`);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }

  private updateBatteryForm(formId: string): void {
    const batteryData: BatteryFormData = this.createBatteryFormData();
    const formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(batteryData);

    formProvider.updateForm(formId, formData).catch((error: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `updateForm failed. code: ${error.code}, message: ${error.message}`);
    });
  }

  private createBatteryFormData(): BatteryFormData {
    const level: number = batteryInfo.batterySOC;
    const chargingStatus: batteryInfo.BatteryChargeState = batteryInfo.chargingStatus;
    const isCharging: boolean =
      chargingStatus === batteryInfo.BatteryChargeState.ENABLE ||
      chargingStatus === batteryInfo.BatteryChargeState.FULL;

    const data: BatteryFormData = {
      level: level,
      isCharging: isCharging,
      statusText: this.createStatusText(level, chargingStatus),
      updateTime: this.formatTime(new Date())
    };
    hilog.info(DOMAIN_NUMBER, TAG, `battery form data: ${JSON.stringify(data)}`);
    return data;
  }

  private createStatusText(level: number, chargingStatus: batteryInfo.BatteryChargeState): string {
    if (chargingStatus === batteryInfo.BatteryChargeState.FULL) {
      return '已充满';
    }
    if (chargingStatus === batteryInfo.BatteryChargeState.ENABLE) {
      return '充电中';
    }
    if (level <= 20) {
      return '电量不足';
    }
    return '电量正常';
  }

  private formatTime(date: Date): string {
    const hour: string = date.getHours().toString().padStart(2, '0');
    const minute: string = date.getMinutes().toString().padStart(2, '0');
    return `${hour}:${minute}`;
  }
}
