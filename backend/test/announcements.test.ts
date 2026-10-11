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

interface AnnouncementJson {
  id: string;
  bf_day_id: string;
  shift_id: string | null;
  text: string;
  created_by: string;
  created_at: string;
}

const DAY_MS = 24 * 60 * 60 * 1000;

function createBfDayBody(
  overrides?: Partial<{ name: string; starts_at: string; ends_at: string }>
) {
  const startsAt = new Date('2026-06-01T08:00:00Z');
  const endsAt = new Date(startsAt.getTime() + DAY_MS);
  return {
    name: 'BF-Tag Durchsagen',
    starts_at: startsAt.toISOString(),
    ends_at: endsAt.toISOString(),
    ...overrides,
  };
}

describe('announcements', () => {
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
      username: 'ann-dispatch1',
      password: 'dispatch-password',
    });
    dispatchToken = await loginAs(app, 'ann-dispatch1', 'dispatch-password');

    const crewPerson = await createPerson(app, {
      displayName: 'Mannschaft',
      personType: 'youth',
      permission: 'crew',
      username: 'ann-crew1',
      password: 'crew-password',
    });
    crewToken = await signTestAccessToken(app, crewPerson.id, 'crew');

    await createPerson(app, {
      displayName: 'Vorbereitung',
      personType: 'supervisor',
      permission: 'preparation',
      username: 'ann-prep1',
      password: 'prep-password',
    });
    preparationToken = await loginAs(app, 'ann-prep1', 'prep-password');
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

  async function startBfDay(bfDayId: string): Promise<void> {
    const res = await app
      .client()
      .post(`/api/v1/bf-days/${bfDayId}/start`, {}, { token: adminToken });
    expect(res.status).toBe(200);
  }

  async function endBfDay(bfDayId: string): Promise<void> {
    const res = await app
      .client()
      .post(`/api/v1/bf-days/${bfDayId}/end`, {}, { token: adminToken });
    expect(res.status).toBe(200);
  }

  async function getDefaultShift(bfDayId: string): Promise<ShiftJson> {
    const res = await app
      .client()
      .get(`/api/v1/bf-days/${bfDayId}/shifts`, { token: dispatchToken });
    expect(res.status).toBe(200);
    const shifts = res.body as ShiftJson[];
    expect(shifts.length).toBeGreaterThan(0);
    return shifts[0] as ShiftJson;
  }

  async function createVehicle(overrides?: Partial<Record<string, string>>): Promise<VehicleJson> {
    const res = await app.client().post(
      '/api/v1/vehicles',
      {
        call_sign: `Florian ${Math.random().toString(36).slice(2, 8)}`,
        short_name: 'HLF',
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
      username: `ann-teilnehmer-${Math.random().toString(36).slice(2)}`,
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

  async function assignCrew(shiftId: string, personId: string, vehicleId: string): Promise<void> {
    const res = await app
      .client()
      .put(
        `/api/v1/shifts/${shiftId}/crew`,
        { assignments: [{ vehicle_id: vehicleId, person_id: personId, function: 'GF' }] },
        { token: dispatchToken }
      );
    expect(res.status).toBe(200);
  }

  async function monitorToken(): Promise<string> {
    const createRes = await app
      .client()
      .post('/api/v1/monitors', { name: `Standby ann ${Math.random()}` }, { token: adminToken });
    const monitorId = (createRes.body as { id: string }).id;
    const codeRes = await app
      .client()
      .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as { code: string }).code;
    const pairRes = await app.client().post('/api/v1/auth/monitor/pair', { code });
    return (pairRes.body as { access_token: string }).access_token;
  }

  /** Sets up a running bf-day with one shift, one assigned crew member, and
   * one crew person with no assignment at all. */
  async function setupRunningDayWithShiftCrew(): Promise<{
    day: BfDayJson;
    shift: ShiftJson;
    assignedPersonId: string;
    assignedToken: string;
    unassignedPersonId: string;
    unassignedToken: string;
  }> {
    const day = await createBfDay({ name: `Running ${Math.random()}` });
    const shift = await getDefaultShift(day.id);
    const assignedPersonId = await createParticipant();
    const vehicle = await createVehicle();
    await setParticipants(day.id, [assignedPersonId]);
    await assignCrew(shift.id, assignedPersonId, vehicle.id);
    await startBfDay(day.id);

    const assignedToken = await signTestAccessToken(app, assignedPersonId, 'crew');

    const unassignedPerson = await createPerson(app, {
      displayName: 'Unbeteiligt',
      personType: 'youth',
      permission: 'crew',
      username: `ann-unassigned-${Math.random().toString(36).slice(2)}`,
      password: 'unassigned-password',
    });
    const unassignedToken = await signTestAccessToken(app, unassignedPerson.id, 'crew');

    return {
      day,
      shift,
      assignedPersonId,
      assignedToken,
      unassignedPersonId: unassignedPerson.id,
      unassignedToken,
    };
  }

  describe('permissions', () => {
    it('dispatch/admin may POST/DELETE; crew and preparation get 403; monitor gets 403 on POST', async () => {
      const { day } = await setupRunningDayWithShiftCrew();
      const monitor = await monitorToken();

      for (const token of [crewToken, preparationToken, monitor]) {
        const res = await app
          .client()
          .post(`/api/v1/bf-days/${day.id}/announcements`, { text: 'x' }, { token });
        expect(res.status).toBe(403);
      }
      expect(
        (await app.client().post(`/api/v1/bf-days/${day.id}/announcements`, { text: 'x' })).status
      ).toBe(401);

      const created = await app.client().post(
        `/api/v1/bf-days/${day.id}/announcements`,
        { text: 'Admin-Durchsage' },
        {
          token: adminToken,
        }
      );
      expect(created.status).toBe(201);
      const announcement = created.body as AnnouncementJson;

      for (const token of [crewToken, preparationToken]) {
        expect(
          (await app.client().delete(`/api/v1/announcements/${announcement.id}`, { token })).status
        ).toBe(403);
      }
      expect((await app.client().delete(`/api/v1/announcements/${announcement.id}`)).status).toBe(
        401
      );

      const createdByDispatch = await app.client().post(
        `/api/v1/bf-days/${day.id}/announcements`,
        { text: 'Dispatch-Durchsage' },
        {
          token: dispatchToken,
        }
      );
      expect(createdByDispatch.status).toBe(201);
      const second = createdByDispatch.body as AnnouncementJson;
      expect(
        (await app.client().delete(`/api/v1/announcements/${second.id}`, { token: dispatchToken }))
          .status
      ).toBe(204);
      expect(
        (
          await app
            .client()
            .delete(`/api/v1/announcements/${announcement.id}`, { token: adminToken })
        ).status
      ).toBe(204);
      await endBfDay(day.id);
    });
  });

  describe('state and validation', () => {
    it('rejects POST/DELETE on a planning or ended day with 409 bf_day_not_running', async () => {
      const planning = await createBfDay({ name: `Planning ${Math.random()}` });
      const planningPost = await app.client().post(
        `/api/v1/bf-days/${planning.id}/announcements`,
        { text: 'x' },
        {
          token: dispatchToken,
        }
      );
      expect(planningPost.status).toBe(409);
      expect(planningPost.body).toMatchObject({ error: { code: 'bf_day_not_running' } });

      const ended = await createBfDay({ name: `Ended ${Math.random()}` });
      await startBfDay(ended.id);
      const createdWhileRunning = await app.client().post(
        `/api/v1/bf-days/${ended.id}/announcements`,
        { text: 'x' },
        {
          token: dispatchToken,
        }
      );
      expect(createdWhileRunning.status).toBe(201);
      const announcement = createdWhileRunning.body as AnnouncementJson;
      await endBfDay(ended.id);
      const endedPost = await app.client().post(
        `/api/v1/bf-days/${ended.id}/announcements`,
        { text: 'x' },
        {
          token: dispatchToken,
        }
      );
      expect(endedPost.status).toBe(409);
      expect(endedPost.body).toMatchObject({ error: { code: 'bf_day_not_running' } });

      const endedDelete = await app
        .client()
        .delete(`/api/v1/announcements/${announcement.id}`, { token: dispatchToken });
      expect(endedDelete.status).toBe(409);
      expect(endedDelete.body).toMatchObject({ error: { code: 'bf_day_not_running' } });
    });

    it('rejects empty text, text over 500 chars, and a shift from another day with 400', async () => {
      const { day, shift } = await setupRunningDayWithShiftCrew();

      const empty = await app
        .client()
        .post(`/api/v1/bf-days/${day.id}/announcements`, { text: '' }, { token: dispatchToken });
      expect(empty.status).toBe(400);
      expect(empty.body).toMatchObject({ error: { code: 'validation_error' } });

      const tooLong = await app.client().post(
        `/api/v1/bf-days/${day.id}/announcements`,
        { text: 'x'.repeat(501) },
        {
          token: dispatchToken,
        }
      );
      expect(tooLong.status).toBe(400);
      expect(tooLong.body).toMatchObject({ error: { code: 'validation_error' } });

      const otherDay = await createBfDay({
        name: `Other ${Math.random()}`,
        starts_at: '2026-07-01T08:00:00Z',
        ends_at: '2026-07-02T08:00:00Z',
      });
      const otherShift = await getDefaultShift(otherDay.id);
      void shift;

      const foreignShift = await app
        .client()
        .post(
          `/api/v1/bf-days/${day.id}/announcements`,
          { text: 'x', shift_id: otherShift.id },
          { token: dispatchToken }
        );
      expect(foreignShift.status).toBe(400);
      expect(foreignShift.body).toMatchObject({ error: { code: 'validation_error' } });
      await endBfDay(day.id);
    });
  });

  describe('GET visibility', () => {
    it('a shift announcement is visible to its crew, preparation/dispatch/admin, and monitor, not to an unassigned crew person; shift_id null is visible to all; newest first', async () => {
      const { day, shift, assignedToken, unassignedToken } = await setupRunningDayWithShiftCrew();
      const monitor = await monitorToken();

      const shiftAnnRes = await app
        .client()
        .post(
          `/api/v1/bf-days/${day.id}/announcements`,
          { text: 'Schicht-Durchsage', shift_id: shift.id },
          { token: dispatchToken }
        );
      expect(shiftAnnRes.status).toBe(201);
      const shiftAnn = shiftAnnRes.body as AnnouncementJson;

      // Distinct `created_at` so "newest first" below has a deterministic
      // order to assert on (FakeClock is frozen otherwise).
      app.clock.advance(1000);

      const allAnnRes = await app.client().post(
        `/api/v1/bf-days/${day.id}/announcements`,
        { text: 'Alle' },
        {
          token: dispatchToken,
        }
      );
      expect(allAnnRes.status).toBe(201);
      const allAnn = allAnnRes.body as AnnouncementJson;

      async function listAs(token: string): Promise<AnnouncementJson[]> {
        const res = await app.client().get(`/api/v1/bf-days/${day.id}/announcements`, { token });
        expect(res.status).toBe(200);
        return res.body as AnnouncementJson[];
      }

      for (const token of [assignedToken, preparationToken, dispatchToken, adminToken, monitor]) {
        const list = await listAs(token);
        expect(list.map(a => a.id)).toContain(shiftAnn.id);
      }

      const unassignedList = await listAs(unassignedToken);
      expect(unassignedList.map(a => a.id)).not.toContain(shiftAnn.id);
      expect(unassignedList.map(a => a.id)).toContain(allAnn.id);

      const adminList = await listAs(adminToken);
      expect(adminList.map(a => a.id)).toEqual([allAnn.id, shiftAnn.id]);
      await endBfDay(day.id);
    });
  });

  describe('realtime', () => {
    it('an unassigned crew connection receives skip with the same seq as the data assigned crew/monitor get, for created and deleted', async () => {
      const { day, shift, assignedToken, unassignedToken } = await setupRunningDayWithShiftCrew();
      const monitor = await monitorToken();

      const unassignedWs = await connectWs(app.baseUrl, unassignedToken);
      const assignedWs = await connectWs(app.baseUrl, assignedToken);
      const monitorWs = await connectWs(app.baseUrl, monitor);
      try {
        await unassignedWs.next(m => m.type === 'hello');
        await assignedWs.next(m => m.type === 'hello');
        await monitorWs.next(m => m.type === 'hello');

        const createRes = await app
          .client()
          .post(
            `/api/v1/bf-days/${day.id}/announcements`,
            { text: 'Nur Schicht', shift_id: shift.id },
            { token: dispatchToken }
          );
        expect(createRes.status).toBe(201);
        const announcement = createRes.body as AnnouncementJson;

        const skipCreated = await unassignedWs.next(m => m.type === 'skip');
        const createdForAssigned = await assignedWs.next(m => m.type === 'announcement.created');
        const createdForMonitor = await monitorWs.next(m => m.type === 'announcement.created');
        expect(skipCreated.seq).toBe(createdForAssigned.seq);
        expect(skipCreated.seq).toBe(createdForMonitor.seq);
        expect((createdForAssigned.data as AnnouncementJson).id).toBe(announcement.id);
        expect((createdForMonitor.data as AnnouncementJson).id).toBe(announcement.id);

        const deleteRes = await app
          .client()
          .delete(`/api/v1/announcements/${announcement.id}`, { token: dispatchToken });
        expect(deleteRes.status).toBe(204);

        const skipDeleted = await unassignedWs.next(m => m.type === 'skip');
        const deletedForAssigned = await assignedWs.next(m => m.type === 'announcement.deleted');
        const deletedForMonitor = await monitorWs.next(m => m.type === 'announcement.deleted');
        expect(skipDeleted.seq).toBe(deletedForAssigned.seq);
        expect(skipDeleted.seq).toBe(deletedForMonitor.seq);
        expect((deletedForAssigned.data as { id: string }).id).toBe(announcement.id);
        expect((deletedForMonitor.data as { id: string }).id).toBe(announcement.id);
      } finally {
        unassignedWs.close();
        assignedWs.close();
        monitorWs.close();
        await endBfDay(day.id);
      }
    });
  });

  describe('snapshot', () => {
    it('contains at most 20 visible announcements, newest first, [] without a running day', async () => {
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
        const noRun = await freshApp.client().get('/api/v1/snapshot', { token: freshAdminToken });
        expect(noRun.status).toBe(200);
        expect((noRun.body as { announcements: unknown[] }).announcements).toEqual([]);

        const createRes = await freshApp
          .client()
          .post('/api/v1/bf-days', createBfDayBody({ name: 'Snapshot' }), {
            token: freshAdminToken,
          });
        const day = createRes.body as BfDayJson;
        await freshApp.client().post(
          `/api/v1/bf-days/${day.id}/start`,
          {},
          {
            token: freshAdminToken,
          }
        );

        const texts: string[] = [];
        for (let i = 0; i < 22; i++) {
          const text = `Durchsage ${i}`;
          texts.push(text);
          const res = await freshApp.client().post(
            `/api/v1/bf-days/${day.id}/announcements`,
            { text },
            {
              token: freshAdminToken,
            }
          );
          expect(res.status).toBe(201);
          // Distinct `created_at` per row (FakeClock is frozen otherwise),
          // so "newest first" has a deterministic order to assert on.
          freshApp.clock.advance(1000);
        }

        const snapshot = await freshApp
          .client()
          .get('/api/v1/snapshot', { token: freshAdminToken });
        expect(snapshot.status).toBe(200);
        const announcements = (snapshot.body as { announcements: AnnouncementJson[] })
          .announcements;
        expect(announcements).toHaveLength(20);
        expect(announcements.map(a => a.text)).toEqual(
          texts.slice(2).reverse() // newest first, oldest two dropped by the 20-cap
        );
      } finally {
        await freshApp.close();
      }
    });
  });

  describe('shift deletion', () => {
    it('deleting a non-last shift emits announcement.deleted and removes its announcements', async () => {
      const day = await createBfDay({ name: `ShiftDelete ${Math.random()}` });
      const nightRes = await app
        .client()
        .post(
          `/api/v1/bf-days/${day.id}/shifts`,
          { name: 'Nacht', starts_at: '2026-06-01T22:00:00Z', ends_at: '2026-06-02T06:00:00Z' },
          { token: dispatchToken }
        );
      expect(nightRes.status).toBe(201);
      const night = nightRes.body as ShiftJson;
      await startBfDay(day.id);

      const annRes = await app
        .client()
        .post(
          `/api/v1/bf-days/${day.id}/announcements`,
          { text: 'An die Nachtschicht', shift_id: night.id },
          { token: dispatchToken }
        );
      expect(annRes.status).toBe(201);
      const announcement = annRes.body as AnnouncementJson;

      const ws = await connectWs(app.baseUrl, adminToken);
      await ws.next(m => m.type === 'hello');
      try {
        const deleteRes = await app
          .client()
          .delete(`/api/v1/bf-days/${day.id}/shifts/${night.id}`, { token: dispatchToken });
        expect(deleteRes.status).toBe(204);
        const deletedEvent = await ws.next(m => m.type === 'announcement.deleted');
        expect(deletedEvent.data).toMatchObject({ id: announcement.id });
      } finally {
        ws.close();
      }

      const list = await app
        .client()
        .get(`/api/v1/bf-days/${day.id}/announcements`, { token: adminToken });
      expect((list.body as AnnouncementJson[]).map(a => a.id)).not.toContain(announcement.id);
      await endBfDay(day.id);
    });
  });
});
