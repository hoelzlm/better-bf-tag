# 09 – Datenschutz

> Kein Rechtsrat. Vor dem Einsatz mit dem **Träger der Feuerwehr** (meist die Gemeinde bzw. ihr
> Datenschutzbeauftragter) oder dem Vorstand des Fördervereins abstimmen. Wer die
> „verantwortliche Stelle“ ist, hängt davon ab, wer die Software betreibt.

## Grundsätze

1. **Datensparsamkeit:** Nur Anzeigename (z. B. „Max M.“), Rolle und Fahrzeugzuordnung.
   Keine Geburtsdaten, Adressen, Telefonnummern oder E-Mails der Jugendlichen.
2. **Keine E-Mail-Registrierung:** Mitglieder koppeln ihr Gerät per QR-Code (ADR 0005).
3. **EU-Hosting:** Hetzner (Deutschland/Finnland) mit AV-Vertrag.
4. **Zweckbindung:** Die Daten dienen nur der Übung bzw. dem BF-Tag.
5. **Löschkonzept:** Nach dem BF-Tag werden Einsatzprotokolle, Rückmeldungen und Statushistorie
   nach X Wochen gelöscht (Admin-Funktion „Veranstaltung archivieren/bereinigen“). Mitglieder
   werden beim Austritt gelöscht.

## Drittanbieter

| Dienst | Zweck | Welche Daten | Ort |
|--------|-------|--------------|-----|
| Hetzner | Hosting | alle Server-Daten | EU |
| Google Firebase Cloud Messaging | Push Android | Push-Token, Benachrichtigungsinhalt (Stichwort, Adresse) | USA (EU-US Data Privacy Framework) |
| Apple Push Notification service | Push iOS | Push-Token, Benachrichtigungsinhalt | USA (EU-US Data Privacy Framework) |
| Google Play / Apple App Store | Verteilung | Store-Konten der Nutzer | – |

Push-Inhalte enthalten **keine** Namen von Personen. Da die Einsätze simuliert sind, sind die
Adressen fiktiv bzw. Übungsorte.

Keine weiteren SDKs: kein Analytics, kein Crashlytics, keine Werbung. Fehlerprotokolle
bleiben auf dem eigenen Server. Optional später ein selbst gehostetes Sentry/GlitchTip.

## Minderjährige

- **Einwilligung der Erziehungsberechtigten** für die App-Nutzung einholen (Formular zusammen mit
  der BF-Tag-Anmeldung). Bis 16 Jahre ist die Einwilligung der Eltern nötig, wenn sich die
  Verarbeitung auf Einwilligung stützt (Art. 8 DSGVO).
- Die App muss auch ohne eigenes Handy funktionieren: Der Monitor und die Betreuer alarmieren,
  niemand wird benachteiligt.

## Pflichtdokumente

- [ ] Datenschutzerklärung (Web + App-Store-Link), statisch unter `/datenschutz`
- [ ] Impressum, falls die Seite öffentlich erreichbar ist
- [ ] Verzeichnis von Verarbeitungstätigkeiten (kurzer Eintrag beim Träger)
- [ ] Einwilligungsformular für Eltern
- [ ] AV-Vertrag mit Hetzner

## Technische Maßnahmen

- TLS überall (Caddy), HSTS
- Passwörter mit Argon2id, Refresh-Tokens nur als Hash in der Datenbank
- Rollenprüfung serverseitig bei jedem Endpunkt
- Verschlüsselte Backups (restic)
- Rate-Limiting auf `/auth/*`
