import { and, eq } from 'drizzle-orm';
import { device, person } from '../db/schema.js';
import type { Db } from '../db/client.js';
import type { PushMessage, PushResult, PushSender } from './push-sender.js';

interface Logger {
  warn: (obj: Record<string, unknown>, msg: string) => void;
}

export interface TestAlarmSchedulerDeps {
  db: Db;
  pushSender: PushSender;
  log: Logger;
  now: () => number;
  setTimer?: (fn: () => void, ms: number) => unknown;
  clearTimer?: (handle: unknown) => void;
}

const COOLDOWN_MS = 10_000;

/**
 * Sends a Testalarm (ADR 0021) to exactly one device, over the real push
 * path — no incident, no alarm, no `realtime.mutate`, no event. In-memory
 * per process: a restart loses pending timers and the cooldown, which is
 * fine (ADR 0021).
 */
export class TestAlarmScheduler {
  private readonly db: Db;
  private readonly pushSender: PushSender;
  private readonly log: Logger;
  private readonly now: () => number;
  private readonly setTimer: (fn: () => void, ms: number) => unknown;
  private readonly clearTimer: (handle: unknown) => void;

  private readonly pendingTimers = new Map<string, unknown>();
  private readonly lastSentAt = new Map<string, number>();

  constructor(deps: TestAlarmSchedulerDeps) {
    this.db = deps.db;
    this.pushSender = deps.pushSender;
    this.log = deps.log;
    this.now = deps.now;
    this.setTimer = deps.setTimer ?? ((fn, ms) => setTimeout(fn, ms));
    this.clearTimer = deps.clearTimer ?? (handle => clearTimeout(handle as NodeJS.Timeout));
  }

  /** A pending scheduled Testalarm, or the last send was under 10s ago. */
  isBlocked(deviceId: string): boolean {
    if (this.pendingTimers.has(deviceId)) {
      return true;
    }
    const last = this.lastSentAt.get(deviceId);
    return last !== undefined && this.now() - last < COOLDOWN_MS;
  }

  /** Sends immediately (`delay_seconds = 0`); resolves with the send outcome. */
  async sendNow(deviceId: string): Promise<PushResult['outcome']> {
    this.lastSentAt.set(deviceId, this.now());
    const outcome = await this.deliver(deviceId);
    return outcome === 'skipped' ? 'rejected' : outcome;
  }

  /** Schedules a delayed send (`delay_seconds > 0`); fire-and-forget. */
  schedule(deviceId: string, delaySeconds: number): void {
    const handle = this.setTimer(() => {
      this.pendingTimers.delete(deviceId);
      this.lastSentAt.set(deviceId, this.now());
      this.deliver(deviceId).catch(err => {
        this.log.warn(
          { error: err instanceof Error ? err.message : String(err), deviceId },
          'test alarm scheduled send failed'
        );
      });
    }, delaySeconds * 1000);
    this.pendingTimers.set(deviceId, handle);
  }

  /** Discards all pending timers (called on app shutdown). */
  close(): void {
    for (const handle of this.pendingTimers.values()) {
      this.clearTimer(handle);
    }
    this.pendingTimers.clear();
  }

  private async deliver(deviceId: string): Promise<PushResult['outcome'] | 'skipped'> {
    const [row] = await this.db
      .select({
        platform: device.platform,
        pushToken: device.pushToken,
        revokedAt: device.revokedAt,
        personId: device.personId,
      })
      .from(device)
      .where(eq(device.id, deviceId))
      .limit(1);

    if (!row || row.revokedAt !== null || row.pushToken === null) {
      return 'skipped';
    }

    const [personRow] = await this.db
      .select({ active: person.active })
      .from(person)
      .where(eq(person.id, row.personId))
      .limit(1);

    if (!personRow || !personRow.active) {
      return 'skipped';
    }

    const message: PushMessage = {
      deviceId,
      platform: row.platform,
      token: row.pushToken,
      data: { type: 'test_alarm' },
    };

    let outcome: PushResult['outcome'];
    try {
      const [result] = await this.pushSender.send([message]);
      outcome = result?.outcome ?? 'rejected';
    } catch (err) {
      this.log.warn(
        { error: err instanceof Error ? err.message : String(err), deviceId },
        'test alarm push send failed'
      );
      outcome = 'rejected';
    }

    if (outcome === 'invalid_token') {
      await this.db
        .update(device)
        .set({ pushToken: null })
        .where(and(eq(device.id, deviceId), eq(device.pushToken, row.pushToken)));
    }

    return outcome;
  }
}
