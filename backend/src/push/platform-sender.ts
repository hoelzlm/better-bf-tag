import type { PushMessage, PushPlatform, PushResult, PushSender } from './push-sender.js';

export interface PlatformSenders {
  android?: PushSender;
  ios?: PushSender;
}

/** Routes each PushMessage to the sender for its platform; missing platform ⇒ rejected (ADR 0018). */
export class PlatformPushSender implements PushSender {
  private readonly android: PushSender | undefined;
  private readonly ios: PushSender | undefined;

  constructor(senders: PlatformSenders) {
    this.android = senders.android;
    this.ios = senders.ios;
  }

  async send(messages: PushMessage[]): Promise<PushResult[]> {
    const byPlatform = new Map<PushPlatform, PushMessage[]>();
    for (const message of messages) {
      const group = byPlatform.get(message.platform);
      if (group) {
        group.push(message);
      } else {
        byPlatform.set(message.platform, [message]);
      }
    }

    const resultsByDeviceId = new Map<string, PushResult>();

    await Promise.all(
      Array.from(byPlatform.entries()).map(async ([platform, group]) => {
        const sender = this.senderFor(platform);
        const outcomes = sender
          ? await sender.send(group)
          : group.map(message => ({ deviceId: message.deviceId, outcome: 'rejected' as const }));
        for (const outcome of outcomes) {
          resultsByDeviceId.set(outcome.deviceId, outcome);
        }
      })
    );

    return messages.map(message => {
      const result = resultsByDeviceId.get(message.deviceId);
      return result ?? { deviceId: message.deviceId, outcome: 'rejected' };
    });
  }

  async close(): Promise<void> {
    await Promise.all(
      [this.android, this.ios].map(async sender => {
        const closable = sender as PushSender & { close?: () => Promise<void> };
        if (closable?.close) {
          await closable.close();
        }
      })
    );
  }

  private senderFor(platform: PushPlatform): PushSender | undefined {
    return platform === 'android' ? this.android : this.ios;
  }
}
