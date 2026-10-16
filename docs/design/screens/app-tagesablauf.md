# App – Tagesablauf (`screens/program_screen.dart`)

Status: Entwurf (ux-02e) · baut auf `docs/design/design-system.md`

## 1. Zweck

Liste der Programmpunkte des laufenden BF-Tags (Essen, Ausbildung, Fahrzeugpflege, Nachtruhe, Sonstiges),
reine Anzeige, aktuelle(r) Punkt(e) hervorgehoben, vergangene abgeblendet. Primäre Aufgabe: "was ist jetzt
dran, was kommt als Nächstes".

## 2. Usability-Probleme heute

1. `docs/design/screenshots/before/app/tagesablauf-390x844.png`: Listenzeilen nutzen reine Checkbox-Icons
   (`Icons.restaurant` o. ä. werden als generisches Quadrat gerendert, vermutlich Font-Lade-Problem im
   Screenshot-Harness, aber auch als echtes Icon wenig aussagekräftig ohne Farbe/Größe) ohne jede farbliche
   Unterscheidung zwischen „jetzt" und „später" — beide Einträge sehen in der Vorschau identisch aus, obwohl
   der Code bereits `isCurrentProgramItem`/`isPastProgramItem`-Hervorhebung vorsieht.
2. Kein erkennbarer Zeitstrahl/keine Gruppierung nach Tageszeit — bei vielen Programmpunkten (z. B. ganzer
   BF-Tag) schwer, sich zeitlich zu orientieren.

## 3. Neues Layout

Kein eigenes HTML-Mockup Pflicht. ASCII-Wireframe (390×844):

```
┌──────────────────────────────────────────┐
│  Tagesablauf                              │  AppBar
├──────────────────────────────────────────┤
│  ┌──────────────────────────────────────┐ │  AKTUELLER Punkt: primaryContainer-Card,
│  │ 🍽  Mittagessen          [Jetzt]      │ │  radiusLarge, "Jetzt"-Chip primary/onPrimary
│  │    12:00–13:00 · Essen                │ │
│  └──────────────────────────────────────┘ │
│  🎓  Ausbildung Löschtechnik              │  Normale Zeile, outline-Trenner,
│     14:00–16:00 · Ausbildung              │  onSurface
│  🔧  Fahrzeugpflege  (vergangen)          │  Opacity 0.5, onSurfaceVariant
│     08:00–09:00 · Fahrzeugpflege          │
└──────────────────────────────────────────┘
```

360×640: Liste scrollt wie heute, kein Element unterhalb des Falzes ist "primär" (kein fixer Button auf
diesem Screen) — unkritisch.

## 4. Alle Zustände

- **Laden:** aktuell kein eigener Ladezustand im Code (`pairedProgramItemsProvider.valueOrNull ?? []`
  rendert sofort mit leerer Liste) — unverändert, kein neuer Spinner eingeführt (würde eine neue Funktion/
  Zustandsunterscheidung erfordern, die der Code heute nicht trifft).
- **Leer:** Text „Kein Tagesablauf vorhanden." — ergänzt um 48px-Icon (`event_note_outlined`,
  `onSurfaceVariant`) nach Leerzustandsmuster 5.10.
- **Aktueller Punkt** (`isCurrentProgramItem`): `Card` mit `primaryContainer`-Fläche + „Jetzt"-Chip in
  `primary`/`onPrimary` (vorher: Standard-`Chip` ohne Token-Bezug).
- **Vergangener Punkt** (`isPastProgramItem`): 50% Opacity (unverändert aus dem Code übernommen — funktioniert
  gut als "erledigt"-Signal, kein neuer Mechanismus nötig).
- **Normaler (zukünftiger) Punkt:** Standard-Listenzeile, `onSurface`-Text.
- **Hell/Dunkel:** Card-/Chip-Token nach Tabelle 2.1.
- **Offline:** kein eigenes Banner im aktuellen Code; Realtime-Updates laufen automatisch über
  `pairedProgramItemsProvider`.

## 5. Interaktionen

- Reine Leseliste, keine Tap-Handlung auf einzelne Zeilen (unverändert, kein Detail-Screen für
  Programmpunkte vorgesehen).
- Automatische Neu-Hervorhebung alle 30 Sekunden (`programNowProvider`), rein visuell, keine Nutzerinteraktion
  nötig.

## 6. Testbare Akzeptanzkriterien

1. Der/die aktuelle(n) Programmpunkt(e) sind durch `primaryContainer`-Fläche + „Jetzt"-Chip erkennbar.
2. Vergangene Punkte sind bei 50% Opacity, zukünftige bei voller Deckkraft.
3. Der Leerzustand zeigt Text + Icon, kein reiner nackter Text.
4. Jede Listenzeile hat Mindesthöhe 48 dp.
5. Die Hervorhebung aktualisiert sich automatisch, ohne dass die Person etwas tun muss (30s-Takt bleibt).
6. Kontrast der „Jetzt"-Chip-Beschriftung erreicht WCAG AA in hell und dunkel.

## 7. Zu erhaltende Keys + Semantics labels

Aus `screens/program_screen.dart` (keine `Semantics`/`tooltip` im Quellcode):

- `Key('program-list')` — die `ListView`.
- `Key('program-current-${item.id}')` dynamisch — aktuelle(r) Programmpunkt(e).
- `Key('program-past-${item.id}')` dynamisch — vergangene Programmpunkte.
- `Key('program-item-${item.id}')` dynamisch — normale (zukünftige) Programmpunkte.

## 8. Function-Mapping vs. regression-inventory.md

| Alte Funktion | Neuer Ort | Noch vorhanden? |
|---|---|---|
| Tagesablauf: anzeigen — `program_screen_test.dart` | Gleiche Liste/Keys, neue Card-/Chip-Optik für „Jetzt" | Ja |
| Tagesablauf: Leerzustand — „shows empty state when there are no program items" | Gleicher Text, ergänzt um Icon | Ja |

Keine Funktion entfällt.
