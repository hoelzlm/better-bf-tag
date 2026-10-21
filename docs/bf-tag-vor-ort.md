# BF-Tag vor Ort (Branch `bf-tag-2026-10-23`)

Einmal-Variante für den BF-Tag am 24.10.2026. **Nicht nach `main` mergen.**

## Was anders ist als `main`

- **Keine Handys.** Jugendliche koppeln kein Gerät. Im Admin-Web gibt es keine
  Kopplungscodes und keine Geräteverwaltung mehr.
- **Alarm** kommt über den Hallen-Monitor (Gong + Einsatzansicht). Leitstelle
  und Monitor zeigen „N alarmiert“ und die Namen, keine Quittierung, keinen Push-Zähler.
- **Fahrzeugzuteilung unverändert:** in *Schichten* werden Personen Fahrzeugen
  mit Funktion (GF, MA, …) zugeteilt. Alarmiert wird weiter die Besatzung.
- **Status per Funk:** Die Besatzung meldet ihren Status per Funk, die Leitstelle setzt ihn in der
  Lage (Status-Kachel anklicken → Status wählen).
- **Einsatzberichte:** schreiben die Betreuer nachträglich im Admin-Web.

Backend, API und App sind unverändert: Ist ein Handy gekoppelt, funktioniert
es weiter, wir nutzen es nur nicht.

## Am Laptop starten

Voraussetzung: Docker, Flutter, `just`. Laptop und TV im selben WLAN.

```sh
just event            # baut alles und startet (1. Mal ~5 Min.)
just event status     # Adressen + Admin-Login
just event backup     # Datenbank sichern (vor/nach der Veranstaltung)
just event stop       # beenden; Daten bleiben erhalten
```

Beim ersten Start entsteht `~/.config/bftag-event/.env` mit zufälligem
Admin-Passwort. Dort **Feuerwehrname** und **Koordinaten der Wache** eintragen,
dann noch einmal `just event`.

- Leitstelle: `http://<Laptop-IP>/admin`
- TV: `http://<Laptop-IP>/monitor` → Kopplungscode im Admin-Web unter
  *Monitore* eingeben (das ist der Monitor, kein Handy). Danach Vollbild.

## Gut zu wissen

- Läuft über **HTTP** im lokalen WLAN (kein Zertifikat nötig).
  Deshalb ist `COOKIE_SECURE=false` gesetzt, sonst muss man sich nach jedem Neuladen neu anmelden.
- **Karte und Adresssuche brauchen Internet** (OpenStreetMap). Ohne Internet läuft
  alles andere, nur ohne Karte. In der `.env` dann `GEOCODING_ENABLED=false`.
- Laptop am Netzteil lassen und Standby ausschalten. Der TV-Browser hält sich selbst wach.
