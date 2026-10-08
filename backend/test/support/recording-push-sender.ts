import type { PushMessage, PushResult, PushSender } from '../../src/push/push-sender.js';

export class RecordingPushSender implements PushSender {
  sent: PushMessage[] = [];
  private invalidTokens = new Set<string>();

  markInvalid(token: string): void {
    this.invalidTokens.add(token);
  }

  async send(messages: PushMessage[]): Promise<PushResult[]> {
    this.sent.push(...messages);
    return messages.map(message => ({
      deviceId: message.deviceId,
      outcome: this.invalidTokens.has(message.token)
        ? ('invalid_token' as const)
        : ('delivered' as const),
    }));
  }

  sentTo(deviceId: string): PushMessage[] {
    return this.sent.filter(message => message.deviceId === deviceId);
  }

  clear(): void {
    this.sent = [];
  }
}
