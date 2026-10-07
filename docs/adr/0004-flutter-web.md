# ADR 0004 – Admin und Monitor als eine Flutter-Web-App

- **Status:** Vorgeschlagen
- **Datum:** 2026-10-07

## Kontext

Admin und Monitor laufen im Browser. Beide brauchen dieselben Daten und denselben Realtime-Client.

## Entscheidung

Eine Flutter-Web-App `apps/web` mit zwei Bereichen über `go_router`: `/admin/...` und `/monitor`.
Die Rollen aus dem Token steuern, was erreichbar ist.

## Abwägung

- **Pro:** ein Build, ein Deploy, geteilte Widgets (z. B. Fahrzeugstatus-Kachel), eine Sprache.
- **Contra:** Flutter Web hat ein großes Bundle (mehrere MB) und einen langsameren Erststart.
  Bei einem internen Tool und einem Monitor, der einmal lädt und dann 24 h läuft, ist das egal.
  Kein SEO nötig.
- Renderer: Standard-Renderer (CanvasKit bzw. skwasm). Auf älteren Fire-TV-Sticks vorher die
  Performance testen. Notfalls läuft der Monitor auf einem Mini-PC oder Laptop.

## Konsequenzen

- Später kann man den Monitor separat bauen (eigenes `main_monitor.dart`), falls das Bundle stört.
