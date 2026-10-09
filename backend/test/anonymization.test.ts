import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs, signTestAccessToken } from './support/create-person.js';
import { connectWs } from './support/ws-client.js';

const DAY_MS = 24 * 60 * 60 * 1000;

interface BfDayJson {
  id: string;
  name: string;
  starts_at: string;
  ends_at: string;
  state: 'planning' | 'running' | 'ended';
  anonymized_at: string | null;
  created_at: string;
}

interface AnonymizationSummaryJson {
  participations: number;
  crew_assignments: number;
  alarm_recipients: number;
  status_events: number;
  persons_deleted: number;
}

interface AnonymizeResponseJson {
  bf_day: BfDayJson;
  summary: AnonymizationSummaryJson;
}

interface ShiftJson {
  id: string;
  bf_day_id: string;
}

interface VehicleJson {
  id: string;
}

interface IncidentJson {
  id: string;
}

interface TriggerAlarmResponse {
  alarm: { id: string; recipients: Array<{ person_id: string }> };
}

describe('anonymization', () => {
  let app: TestApp;
  let pool: Pool;
  let adminToken: string;
  let dispatchToken: string;
  let dispatchPersonId: string;
  let crewToken: string;
  let preparationToken: string;
  let otherFireDepartmentId: string;

  beforeAll(async () => {
    app = await startTestApp();
    pool = new Pool({ connectionString: app.databaseUrl });

    adminToken = await loginAs(app, 'admin', 'admin-password');

    const dispatchPerson = await createPerson(app, {
      displayName: 'Leitstelle',
      personType: 'supervisor',
      permission: 'dispatch',
      username: 'anon-dispatch1',
      password: 'dispatch-password',
    });
    dispatchPersonId = dispatchPerson.id;
    dispatchToken = await loginAs(app, 'anon-dispatch1', 'dispatch-password');

    await createPerson(app, {
      displayName: 'Vorbereitung',
      personType: 'supervisor',
      permission: 'preparation',
      username: 'anon-prep1',
      password: 'prep-password',
    });
    preparationToken = await loginAs(app, 'anon-prep1', 'prep-password');

    const bystander = await createPerson(app, {
      displayName: 'Unbeteiligt',
      personType: 'youth',
      permission: 'crew',
      username: 'anon-bystander',
      password: 'bystander-password',
    });
    crewToken = await signTestAccessToken(app, bystander.id, 'crew');

    const otherFd = await pool.query<{ id: string }>(
      `insert into fire_department (name, is_own) values ('Nachbarwehr', false) returning id`
    );
    otherFireDepartmentId = otherFd.rows[0]!.id;
  });

  afterAll(async () => {
    await pool.end();
    await app.close();
  });

  async function createOtherFdPerson(displayName: string): Promise<string> {
    const result = await pool.query<{ id: string }>(
      `insert into person (fire_department_id, display_name, person_type, permission, active)
       values ($1, $2, 'youth', 'crew', true) returning id`,
      [otherFireDepartmentId, displayName]
    );
    return result.rows[0]!.id;
  }

  async function createBfDay(name: string): Promise<BfDayJson> {
    const startsAt = app.clock.now();
    const endsAt = new Date(startsAt.getTime() + DAY_MS);
    const res = await app
      .client()
      .post(
        '/api/v1/bf-days',
        { name, starts_at: startsAt.toISOString(), ends_at: endsAt.toISOString() },
        { token: adminToken }
      );
    expect(res.status).toBe(201);
    return res.body as BfDayJson;
  }

  async function startBfDay(id: string): Promise<void> {
    await pool.query(`update bf_day set state = 'ended' where state = 'running' and id != $1`, [
      id,
    ]);
    const res = await app.client().post(`/api/v1/bf-days/${id}/start`, {}, { token: adminToken });
    expect(res.status).toBe(200);
  }

  async function endBfDay(id: string): Promise<void> {
    const res = await app.client().post(`/api/v1/bf-days/${id}/end`, {}, { token: adminToken });
    expect(res.status).toBe(200);
  }

  async function getDefaultShift(bfDayId: string): Promise<ShiftJson> {
    const res = await app
      .client()
      .get(`/api/v1/bf-days/${bfDayId}/shifts`, { token: dispatchToken });
    expect(res.status).toBe(200);
    return (res.body as ShiftJson[])[0] as ShiftJson;
  }

  async function createVehicle(callSign: string): Promise<VehicleJson> {
    const res = await app
      .client()
      .post(
        '/api/v1/vehicles',
        { call_sign: callSign, short_name: callSign, type: 'HLF' },
        { token: adminToken }
      );
    expect(res.status).toBe(201);
    return res.body as VehicleJson;
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

  async function setCrew(
    shiftId: string,
    assignments: Array<{ vehicle_id: string; person_id: string; function: string }>
  ): Promise<void> {
    const res = await app
      .client()
      .put(`/api/v1/shifts/${shiftId}/crew`, { assignments }, { token: dispatchToken });
    expect(res.status).toBe(200);
  }

  async function createIncident(bfDayId: string, script?: string): Promise<IncidentJson> {
    const res = await app.client().post(
      `/api/v1/bf-days/${bfDayId}/incidents`,
      {
        keyword: 'Wohnungsbrand',
        address: 'Musterstraße 1',
        report: 'Rauch aus dem Fenster',
        ...(script !== undefined ? { script } : {}),
      },
      { token: preparationToken }
    );
    expect(res.status).toBe(201);
    return res.body as IncidentJson;
  }

  async function triggerAlarm(
    incidentId: string,
    vehicleIds: string[]
  ): Promise<TriggerAlarmResponse> {
    const res = await app
      .client()
      .post(
        `/api/v1/incidents/${incidentId}/alarms`,
        { vehicle_ids: vehicleIds },
        { token: dispatchToken }
      );
    expect(res.status).toBe(201);
    return res.body as TriggerAlarmResponse;
  }

  async function acknowledgeAlarm(alarmId: string, token: string): Promise<void> {
    const res = await app.client().post(`/api/v1/alarms/${alarmId}/acknowledge`, {}, { token });
    expect(res.status).toBe(200);
  }

  async function pairDevice(personId: string): Promise<{ deviceId: string }> {
    const codeRes = await app
      .client()
      .post(`/api/v1/persons/${personId}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as { code: string }).code;
    const pairRes = await app
      .client()
      .post('/api/v1/auth/pair', { code, platform: 'android', app_version: '1.0.0' });
    expect(pairRes.status).toBe(200);
    return { deviceId: (pairRes.body as { device_id: string }).device_id };
  }

  async function setVehicleStatus(vehicleId: string, status: number, token: string): Promise<void> {
    const res = await app
      .client()
      .put(`/api/v1/vehicles/${vehicleId}/status`, { status }, { token });
    expect(res.status).toBe(200);
  }

  /** Builds the full ended, non-anonymized BF-Tag fixture described in the ticket. */
  async function buildFixture(label: string): Promise<{
    day: BfDayJson;
    otherDay: BfDayJson;
    incident: IncidentJson;
    vehicle: VehicleJson;
    ownCrewPerson: string;
    otherOnlyThisDay: string;
    otherAlsoOtherDay: string;
    otherNoDay: string;
    runningEventVehicleId: string;
    outsideEventVehicleId: string;
  }> {
    const ownCrewPerson = (
      await createPerson(app, {
        displayName: `${label}-OwnCrew`,
        personType: 'youth',
        permission: 'crew',
        username: `${label}-own-crew`.toLowerCase(),
        password: 'own-crew-password',
      })
    ).id;

    const otherOnlyThisDay = await createOtherFdPerson(`${label}-OtherOnly`);
    const otherAlsoOtherDay = await createOtherFdPerson(`${label}-OtherAlso`);
    const otherNoDay = await createOtherFdPerson(`${label}-OtherNone`);

    const day = await createBfDay(label);
    const shift = await getDefaultShift(day.id);
    const vehicle = await createVehicle(`${label}-V1`);

    await setParticipants(day.id, [ownCrewPerson, otherOnlyThisDay, otherAlsoOtherDay]);
    await setCrew(shift.id, [
      { vehicle_id: vehicle.id, person_id: ownCrewPerson, function: 'GF' },
      { vehicle_id: vehicle.id, person_id: otherOnlyThisDay, function: 'MA' },
    ]);

    await pairDevice(otherOnlyThisDay);

    await startBfDay(day.id);
    const incident = await createIncident(day.id, 'GEHEIMES-DREHBUCH');
    const triggered = await triggerAlarm(incident.id, [vehicle.id]);
    const otherOnlyRecipient = triggered.alarm.recipients.find(
      r => r.person_id === otherOnlyThisDay
    );
    expect(otherOnlyRecipient).toBeDefined();
    const otherOnlyToken = await signTestAccessToken(app, otherOnlyThisDay, 'crew');
    await acknowledgeAlarm(triggered.alarm.id, otherOnlyToken);

    // Status event while this BF-Tag is running: bf_day_id gets stamped.
    await setVehicleStatus(vehicle.id, 3, dispatchToken);

    await endBfDay(day.id);

    // Status event with no BF-Tag running: bf_day_id stays null, person_id kept.
    await setVehicleStatus(vehicle.id, 4, dispatchToken);

    const otherDay = await createBfDay(`${label}-Other`);
    await setParticipants(otherDay.id, [otherAlsoOtherDay]);

    return {
      day,
      otherDay,
      incident,
      vehicle,
      ownCrewPerson,
      otherOnlyThisDay,
      otherAlsoOtherDay,
      otherNoDay,
      runningEventVehicleId: vehicle.id,
      outsideEventVehicleId: vehicle.id,
    };
  }

  it('preview matches the anonymize result; deletes the right rows and keeps the rest', async () => {
    const f = await buildFixture('Full');

    const previewRes = await app
      .client()
      .get(`/api/v1/bf-days/${f.day.id}/anonymization-preview`, { token: dispatchToken });
    expect(previewRes.status).toBe(200);
    const preview = previewRes.body as AnonymizationSummaryJson;
    expect(preview).toMatchObject({
      participations: 3,
      crew_assignments: 2,
      alarm_recipients: 2,
      status_events: 1,
      persons_deleted: 1,
    });

    const anonRes = await app
      .client()
      .post(`/api/v1/bf-days/${f.day.id}/anonymize`, {}, { token: dispatchToken });
    expect(anonRes.status).toBe(200);
    const body = anonRes.body as AnonymizeResponseJson;
    expect(body.summary).toEqual(preview);
    expect(body.bf_day.anonymized_at).toBe(app.clock.now().toISOString());

    // Teilnahmen/Besatzung/Empfänger of this day are gone.
    const participationRows = await pool.query('select 1 from participation where bf_day_id = $1', [
      f.day.id,
    ]);
    expect(participationRows.rowCount).toBe(0);

    const crewRows = await pool.query(
      `select 1 from crew_assignment ca join shift s on ca.shift_id = s.id where s.bf_day_id = $1`,
      [f.day.id]
    );
    expect(crewRows.rowCount).toBe(0);

    const recipientRows = await pool.query(
      `select 1 from alarm_recipient ar join alarm a on ar.alarm_id = a.id join incident i on a.incident_id = i.id where i.bf_day_id = $1`,
      [f.day.id]
    );
    expect(recipientRows.rowCount).toBe(0);

    // The other BF-Tag's participation is untouched.
    const otherDayParticipation = await pool.query(
      'select person_id from participation where bf_day_id = $1',
      [f.otherDay.id]
    );
    expect(otherDayParticipation.rows.map(r => r.person_id)).toEqual([f.otherAlsoOtherDay]);

    // Status events: the one stamped with this day's id lost person_id but
    // kept everything else; the one outside the day kept person_id.
    const events = await pool.query<{
      status: number;
      source: string;
      person_id: string | null;
      bf_day_id: string | null;
    }>(
      `select status, source, person_id, bf_day_id from vehicle_status_event
       where vehicle_id = $1 order by created_at asc`,
      [f.vehicle.id]
    );
    const insideEvent = events.rows.find(e => e.status === 3);
    const outsideEvent = events.rows.find(e => e.status === 4);
    expect(insideEvent).toMatchObject({ status: 3, source: 'dispatch', person_id: null });
    expect(outsideEvent).toMatchObject({ status: 4, source: 'dispatch' });
    expect(outsideEvent?.person_id).toBe(dispatchPersonId);
    expect(outsideEvent?.bf_day_id).toBeNull();

    // Persons: otherOnlyThisDay deleted (+ device + pairing code gone),
    // otherAlsoOtherDay and otherNoDay and own-FD persons kept.
    const deletedPerson = await pool.query('select 1 from person where id = $1', [
      f.otherOnlyThisDay,
    ]);
    expect(deletedPerson.rowCount).toBe(0);
    const deletedDevices = await pool.query('select 1 from device where person_id = $1', [
      f.otherOnlyThisDay,
    ]);
    expect(deletedDevices.rowCount).toBe(0);
    const deletedPairingCodes = await pool.query(
      `select 1 from pairing_code where target_type = 'person' and target_id = $1`,
      [f.otherOnlyThisDay]
    );
    expect(deletedPairingCodes.rowCount).toBe(0);

    const keptOtherAlso = await pool.query('select 1 from person where id = $1', [
      f.otherAlsoOtherDay,
    ]);
    expect(keptOtherAlso.rowCount).toBe(1);
    const keptOtherNone = await pool.query('select 1 from person where id = $1', [f.otherNoDay]);
    expect(keptOtherNone.rowCount).toBe(1);
    const keptOwnCrew = await pool.query('select 1 from person where id = $1', [f.ownCrewPerson]);
    expect(keptOwnCrew.rowCount).toBe(1);

    // Einsatz (Meldebild+Drehbuch), Alarm, alarm_vehicle, Fahrzeug, Schicht bleiben.
    const incidentRow = await pool.query('select report, script from incident where id = $1', [
      f.incident.id,
    ]);
    expect(incidentRow.rows[0]).toMatchObject({
      report: 'Rauch aus dem Fenster',
      script: 'GEHEIMES-DREHBUCH',
    });
    const alarmRows = await pool.query('select 1 from alarm where incident_id = $1', [
      f.incident.id,
    ]);
    expect(alarmRows.rowCount).toBe(1);
    const alarmVehicleRows = await pool.query(
      `select 1 from alarm_vehicle av join alarm a on av.alarm_id = a.id where a.incident_id = $1`,
      [f.incident.id]
    );
    expect(alarmVehicleRows.rowCount).toBe(1);
    const vehicleRow = await pool.query('select 1 from vehicle where id = $1', [f.vehicle.id]);
    expect(vehicleRow.rowCount).toBe(1);
    const shiftRows = await pool.query('select 1 from shift where bf_day_id = $1', [f.day.id]);
    expect(shiftRows.rowCount).toBe(1);

    // Second call -> 409 already anonymized.
    const second = await app
      .client()
      .post(`/api/v1/bf-days/${f.day.id}/anonymize`, {}, { token: dispatchToken });
    expect(second.status).toBe(409);
    expect(second.body).toMatchObject({ error: { code: 'bf_day_already_anonymized' } });

    const secondPreview = await app
      .client()
      .get(`/api/v1/bf-days/${f.day.id}/anonymization-preview`, { token: dispatchToken });
    expect(secondPreview.status).toBe(409);
    expect(secondPreview.body).toMatchObject({ error: { code: 'bf_day_already_anonymized' } });
  });

  it('rejects a running or planning BF-Tag with 409 bf_day_not_ended, nothing changes', async () => {
    const runningDay = await createBfDay('Running-Anon');
    await startBfDay(runningDay.id);

    const runningAnon = await app
      .client()
      .post(`/api/v1/bf-days/${runningDay.id}/anonymize`, {}, { token: dispatchToken });
    expect(runningAnon.status).toBe(409);
    expect(runningAnon.body).toMatchObject({ error: { code: 'bf_day_not_ended' } });

    const runningPreview = await app
      .client()
      .get(`/api/v1/bf-days/${runningDay.id}/anonymization-preview`, { token: dispatchToken });
    expect(runningPreview.status).toBe(409);
    expect(runningPreview.body).toMatchObject({ error: { code: 'bf_day_not_ended' } });

    const reloadedRunning = await pool.query('select state from bf_day where id = $1', [
      runningDay.id,
    ]);
    expect(reloadedRunning.rows[0]?.state).toBe('running');

    await pool.query(`update bf_day set state = 'ended' where id = $1`, [runningDay.id]);

    const planningDay = await createBfDay('Planning-Anon');
    const planningAnon = await app
      .client()
      .post(`/api/v1/bf-days/${planningDay.id}/anonymize`, {}, { token: dispatchToken });
    expect(planningAnon.status).toBe(409);
    expect(planningAnon.body).toMatchObject({ error: { code: 'bf_day_not_ended' } });

    const reloadedPlanning = await pool.query('select state from bf_day where id = $1', [
      planningDay.id,
    ]);
    expect(reloadedPlanning.rows[0]?.state).toBe('planning');
  });

  it('404s for an unknown id', async () => {
    const res = await app.client().post(
      '/api/v1/bf-days/00000000-0000-0000-0000-000000000000/anonymize',
      {},
      {
        token: dispatchToken,
      }
    );
    expect(res.status).toBe(404);
    expect(res.body).toMatchObject({ error: { code: 'bf_day_not_found' } });

    const previewRes = await app
      .client()
      .get('/api/v1/bf-days/00000000-0000-0000-0000-000000000000/anonymization-preview', {
        token: dispatchToken,
      });
    expect(previewRes.status).toBe(404);
    expect(previewRes.body).toMatchObject({ error: { code: 'bf_day_not_found' } });
  });

  it('Berechtigung: dispatch and admin OK, preparation and crew 403, unauthenticated 401', async () => {
    const dayForAdmin = await createBfDay('Perm-Admin');
    await startBfDay(dayForAdmin.id);
    await endBfDay(dayForAdmin.id);

    const prepRes = await app
      .client()
      .post(`/api/v1/bf-days/${dayForAdmin.id}/anonymize`, {}, { token: preparationToken });
    expect(prepRes.status).toBe(403);
    const crewRes = await app
      .client()
      .post(`/api/v1/bf-days/${dayForAdmin.id}/anonymize`, {}, { token: crewToken });
    expect(crewRes.status).toBe(403);
    const unauthRes = await app.client().post(`/api/v1/bf-days/${dayForAdmin.id}/anonymize`, {});
    expect(unauthRes.status).toBe(401);

    const previewPrepRes = await app
      .client()
      .get(`/api/v1/bf-days/${dayForAdmin.id}/anonymization-preview`, {
        token: preparationToken,
      });
    expect(previewPrepRes.status).toBe(403);
    const previewCrewRes = await app
      .client()
      .get(`/api/v1/bf-days/${dayForAdmin.id}/anonymization-preview`, { token: crewToken });
    expect(previewCrewRes.status).toBe(403);
    const previewUnauthRes = await app
      .client()
      .get(`/api/v1/bf-days/${dayForAdmin.id}/anonymization-preview`);
    expect(previewUnauthRes.status).toBe(401);

    const adminRes = await app
      .client()
      .post(`/api/v1/bf-days/${dayForAdmin.id}/anonymize`, {}, { token: adminToken });
    expect(adminRes.status).toBe(200);

    const dayForDispatch = await createBfDay('Perm-Dispatch');
    await startBfDay(dayForDispatch.id);
    await endBfDay(dayForDispatch.id);
    const dispatchRes = await app
      .client()
      .post(`/api/v1/bf-days/${dayForDispatch.id}/anonymize`, {}, { token: dispatchToken });
    expect(dispatchRes.status).toBe(200);
  });

  it('vehicle status PATCH stores bf_day_id while a day is running, null otherwise', async () => {
    const day = await createBfDay('StatusStamp');
    const vehicle = await createVehicle('StatusStamp-V1');

    async function bfDayIdForStatus(status: number): Promise<string | null> {
      const result = await pool.query<{ bf_day_id: string | null }>(
        'select bf_day_id from vehicle_status_event where vehicle_id = $1 and status = $2',
        [vehicle.id, status]
      );
      return result.rows[0]?.bf_day_id ?? null;
    }

    await setVehicleStatus(vehicle.id, 2, dispatchToken);
    expect(await bfDayIdForStatus(2)).toBeNull();

    await startBfDay(day.id);
    await setVehicleStatus(vehicle.id, 3, dispatchToken);
    expect(await bfDayIdForStatus(3)).toBe(day.id);

    await endBfDay(day.id);
    await setVehicleStatus(vehicle.id, 4, dispatchToken);
    expect(await bfDayIdForStatus(4)).toBeNull();
  });

  it('emits bf_day.updated on anonymize', async () => {
    const day = await createBfDay('Realtime-Anon');
    await startBfDay(day.id);
    await endBfDay(day.id);

    const ws = await connectWs(app.baseUrl, adminToken);
    await ws.next(m => m.type === 'hello');
    try {
      const res = await app
        .client()
        .post(`/api/v1/bf-days/${day.id}/anonymize`, {}, { token: dispatchToken });
      expect(res.status).toBe(200);

      const event = await ws.next(m => m.type === 'bf_day.updated');
      const data = event.data as BfDayJson;
      expect(data.id).toBe(day.id);
      expect(data.anonymized_at).not.toBeNull();
    } finally {
      ws.close();
    }
  });
});
