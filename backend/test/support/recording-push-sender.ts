import type { PushMessage, PushResult, PushSender } from '../../src/push/push-sender.js';

export class RecordingPushSender implements PushSender {
  sent: PushMessage[] = [];
  private invalidTokens = new Set<string>();
  private throwError: Error | undefined;

  markInvalid(token: string): void {
    this.invalidTokens.add(token);
  }

  /** Makes every subsequent `send()` reject, to test the caller's error handling. */
  throwOnSend(error: Error = new Error('RecordingPushSender: simulated transport failure')): void {
    this.throwError = error;
  }

  stopThrowing(): void {
    this.throwError = undefined;
  }

  async send(messages: PushMessage[]): Promise<PushResult[]> {
    if (this.throwError) {
      throw this.throwError;
    }
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
