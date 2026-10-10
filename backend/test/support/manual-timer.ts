/**
 * A controllable stand-in for setTimeout/clearTimeout, injected into
 * `TestAlarmScheduler` (ADR 0021) so tests can fire a scheduled Testalarm
 * deterministically instead of waiting on a real timer.
 */
export class ManualTimerRegistry {
  private handlers = new Map<number, () => void>();
  private nextId = 1;

  setTimer = (fn: () => void): number => {
    const id = this.nextId++;
    this.handlers.set(id, fn);
    return id;
  };

  clearTimer = (handle: unknown): void => {
    this.handlers.delete(handle as number);
  };

  /** Fires every pending timer (in registration order) and clears them. */
  fireAll(): void {
    const fns = Array.from(this.handlers.values());
    this.handlers.clear();
    for (const fn of fns) {
      fn();
    }
  }

  get pendingCount(): number {
    return this.handlers.size;
  }
}
