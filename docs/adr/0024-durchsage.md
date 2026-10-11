# ADR 0024 – Durchsage: Sichtbarkeit, Echtzeit, Push, Monitor-Banner

- **Status:** Angenommen
- **Datum:** 2026-10-11

## Kontext

Ticket v2-01 (`.scratch/v2/issues/01-durchsage.md`) und `.scratch/v2/spec.md` Abschnitt „Durchsage“
geben Routen, Berechtigungen, Zustandsregel, Events und Push-Art vor. Offen waren: wie die
personenbezogene Sichtbarkeit (Schicht-Besatzung) durch den WebSocket-Filter kommt, der bisher nur die
Berechtigung kennt (ADR 0009), wer genau Push bekommt, was beim Löschen einer Schicht passiert, die
JSON-Form und wie Banner und Vordergrund-Anzeige in den Clients funktionieren.

## Entscheidung

### Datenmodell

Tabelle `announcement`: `id uuid pk`, `bf_day_id → bf_day on delete cascade`, `shift_id null → shift
on delete cascade`, `text varchar(500) not null`, `created_by → person` (restrict), `created_at
timestamptz not null default now()`. Index `(bf_day_id, created_at desc)`.

`on delete cascade` an `shift_id` statt `set null`: eine an eine Schicht gerichtete Durchsage darf nie
nachträglich für alle sichtbar werden. Die Schicht-Löschroute emittiert in derselben `mutate` vor dem
Löschen für jede betroffene Durchsage `announcement.deleted { id }`.

### Sichtbarkeit

Eine Durchsage ist sichtbar für einen **Viewer**, wenn
- `shift_id = null`, oder
- der Viewer ein Monitor ist oder die Berechtigung `preparation`, `dispatch` oder `admin` hat, oder
- der Viewer eine Person mit einem `crew_assignment` in dieser Schicht ist (beliebiges Fahrzeug,
  beliebige Funktion).

Die Besatzung wird beim Lesen (GET, Snapshot) bzw. beim Emittieren (Event, Push) ausgewertet; spätere
Besatzungsänderungen wirken nicht rückwirkend auf bereits zugestellte Events.

### Echtzeit: `Viewer` statt `Permission`

`RealtimeEvent.audience` und `project` bekommen statt `Permission` einen `Viewer`:

```ts
export type Viewer =
  | { kind: 'person'; personId: string; permission: Permission }
  | { kind: 'monitor'; permission: 'crew' };
```

Bestehende Aufrufer werden mechanisch umgestellt (`v => scriptAudience(v.permission)`). Für eine
Schicht-Durchsage berechnet die Route die Menge der Besatzungs-`personId`s in der Transaktion und
übergibt `audience: v => announcementVisibleTo(v, crewIds)`. `announcement.deleted` nutzt dieselbe
Audience wie das zugehörige `created`, damit Unbeteiligte auch beim Löschen nur `skip` sehen.

### API

- `POST /bf-days/{day}/announcements` – `dispatch`, `admin`. Body `{ text: string (trim, 1–500),
  shift_id?: uuid | null }`. BF-Tag nicht `running` → 409 `bf_day_not_running`. `shift_id` gehört nicht
  zu diesem BF-Tag → 400 `validation_error`. Antwort 201 mit Announcement-JSON.
- `GET /bf-days/{day}/announcements` – alle Personen und Monitore, jeder Zustand; nur sichtbare,
  neueste zuerst, ohne Paging.
- `DELETE /announcements/{id}` – `dispatch`, `admin`; BF-Tag nicht `running` → 409
  `bf_day_not_running`; unbekannt → 404. Antwort 204.
- JSON: `{ id, bf_day_id, shift_id: string | null, text, created_by: string /* person id */, created_at }`.
- Snapshot: `announcements` – die letzten 20 sichtbaren des laufenden BF-Tags, neueste zuerst (leer
  ohne laufenden BF-Tag).
- Events: `announcement.created` (Daten = Announcement-JSON), `announcement.deleted { id }`.

### Push

- Neue `PushData`-Variante `{ type: 'announcement.created', announcement_id, bf_day_id, text }`.
- Empfänger: aktive Personen mit **Teilnahme** am BF-Tag, die die Durchsage sehen (Regel oben), mit
  nicht widerrufenem Gerät und Push-Token, **ohne** den Absender selbst.
- FCM: `android.priority normal`, `notification.channel_id announcement`, Titel „Durchsage“, Body = Text,
  `tag announcement-<id>`, `ttl 3600s`, kein `sound alarm`.
- APNs: `apns-push-type alert`, `apns-priority 5`, `alert { title: 'Durchsage', body }`, `sound default`,
  **kein** `interruption-level` (also Standard `active`), kein Alarm-Sound.
- Versand nach dem Commit, fire-and-forget (`void ... .catch(log)`): Fehler blockieren und ändern die
  Antwort nicht. `invalid_token` leert den Token wie bei der Alarmierung. Kein `alarm.push_reported`-
  Gegenstück.

### Clients

- Android-Channel `announcement`, Name „Durchsagen“, `IMPORTANCE_DEFAULT`, Standard-Ton, **kein**
  `setBypassDnd`, angelegt in `MainActivity.kt` neben `alarm`.
- App im Vordergrund: kein lokales Notification-Plugin; ein `announcement.created` aus dem WebSocket
  zeigt eine SnackBar „Durchsage: …“. Tippen auf eine Push-Benachrichtigung öffnet `/durchsagen`.
- App-Bereich „Durchsagen“ (`/durchsagen`, dritter Eintrag der Navigationsleiste) aus
  `snapshot.announcements` + Events.
- Monitor: Ein live empfangenes `announcement.created` (nicht aus dem Snapshot) zeigt 60 s ein Banner
  (`announcementBannerDuration`). Danach zeigt der Standby „Letzte Durchsage“ = neueste in
  `snapshot.announcements`. Läuft ein Einsatz, hat die Einsatzansicht Vorrang; das Banner wird nicht
  nachgeholt. Gelöschte Durchsagen verschwinden sofort aus Banner und Standby.
- Web: Seite „Durchsagen“ (`/durchsagen`) für `dispatch`/`admin`.

### Anonymisierung

`anonymize` löscht alle `announcement`-Zeilen des BF-Tags vor dem Löschen fremder Personen;
Preview/Summary bekommen `announcements: number`.

## Konsequenzen

- Der WebSocket-Filter kann künftig personenbezogen filtern; das betrifft alle bestehenden Audiences
  (mechanische Umstellung, keine Verhaltensänderung).
- Monitore sind nicht mehr als `crew` verkleidet, sondern explizit `kind: 'monitor'`.
- Durchsagen an eine Schicht verschwinden mit der Schicht.
