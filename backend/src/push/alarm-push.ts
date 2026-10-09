import { and, eq, isNull } from 'drizzle-orm';
import { alarm, alarmRecipient, device, incident, person } from '../db/schema.js';
import type { Db } from '../db/client.js';
import type { Realtime } from '../realtime/realtime.js';
import type { PushMessage, PushSender } from './push-sender.js';

const SEND_TIMEOUT_MS = 10_000;

interface Logger {
  warn: (obj: Record<string, unknown>, msg: string) => void;
}

export interface DispatchAlarmPushesDeps {
  db: Db;
  pushSender: PushSender;
  realtime: Realtime;
  log: Logger;
}

/**
 * Sends pushes for a just-triggered Alarmierung (ADR 0018). Runs strictly
 * after the triggering `realtime.mutate` has committed — never call this
 * from inside a `mutate`/transaction, since it talks to an external push
 * transport under a 10s timeout.
 */
export async function dispatchAlarmPushes(
  deps: DispatchAlarmPushesDeps,
  alarmId: string
): Promise<void> {
  const { db, pushSender, realtime, log } = deps;

  const [alarmRow] = await db.select().from(alarm).where(eq(alarm.id, alarmId)).limit(1);
  if (!alarmRow) {
    throw new Error(`dispatchAlarmPushes: alarm ${alarmId} not found`);
  }

  const [incidentRow] = await db
    .select({ keyword: incident.keyword, address: incident.address })
    .from(incident)
    .where(eq(incident.id, alarmRow.incidentId))
    .limit(1);
  if (!incidentRow) {
    throw new Error(`dispatchAlarmPushes: incident for alarm ${alarmId} not found`);
  }

  // Targets: devices of recipients of this alarm (ADR 0018) — active
  // person, non-revoked device, push token set. Through the PK of
  // `alarm_recipient`, a doubly crewed person already appears once.
  const targetRows = await db
    .select({ deviceId: device.id, platform: device.platform, token: device.pushToken })
    .from(alarmRecipient)
    .innerJoin(person, eq(alarmRecipient.personId, person.id))
    .innerJoin(device, eq(device.personId, person.id))
    .where(
      and(eq(alarmRecipient.alarmId, alarmId), eq(person.active, true), isNull(device.revokedAt))
    );

  const targets = targetRows.filter(
    (row): row is { deviceId: string; platform: 'android' | 'ios'; token: string } =>
      row.token !== null
  );

  const messages: PushMessage[] = targets.map(target => ({
    deviceId: target.deviceId,
    platform: target.platform,
    token: target.token,
    data: {
      incident_id: alarmRow.incidentId,
      alarm_id: alarmId,
      keyword: incidentRow.keyword,
      address: incidentRow.address,
    },
  }));

  let delivered = 0;
  let rejected = 0;
  const invalidTokenDeviceIds: Array<{ deviceId: string; token: string }> = [];

  if (messages.length > 0) {
    let results: Array<{ deviceId: string; outcome: 'delivered' | 'rejected' | 'invalid_token' }>;
    try {
      results = await Promise.race([
        pushSender.send(messages),
        new Promise<never>((_resolve, reject) => {
          setTimeout(() => reject(new Error('push send timeout')), SEND_TIMEOUT_MS);
        }),
      ]);
    } catch (err) {
      log.warn(
        { error: err instanceof Error ? err.message : String(err), alarmId },
        'push send failed or timed out'
      );
      // Every targeted device counts as rejected when the sender throws or
      // the overall timeout elapses (ADR 0018).
      results = messages.map(message => ({ deviceId: message.deviceId, outcome: 'rejected' }));
    }

    const byDeviceId = new Map(results.map(result => [result.deviceId, result.outcome]));
    for (const message of messages) {
      const outcome = byDeviceId.get(message.deviceId) ?? 'rejected';
      if (outcome === 'delivered') {
        delivered += 1;
      } else if (outcome === 'invalid_token') {
        rejected += 1;
        invalidTokenDeviceIds.push({ deviceId: message.deviceId, token: message.token });
      } else {
        rejected += 1;
      }
    }
  }

  for (const { deviceId, token } of invalidTokenDeviceIds) {
    await db
      .update(device)
      .set({ pushToken: null })
      .where(and(eq(device.id, deviceId), eq(device.pushToken, token)));
  }

  // Zero targets: still persist 0/0 so the counters reflect this alarm, but
  // skip the event (ADR 0018 leaves this a free choice) — no client needs
  // to be told that nothing happened.
  await realtime.mutate(async (tx, emit) => {
    await tx
      .update(alarm)
      .set({ pushDelivered: delivered, pushRejected: rejected })
      .where(eq(alarm.id, alarmId));

    if (messages.length > 0) {
      await emit('alarm.push_reported', {
        alarm_id: alarmId,
        incident_id: alarmRow.incidentId,
        push_delivered: delivered,
        push_rejected: rejected,
      });
    }
  });
}
