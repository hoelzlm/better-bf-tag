# 10 – Roadmap

Ziel: **nutzbare Version in 2 Wochen**. Das ist ambitioniert. Deshalb laufen die
Store-Formalitäten ab Tag 1 parallel, und der Umfang wird strikt auf das MVP aus
[01 – Vision und Scope](01-vision-scope.md) begrenzt.

## Woche 0 / Tag 1 – Vorbereitungen mit Wartezeit (sofort starten)

- [ ] Google-Play-Developer-Account anlegen und verifizieren
- [ ] Firebase-Projekt anlegen (nur Cloud Messaging), Android-App registrieren
- [ ] Apple: Bundle-ID, Push-Capability, APNs-Key
- [ ] Domain bzw. Subdomain einrichten, Hetzner-VPS bestellen, Grundhärtung
- [ ] Testerliste sammeln (Google-Konten bzw. E-Mail-Adressen), Family-Link-Frage klären
- [ ] Backend-Sprache final entscheiden ([ADR 0002](adr/0002-backend-sprache.md))
- [ ] Datenschutz mit dem Träger abklären, Elternformular vorbereiten

## Woche 1 – Backend und Admin

| Tag | Aufgabe |
|-----|---------|
| 1 | Backend-Gerüst, Docker Compose lokal, Migrationen, Health-Endpunkt, CI |
| 2 | Auth (Login, Kopplung, Refresh), Personen, Berechtigungen, Geräte, BF-Tag, Teilnahme |
| 3 | Fahrzeuge, Schichten, Besatzung, Fahrzeugstatus, WebSocket + Snapshot |
| 4 | Einsätze (Meldebild/Drehbuch), Alarmierungen sofort + geplant, Nachalarmierung, Empfänger einfrieren, Quittierung |
| 5 | Push-Versand FCM + APNs, OpenAPI → `packages/api_client` generieren |
| 6–7 | Flutter-Monorepo, `packages/core`, Web: Login, Lage, Einsätze, Schichten, Personen, Fahrzeuge |

## Woche 2 – Monitor, App, Release

| Tag | Aufgabe |
|-----|---------|
| 8 | Monitor: Einsatzansicht, Statusleiste, Besatzungen, Standby-Folien, Ton, Wake Lock |
| 9 | App: Kopplung, Push-Setup, Alarm-Screen, Quittierung |
| 10 | App: Einsatzliste, FMS-Tasten, Onboarding (Berechtigungen, Testalarm) |
| 11 | Deployment auf den VPS, Backups, erste Builds in Play Internal Testing und TestFlight |
| 12 | Probealarm mit echten Geräten (Android verschiedener Hersteller, iPhone) |
| 13 | Bugfixes, Lasttest (30 Geräte, 20 Einsätze) |
| 14 | Puffer, Doku, Einweisung der Betreuer |

## Risiken

| Risiko | Gegenmaßnahme |
|--------|---------------|
| Play-Verifizierung dauert länger | Account an Tag 1 anlegen; Notfall: signierte APK per Sideload |
| Kinderkonten (Family Link) können nicht testen | früh mit 1–2 Kindern prüfen; Eltern-Konten oder APK |
| Push kommt bei manchen Android-Herstellern nicht an | Onboarding für die Akku-Optimierung, Testalarm-Funktion, Monitor als Zweitalarm |
| iOS-Gerät stumm geschaltet | Hinweis an die Teilnehmer, Time-Sensitive-Notifications |
| 2 Wochen reichen nicht | Admin anfangs minimal halten (Einsätze, Fahrzeuge); Folien und Personen-UI notfalls per Seed-Skript |
| Netz am Gerätehaus schlecht | WLAN-Abdeckung vorher prüfen, Monitor per LAN anschließen |

## Nach dem MVP

Siehe „Später“ in [01 – Vision und Scope](01-vision-scope.md). Production-Release im Play Store,
sobald der Closed Test 14 Tage mit ≥ 12 Testern gelaufen ist.
