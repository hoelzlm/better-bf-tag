import { sql } from 'drizzle-orm';
import type { Db } from '../db/client.js';
import type { Clock } from '../clock.js';

/** The transaction type passed into a `mutate()` callback. */
export type Tx = Parameters<Db['transaction']>[0] extends (tx: infer T) => unknown ? T : never;

export interface RealtimeEvent {
  seq: number;
  type: string;
  at: string;
  data: unknown;
}

export type Emit = (type: string, data: unknown) => Promise<void>;

/** T02-2 wraps this with permission filtering before delivering to WebSocket clients. */
export interface RealtimeSubscriber {
  send(event: RealtimeEvent): void;
}

/** Minimal promise-chain mutex: serializes everything queued through `run()`. */
class Mutex {
  private tail: Promise<unknown> = Promise.resolve();

  run<T>(fn: () => Promise<T>): Promise<T> {
    const result = this.tail.then(fn, fn);
    // Swallow errors here so one failed task doesn't wedge the chain for
    // later tasks; the caller still gets the rejection via `result`.
    this.tail = result.catch(() => undefined);
    return result;
  }
}

/**
 * The realtime core (ADR 0009): serializes event-producing mutations behind
 * an in-process mutex, bumps the persistent `seq` counter inside the same
 * DB transaction as the data write, and delivers events to subscribers in
 * `seq` order only after the transaction has committed.
 */
export class Realtime {
  private readonly mutex = new Mutex();
  private readonly subscribers = new Set<RealtimeSubscriber>();

  constructor(
    private readonly db: Db,
    private readonly clock: Clock
  ) {}

  mutate<T>(fn: (tx: Tx, emit: Emit) => Promise<T>): Promise<T> {
    return this.mutex.run(async () => {
      const pending: RealtimeEvent[] = [];

      const result = await this.db.transaction(async tx => {
        const emit: Emit = async (type, data) => {
          const result = await tx.execute<{ seq: number }>(
            sql`update realtime_state set seq = seq + 1 where id = 1 returning seq`
          );
          const seq = Number(result.rows[0]?.seq);
          pending.push({ seq, type, at: this.clock.now().toISOString(), data });
        };
        return fn(tx as Tx, emit);
      });

      pending.sort((a, b) => a.seq - b.seq);
      for (const event of pending) {
        for (const subscriber of this.subscribers) {
          subscriber.send(event);
        }
      }

      return result;
    });
  }

  async currentSeq(tx?: Tx): Promise<number> {
    const runner = tx ?? this.db;
    const result = await runner.execute<{ seq: number }>(
      sql`select seq from realtime_state where id = 1`
    );
    return Number(result.rows[0]?.seq ?? 0);
  }

  subscribe(subscriber: RealtimeSubscriber): () => void {
    this.subscribers.add(subscriber);
    return () => {
      this.subscribers.delete(subscriber);
    };
  }
}
