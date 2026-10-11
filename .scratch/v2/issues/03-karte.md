# v2-03 — Karte

**What to build:** Einsätze bekommen einen Ort (Pin). Der Monitor zeigt den laufenden Einsatz auf einer Karte mit der Wache, die App eine kleine Karte auf dem Alarm-Screen mit „Navigation starten“. Details und Entscheidungen: `.scratch/v2/spec.md` Abschnitt „Karte“.

**Blocked by:** v2-02

**Status:** ready-for-agent

- [ ] Migration: `incident.latitude`, `incident.longitude` (nullable, beide oder keiner), in Create/PATCH/JSON, Validierung (-90..90, -180..180)
- [ ] Backend-Geocoding `GET /geocode?q=` (Einsatzvorbereitung, Leitstelle, Admin): Proxy auf Nominatim mit eigenem User-Agent + Kontakt, max. 1 Anfrage/s global, Cache, Timeout 5 s, Fehler → leere Liste (nie 500), abschaltbar per `GEOCODING_ENABLED=false`
- [ ] Wache-Standort per Config `STATION_LATITUDE` / `STATION_LONGITUDE` (optional) in `infra/docker-compose.yml`, `.env.example`, Snapshot (`station`)
- [ ] Web (Einsatz-Formular): Adresse suchen → Vorschläge → Pin setzen; Pin per Klick/Ziehen frei setzbar; Pin entfernen
- [ ] Monitor-Einsatzansicht: Karte (OSM-Kacheln, `flutter_map`) mit Einsatz-Pin + Wache; ohne Koordinaten bleibt die Ansicht wie heute
- [ ] App-Alarm-Screen und Einsatzdetail: kleine Karte + „Navigation starten“ (`geo:`-URI Android, Apple Maps iOS)
- [ ] OSM-Attribution sichtbar, `userAgentPackageName` gesetzt (Tile-Usage-Policy)
- [ ] Doku: `04-api`, `03-datenmodell`, `06-clients`, `07-deployment` (Env), `09-datenschutz` (Adressen gehen an Nominatim, Kacheln von openstreetmap.org); Platzhalter in der Datenschutzerklärung als offenen Punkt für GitHub #20 vermerken
- [ ] Tests: Geocode-Proxy mit Fake (Rate-Limit, Cache, Fehler), Koordinaten-Validierung, Drehbuch-Filter unverändert; Widget-Test Monitor mit/ohne Koordinaten; E2E-Schritt (Einsatz mit Pin, `GEOCODING_ENABLED=false` im E2E)

Spec: `.scratch/v2/spec.md` · Glossar: `CONTEXT.md`
