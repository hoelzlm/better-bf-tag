# 01 – Vision und Scope

## Ziel

Beim BF-Tag erlebt die Jugendfeuerwehr 24 Stunden lang einen „Berufsfeuerwehr-Alltag“ mit
simulierten Einsätzen. Die Software soll das realistisch abbilden:

- Die Betreuer (Leitstelle) bereiten Einsätze vor und lösen sie manuell oder zeitgesteuert aus.
- Die Jugendlichen werden über ihr Handy alarmiert, sehen den Einsatz und geben eine Rückmeldung.
- Ein Monitor in der Fahrzeughalle bzw. im Aufenthaltsraum zeigt den laufenden Einsatz groß an.
- Fahrzeuge melden ihren Status (FMS 1–8) wie im echten Funkverkehr.

## Vorbild

[bf-tag.de](https://bf-tag.de) bietet das als kostenlosen Dienst an (Web-Dashboard, Alarmmonitor,
iOS-App, Android nur als APK-Download). Wir wollen:

1. eine Android-App über den Play Store,
2. volle Kontrolle über Daten und Hosting,
3. einen kleineren, auf unsere JF zugeschnittenen Funktionsumfang.

## MVP (Version 1)

| # | Funktion | Admin (Web) | Monitor (Web) | App |
|---|----------|:-----------:|:-------------:|:---:|
| 1 | Mitglieder und Rollen verwalten | ✓ | | |
| 2 | Geräte per QR-Code koppeln | ✓ | ✓ | ✓ |
| 3 | Fahrzeuge verwalten (Funkrufname, Typ, Sortierung) | ✓ | | |
| 4 | Fahrzeugstatus FMS setzen und anzeigen | ✓ | ✓ (nur Anzeige) | ✓ |
| 5 | Einsätze anlegen (Stichwort, Adresse, Text, Fahrzeuge) | ✓ | | |
| 6 | Einsatz sofort alarmieren | ✓ | | |
| 7 | Einsatz zeitgesteuert alarmieren | ✓ | | |
| 8 | Push-Alarm mit Alarmton | | | ✓ |
| 9 | Rückmeldung „komme“ / „komme nicht“ | | ✓ (Anzeige) | ✓ |
| 10 | Einsatz abschließen | ✓ | | |
| 11 | Monitor: aktiver Einsatz, Fahrzeugstatus, Uhr | | ✓ | |
| 12 | Monitor: Standby-Folien (Text/Bild) | ✓ (pflegen) | ✓ | |
| 13 | Einsatzliste (laufend + vergangen) | ✓ | | ✓ |

## Später (nach MVP)

- Dienstplan / Wachabteilungen
- Ausbildungsplanung
- Einsatzberichte (Formular nach dem Einsatz)
- Karte mit Einsatzort und Route
- Gong und Sprachausgabe (TTS) am Monitor
- Einsatzvorlagen und Szenario-Import (CSV)
- Statistik nach dem BF-Tag

## Nicht-Ziele

- Echter Einsatzbetrieb, Anbindung an echte Leitstellen, FMS/TETRA-Schnittstellen
- Mehrere Organisationen (Multi-Tenant)
- Öffentliche Registrierung
- Offline-Betrieb ohne Netz (Grundvoraussetzung ist WLAN oder Mobilfunk am Gerätehaus)

## Erfolgskriterien

- Alarm erreicht ≥ 95 % der gekoppelten Geräte innerhalb von 5 Sekunden.
- Monitor zeigt Statusänderungen in < 1 Sekunde.
- Ein Betreuer kann einen Einsatz in < 1 Minute anlegen und auslösen.
- System läuft 24 h stabil auf einem kleinen VPS.
