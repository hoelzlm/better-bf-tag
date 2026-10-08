import type { Clock } from '../../src/clock.js';

export class FakeClock implements Clock {
  private current: Date;

  constructor(start: Date = new Date('2026-10-10T08:00:00Z')) {
    this.current = new Date(start);
  }

  now(): Date {
    return new Date(this.current);
  }

  set(d: Date): void {
    this.current = new Date(d);
  }

  advance(ms: number): void {
    this.current = new Date(this.current.getTime() + ms);
  }
}
