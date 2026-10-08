export type PushPlatform = 'android' | 'ios';

export interface PushMessage {
  deviceId: string;
  platform: PushPlatform;
  token: string;
  data: {
    incident_id: string;
    alarm_id: string;
    keyword: string;
    address: string;
  };
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
