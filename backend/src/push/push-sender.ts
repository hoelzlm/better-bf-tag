export type PushPlatform = 'android' | 'ios';

/** Discriminated union (ADR 0021): a real Alarmierung or a Testalarm (no incident/alarm). */
export type PushData =
  | {
      type: 'alarm.triggered';
      incident_id: string;
      alarm_id: string;
      keyword: string;
      address: string;
    }
  | { type: 'test_alarm' };

export interface PushMessage {
  deviceId: string;
  platform: PushPlatform;
  token: string;
  data: PushData;
}

export interface PushResult {
  deviceId: string;
  outcome: 'delivered' | 'rejected' | 'invalid_token';
}

export interface PushSender {
  send(messages: PushMessage[]): Promise<PushResult[]>;
}

export const noopPushSender: PushSender = {
  async send(messages: PushMessage[]): Promise<PushResult[]> {
    return messages.map(message => ({ deviceId: message.deviceId, outcome: 'delivered' }));
  },
};
