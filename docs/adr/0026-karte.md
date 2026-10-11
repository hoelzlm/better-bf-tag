# ADR 0026 – Karte: Einsatzort, Geocoding-Proxy, Wache, Kartenanzeige

- **Status:** Angenommen
- **Datum:** 2026-10-11

## Kontext

Ticket v2-03 (`.scratch/v2/issues/03-karte.md`) und `.scratch/v2/spec.md` Abschnitt „Karte“ geben vor:
Koordinaten am Einsatz (nullable, nur gemeinsam), Geocoding nur über das Backend (Nominatim, ≤ 1/s,
Cache, Timeout 5 s, Fehler → leere Liste, abschaltbar), Wache aus Config, OSM-Kacheln über
`flutter_map` mit Attribution, kein Routing. Offen waren Spaltentyp, PATCH-Semantik, Antwortform von
`/geocode`, Cache/Rate-Limit-Details, Snapshot-Form der Wache, Ort des Karten-Widgets und die
Navigations-URIs.

## Entscheidung

### Datenmodell

`incident.latitude double precision null`, `incident.longitude double precision null`.
DB-Checks: `(latitude is null) = (longitude is null)`, `latitude between -90 and 90`,
`longitude between -180 and 180`. Die Koordinaten gehören zum Meldebild (kein Personenbezug, bleiben
bei der Anonymisierung unverändert).

### API Einsatz

- JSON (`toIncidentJson`): `latitude: number | null`, `longitude: number | null`, immer vorhanden,
  für jeden, der den Einsatz sieht. Drehbuch-Filter unverändert.
- `POST /bf-days/{day}/incidents`: optional `latitude`, `longitude` (number oder null). Genau eins
  von beiden gesetzt (nicht-null) → 400 `validation_error`. Bereich -90..90 / -180..180, sonst 400.
- `PATCH /incidents/{id}`: dieselben Regeln, gleiche Bearbeitbarkeit wie `address` (draft, running).
  Geprüft wird das **zusammengeführte** Ergebnis: wer nur eine Koordinate schickt, so dass danach
  genau eine null ist → 400. Pin entfernen = beide `null` schicken.

### Geocoding `GET /geocode?q=`

- Berechtigungen `preparation`, `dispatch`, `admin` (sonst 403; Monitore 403).
- `q` wird getrimmt, 3–200 Zeichen, sonst 400 `validation_error`.
- Antwort 200 `{ results: [{ label: string, latitude: number, longitude: number }] }`, max. 5 Einträge.
  Jede Störung (deaktiviert, Timeout, HTTP-Fehler, ungültiges JSON, Rate-Limit-Wartezeit zu lang)
  → `{ results: [] }`, nie 5xx.
- Upstream: `GET {GEOCODING_URL}/search?q=…&format=jsonv2&limit=5&accept-language=de` plus
  `countrycodes={GEOCODING_COUNTRY_CODES}` wenn nicht leer, plus `email={GEOCODING_CONTACT}` wenn
  gesetzt. Header `User-Agent: better-bf-tag/1.0 (+https://github.com/hoelzlm/better-bf-tag; <contact>)`
  (Contact-Teil nur wenn gesetzt). Mapping: `label = display_name`, `latitude = Number(lat)`,
  `longitude = Number(lon)`; Einträge mit nicht-endlichen Zahlen werden verworfen.
- Klasse `Geocoder` in `backend/src/geocoding/geocoder.ts` mit injizierbarem `fetch`, `now()` und
  `sleep()`; eine Instanz pro App (Fastify-Decorator `fastify.geocoder`), damit Rate-Limit und Cache
  global sind.
  - **Rate-Limit global:** Upstream-Anfragen werden serialisiert, zwischen zwei Anfrage-Starts liegen
    ≥ 1000 ms. Müsste eine Anfrage länger als 3000 ms auf ihren Slot warten → sofort `[]`
    (kein Upstream-Aufruf, Slot nicht verbraucht).
  - **Cache:** in-memory, Schlüssel = `q` getrimmt, klein, Mehrfach-Leerzeichen zusammengefasst;
    TTL 24 h, max. 500 Einträge (ältester fliegt). Nur erfolgreiche Upstream-Antworten werden gecacht
    (auch leere Trefferlisten), Fehler nicht. Cache-Treffer verbrauchen keinen Rate-Limit-Slot.
  - **Timeout** 5000 ms per `AbortController`.
- Config: `GEOCODING_ENABLED` (strict boolean, Default `true`), `GEOCODING_URL`
  (Default `https://nominatim.openstreetmap.org`), `GEOCODING_CONTACT` (optional, E-Mail),
  `GEOCODING_COUNTRY_CODES` (Default `de`). Deaktiviert → `[]` ohne Upstream-Aufruf. Tests und E2E
  laufen mit `GEOCODING_ENABLED=false` bzw. mit Fake-`fetch`.

### Wache

Config `STATION_LATITUDE`, `STATION_LONGITUDE` (optional, `z.coerce.number()`, Bereich wie oben;
nur eine gesetzt → Config-Fehler beim Start). Snapshot-Feld `station: { latitude, longitude } | null`
für alle Snapshot-Empfänger (Personen und Monitore). Kein eigener Endpunkt, kein Event (ändert sich nur
per Neustart).

### Clients

- Abhängigkeiten: `flutter_map` (aktuelle Major-Version) und `latlong2` in `packages/core`;
  `url_launcher` in `apps/mobile`. Kein API-Key, keine kostenpflichtigen Dienste.
- Gemeinsames Widget `IncidentMap` in `packages/core/lib/src/map/incident_map.dart`:
  Kacheln `https://tile.openstreetmap.org/{z}/{x}/{y}.png`, `userAgentPackageName: 'de.bftag.app'`,
  `maxZoom 19`, sichtbare Attribution „© OpenStreetMap-Mitwirkende“ (`SimpleAttributionWidget` oder
  `RichAttributionWidget`, auf Monitor ohne Interaktion dauerhaft sichtbar). Einsatz-Pin rot
  (`Icons.location_on`), Wache als eigenes Symbol (`Icons.home` / Feuerwehr-Symbol). Mit Wache:
  Kamera passt beide Punkte ein (Padding, max. Zoom 16); ohne Wache: Einsatz-Pin, Zoom 15.
  Der `TileProvider` ist per Konstruktor injizierbar, damit Widget-Tests ohne Netz laufen.
- **Monitor-Einsatzansicht:** mit Koordinaten Karte neben bzw. unter dem Meldebild, nicht interaktiv;
  ohne Koordinaten unverändert.
- **Web-Einsatzformular:** Adresssuche (Button „Suchen“ → `GET /geocode`, Vorschläge als Liste; Auswahl
  setzt den Pin und zentriert), Klick auf die Karte setzt/versetzt den Pin („Ziehen“ = Pin per Klick
  versetzen; kein Drag-Marker-Paket), Button „Pin entfernen“. Startansicht ohne Pin: Wache (Zoom 13),
  sonst Mitte Deutschland (51.16, 10.45, Zoom 6). Die Adresse im Textfeld wird durch die Suche nicht
  überschrieben (Pin ist nur ein Vorschlag).
- **App (Alarm-Screen, Einsatzdetail):** kleine Karte (Höhe ca. 180) wenn Koordinaten vorhanden, darunter
  Button „Navigation starten“. URI als reine Funktion `navigationUri(lat, lng, platform)`:
  Android `geo:<lat>,<lng>?q=<lat>,<lng>`, iOS `https://maps.apple.com/?daddr=<lat>,<lng>`.
  Start über `url_launcher` (`LaunchMode.externalApplication`). Android-Manifest `<queries>` für
  `geo`-Intents.

## Konsequenzen

- Adressen (Suchtexte) gehen an Nominatim, Kachel-Abrufe der Clients an openstreetmap.org; das wird in
  `docs/09-datenschutz.md` dokumentiert. Die Datenschutzerklärung (GitHub #20) muss das noch aufnehmen.
- Ohne Netz zu Nominatim funktioniert alles weiter, nur die Suche liefert keine Vorschläge.
- Für größere Installationen kann `GEOCODING_URL` auf eine eigene Nominatim-Instanz zeigen.
