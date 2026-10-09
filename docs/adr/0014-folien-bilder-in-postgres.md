# ADR 0014 – Folien: Bilder in PostgreSQL, Rohdaten-Upload, Event mit voller Liste

- **Status:** Angenommen
- **Datum:** 2026-10-09

## Kontext

Ticket 12 bringt Folien (Titel, Markdown-Text, optionales Bild, Anzeigedauer) in den Standby des
Monitors. Offen waren: wo Bilder liegen (docs/03-datenmodell.md nannte `image_path`), wie der
Upload aussieht und begrenzt wird, wie der Monitor ein Bild trotz Bearer-Token laden kann, was
`slides.changed` enthält und wer es bekommt.

## Entscheidung

### Speicherung

- Tabelle `slide`: `id` uuid PK, `title` text not null (1–200 Zeichen), `body` text not null
  default `''` (Markdown, max. 5000 Zeichen), `duration_seconds` int not null default 10
  (Check 3–300), `sort_order` int not null, `active` bool not null default true,
  `created_at`, `updated_at`.
- Tabelle `slide_image`: `slide_id` uuid PK, FK auf `slide` mit `ON DELETE CASCADE`,
  `content_type` text not null, `data` bytea not null, `sha256` text not null (hex),
  `size_bytes` int not null, `created_at`. Getrennte Tabelle, damit Listen und Snapshot keine
  Bilddaten laden.
- **Bilder liegen in PostgreSQL**, nicht im Dateisystem: Das nächtliche Datenbank-Backup
  (ADR 0011) enthält sie automatisch, es braucht kein weiteres Volume und keinen zweiten
  Backup-Pfad. Bei einer Handvoll Folien zu je höchstens 5 MB ist das unkritisch.
  `image_path` aus docs/03-datenmodell.md entfällt.

### API (nur Administrator, außer ausdrücklich genannt)

- Folie als JSON: `{ id, title, body, duration_seconds, sort_order, active, image, created_at,
  updated_at }` mit `image = { content_type, size_bytes, version } | null`;
  `version` = die ersten 16 Hex-Zeichen von `sha256`.
- `GET /slides` (alle, nach `sort_order`), `POST /slides { title, body?, duration_seconds?, active? }`
  (201, ans Ende gehängt), `PATCH /slides/{id}` (Teilupdate dieser Felder),
  `DELETE /slides/{id}` (echtes Löschen, 204; Bild wird mitgelöscht),
  `PUT /slides/order { slide_ids }` (vollständige Liste aller Folien-IDs, sonst 400; wie Fahrzeuge
  in ADR 0009).
- `POST /slides/{id}/image`: **Rohdaten** im Body (kein Multipart), `Content-Type` ist
  `image/png`, `image/jpeg` oder `image/webp`. Der Server prüft zusätzlich die Magic Bytes
  (PNG `89 50 4E 47 0D 0A 1A 0A`, JPEG `FF D8 FF`, WebP `RIFF????WEBP`); sie müssen zum
  `Content-Type` passen. Fehler: anderer Typ oder falsche Magic Bytes ⇒ 415
  `unsupported_image_type`; mehr als 5 MB (`SLIDE_IMAGE_MAX_BYTES`, Standard 5 242 880) ⇒ 413
  `image_too_large`; leerer Body ⇒ 400 `validation_error`. Ein neues Bild ersetzt das alte.
  Antwort 200: Folie.
- `DELETE /slides/{id}/image` ⇒ 204 (idempotent).
- `GET /slides/{id}/image` – **Administrator und Monitor** (`allowMonitor`): liefert die Bytes mit
  dem gespeicherten `Content-Type`, `ETag: "<sha256>"`, `Cache-Control: private, max-age=0,
  must-revalidate`; 304 bei passendem `If-None-Match`; 404 ohne Bild.
- Clients laden Bilder **per Dio mit Bearer-Token** und zeigen sie mit `Image.memory`
  (`Image.network` kann im Browser keinen Authorization-Header setzen). Sie cachen die Bytes im
  Speicher pro `(slide_id, version)`.

### Snapshot und Event

- `GET /snapshot` enthält `slides`: nur aktive Folien, nach `sort_order`, für alle Principals
  (Folien sind nicht vertraulich; die Mobile-App ignoriert sie).
- Jede Änderung an Folien (Anlegen, Bearbeiten, Löschen, Sortieren, Bild setzen/löschen) läuft
  über `Realtime.mutate` und emittiert **ein** Event `slides.changed` mit
  `data = { slides: [ … ] }` = die vollständige Liste der aktiven Folien wie im Snapshot. Der
  Client ersetzt seine Liste damit, ohne eigenen Zustand nachzuführen. Empfänger: alle
  (kein `audience`), also ohne `skip`-Sonderfall; Clients ignorieren unbekannte Felder.

### Monitor

- Standby zeigt neben Uhr und Fahrzeugstatus-Leiste einen Folienbereich. Ohne aktive Folien
  bleibt der Standby wie in ADR 0012.
- Rotation: Folie `i` steht `duration_seconds` lang, dann `i+1` (zyklisch); nur eine Folie ⇒
  keine Rotation. Kommt eine neue Liste, bleibt die aktuelle Folie stehen, falls sie noch
  existiert (Index neu bestimmt, Timer läuft weiter), sonst beginnt die Rotation bei Index 0.
- Markdown wird mit `flutter_markdown_plus` gerendert (Fork des eingestellten
  `flutter_markdown`), große Schrift im dunklen Monitor-Theme; Bilder im Markdown werden nicht
  geladen. Das Folienbild steht neben bzw. über dem Text, `BoxFit.contain`.

### Admin-Web

- Neuer Bereich „Folien“: Liste mit Ziehen zum Sortieren, Schalter aktiv/inaktiv, Anlegen und
  Bearbeiten im Dialog (Titel, Markdown-Text mit Vorschau, Anzeigedauer), Bild hochladen
  (Dateiauswahl über `file_picker`, Typ und Größe werden schon im Client geprüft) und entfernen,
  Löschen mit Rückfrage.

## Konsequenzen

- Die Datenbank (und damit das Backup) wächst um die Bilder; das Limit von 5 MB pro Bild hält das
  klein.
- Der Upload lässt sich nicht sinnvoll über den generierten Dart-Client abbilden; das
  Repository in `packages/core` ruft diesen einen Endpunkt direkt über Dio auf.
- Ein Event mit der vollständigen Liste ist größer als ein Delta, erspart aber jede
  Zusammenführungslogik im Client.
