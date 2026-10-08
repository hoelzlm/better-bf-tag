import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs, signTestAccessToken } from './support/create-person.js';
import { connectWs } from './support/ws-client.js';

interface BfDayJson {
  id: string;
  name: string;
  starts_at: string;
  ends_at: string;
  state: 'planning' | 'running' | 'ended';
  anonymized_at: string | null;
  created_at: string;
}

interface ShiftJson {
  id: string;
  bf_day_id: string;
  name: string;
  starts_at: string;
  ends_at: string;
  crew: Array<{ vehicle_id: string; person_id: string; display_name: string; function: string }>;
}

interface VehicleJson {
  id: string;
  call_sign: string;
  active: boolean;
}

const DAY_MS = 24 * 60 * 60 * 1000;

function createBfDayBody(
  overrides?: Partial<{ name: string; starts_at: string; ends_at: string }>
) {
  const startsAt = new Date('2026-06-01T08:00:00Z');
  const endsAt = new Date(startsAt.getTime() + DAY_MS);
  return {
    name: 'BF-Tag Schichten',
    starts_at: startsAt.toISOString(),
    ends_at: endsAt.toISOString(),
    ...overrides,
  };
}

describe('shifts', () => {
  let app: TestApp;
  let adminToken: string;
  let dispatchToken: string;
  let crewToken: string;
  let preparationToken: string;

  beforeAll(async () => {
    app = await startTestApp();

    adminToken = await loginAs(app, 'admin', 'admin-password');

    await createPerson(app, {
      displayName: 'Leitstelle',
      personType: 'supervisor',
      permission: 'dispatch',
      username: 'dispatch1',
      password: 'dispatch-password',
    });
    dispatchToken = await loginAs(app, 'dispatch1', 'dispatch-password');

    const crewPerson = await createPerson(app, {
      displayName: 'Mannschaft',
      personType: 'youth',
      permission: 'crew',
      username: 'crew1',
      password: 'crew-password',
    });
    // permission=crew cannot log in (ADR 0010); sign a token directly.
    crewToken = await signTestAccessToken(app, crewPerson.id, 'crew');

    await createPerson(app, {
      displayName: 'Vorbereitung',
      personType: 'supervisor',
      permission: 'preparation',
      username: 'prep1',
      password: 'prep-password',
    });
    preparationToken = await loginAs(app, 'prep1', 'prep-password');
  });

  afterAll(async () => {
    await app.close();
  });

  async function createBfDay(
    overrides?: Partial<{ name: string; starts_at: string; ends_at: string }>
  ): Promise<BfDayJson> {
    const res = await app
      .client()
      .post('/api/v1/bf-days', createBfDayBody(overrides), { token: adminToken });
    expect(res.status).toBe(201);
    return res.body as BfDayJson;
  }

  async function createVehicle(overrides?: Partial<Record<string, string>>): Promise<VehicleJson> {
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

  async function createParticipant(overrides?: Partial<Record<string, string>>): Promise<string> {
    const person = await createPerson(app, {
      displayName: 'Teilnehmer',
      personType: 'youth',
      permission: 'crew',
      username: `teilnehmer-${Math.random().toString(36).slice(2)}`,
      password: 'teilnehmer-password',
      ...overrides,
    });
    return person.id;
  }

  async function setParticipants(bfDayId: string, personIds: string[]): Promise<void> {
    const res = await app
      .client()
      .put(
        `/api/v1/bf-days/${bfDayId}/participants`,
        { person_ids: personIds },
        { token: adminToken }
      );
    expect(res.status).toBe(200);
  }

  async function monitorToken(): Promise<string> {
    const createRes = await app
      .client()
      .post('/api/v1/monitors', { name: 'Standby shifts' }, { token: adminToken });
    const monitorId = (createRes.body as { id: string }).id;
    const codeRes = await app
      .client()
      .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as { code: string }).code;
    const pairRes = await app.client().post('/api/v1/auth/monitor/pair', { code });
    return (pairRes.body as { access_token: string }).access_token;
  }

  async function getDefaultShift(bfDayId: string): Promise<ShiftJson> {
    const res = await app
      .client()
      .get(`/api/v1/bf-days/${bfDayId}/shifts`, { token: dispatchToken });
    expect(res.status).toBe(200);
    const shifts = res.body as ShiftJson[];
    expect(shifts).toHaveLength(1);
    return shifts[0] as ShiftJson;
  }

  describe('list', () => {
    it('shows the default shift via GET, sorted by starts_at then name', async () => {
      const created = await createBfDay({ name: 'Liste' });
      const shift = await getDefaultShift(created.id);
      expect(shift.name).toBe('Schicht 1');
      expect(shift.bf_day_id).toBe(created.id);
      expect(shift.crew).toEqual([]);
    });
  });

  describe('create/patch/delete', () => {
    it('creates a shift fully within the period', async () => {
      const created = await createBfDay({ name: 'CRUD' });
      const res = await app.client().post(
        `/api/v1/bf-days/${created.id}/shifts`,
        {
          name: 'Nachtschicht',
          starts_at: '2026-06-01T22:00:00Z',
          ends_at: '2026-06-02T06:00:00Z',
        },
        { token: dispatchToken }
      );
      expect(res.status).toBe(201);
      const shift = res.body as ShiftJson;
      expect(shift.name).toBe('Nachtschicht');
      expect(shift.bf_day_id).toBe(created.id);
    });

    it('rejects a shift outside the bf-day period with 409 shift_outside_bf_day', async () => {
      const created = await createBfDay({ name: 'Outside' });
      const res = await app
        .client()
        .post(
          `/api/v1/bf-days/${created.id}/shifts`,
          { name: 'Zu spät', starts_at: '2026-06-02T07:00:00Z', ends_at: '2026-06-02T10:00:00Z' },
          { token: dispatchToken }
        );
      expect(res.status).toBe(409);
      expect(res.body).toMatchObject({ error: { code: 'shift_outside_bf_day' } });
    });

    it('rejects ends_at <= starts_at with 400', async () => {
      const created = await createBfDay({ name: 'InvalidPeriod' });
      const res = await app
        .client()
        .post(
          `/api/v1/bf-days/${created.id}/shifts`,
          { name: 'x', starts_at: '2026-06-01T10:00:00Z', ends_at: '2026-06-01T10:00:00Z' },
          { token: dispatchToken }
        );
      expect(res.status).toBe(400);
      expect(res.body).toMatchObject({ error: { code: 'validation_error' } });
    });

    it('patches a shift, rejecting a move outside the period', async () => {
      const created = await createBfDay({ name: 'Patch' });
      const nightRes = await app
        .client()
        .post(
          `/api/v1/bf-days/${created.id}/shifts`,
          { name: 'Nacht', starts_at: '2026-06-01T22:00:00Z', ends_at: '2026-06-02T06:00:00Z' },
          { token: dispatchToken }
        );
      const night = nightRes.body as ShiftJson;

      const renamed = await app.client().patch(
        `/api/v1/bf-days/${created.id}/shifts/${night.id}`,
        { name: 'Nacht geändert' },
        {
          token: dispatchToken,
        }
      );
      expect(renamed.status).toBe(200);
      expect((renamed.body as ShiftJson).name).toBe('Nacht geändert');

      const moved = await app
        .client()
        .patch(
          `/api/v1/bf-days/${created.id}/shifts/${night.id}`,
          { ends_at: '2026-06-02T09:00:00Z' },
          { token: dispatchToken }
        );
      expect(moved.status).toBe(409);
      expect(moved.body).toMatchObject({ error: { code: 'shift_outside_bf_day' } });
    });

    it('404s for a shift id that does not belong to the given bf-day', async () => {
      const created = await createBfDay({ name: '404-Owner' });
      const other = await createBfDay({
        name: 'Anderer',
        starts_at: '2026-07-01T08:00:00Z',
        ends_at: '2026-07-02T08:00:00Z',
      });
      const otherShift = await getDefaultShift(other.id);

      const res = await app.client().patch(
        `/api/v1/bf-days/${created.id}/shifts/${otherShift.id}`,
        { name: 'x' },
        {
          token: dispatchToken,
        }
      );
      expect(res.status).toBe(404);
    });

    it('cannot delete the last shift of a bf-day (409 last_shift)', async () => {
      const created = await createBfDay({ name: 'LastShift' });
      const shift = await getDefaultShift(created.id);

      const res = await app
        .client()
        .delete(`/api/v1/bf-days/${created.id}/shifts/${shift.id}`, { token: dispatchToken });
      expect(res.status).toBe(409);
      expect(res.body).toMatchObject({ error: { code: 'last_shift' } });
    });

    it('deletes a non-last shift', async () => {
      const created = await createBfDay({ name: 'Delete' });
      const nightRes = await app
        .client()
        .post(
          `/api/v1/bf-days/${created.id}/shifts`,
          { name: 'Nacht', starts_at: '2026-06-01T22:00:00Z', ends_at: '2026-06-02T06:00:00Z' },
          { token: dispatchToken }
        );
      const night = nightRes.body as ShiftJson;

      const res = await app
        .client()
        .delete(`/api/v1/bf-days/${created.id}/shifts/${night.id}`, { token: dispatchToken });
      expect(res.status).toBe(204);

      const list = await app
        .client()
        .get(`/api/v1/bf-days/${created.id}/shifts`, { token: dispatchToken });
      expect((list.body as ShiftJson[]).map(s => s.id)).not.toContain(night.id);
    });

    it('rejects create/patch/delete on an ended bf-day with 409 bf_day_ended', async () => {
      const created = await createBfDay({ name: 'Ended' });
      const shift = await getDefaultShift(created.id);
      await app.client().post(`/api/v1/bf-days/${created.id}/start`, {}, { token: adminToken });
      await app.client().post(`/api/v1/bf-days/${created.id}/end`, {}, { token: adminToken });

      const create = await app
        .client()
        .post(
          `/api/v1/bf-days/${created.id}/shifts`,
          { name: 'x', starts_at: '2026-06-01T08:00:00Z', ends_at: '2026-06-01T09:00:00Z' },
          { token: dispatchToken }
        );
      expect(create.status).toBe(409);
      expect(create.body).toMatchObject({ error: { code: 'bf_day_ended' } });

      const patch = await app.client().patch(
        `/api/v1/bf-days/${created.id}/shifts/${shift.id}`,
        { name: 'x' },
        {
          token: dispatchToken,
        }
      );
      expect(patch.status).toBe(409);
      expect(patch.body).toMatchObject({ error: { code: 'bf_day_ended' } });

      const del = await app
        .client()
        .delete(`/api/v1/bf-days/${created.id}/shifts/${shift.id}`, { token: dispatchToken });
      expect(del.status).toBe(409);
      expect(del.body).toMatchObject({ error: { code: 'bf_day_ended' } });
    });
  });

  describe('crew', () => {
    it('replaces the crew, allowing a person on two vehicles in the same shift', async () => {
      const created = await createBfDay({ name: 'Crew' });
      const shift = await getDefaultShift(created.id);
      const p1 = await createParticipant({ username: 'crew-p1' });
      await setParticipants(created.id, [p1]);
      const v1 = await createVehicle({ call_sign: 'V1' });
      const v2 = await createVehicle({ call_sign: 'V2' });

      const res = await app.client().put(
        `/api/v1/shifts/${shift.id}/crew`,
        {
          assignments: [
            { vehicle_id: v1.id, person_id: p1, function: 'GF' },
            { vehicle_id: v2.id, person_id: p1, function: 'MA' },
          ],
        },
        { token: dispatchToken }
      );
      expect(res.status).toBe(200);
      const crew = (res.body as ShiftJson).crew;
      expect(crew).toHaveLength(2);
      expect(crew.map(c => c.vehicle_id).sort()).toEqual([v1.id, v2.id].sort());
    });

    it('rejects a non-participant with 409 person_not_participant', async () => {
      const created = await createBfDay({ name: 'NonParticipant' });
      const shift = await getDefaultShift(created.id);
      const nonParticipant = await createParticipant({ username: 'non-participant' });
      const v1 = await createVehicle({ call_sign: 'NP-V' });

      const res = await app
        .client()
        .put(
          `/api/v1/shifts/${shift.id}/crew`,
          { assignments: [{ vehicle_id: v1.id, person_id: nonParticipant, function: 'GF' }] },
          { token: dispatchToken }
        );
      expect(res.status).toBe(409);
      expect(res.body).toMatchObject({ error: { code: 'person_not_participant' } });
    });

    it('rejects an unknown vehicle with 400 validation_error', async () => {
      const created = await createBfDay({ name: 'UnknownVehicle' });
      const shift = await getDefaultShift(created.id);
      const p1 = await createParticipant({ username: 'uv-p1' });
      await setParticipants(created.id, [p1]);

      const res = await app.client().put(
        `/api/v1/shifts/${shift.id}/crew`,
        {
          assignments: [
            {
              vehicle_id: '00000000-0000-0000-0000-000000000000',
              person_id: p1,
              function: 'GF',
            },
          ],
        },
        { token: dispatchToken }
      );
      expect(res.status).toBe(400);
      expect(res.body).toMatchObject({ error: { code: 'validation_error' } });
    });

    it('rejects an inactive vehicle with 409 vehicle_inactive', async () => {
      const created = await createBfDay({ name: 'InactiveVehicle' });
      const shift = await getDefaultShift(created.id);
      const p1 = await createParticipant({ username: 'iv-p1' });
      await setParticipants(created.id, [p1]);
      const v1 = await createVehicle({ call_sign: 'Inactive-V' });
      await app
        .client()
        .patch(`/api/v1/vehicles/${v1.id}`, { active: false }, { token: adminToken });

      const res = await app
        .client()
        .put(
          `/api/v1/shifts/${shift.id}/crew`,
          { assignments: [{ vehicle_id: v1.id, person_id: p1, function: 'GF' }] },
          { token: dispatchToken }
        );
      expect(res.status).toBe(409);
      expect(res.body).toMatchObject({ error: { code: 'vehicle_inactive' } });
    });

    it('rejects a duplicate (vehicle_id, person_id) pair with 400 validation_error', async () => {
      const created = await createBfDay({ name: 'Duplicate' });
      const shift = await getDefaultShift(created.id);
      const p1 = await createParticipant({ username: 'dup-p1' });
      await setParticipants(created.id, [p1]);
      const v1 = await createVehicle({ call_sign: 'Dup-V' });

      const res = await app.client().put(
        `/api/v1/shifts/${shift.id}/crew`,
        {
          assignments: [
            { vehicle_id: v1.id, person_id: p1, function: 'GF' },
            { vehicle_id: v1.id, person_id: p1, function: 'MA' },
          ],
        },
        { token: dispatchToken }
      );
      expect(res.status).toBe(400);
      expect(res.body).toMatchObject({ error: { code: 'validation_error' } });
    });

    it('rejects a function longer than 16 chars after trim with 400 validation_error', async () => {
      const created = await createBfDay({ name: 'FunctionTooLong' });
      const shift = await getDefaultShift(created.id);
      const p1 = await createParticipant({ username: 'ft-p1' });
      await setParticipants(created.id, [p1]);
      const v1 = await createVehicle({ call_sign: 'FT-V' });

      const res = await app.client().put(
        `/api/v1/shifts/${shift.id}/crew`,
        {
          assignments: [{ vehicle_id: v1.id, person_id: p1, function: '  this-is-way-too-long  ' }],
        },
        { token: dispatchToken }
      );
      expect(res.status).toBe(400);
      expect(res.body).toMatchObject({ error: { code: 'validation_error' } });
    });

    it('rejects crew replace on an ended bf-day with 409 bf_day_ended', async () => {
      const created = await createBfDay({ name: 'EndedCrew' });
      const shift = await getDefaultShift(created.id);
      await app.client().post(`/api/v1/bf-days/${created.id}/start`, {}, { token: adminToken });
      await app.client().post(`/api/v1/bf-days/${created.id}/end`, {}, { token: adminToken });

      const res = await app
        .client()
        .put(`/api/v1/shifts/${shift.id}/crew`, { assignments: [] }, { token: dispatchToken });
      expect(res.status).toBe(409);
      expect(res.body).toMatchObject({ error: { code: 'bf_day_ended' } });
    });
  });

  describe('permissions', () => {
    it('dispatch and admin may write shifts; crew/preparation get 403; crew may GET; monitor gets 403', async () => {
      const created = await createBfDay({ name: 'Perm-Shifts' });
      const shift = await getDefaultShift(created.id);
      const monitor = await monitorToken();

      expect(
        (await app.client().get(`/api/v1/bf-days/${created.id}/shifts`, { token: crewToken }))
          .status
      ).toBe(200);
      expect(
        (await app.client().get(`/api/v1/bf-days/${created.id}/shifts`, { token: monitor })).status
      ).toBe(403);
      expect((await app.client().get(`/api/v1/bf-days/${created.id}/shifts`)).status).toBe(401);

      for (const t of [crewToken, preparationToken]) {
        expect(
          (
            await app
              .client()
              .post(
                `/api/v1/bf-days/${created.id}/shifts`,
                { name: 'x', starts_at: '2026-06-01T08:00:00Z', ends_at: '2026-06-01T09:00:00Z' },
                { token: t }
              )
          ).status
        ).toBe(403);
        expect(
          (
            await app
              .client()
              .patch(
                `/api/v1/bf-days/${created.id}/shifts/${shift.id}`,
                { name: 'x' },
                { token: t }
              )
          ).status
        ).toBe(403);
        expect(
          (
            await app
              .client()
              .delete(`/api/v1/bf-days/${created.id}/shifts/${shift.id}`, { token: t })
          ).status
        ).toBe(403);
        expect(
          (
            await app
              .client()
              .put(`/api/v1/shifts/${shift.id}/crew`, { assignments: [] }, { token: t })
          ).status
        ).toBe(403);
      }

      expect(
        (
          await app
            .client()
            .post(
              `/api/v1/bf-days/${created.id}/shifts`,
              { name: 'x', starts_at: '2026-06-01T08:00:00Z', ends_at: '2026-06-01T09:00:00Z' },
              { token: monitor }
            )
        ).status
      ).toBe(403);
    });
  });

  describe('realtime', () => {
    it('emits shift.crew_changed on create/patch/crew-replace, and shift.deleted on delete', async () => {
      const created = await createBfDay({ name: 'Realtime' });
      const ws = await connectWs(app.baseUrl, adminToken);
      await ws.next(m => m.type === 'hello');
      try {
        const createRes = await app
          .client()
          .post(
            `/api/v1/bf-days/${created.id}/shifts`,
            { name: 'Nacht', starts_at: '2026-06-01T22:00:00Z', ends_at: '2026-06-02T06:00:00Z' },
            { token: dispatchToken }
          );
        const night = createRes.body as ShiftJson;
        const createdEvent = await ws.next(m => m.type === 'shift.crew_changed');
        expect((createdEvent.data as ShiftJson).id).toBe(night.id);

        await app.client().patch(
          `/api/v1/bf-days/${created.id}/shifts/${night.id}`,
          { name: 'Nacht2' },
          {
            token: dispatchToken,
          }
        );
        const patchedEvent = await ws.next(m => m.type === 'shift.crew_changed');
        expect((patchedEvent.data as ShiftJson).name).toBe('Nacht2');

        const p1 = await createParticipant({ username: 'rt-p1' });
        await setParticipants(created.id, [p1]);
        const v1 = await createVehicle({ call_sign: 'RT-V' });
        await app
          .client()
          .put(
            `/api/v1/shifts/${night.id}/crew`,
            { assignments: [{ vehicle_id: v1.id, person_id: p1, function: 'GF' }] },
            { token: dispatchToken }
          );
        const crewEvent = await ws.next(m => m.type === 'shift.crew_changed');
        expect((crewEvent.data as ShiftJson).crew).toHaveLength(1);

        const deleteRes = await app
          .client()
          .delete(`/api/v1/bf-days/${created.id}/shifts/${night.id}`, { token: dispatchToken });
        expect(deleteRes.status).toBe(204);
        const deletedEvent = await ws.next(m => m.type === 'shift.deleted');
        expect(deletedEvent.data).toMatchObject({ id: night.id, bf_day_id: created.id });
      } finally {
        ws.close();
      }
    });
  });

  describe('snapshot', () => {
    it('no running day -> bf_day null, shifts [], current_shift_id null', async () => {
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
        const res = await freshApp.client().get('/api/v1/snapshot', { token: freshAdminToken });
        expect(res.status).toBe(200);
        expect(res.body).toMatchObject({ bf_day: null, shifts: [], current_shift_id: null });
      } finally {
        await freshApp.close();
      }
    });

    it('running day: current_shift_id changes as the clock moves across a night shift boundary', async () => {
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
        freshApp.clock.set(new Date('2026-06-01T08:00:00Z'));

        const createRes = await freshApp
          .client()
          .post('/api/v1/bf-days', createBfDayBody(), { token: freshAdminToken });
        const day = createRes.body as BfDayJson;

        const defaultShiftRes = await freshApp
          .client()
          .get(`/api/v1/bf-days/${day.id}/shifts`, { token: freshAdminToken });
        const defaultShift = (defaultShiftRes.body as ShiftJson[])[0] as ShiftJson;

        const nightRes = await freshApp
          .client()
          .post(
            `/api/v1/bf-days/${day.id}/shifts`,
            { name: 'Nacht', starts_at: '2026-06-01T22:00:00Z', ends_at: '2026-06-02T06:00:00Z' },
            { token: freshAdminToken }
          );
        const night = nightRes.body as ShiftJson;

        await freshApp
          .client()
          .post(`/api/v1/bf-days/${day.id}/start`, {}, { token: freshAdminToken });

        freshApp.clock.set(new Date('2026-06-01T12:00:00Z'));
        const beforeNight = await freshApp
          .client()
          .get('/api/v1/snapshot', { token: freshAdminToken });
        expect(beforeNight.status).toBe(200);
        expect((beforeNight.body as { current_shift_id: string }).current_shift_id).toBe(
          defaultShift.id
        );
        expect((beforeNight.body as { shifts: ShiftJson[] }).shifts.map(s => s.id).sort()).toEqual(
          [defaultShift.id, night.id].sort()
        );

        freshApp.clock.set(new Date('2026-06-01T23:00:00Z'));
        const duringNight = await freshApp
          .client()
          .get('/api/v1/snapshot', { token: freshAdminToken });
        expect((duringNight.body as { current_shift_id: string }).current_shift_id).toBe(night.id);
      } finally {
        await freshApp.close();
      }
    });

    it('monitor token can read the snapshot including crew', async () => {
      const created = await createBfDay({ name: 'MonitorSnapshot' });
      const p1 = await createParticipant({ username: 'ms-p1' });
      await setParticipants(created.id, [p1]);
      const shift = await getDefaultShift(created.id);
      const v1 = await createVehicle({ call_sign: 'MS-V' });
      await app
        .client()
        .put(
          `/api/v1/shifts/${shift.id}/crew`,
          { assignments: [{ vehicle_id: v1.id, person_id: p1, function: 'GF' }] },
          { token: dispatchToken }
        );
      await app.client().post(`/api/v1/bf-days/${created.id}/start`, {}, { token: adminToken });

      const monitor = await monitorToken();
      const res = await app.client().get('/api/v1/snapshot', { token: monitor });
      expect(res.status).toBe(200);
      const body = res.body as { shifts: ShiftJson[] };
      expect(body.shifts.find(s => s.id === shift.id)?.crew).toHaveLength(1);

      // End the running bf-day started above so it doesn't collide with
      // later tests in this file (at most one running bf-day at a time).
      await app.client().post(`/api/v1/bf-days/${created.id}/end`, {}, { token: adminToken });
    });
  });
});
