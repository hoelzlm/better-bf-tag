# ADR 0009 – Echtzeit-Schicht: WebSocket, `seq`, Snapshot, Fahrzeuge

- **Status:** Angenommen
- **Datum:** 2026-10-08

## Kontext

Ticket 02 führt die Echtzeit-Schicht ein (docs/02-architektur.md, docs/04-api.md). Offen waren:
wie `seq` entsteht und einen Neustart übersteht, wie Snapshot und `seq` konsistent bleiben, wie
nach Berechtigung gefilterte Events mit der Lückenerkennung zusammenpassen, wie der Heartbeat im
Browser funktioniert, und einige Details der Fahrzeug-API.

## Entscheidung

### `seq` und Veröffentlichung

- Das Backend läuft als **eine** Instanz (ADR 0002, Hetzner-VPS). Es gibt keinen externen Broker.
- `seq` ist **global** (eine Folge für alle Clients) und liegt persistent in der Tabelle
  `realtime_state` (genau eine Zeile, `seq bigint`). Ein Neustart setzt `seq` nicht zurück.
- Jede Änderung, die ein Event erzeugt, läuft durch `Realtime.mutate(fn)`:
  1. ein In-Process-Mutex (serialisiert alle Event-erzeugenden Schreibvorgänge),
  2. eine DB-Transaktion, in der `fn(tx, emit)` die Daten schreibt und für jedes Event
     `UPDATE realtime_state SET seq = seq + 1 RETURNING seq` ausführt,
  3. nach dem Commit werden die Events in `seq`-Reihenfolge an alle Verbindungen gesendet,
  4. erst dann wird der Mutex freigegeben. Rollback ⇒ kein Event.
- Der Snapshot liest Daten und `seq` in **einer** Transaktion mit `REPEATABLE READ`. Weil `seq`
  in derselben Transaktion wie die Daten erhöht wird, passt der Snapshot immer genau zu seiner `seq`.

### WebSocket `/ws`

- Pfad `/ws` (nicht unter `/api/v1`), Plugin `@fastify/websocket`.
- Authentifizierung: `?token=<Access-Token>` (JWT aus ADR 0008). Ungültig/fehlend ⇒ die
  Verbindung wird mit Close-Code **4401** geschlossen. Das Token wird nur beim Verbindungsaufbau
  geprüft; ein später ablaufendes Access-Token beendet die Verbindung nicht
  (Sperrung kommt mit `session.revoked`, Ticket 03/04).
- Server → Client, alle Nachrichten JSON:
  - `{ "type": "hello", "seq": <aktuelle seq> }` sofort nach erfolgreicher Authentifizierung.
  - `{ "type": "heartbeat", "seq": <aktuelle seq> }` alle `WS_HEARTBEAT_MS` (Standard 25000).
    Ohne eigene `seq`-Erhöhung; der Client erkennt daran Lücken auch bei Ruhe.
  - Events: `{ "seq": N, "type": "<event>", "at": "<ISO-8601 aus Clock>", "data": { … } }`.
  - Für Events, die eine Verbindung laut Berechtigung nicht sehen darf, bekommt sie stattdessen
    `{ "seq": N, "type": "skip" }`. So bleibt `seq` pro Verbindung lückenlos, ohne Inhalte zu
    verraten. (Im Ticket 02 gehen alle Events an alle.)
- Zusätzlich sendet der Server WebSocket-Protokoll-Pings im gleichen Takt und beendet Verbindungen
  ohne Pong (Aufräumen toter Sockets). Browser sehen diese Pings nicht, deshalb der
  anwendungsseitige `heartbeat`.
- Client → Server: nichts erforderlich; unbekannte Nachrichten werden ignoriert.

### Client-Protokoll (`RealtimeClient` in `packages/core`)

1. Verbinden mit `ws(s)://<api-host>/ws?token=…` (Schema aus der API-Basis-URL abgeleitet).
2. Eingehende Events puffern, bis der Snapshot (`GET /api/v1/snapshot`) geladen ist; Events mit
   `seq <= snapshot.seq` verwerfen, den Rest anwenden.
3. Danach muss jedes Event `seq == letzte + 1` haben; `hello`/`heartbeat` müssen
   `seq == letzte` haben. Sonst: Snapshot neu laden (Lücke).
4. Keine Nachricht für 2 × Heartbeat-Intervall oder Socket geschlossen ⇒ Reconnect mit
   exponentiellem Backoff (1 s, 2 s, 4 s … max. 30 s, mit Jitter), danach wieder ab Schritt 1.
   Bei Close-Code 4401 vorher das Access-Token erneuern (Session-Refresh).

### Fahrzeuge

- `vehicle` gehört immer zur eigenen Feuerwehr (`fire_department.is_own`); die API nimmt keine
  `fire_department_id` entgegen.
- Kein Löschen: `active=false` deaktiviert. Inaktive Fahrzeuge erscheinen nicht im Snapshot,
  aber in `GET /vehicles` (Administrator).
- Sortierung: `PUT /vehicles/order` mit der vollständigen Liste der Fahrzeug-IDs; Neue Fahrzeuge
  werden ans Ende gehängt.
- Anfangsstatus eines neuen Fahrzeugs: 2 (Einsatzbereit auf Wache), `status_changed_at = null`.
- Statushistorie: `vehicle_status_event` mit `source` (`app`, `dispatch`, `system`); im Web setzt
  die Leitstelle mit `source = dispatch`. Auch ein Setzen auf den gleichen Status wird
  protokolliert und erzeugt ein Event. Lesbar über `GET /vehicles/{id}/status-history`.
- Ein Event `vehicle.updated` (Daten: vollständiges Fahrzeug) entsteht bei Anlegen, Bearbeiten,
  (De-)Aktivieren und für jedes Fahrzeug, dessen Position sich beim Sortieren ändert.

## Konsequenzen

- Mehrere Backend-Instanzen wären nur mit einem Broker (z. B. PostgreSQL `LISTEN/NOTIFY`) möglich;
  das ist bewusst nicht vorgesehen.
- Der Mutex macht Event-erzeugende Schreibvorgänge seriell. Bei rund 50 Personen ist das
  unkritisch.
- Die Event-Typen werden in `packages/core` von Hand gepflegt (docs/04-api.md).
