import { and, eq, inArray, isNull, ne } from 'drizzle-orm';
import { announcement, crewAssignment, device, participation, person } from '../db/schema.js';
import type { Db } from '../db/client.js';
import type { PushMessage, PushSender } from './push-sender.js';

const SEND_TIMEOUT_MS = 10_000;

interface Logger {
  warn: (obj: Record<string, unknown>, msg: string) => void;
}

export interface DispatchAnnouncementPushesDeps {
  db: Db;
  pushSender: PushSender;
  log: Logger;
}

/**
 * Sends pushes for a just-created Durchsage (ADR 0024). Runs strictly after
 * the triggering `realtime.mutate` has committed — never call this from
 * inside a `mutate`/transaction, since it talks to an external push
 * transport under a 10s timeout. Never throws to the caller: transport
 * errors and timeouts are only logged (ADR 0024 keeps the POST response
 * independent of push delivery).
 */
export async function dispatchAnnouncementPushes(
  deps: DispatchAnnouncementPushesDeps,
  announcementId: string
): Promise<void> {
  const { db, pushSender, log } = deps;

  try {
    const [row] = await db
      .select()
      .from(announcement)
      .where(eq(announcement.id, announcementId))
      .limit(1);
    if (!row) {
      log.warn({ announcementId }, 'dispatchAnnouncementPushes: announcement not found');
      return;
    }

    // Candidates: active participants of this BF-Tag, excluding the sender.
    const participantRows = await db
      .select({ personId: participation.personId, permission: person.permission })
      .from(participation)
      .innerJoin(person, eq(participation.personId, person.id))
      .where(
        and(
          eq(participation.bfDayId, row.bfDayId),
          eq(person.active, true),
          ne(participation.personId, row.createdBy)
        )
      );

    // Visibility (ADR 0024): shift_id null → everyone; otherwise only the
    // crew of that Schicht plus persons with permission
    // preparation/dispatch/admin.
    let targetPersonIds: string[];
    if (row.shiftId === null) {
      targetPersonIds = participantRows.map(r => r.personId);
    } else {
      const crewRows = await db
        .select({ personId: crewAssignment.personId })
        .from(crewAssignment)
        .where(eq(crewAssignment.shiftId, row.shiftId));
      const crewPersonIds = new Set(crewRows.map(r => r.personId));
      targetPersonIds = participantRows
        .filter(
          r =>
            crewPersonIds.has(r.personId) ||
            r.permission === 'preparation' ||
            r.permission === 'dispatch' ||
            r.permission === 'admin'
        )
        .map(r => r.personId);
    }

    const targetRows =
      targetPersonIds.length === 0
        ? []
        : await db
            .select({ deviceId: device.id, platform: device.platform, token: device.pushToken })
            .from(device)
            .where(and(inArray(device.personId, targetPersonIds), isNull(device.revokedAt)));

    const targets = targetRows.filter(
      (r): r is { deviceId: string; platform: 'android' | 'ios'; token: string } => r.token !== null
    );

    if (targets.length === 0) {
      return;
    }

    const messages: PushMessage[] = targets.map(target => ({
      deviceId: target.deviceId,
      platform: target.platform,
      token: target.token,
      data: {
        type: 'announcement.created',
        announcement_id: row.id,
        bf_day_id: row.bfDayId,
        text: row.text,
      },
    }));

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
        { error: err instanceof Error ? err.message : String(err), announcementId },
        'announcement push send failed or timed out'
      );
      results = messages.map(message => ({ deviceId: message.deviceId, outcome: 'rejected' }));
    }

    const byDeviceId = new Map(results.map(result => [result.deviceId, result.outcome]));
    const invalidTokenDeviceIds: Array<{ deviceId: string; token: string }> = [];
    for (const message of messages) {
      const outcome = byDeviceId.get(message.deviceId) ?? 'rejected';
      if (outcome === 'invalid_token') {
        invalidTokenDeviceIds.push({ deviceId: message.deviceId, token: message.token });
      }
    }

    for (const { deviceId, token } of invalidTokenDeviceIds) {
      await db
        .update(device)
        .set({ pushToken: null })
        .where(and(eq(device.id, deviceId), eq(device.pushToken, token)));
    }
  } catch (err) {
    // Belt-and-suspenders: any unexpected error (e.g. a DB hiccup while
    // loading targets) must never propagate — the triggering POST has
    // already responded (ADR 0024: push is fire-and-forget).
    log.warn(
      { error: err instanceof Error ? err.message : String(err), announcementId },
      'dispatchAnnouncementPushes failed'
    );
  }
}
