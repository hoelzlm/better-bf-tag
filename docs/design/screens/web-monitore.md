# Monitore (Verwaltung) — Admin-Web

Grundlage: `docs/design/design-system.md`. Quelle: `apps/web/lib/screens/monitors_screen.dart`.

## 1. Zweck

Administrator verwaltet die Fernseher-Monitore auf der Wache: anlegen, umbenennen, Kopplungscode erzeugen
(damit ein Fernseher sich unter `/monitor` koppelt), sperren (beendet die Kopplung, Monitor zeigt nichts mehr).
Seltene Verwaltungsaufgabe, meist beim Aufbau oder wenn ein Fernseher getauscht/zurückgesetzt wird.

## 2. Usability-Probleme heute

Screenshot: `docs/design/screenshots/before/web/monitore-1440x900.png`.

1. Status „nicht gekoppelt“ steht als unauffälliger grauer Subtitle-Text — die wichtigste Information der Seite
   (ist dieser Monitor gerade aktiv?) hat keine visuelle Priorität, sieht wie Nebensache aus.
2. Kopplungscode-Button ist ein reines Schlüssel-Icon ohne sichtbares Label — ohne Hover/Tooltip unklar, was
   es tut; besonders für einen seltenen Admin-Vorgang ungünstig (Wiedererkennungswert fehlt).
3. „Sperren“ ist ein reiner `TextButton` in der Akzentfarbe (Seed-Rot) ohne jede Hervorhebung als destruktive
   Aktion — sieht aus wie ein normaler Link, obwohl die Aktion den Monitor vom Netz nimmt und eine Neukopplung
   erfordert.
4. Keine Gruppierung/Kennzeichnung nach Status (gekoppelt/nicht gekoppelt/gesperrt) — bei vielen Monitoren
   (mehrere Wachabteilungen) ist nicht auf einen Blick erkennbar, welche gerade Probleme haben.
5. „Zuletzt gesehen –“ (Gedankenstrich) als Zeitangabe für nie gekoppelte Monitore ist technisch korrekt aber
   nicht selbsterklärend ohne Kontext.

## 3. Neues Layout

```
┌───────────────────────────────────────────────────────────────────────────┐
│ Monitore                                              [+ Monitor anlegen] │
├───────────────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ ●  Monitor Wache 1                                                    │ │ ● primary = gekoppelt
│ │    gekoppelt · zuletzt gesehen 16.10. 09:12                           │ │
│ │                                [🔑 Kopplungscode erzeugen]  [Sperren] │ │ Sperren = alarm-farben
│ ├─────────────────────────────────────────────────────────────────────┤ │
│ │ ○  Monitor Schulungsraum                                              │ │ ○ outline = nicht gekoppelt
│ │    nicht gekoppelt · noch nie gesehen                                 │ │
│ │                                [🔑 Kopplungscode erzeugen]            │ │ kein Sperren-Button (nicht gekoppelt)
│ └─────────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────────┘
```

Änderungen:

- Status bekommt einen Punkt-Indikator vor dem Namen (`primary` gefüllt = gekoppelt, `outline`-Ring = nicht
  gekoppelt, `onSurfaceVariant` gestrichelt = gesperrt) **plus** weiterhin den Textstatus daneben (Farbe ist nie
  alleiniger Träger, Designsystem 8). Status-Text wird `titleMedium`-Gewicht statt reinem `bodyMedium`.
- Kopplungscode-Aktion bekommt sichtbaren Text „Kopplungscode erzeugen“ neben dem Schlüssel-Icon
  (`FilledButton.tonal`/`OutlinedButton`-artig, `primary`), Tooltip bleibt zusätzlich erhalten.
- „Sperren“ wird zum sekundären `alarm`-farbenen Button (Text, nicht gefüllt — konsistent mit Designsystem 5.1:
  „destruktive Aktionen mit Bestätigungsdialog“ nutzen die Alarm-Farbe, hier als Outline/Text-Variante, da es
  eine Zeilenaktion unter mehreren ist, nicht die Seiten-Primäraktion).
- Zeilen gruppieren implizit durch Sortierung: gekoppelt zuerst, dann nicht gekoppelt, dann gesperrt
  (**Flow-Vereinfachung**, zu begründen: erleichtert das Erkennen „welcher Monitor hat gerade ein Problem“ ohne
  eine neue Filterfunktion einzuführen — reine Sortierreihenfolge, keine Funktion entfernt, alle Monitore
  weiterhin sichtbar).
- „noch nie gesehen“ statt „zuletzt gesehen –“ für Monitore ohne `lastSeenAt` (klarerer Text, gleiche
  Information).

## 4. Alle Zustände

- **Laden:** zentrierter `CircularProgressIndicator`.
- **Leer:** Icon `desktop_windows` 48 px + „Noch keine Monitore angelegt.“ + Primäraktion.
- **Fehler:** „Monitore konnten nicht geladen werden.“ + „Erneut versuchen“.
- **Dialog Anlegen/Umbenennen:** ein Textfeld „Name“, Pflichtfeld-Validierung analog Fahrzeuge (neu, verhindert
  leeren Namen clientseitig).
- **Kopplungscode-Dialog:** großer monospace-Code (bleibt, `48px/Bold`), Ablaufzeit, Anleitungstext, **Warnhinweis**
  „Dieser Code wird nur einmal angezeigt. Ein neuer Code beendet die aktuelle Sitzung …“ wird als
  `warningContainer`-Banner mit Icon dargestellt (nicht reiner Fließtext) — es ist eine Konsequenz-Warnung, kein
  Alarm, passt zur `warning`-Rolle aus Designsystem 2.1/5.10.
- **Destructive Confirmation (Sperren):** „Monitor sperren“ / „Der Monitor zeigt danach nichts mehr an und muss
  neu gekoppelt werden.“ — Titel/Text neutral, nur „Sperren“-Button `alarm`-farben.
- **Gesperrter Monitor:** kein „Sperren“-Button mehr (bereits gesperrt), „Kopplungscode erzeugen“ bleibt
  verfügbar (Re-Pairing ist der vorgesehene Weg zurück — Funktion unverändert).
- **Offline:** kein eigener Zustand (kein Realtime-Abo).
- **Ohne Berechtigung:** Route `/admin/monitors` ist für **Mannschaft, Einsatzvorbereitung und Leitstelle**
  gesperrt (`router.dart`: `isMonitorsRoute && person.permission != Permission.admin` → Redirect nach
  `/admin`); nur **Administrator** erreicht den Screen. Navigation blendet den Menüpunkt für alle anderen drei
  Berechtigungsstufen aus (`web-navigation.md`).

## 5. Interaktionen

- Klick auf eine Zeile (außerhalb der Buttons) öffnet den Umbenennen-Dialog.
- Tab-Reihenfolge: „Monitor anlegen“ → je Zeile: Kopplungscode-Button → Sperren-Button (falls vorhanden).
- Kopplungscode-Dialog: Code ist nicht editierbar, „Schließen“ ist die einzige Aktion; Enter/Escape schließt.

## 6. Testbare Akzeptanzkriterien

1. Liste zeigt alle Monitore mit Name, Status-Label und „zuletzt gesehen“.
2. „Monitor anlegen“ öffnet den Dialog; Speichern ruft `createMonitor(name:)` auf.
3. Klick auf eine Zeile öffnet Umbenennen vorausgefüllt; Speichern ruft `updateMonitor(id, name:)` auf.
4. Kopplungscode-Button ruft `createPairingCode(id)` auf und zeigt den Code-Dialog mit Code + Ablaufdatum.
5. „Sperren“ ist nur sichtbar, wenn `monitor.isRevoked == false`.
6. „Sperren“ öffnet die Bestätigung; erst nach Bestätigen wird `revokeMonitor(id)` aufgerufen.
7. Ladefehler zeigt „Monitore konnten nicht geladen werden.“ statt der Liste.
8. Monitore sind gekoppelt-zuerst, dann nicht-gekoppelt, dann gesperrt sortiert.
9. Leeres Namensfeld im Anlegen-/Umbenennen-Dialog zeigt einen Inline-Fehler statt eines stillen Fehlschlags.

## 7. Zu erhaltende Keys + Semantics

Aus `apps/web/lib/screens/monitors_screen.dart`:

- `create-monitor`
- `monitors-list`
- `monitor-${monitor.id}` je Zeile
- `pairing-code-${monitor.id}`
- `revoke-monitor-${monitor.id}`
- `monitor-form-name`
- `monitor-form-submit`
- `pairing-code-text` (Code-Anzeige im Dialog)
- `confirm-dialog-confirm` (lokale `_confirm`-Hilfsfunktion dieses Screens)

## 8. Flows

Keine Funktion fällt weg. Mapping gegen Regressionsinventar § Monitore: anzeigen, anlegen, bearbeiten (Rename),
löschen (= Sperren), Fehlerzustand — alle erhalten; Sortierung nach Status ist eine reine Darstellungs-
vereinfachung (alle Monitore weiter sichtbar, kein Filter entfernt eine Zeile dauerhaft).
