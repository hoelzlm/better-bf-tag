import { and, asc, eq, inArray, lte } from 'drizzle-orm';
import { alarm, alarmVehicle, bfDay, incident, vehicle } from '../db/schema.js';
import type { Tx, Realtime } from '../realtime/realtime.js';
import type { Clock } from '../clock.js';
import type { Db } from '../db/client.js';
import type { PushSender } from '../push/push-sender.js';
import { toIncidentJson, type IncidentRow } from '../incidents/incident-json.js';
import { scriptAudience } from '../incidents/visibility.js';
import { computeCloseSuggested } from '../incidents/close-suggestion.js';
import { loadAlarms, type AlarmRow } from './alarm-json.js';
import { triggerAlarm } from './trigger.js';
import { dispatchAlarmPushes } from '../push/alarm-push.js';

/** ADR 0022: a `planned` alarm is considered verpasst once it is more than
 * 10 minutes past `scheduled_at` (exactly 10 minutes still triggers). */
export const MISSED_AFTER_MS = 600_000;

interface Logger {
  warn: (obj: Record<string, unknown>, msg: string) => void;
}

export interface AlarmSchedulerDeps {
  db: Db;
  realtime: Realtime;
  clock: Clock;
  pushSender: PushSender;
  log: Logger;
}

async function loadIncidentRow(tx: Tx, id: string): Promise<IncidentRow | undefined> {
  const [row] = await tx.select().from(incident).where(eq(incident.id, id)).limit(1);
  return row as IncidentRow | undefined;
}

async function loadVehicleIdsForAlarm(tx: Tx, alarmId: string): Promise<string[]> {
  const rows = await tx
    .select({ vehicleId: alarmVehicle.vehicleId })
    .from(alarmVehicle)
    .where(eq(alarmVehicle.alarmId, alarmId));
  return rows.map(row => row.vehicleId);
}

/**
 * ADR 0022: whether a due alarm can still be triggered right now — BF-Tag
 * `running`, Einsatz `draft`/`running`, every one of its vehicles `active`,
 * and none of them already bound to a `triggered` alarm of the same
 * incident. Anything else means `missed` instead.
 */
async function isTriggerable(
  tx: Tx,
  alarmRow: AlarmRow,
  incidentRow: IncidentRow
): Promise<boolean> {
  if (incidentRow.state !== 'draft' && incidentRow.state !== 'running') {
    return false;
  }

  const [bfDayRow] = await tx
    .select({ state: bfDay.state })
    .from(bfDay)
    .where(eq(bfDay.id, incidentRow.bfDayId))
    .limit(1);
  if (!bfDayRow || bfDayRow.state !== 'running') {
    return false;
  }

  const vehicleIds = await loadVehicleIdsForAlarm(tx, alarmRow.id);
  if (vehicleIds.length === 0) {
    return true;
  }

  const vehicleRows = await tx
    .select({ id: vehicle.id, active: vehicle.active })
    .from(vehicle)
    .where(inArray(vehicle.id, vehicleIds));
  const activeById = new Map(vehicleRows.map(row => [row.id, row.active]));
  for (const id of vehicleIds) {
    if (!activeById.get(id)) return false;
  }

  const triggeredVehicleRows = await tx
    .select({ vehicleId: alarmVehicle.vehicleId })
    .from(alarmVehicle)
    .innerJoin(alarm, eq(alarmVehicle.alarmId, alarm.id))
    .where(and(eq(alarm.incidentId, incidentRow.id), eq(alarm.state, 'triggered')));
  const alreadyTriggeredVehicleIds = new Set(triggeredVehicleRows.map(row => row.vehicleId));
  for (const id of vehicleIds) {
    if (alreadyTriggeredVehicleIds.has(id)) return false;
  }

  return true;
}

/**
 * The scheduler side of ADR 0022: the `alarm` table itself is the job
 * queue, this class just drives it. `runDue()` is black-box tested
 * directly (ADR 0022's one exception to that principle, alongside the
 * `Clock`); the real timer is driven by `start()`/`stop()`, wired into
 * Fastify's `onReady`/`onClose` in `app.ts`.
 */
export class AlarmScheduler {
  private readonly deps: AlarmSchedulerDeps;
  private readonly intervalMs: number;
  private timer: ReturnType<typeof setInterval> | undefined;
  private running = false;

  constructor(deps: AlarmSchedulerDeps, intervalMs: number) {
    this.deps = deps;
    this.intervalMs = intervalMs;
  }

  /** Runs `runDue()` once immediately (catch-up after a restart), then
   * starts the real-time interval timer if configured. */
  async start(): Promise<void> {
    await this.runDue();
    if (this.intervalMs > 0) {
      this.timer = setInterval(() => this.tick(), this.intervalMs);
    }
  }

  stop(): void {
    if (this.timer !== undefined) {
      clearInterval(this.timer);
      this.timer = undefined;
    }
  }

  private tick(): void {
    if (this.running) {
      // A previous run is still in progress — skip this tick rather than
      // overlap it.
      return;
    }
    this.runDue().catch(err => {
      this.deps.log.warn(
        { error: err instanceof Error ? err.message : String(err) },
        'alarm scheduler tick failed'
      );
    });
  }

  /**
   * Selects every `planned` alarm that is due and, each in its own
   * `realtime.mutate`, either triggers it or marks it `missed`. Errors on
   * one alarm are logged and never stop the others. Guarded against
   * overlapping invocations (e.g. a direct test call racing the interval
   * timer): a call made while another is still running returns immediately
   * with empty results.
   */
  async runDue(): Promise<{ triggered: string[]; missed: string[] }> {
    if (this.running) {
      return { triggered: [], missed: [] };
    }
    this.running = true;
    try {
      return await this.runOnce();
    } catch (err) {
      // A failure to even select the due alarms (e.g. DB unreachable during
      // the startup catch-up) must not crash the app — log and let the next
      // tick (or the next explicit call) retry.
      this.deps.log.warn(
        { error: err instanceof Error ? err.message : String(err) },
        'alarm scheduler run failed'
      );
      return { triggered: [], missed: [] };
    } finally {
      this.running = false;
    }
  }

  private async runOnce(): Promise<{ triggered: string[]; missed: string[] }> {
    const { db, clock, realtime, log } = this.deps;
    const now = clock.now();

    const dueRows = await db
      .select({ id: alarm.id })
      .from(alarm)
      .where(and(eq(alarm.state, 'planned'), lte(alarm.scheduledAt, now)))
      .orderBy(asc(alarm.scheduledAt), asc(alarm.id));

    const triggered: string[] = [];
    const missed: string[] = [];
    const triggeredPushAlarmIds: string[] = [];

    for (const { id } of dueRows) {
      try {
        const outcome = await realtime.mutate(async (tx, emit) => {
          const [alarmRow] = await tx.select().from(alarm).where(eq(alarm.id, id)).limit(1);
          if (!alarmRow || (alarmRow as AlarmRow).state !== 'planned') {
            // Already handled by an earlier/overlapping run — harmless no-op.
            return undefined;
          }
          const typedAlarmRow = alarmRow as AlarmRow;

          const incidentRow = await loadIncidentRow(tx, typedAlarmRow.incidentId);
          if (!incidentRow) {
            throw new Error(`AlarmScheduler: incident for alarm ${id} not found`);
          }

          const scheduledAt = typedAlarmRow.scheduledAt;
          const isLate =
            scheduledAt !== null && now.getTime() - scheduledAt.getTime() > MISSED_AFTER_MS;
          const triggerable = !isLate && (await isTriggerable(tx, typedAlarmRow, incidentRow));

          if (!triggerable) {
            const [row] = await tx
              .update(alarm)
              .set({ state: 'missed' })
              .where(and(eq(alarm.id, id), eq(alarm.state, 'planned')))
              .returning();
            if (!row) {
              return undefined;
            }
            const [alarmJson] = await loadAlarms(tx, { alarmIds: [id] });
            if (!alarmJson) {
              throw new Error(`AlarmScheduler: missed alarm ${id} disappeared`);
            }
            await emit(
              'alarm.missed',
              { incident: toIncidentJson(incidentRow, { includeScript: true }), alarm: alarmJson },
              { audience: scriptAudience }
            );
            return { kind: 'missed' as const };
          }

          const closeSuggestedBefore = await computeCloseSuggested(tx, [incidentRow.id]);
          const { alarm: alarmJson } = await triggerAlarm(
            tx,
            emit,
            { clock: this.deps.clock, pushSender: this.deps.pushSender, log },
            id,
            closeSuggestedBefore
          );
          return { kind: 'triggered' as const, alarmId: alarmJson.id };
        });

        if (outcome?.kind === 'missed') {
          missed.push(id);
        } else if (outcome?.kind === 'triggered') {
          triggered.push(id);
          triggeredPushAlarmIds.push(outcome.alarmId);
        }
      } catch (err) {
        log.warn(
          { error: err instanceof Error ? err.message : String(err), alarmId: id },
          'alarm scheduler failed to process a due alarm'
        );
      }
    }

    // Push dispatch (ADR 0018) happens strictly after each triggering
    // `realtime.mutate` has committed — same rule as immediate alarming.
    for (const alarmId of triggeredPushAlarmIds) {
      try {
        await dispatchAlarmPushes({ db, pushSender: this.deps.pushSender, realtime, log }, alarmId);
      } catch (err) {
        log.warn(
          { error: err instanceof Error ? err.message : String(err), alarmId },
          'alarm scheduler push dispatch failed'
        );
      }
    }

    return { triggered, missed };
  }
}
