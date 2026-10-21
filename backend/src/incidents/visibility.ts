import type { AuthContext } from '../access/authenticate.js';
import type { Viewer } from '../realtime/realtime.js';

type IncidentState = 'draft' | 'running' | 'closed' | 'discarded';

/**
 * Berechtigungen mit Drehbuch-Zugriff (ADR 0016): `preparation`, `dispatch`,
 * `admin`. Mannschaft und Monitore nie.
 */
export const scriptAudience = (v: Viewer): boolean =>
  v.permission === 'preparation' || v.permission === 'dispatch' || v.permission === 'admin';

/**
 * Audience for the Abschlussvorschlag (ADR 0019 "Abschlussvorschlag"):
 * `dispatch`, `admin` only — Einsatzvorbereitung and Mannschaft never see
 * it, Monitore never either.
 */
export const closeSuggestedAudience = (v: Viewer): boolean =>
  v.permission === 'dispatch' || v.permission === 'radio' || v.permission === 'admin';

/**
 * Whether the given Principal may see an Einsatz's Drehbuch (ADR 0016).
 * Monitors count as Mannschaft and never see it.
 */
export function canSeeScript(principal: AuthContext): boolean {
  if (principal.kind === 'monitor') return false;
  return scriptAudience({
    kind: 'person',
    personId: principal.personId,
    permission: principal.permission,
  });
}

/**
 * Whether the given Principal may see an Einsatz in the given state (ADR
 * 0016). Whoever may see the Drehbuch sees every state; everyone else
 * (Mannschaft, Monitore) only sees `running`/`closed` — `draft` and
 * `discarded` don't exist for them.
 */
export function canSeeIncident(principal: AuthContext, state: IncidentState): boolean {
  if (canSeeScript(principal)) return true;
  return state === 'running' || state === 'closed';
}
