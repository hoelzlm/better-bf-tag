# Durchsagen — Admin-Web

Grundlage: `docs/design/design-system.md`. Quelle: `apps/web/lib/screens/announcements_screen.dart`.

## 1. Zweck

Leitstelle schickt während eines laufenden BF-Tags kurze Durchsagen („Abendessen ist fertig“) an alle Personen
oder eine einzelne Schicht — **ausdrücklich kein Alarm, kein Alarmton** (`CONTEXT.md`). Wird nebenbei zur
Einsatzführung benutzt, Eingabe muss daher schnell und ohne Ablenkung gehen.

## 2. Usability-Probleme heute

Screenshot: `docs/design/screenshots/before/web/durchsagen-1440x900.png`.

1. Textfeld, Zähler, Zielauswahl und Senden-Button schweben lose im Seitenbereich ohne Rahmung — kein visueller
   Unterschied zwischen „Formular“ und „Liste“, beides sieht wie derselbe Textfluss aus.
2. Zeichenzähler „0/500“ sitzt rechtsbündig unter dem Feld, optisch abgekoppelt vom Feld selbst (kein Bezug
   erkennbar, könnte ein eigenständiges Element sein).
3. „Senden“-Button im deaktivierten Zustand ist fast unsichtbar (sehr helles Grau auf fast-weißem Seed-Pink-
   Hintergrund) — nicht erkennbar, dass dort überhaupt ein Button ist, bevor Text eingegeben wird.
4. Zielauswahl „Alle“ ist ein einfaches Dropdown ohne Label/Beschriftung „An“ — beim ersten Blick unklar, wofür
   das Feld steht.
5. Liste zeigt Zeit/Ziel als Metazeile unter dem Text, aber keine visuelle Trennung zwischen Einträgen außer
   Zeilenumbruch — bei vielen Durchsagen schwer scannbar.
6. Kein Hinweis, dass Durchsagen kein Alarm sind — in einer stressigen Leitstellen-Situation kann Verwechslung
   mit einer Alarmierung passieren, wenn optisch nichts sie unterscheidet.

## 3. Neues Layout

```
┌───────────────────────────────────────────────────────────────────────────┐
│ Durchsagen                                                                │
├───────────────────────────────────────────────────────────────────────────┤
│ ┌─ Neue Durchsage ──────────────────────────────────────────────────────┐ │ Karte, surfaceVariant
│ │ 📣  [ Text ...........................................    ] 128/500   │ │ Icon Megafon, primary
│ │     An: [Alle ▾]                                    [ Senden ]        │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                                                                            │
│  Gesendete Durchsagen                                                     │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ Abendessen ist in 10 Minuten fertig.                          🗑      │ │ Zeile ≥48dp
│ │ 08:34 · Alle                                                          │ │
│ ├─────────────────────────────────────────────────────────────────────┤ │
│ │ Nachtruhe ab 22 Uhr.                                           🗑      │ │
│ │ 21:50 · Schicht Nacht                                                 │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────────┘
```

Änderungen:

- Formular bekommt eine eigene Karte (`surfaceVariant`, `radiusLarge`, `xl`-Innenabstand) mit Megafon-Icon
  (`campaign`, `primary`) links — macht sofort klar „das ist eine Durchsage, kein Alarm“ (Designsystem 5.7).
- Zeichenzähler bleibt rechtsbündig, aber **innerhalb** der Karte direkt unter dem Feld (`InputDecoration.
  counterText`-Position bleibt Flutter-Standard, nur optisch jetzt im Kartenrahmen statt freischwebend).
- Zielauswahl bekommt vorangestelltes Label „An:“ (`bodyMedium`, `onSurfaceVariant`) vor dem Dropdown.
- „Senden“ als `FilledButton` mit `primary`-Fläche (nicht `alarm`) — deaktiviert: 38 % Opazität nach
  Designsystem 5.1, immer als Button erkennbar, auch deaktiviert.
- Liste bekommt eine Abschnittsüberschrift „Gesendete Durchsagen“ (`titleMedium`) und `outline`-Trenner
  zwischen Zeilen (Designsystem 5.3).
- Kein-laufender-BF-Tag-Zustand wird zum Standard-Leer-/Hinweisbanner (Icon `info_outline`, `onSurfaceVariant`-
  Fläche) statt fettem Fließtext — konsistent mit Designsystem 5.10, deutlicher sichtbar.

## 4. Alle Zustände

- **Kein laufender BF-Tag:** Banner oberhalb der Karte: Icon `info_outline` + „Kein laufender BF-Tag — Durchsagen
  sind nur während eines laufenden BF-Tags möglich.“ Formularfeld, Zielauswahl und Senden deaktiviert (bestehendes
  Verhalten).
- **Laden (Senden):** Button zeigt `CircularProgressIndicator` (16 px, `onPrimary`) statt Text, Feld bleibt
  bis zur Antwort deaktiviert (`_sending`).
- **Leer (keine Durchsagen):** zentriertes Icon `campaign` 48 px (`onSurfaceVariant`) + „Noch keine Durchsagen.“
- **Fehler (Senden/Löschen fehlgeschlagen):** SnackBar mit der Server-Fehlermeldung (`describeAnnouncementError`),
  Formularinhalt bleibt erhalten (kein Datenverlust bei Fehler).
- **Destructive Confirmation (Löschen):** Dialog „Durchsage löschen“ / „Diese Durchsage wird für alle Empfänger
  entfernt.“ — Titel/Text neutral (`onSurface`), nur der „Löschen“-Button `alarm`-farben (Designsystem 5.6).
- **Zeichenlimit erreicht (500):** Flutter-`maxLength`-Standardverhalten (Zähler färbt sich, weitere Eingabe
  blockiert) bleibt erhalten.
- **Offline:** kein eigener Zustand auf diesem Screen (kein Realtime-Rendering-Unterschied nötig über die
  normale Fehlermeldung hinaus).

## 5. Interaktionen

- Tab-Reihenfolge: Textfeld → Zielauswahl → Senden → Liste (Zeile für Zeile) → je Zeile Löschen-Icon.
- Enter im Textfeld sendet **nicht** automatisch (Mehrzeilenfeld, `maxLines: 4`) — nur der Senden-Button löst
  aus, wie bisher.
- Nach erfolgreichem Senden: Feld leert sich, Fokus bleibt im Textfeld (schnelle Folge-Durchsage ohne erneuten
  Klick), Zielauswahl springt zurück auf „Alle“ (bestehendes Verhalten).
- Löschen-Icon je Zeile öffnet die Bestätigung; „Abbrechen“ schließt ohne Aktion.

## 6. Testbare Akzeptanzkriterien

1. Ohne laufenden BF-Tag ist das Formular deaktiviert und das Hinweisbanner sichtbar.
2. Eingabe eines Texts aktiviert „Senden“ erst, wenn der getrimmte Text nicht leer ist.
3. „Senden“ ruft `create()` mit dem eingegebenen Text und der gewählten Schicht-ID (oder `null` für „Alle“)
   auf.
4. Nach erfolgreichem Senden ist das Textfeld leer und die Zielauswahl zurück auf „Alle“.
5. Ein Fehler beim Senden zeigt die Fehlermeldung in einer SnackBar, der eingegebene Text bleibt im Feld.
6. Liste zeigt alle Durchsagen des Tages, neueste zuerst, mit Zeit und Ziel-Label.
7. Löschen-Icon öffnet die Bestätigung; erst nach Bestätigen wird `delete()` aufgerufen; „Abbrechen“ löst
   nichts aus.
8. Ein neues `announcementsProvider`-Ereignis aktualisiert die Liste ohne manuelles Neuladen.
9. Leere Durchsagenliste zeigt „Noch keine Durchsagen.“ statt einer leeren Fläche.

## 7. Zu erhaltende Keys + Semantics

Aus `apps/web/lib/screens/announcements_screen.dart`:

- `announcements-no-running-day` (Hinweistext/-banner)
- `announcement-text` (Textfeld)
- `announcement-target` (Zielauswahl-Dropdown)
- `announcement-send` (Senden-Button)
- `announcements-list`
- `announcement-${announcement.id}` je Zeile
- `delete-announcement-${announcement.id}` je Löschen-Icon

Aus `apps/web/lib/widgets/confirm_dialog.dart` (gemeinsame Komponente): `confirm-dialog-confirm` (Standard-Key
des Bestätigen-Buttons in `showConfirmDialog`, hier für „Durchsage löschen“ verwendet — derselbe Key wird von
mehreren Screens für ihre jeweils einzige offene Bestätigung genutzt, das ist unkritisch, da nie zwei
Bestätigungsdialoge gleichzeitig offen sind).

## 8. Flows

Keine Funktion fällt weg. Mapping gegen Regressionsinventar § Durchsagen: anzeigen, anlegen, löschen,
Echtzeit-Updates, Fehlerzustand, Leerzustand — alle erhalten, nur neue Kartenrahmung, Icon-Kennzeichnung
(bewusst **kein** Alarm-Rot, siehe Designsystem 5.7) und Button-Sichtbarkeit im deaktivierten Zustand.
