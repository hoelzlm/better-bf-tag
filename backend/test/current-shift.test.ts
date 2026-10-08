import { describe, it, expect } from 'vitest';
import { currentShift } from '../src/shifts/current-shift.js';

interface TestShift {
  id: string;
  startsAt: Date;
  endsAt: Date;
}

function shift(id: string, startsAt: string, endsAt: string): TestShift {
  return { id, startsAt: new Date(startsAt), endsAt: new Date(endsAt) };
}

describe('currentShift', () => {
  it('returns null when there are no shifts', () => {
    expect(currentShift([], new Date('2026-06-01T12:00:00Z'))).toBeNull();
  });

  it('returns null when now is before all shifts', () => {
    const shifts = [shift('a', '2026-06-01T08:00:00Z', '2026-06-02T08:00:00Z')];
    expect(currentShift(shifts, new Date('2026-06-01T07:59:59.999Z'))).toBeNull();
  });

  it('returns null when now is after all shifts', () => {
    const shifts = [shift('a', '2026-06-01T08:00:00Z', '2026-06-02T08:00:00Z')];
    expect(currentShift(shifts, new Date('2026-06-02T08:00:00.001Z'))).toBeNull();
  });

  it('includes the boundary exactly at starts_at', () => {
    const shifts = [shift('a', '2026-06-01T08:00:00Z', '2026-06-02T08:00:00Z')];
    const result = currentShift(shifts, new Date('2026-06-01T08:00:00.000Z'));
    expect(result?.id).toBe('a');
  });

  it('excludes the boundary exactly at ends_at', () => {
    const shifts = [shift('a', '2026-06-01T08:00:00Z', '2026-06-02T08:00:00Z')];
    const result = currentShift(shifts, new Date('2026-06-02T08:00:00.000Z'));
    expect(result).toBeNull();
  });

  it('prefers the overlapping night shift over the default 24h shift', () => {
    const defaultShift = shift('default', '2026-06-01T00:00:00Z', '2026-06-02T00:00:00Z');
    const nightShift = shift('night', '2026-06-01T22:00:00Z', '2026-06-02T06:00:00Z');
    const result = currentShift([defaultShift, nightShift], new Date('2026-06-01T23:00:00Z'));
    expect(result?.id).toBe('night');
  });

  it('breaks a starts_at tie by the earlier ends_at', () => {
    const longer = shift('longer', '2026-06-01T08:00:00Z', '2026-06-02T08:00:00Z');
    const shorter = shift('shorter', '2026-06-01T08:00:00Z', '2026-06-01T12:00:00Z');
    const result = currentShift([longer, shorter], new Date('2026-06-01T09:00:00Z'));
    expect(result?.id).toBe('shorter');
  });

  it('breaks a starts_at and ends_at tie by the smaller id', () => {
    const b = shift('b', '2026-06-01T08:00:00Z', '2026-06-01T12:00:00Z');
    const a = shift('a', '2026-06-01T08:00:00Z', '2026-06-01T12:00:00Z');
    const result = currentShift([b, a], new Date('2026-06-01T09:00:00Z'));
    expect(result?.id).toBe('a');
  });
});
