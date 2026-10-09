import { describe, it, expect } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs, signTestAccessToken } from './support/create-person.js';
import { connectWs } from './support/ws-client.js';

interface VehicleJson {
  id: string;
  call_sign: string;
  short_name: string;
  type: string;
  status: number;
  status_changed_at: string | null;
  sort_order: number;
  active: boolean;
}

interface ShiftJson {
  id: string;
  bf_day_id: string;
  name: string;
  starts_at: string;
  ends_at: string;
  crew: Array<{ vehicle_id: string; person_id: string; display_name: string; function: string }>;
}

interface BfDayJson {
  id: string;
  state: 'planning' | 'running' | 'ended';
}

interface MeJson {
  person: { id: string };
  crew_assignments: Array<{ shift_id: string; vehicle_id: string; function: string }>;
}

const DAY_MS = 24 * 60 * 60 * 1000;

describe('vehicle status: crew-based auth, FMS 7/8 rule, /me crew_assignments', () => {
  async function setup(): Promise<{ app: TestApp; adminToken: string; dispatchToken: string }> {
    const app = await startTestApp();
    app.clock.set(new Date('2026-06-01T08:00:00Z'));
    const adminToken = await loginAs(app, 'admin', 'admin-password');
    await createPerson(app, {
      displayName: 'Leitstelle',
      personType: 'supervisor',
      permission: 'dispatch',
      username: 'dispatch1',
      password: 'dispatch-password',
    });
    const dispatchToken = await loginAs(app, 'dispatch1', 'dispatch-password');
    return { app, adminToken, dispatchToken };
  }

  async function createCrewPerson(
    app: TestApp,
    username: string
  ): Promise<{ id: string; token: string }> {
    const person = await createPerson(app, {
      displayName: username,
      personType: 'youth',
      permission: 'crew',
      username,
      password: `${username}-password`,
    });
    const token = await signTestAccessToken(app, person.id, 'crew');
    return { id: person.id, token };
  }

  async function createBfDay(
    app: TestApp,
    adminToken: string,
    overrides?: Partial<{ name: string; starts_at: string; ends_at: string }>
  ): Promise<BfDayJson> {
    const startsAt = new Date('2026-06-01T08:00:00Z');
    const endsAt = new Date(startsAt.getTime() + DAY_MS);
    const res = await app.client().post(
      '/api/v1/bf-days',
      {
        name: 'BF-Tag',
        starts_at: startsAt.toISOString(),
        ends_at: endsAt.toISOString(),
        ...overrides,
      },
      { token: adminToken }
    );
    expect(res.status).toBe(201);
    return res.body as BfDayJson;
  }

  async function getDefaultShift(
    app: TestApp,
    dispatchToken: string,
    bfDayId: string
  ): Promise<ShiftJson> {
    const res = await app
      .client()
      .get(`/api/v1/bf-days/${bfDayId}/shifts`, { token: dispatchToken });
    expect(res.status).toBe(200);
    const shifts = res.body as ShiftJson[];
    return shifts[0] as ShiftJson;
  }

  async function createVehicle(
    app: TestApp,
    adminToken: string,
    overrides?: Partial<Record<string, string>>
  ): Promise<VehicleJson> {
    const res = await app.client().post(
      '/api/v1/vehicles',
      {
        call_sign: 'Florian 1',
        short_name: 'HLF 1',
        type: 'HLF',
        ...overrides,
      },
      { token: adminToken }
    );
    expect(res.status).toBe(201);
    return res.body as VehicleJson;
  }

  async function setParticipants(
    app: TestApp,
    adminToken: string,
    bfDayId: string,
    personIds: string[]
  ): Promise<void> {
    const res = await app
      .client()
      .put(
        `/api/v1/bf-days/${bfDayId}/participants`,
        { person_ids: personIds },
        { token: adminToken }
      );
    expect(res.status).toBe(200);
  }

  async function assignCrew(
    app: TestApp,
    dispatchToken: string,
    shiftId: string,
    assignments: Array<{ vehicle_id: string; person_id: string; function: string }>
  ): Promise<void> {
    const res = await app
      .client()
      .put(`/api/v1/shifts/${shiftId}/crew`, { assignments }, { token: dispatchToken });
    expect(res.status).toBe(200);
  }

  it('crew member of the current shift sets status -> 200, source app (history + event)', async () => {
    const { app, adminToken, dispatchToken } = await setup();
    try {
      const day = await createBfDay(app, adminToken);
      const shift = await getDefaultShift(app, dispatchToken, day.id);
      const vehicle = await createVehicle(app, adminToken);
      const crewPerson = await createCrewPerson(app, 'crew-app');
      await setParticipants(app, adminToken, day.id, [crewPerson.id]);
      await assignCrew(app, dispatchToken, shift.id, [
        { vehicle_id: vehicle.id, person_id: crewPerson.id, function: 'GF' },
      ]);
      await app.client().post(`/api/v1/bf-days/${day.id}/start`, {}, { token: adminToken });

      const ws = await connectWs(app.baseUrl, dispatchToken);
      try {
        const res = await app
          .client()
          .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 3 }, { token: crewPerson.token });
        expect(res.status).toBe(200);
        expect((res.body as VehicleJson).status).toBe(3);

        const event = await ws.next(m => m.type === 'vehicle.status_changed');
        expect(event.data).toMatchObject({ vehicle_id: vehicle.id, status: 3, source: 'app' });
      } finally {
        ws.close();
      }

      const history = await app
        .client()
        .get(`/api/v1/vehicles/${vehicle.id}/status-history`, { token: dispatchToken });
      expect(history.status).toBe(200);
      const items = history.body as Array<{ status: number; source: string; person_id: string }>;
      expect(items[0]).toMatchObject({ status: 3, source: 'app', person_id: crewPerson.id });
    } finally {
      await app.close();
    }
  });

  it('other crew person, not in the crew of this vehicle -> 403', async () => {
    const { app, adminToken, dispatchToken } = await setup();
    try {
      const day = await createBfDay(app, adminToken);
      const shift = await getDefaultShift(app, dispatchToken, day.id);
      const vehicle = await createVehicle(app, adminToken);
      const crewPerson = await createCrewPerson(app, 'crew-on-vehicle');
      const otherPerson = await createCrewPerson(app, 'crew-other');
      await setParticipants(app, adminToken, day.id, [crewPerson.id, otherPerson.id]);
      await assignCrew(app, dispatchToken, shift.id, [
        { vehicle_id: vehicle.id, person_id: crewPerson.id, function: 'GF' },
      ]);
      await app.client().post(`/api/v1/bf-days/${day.id}/start`, {}, { token: adminToken });

      const res = await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 3 }, { token: otherPerson.token });
      expect(res.status).toBe(403);
      expect(res.body).toMatchObject({ error: { code: 'forbidden' } });
    } finally {
      await app.close();
    }
  });

  it('crew member after shift end -> 403; and with no running BF-Tag -> 403', async () => {
    const { app, adminToken, dispatchToken } = await setup();
    try {
      const day = await createBfDay(app, adminToken);
      const shift = await getDefaultShift(app, dispatchToken, day.id);
      const vehicle = await createVehicle(app, adminToken);
      const crewPerson = await createCrewPerson(app, 'crew-end');
      await setParticipants(app, adminToken, day.id, [crewPerson.id]);
      await assignCrew(app, dispatchToken, shift.id, [
        { vehicle_id: vehicle.id, person_id: crewPerson.id, function: 'GF' },
      ]);
      await app.client().post(`/api/v1/bf-days/${day.id}/start`, {}, { token: adminToken });

      app.clock.set(new Date(new Date(shift.ends_at).getTime() + 1000));
      // Re-sign: the access token's own TTL (900s) must not be the reason
      // for a 403 here, only the shift-boundary rule.
      const tokenAfterEnd = await signTestAccessToken(app, crewPerson.id, 'crew');
      const afterEnd = await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 3 }, { token: tokenAfterEnd });
      expect(afterEnd.status).toBe(403);

      await app.client().post(`/api/v1/bf-days/${day.id}/end`, {}, { token: adminToken });
      const tokenNoRunningDay = await signTestAccessToken(app, crewPerson.id, 'crew');
      const noRunningDay = await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 3 }, { token: tokenNoRunningDay });
      expect(noRunningDay.status).toBe(403);
    } finally {
      await app.close();
    }
  });

  it('crew member on an overlapping but non-current shift -> 403', async () => {
    const { app, adminToken, dispatchToken } = await setup();
    try {
      const day = await createBfDay(app, adminToken);
      const defaultShift = await getDefaultShift(app, dispatchToken, day.id);
      const vehicle = await createVehicle(app, adminToken);
      const crewPerson = await createCrewPerson(app, 'crew-overlap');
      await setParticipants(app, adminToken, day.id, [crewPerson.id]);
      // Only assigned on the default (whole-day) shift.
      await assignCrew(app, dispatchToken, defaultShift.id, [
        { vehicle_id: vehicle.id, person_id: crewPerson.id, function: 'GF' },
      ]);

      // A later-starting overlapping shift wins the "current shift" rule
      // (ADR 0013), so during its window the default shift is not current.
      const otherShiftRes = await app.client().post(
        `/api/v1/bf-days/${day.id}/shifts`,
        {
          name: 'Zwischenschicht',
          starts_at: '2026-06-01T10:00:00Z',
          ends_at: '2026-06-01T14:00:00Z',
        },
        { token: dispatchToken }
      );
      expect(otherShiftRes.status).toBe(201);

      await app.client().post(`/api/v1/bf-days/${day.id}/start`, {}, { token: adminToken });
      app.clock.set(new Date('2026-06-01T11:00:00Z'));
      const tokenDuringOverlap = await signTestAccessToken(app, crewPerson.id, 'crew');

      const res = await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 3 }, { token: tokenDuringOverlap });
      expect(res.status).toBe(403);
    } finally {
      await app.close();
    }
  });

  it('dispatch person not in the crew -> 200, source dispatch', async () => {
    const { app, adminToken, dispatchToken } = await setup();
    try {
      const day = await createBfDay(app, adminToken);
      await getDefaultShift(app, dispatchToken, day.id);
      const vehicle = await createVehicle(app, adminToken);
      await app.client().post(`/api/v1/bf-days/${day.id}/start`, {}, { token: adminToken });

      const res = await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 3 }, { token: dispatchToken });
      expect(res.status).toBe(200);

      const history = await app
        .client()
        .get(`/api/v1/vehicles/${vehicle.id}/status-history`, { token: dispatchToken });
      const items = history.body as Array<{ status: number; source: string }>;
      expect(items[0]).toMatchObject({ status: 3, source: 'dispatch' });
    } finally {
      await app.close();
    }
  });

  describe('FMS 7/8 rule (status_not_allowed)', () => {
    it('status 7 on an HLF -> 409 status_not_allowed, for crew and for dispatch', async () => {
      const { app, adminToken, dispatchToken } = await setup();
      try {
        const day = await createBfDay(app, adminToken);
        const shift = await getDefaultShift(app, dispatchToken, day.id);
        const vehicle = await createVehicle(app, adminToken, { type: 'HLF' });
        const crewPerson = await createCrewPerson(app, 'crew-hlf');
        await setParticipants(app, adminToken, day.id, [crewPerson.id]);
        await assignCrew(app, dispatchToken, shift.id, [
          { vehicle_id: vehicle.id, person_id: crewPerson.id, function: 'GF' },
        ]);
        await app.client().post(`/api/v1/bf-days/${day.id}/start`, {}, { token: adminToken });

        const byCrew = await app
          .client()
          .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 7 }, { token: crewPerson.token });
        expect(byCrew.status).toBe(409);
        expect(byCrew.body).toMatchObject({ error: { code: 'status_not_allowed' } });

        const byDispatch = await app
          .client()
          .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 7 }, { token: dispatchToken });
        expect(byDispatch.status).toBe(409);
        expect(byDispatch.body).toMatchObject({ error: { code: 'status_not_allowed' } });
      } finally {
        await app.close();
      }
    });

    it('status 7 on an RTW and on " ktw " is allowed for crew', async () => {
      const { app, adminToken, dispatchToken } = await setup();
      try {
        const day = await createBfDay(app, adminToken);
        const shift = await getDefaultShift(app, dispatchToken, day.id);
        const rtw = await createVehicle(app, adminToken, {
          call_sign: 'RTW 1',
          short_name: 'RTW',
          type: 'RTW',
        });
        const ktw = await createVehicle(app, adminToken, {
          call_sign: 'KTW 1',
          short_name: 'KTW',
          type: ' ktw ',
        });
        const crewPerson = await createCrewPerson(app, 'crew-rtw-ktw');
        await setParticipants(app, adminToken, day.id, [crewPerson.id]);
        await assignCrew(app, dispatchToken, shift.id, [
          { vehicle_id: rtw.id, person_id: crewPerson.id, function: 'GF' },
          { vehicle_id: ktw.id, person_id: crewPerson.id, function: 'MA' },
        ]);
        await app.client().post(`/api/v1/bf-days/${day.id}/start`, {}, { token: adminToken });

        const onRtw = await app
          .client()
          .put(`/api/v1/vehicles/${rtw.id}/status`, { status: 7 }, { token: crewPerson.token });
        expect(onRtw.status).toBe(200);

        const onKtw = await app
          .client()
          .put(`/api/v1/vehicles/${ktw.id}/status`, { status: 8 }, { token: crewPerson.token });
        expect(onKtw.status).toBe(200);
      } finally {
        await app.close();
      }
    });
  });

  describe('/me crew_assignments', () => {
    it('no assignments -> []', async () => {
      const { app, adminToken, dispatchToken } = await setup();
      try {
        const day = await createBfDay(app, adminToken);
        await getDefaultShift(app, dispatchToken, day.id);
        await app.client().post(`/api/v1/bf-days/${day.id}/start`, {}, { token: adminToken });
        const crewPerson = await createCrewPerson(app, 'me-none');
        await setParticipants(app, adminToken, day.id, [crewPerson.id]);

        const res = await app.client().get('/api/v1/me', { token: crewPerson.token });
        expect(res.status).toBe(200);
        expect((res.body as MeJson).crew_assignments).toEqual([]);
      } finally {
        await app.close();
      }
    });

    it('double assignment (two vehicles, same shift) -> 2 entries', async () => {
      const { app, adminToken, dispatchToken } = await setup();
      try {
        const day = await createBfDay(app, adminToken);
        const shift = await getDefaultShift(app, dispatchToken, day.id);
        const v1 = await createVehicle(app, adminToken, { call_sign: 'V1', short_name: 'V1' });
        const v2 = await createVehicle(app, adminToken, { call_sign: 'V2', short_name: 'V2' });
        const crewPerson = await createCrewPerson(app, 'me-double');
        await setParticipants(app, adminToken, day.id, [crewPerson.id]);
        await assignCrew(app, dispatchToken, shift.id, [
          { vehicle_id: v1.id, person_id: crewPerson.id, function: 'GF' },
          { vehicle_id: v2.id, person_id: crewPerson.id, function: 'MA' },
        ]);
        await app.client().post(`/api/v1/bf-days/${day.id}/start`, {}, { token: adminToken });

        const res = await app.client().get('/api/v1/me', { token: crewPerson.token });
        expect(res.status).toBe(200);
        const assignments = (res.body as MeJson).crew_assignments;
        expect(assignments).toHaveLength(2);
        expect(assignments.map(a => a.vehicle_id).sort()).toEqual([v1.id, v2.id].sort());
        for (const a of assignments) {
          expect(a.shift_id).toBe(shift.id);
        }
      } finally {
        await app.close();
      }
    });

    it('after shift end -> []', async () => {
      const { app, adminToken, dispatchToken } = await setup();
      try {
        const day = await createBfDay(app, adminToken);
        const shift = await getDefaultShift(app, dispatchToken, day.id);
        const vehicle = await createVehicle(app, adminToken);
        const crewPerson = await createCrewPerson(app, 'me-after-end');
        await setParticipants(app, adminToken, day.id, [crewPerson.id]);
        await assignCrew(app, dispatchToken, shift.id, [
          { vehicle_id: vehicle.id, person_id: crewPerson.id, function: 'GF' },
        ]);
        await app.client().post(`/api/v1/bf-days/${day.id}/start`, {}, { token: adminToken });

        const before = await app.client().get('/api/v1/me', { token: crewPerson.token });
        expect((before.body as MeJson).crew_assignments).toHaveLength(1);

        app.clock.set(new Date(new Date(shift.ends_at).getTime() + 1000));
        const tokenAfterEnd = await signTestAccessToken(app, crewPerson.id, 'crew');
        const after = await app.client().get('/api/v1/me', { token: tokenAfterEnd });
        expect(after.status).toBe(200);
        expect((after.body as MeJson).crew_assignments).toEqual([]);
      } finally {
        await app.close();
      }
    });
  });
});
