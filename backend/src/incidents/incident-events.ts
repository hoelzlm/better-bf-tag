import type { Viewer } from '../realtime/realtime.js';
import { scriptAudience } from './visibility.js';
import { toIncidentJson, type IncidentRow } from './incident-json.js';

/**
 * The `incident.updated` (and `incident.created`) audience/projection (ADR
 * 0016): Einsatzvorbereitung/Leitstelle/Admin always see it (with Drehbuch);
 * everyone else only once the Einsatz reaches `running`/`closed` (without
 * Drehbuch). Shared between `routes/incidents.ts` and `routes/alarms.ts` so
 * the two never drift (ADR 0017).
 */
export function incidentUpdatedEventOpts(incidentRow: IncidentRow): {
  audience: (v: Viewer) => boolean;
  project: (v: Viewer) => unknown;
} {
  return {
    audience: v =>
      scriptAudience(v) || incidentRow.state === 'running' || incidentRow.state === 'closed',
    project: v => toIncidentJson(incidentRow, { includeScript: scriptAudience(v) }),
  };
}
