# App – Durchsagen (`screens/announcements_screen.dart`, `announcements/announcement_snackbar_listener.dart`)

Status: Entwurf (ux-02e) · baut auf `docs/design/design-system.md`

## 1. Zweck

Persistente Liste aller Durchsagen der Leitstelle (letzte 20, neueste zuerst) auf `/durchsagen`, ergänzt um
eine transiente SnackBar-Benachrichtigung (`AnnouncementSnackbarListener`), die app-weit erscheint, sobald
eine neue Durchsage eintrifft, auch wenn die Person gerade auf einem anderen Tab ist. Durchsagen sind
**ausdrücklich kein Alarm** (CONTEXT.md) — kein Alarmton, keine Alarm-Optik.

## 2. Usability-Probleme heute

1. `docs/design/screenshots/before/app/durchsagen-390x844.png`: Durchsage-Text und Zeitstempel sind reiner,
   gleich gewichteter Fließtext ohne Icon/Label — auf den ersten Blick nicht von einer normalen Listenzeile
   (z. B. Einsatz) zu unterscheiden, obwohl Durchsagen einen eigenen, wiedererkennbaren Charakter brauchen
   (Designsystem 5.7: eigenes Icon „campaign", eigene Fläche).
2. Keine visuelle Verbindung zwischen der transienten SnackBar (`AnnouncementSnackbarListener`, erscheint
   überall in der App) und dieser Liste — eine Person, die die SnackBar sieht und auf „Anzeigen" tippt, landet
   auf einer Liste, die optisch nichts mit der SnackBar gemeinsam hat.

## 3. Neues Layout

Kein eigenes HTML-Mockup Pflicht. ASCII-Wireframe (390×844):

```
┌──────────────────────────────────────────┐
│  Durchsagen                               │  AppBar
├──────────────────────────────────────────┤
│ ┌────────────────────────────────────────┐│  Card je Durchsage: primaryContainer-
│ │ 📢  Abendessen ist in 10 Minuten fertig.││  Fläche (NICHT alarm, NICHT neutral-grau),
│ │     18:00                               ││  radiusLarge, Icon „campaign" primary
│ └────────────────────────────────────────┘│
├──────────────────────────────────────────┤
│  🚒 Fahrzeug  📢 Einsätze  💬 Durchsagen.. │  Navigationsleiste
└──────────────────────────────────────────┘

Transiente SnackBar (von überall in der App, gleiches Icon/Farbschema):
┌────────────────────────────────────────┐
│ 📢 Durchsage: Abendessen in 10 Min.  [Anzeigen] │
└────────────────────────────────────────┘
```

360×640: Liste scrollt wie heute, unkritisch (kein primärer fixer Button).

## 4. Alle Zustände

- **Leer:** Text „Keine Durchsagen" — ergänzt um 48px-Icon (`campaign_outlined`, `onSurfaceVariant`) nach
  Leerzustandsmuster 5.10.
- **Gefüllt:** jede Durchsage als eigene Card (`primaryContainer`-Fläche, Icon „campaign" in `primary`,
  Text max. 3 Zeilen mit „mehr"-Erweiterung bei längeren Texten laut Designsystem 5.7 — heutiger Code zeigt
  den vollen Text ohne Begrenzung; da Durchsagen laut Backend kurz sind, ist eine Kürzung optisch vorbereitet,
  aber nicht zwingend aktiv, wenn der Text ohnehin selten 3 Zeilen überschreitet — keine neue Pflichtfunktion,
  nur vorbereitetes CSS/Widget-Verhalten für sehr lange Ausnahmefälle).
- **Realtime-Update** (neue Durchsage trifft ein, während die Liste offen ist): neue Zeile erscheint oben
  (`pairedAnnouncementsProvider`, bereits sortiert) — kein manuelles Neuladen nötig, unverändert.
- **Transiente SnackBar** (`AnnouncementSnackbarListener`, app-weit, auch auf anderen Tabs sichtbar): Text
  „Durchsage: <Text>" + Aktion „Anzeigen" → navigiert zu `/durchsagen`; Fläche/Icon konsistent zur Listen-Card
  (`primaryContainer`, Icon „campaign"), KEINE `alarm`-Farbe, Auto-Dismiss nach 8s (Designsystem 5.7).
- **Hell/Dunkel:** Card-/SnackBar-Token nach Tabelle 2.1.
- **Offline:** kein eigenes Banner im aktuellen Code; neue Durchsagen kommen automatisch nach, sobald die
  Realtime-Verbindung wiederhergestellt ist.

## 5. Interaktionen

- Reine Leseliste (kein Tap auf einzelne Durchsagen vorgesehen, unverändert).
- SnackBar-Aktion „Anzeigen" navigiert zur Liste.
- SnackBar verschwindet automatisch nach 8s oder bei manuellem Wegwischen (Standard-SnackBar-Verhalten).

## 6. Testbare Akzeptanzkriterien

1. Jede Durchsage-Card nutzt `primaryContainer`-Fläche + „campaign"-Icon, niemals `alarm`-Farbe oder reines
   Grau.
2. Die transiente SnackBar nutzt dasselbe Icon/Farbschema wie die Listen-Cards (visuelle Konsistenz).
3. Der Leerzustand zeigt Text + Icon.
4. Eine neu eintreffende Durchsage erscheint automatisch oben in der Liste, ohne manuelles Neuladen.
5. Die SnackBar-Aktion „Anzeigen" navigiert zu `/durchsagen`.
6. Kontrast Text-auf-`primaryContainer` erreicht WCAG AA in hell und dunkel.

## 7. Zu erhaltende Keys + Semantics labels

Aus `screens/announcements_screen.dart` (keine `Semantics`/`tooltip` im Quellcode):

- `Key('announcements-list')` — die `ListView`.
- `Key('announcement-${announcement.id}')` dynamisch — jede Listenzeile.

(`announcement_snackbar_listener.dart` hat keinen eigenen Key — die SnackBar wird über
`messengerKey.currentState` gezeigt, kein Widget-Key nötig/vorhanden, bleibt unverändert.)

## 8. Function-Mapping vs. regression-inventory.md

| Alte Funktion | Neuer Ort | Noch vorhanden? |
|---|---|---|
| Durchsagen: anzeigen — `announcements_screen_test.dart` | Gleiche Liste/Keys, neue Card-Optik | Ja |
| Durchsagen: Echtzeit-Updates/Leerzustand — „shows 'Keine Durchsagen' when the list is empty" | Gleicher Text, ergänzt um Icon; Realtime unverändert über `pairedAnnouncementsProvider` | Ja |

Keine Funktion entfällt.
