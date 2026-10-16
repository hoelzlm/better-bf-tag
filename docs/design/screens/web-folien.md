# Folien — Admin-Web

Grundlage: `docs/design/design-system.md`. Quelle: `apps/web/lib/screens/slides_screen.dart`.
Mockup: `docs/design/mockups/web-folien.html`/`.png`.

## 1. Zweck

Administrator pflegt die Standby-Folien des Monitors (Begrüßung, Sicherheitshinweise, Sponsoren, …):
Reihenfolge, Anzeigedauer, Markdown-Text, optionales Bild, aktiv/inaktiv. Vorbereitungsaufgabe, meist vor dem
BF-Tag erledigt, gelegentlich währenddessen angepasst (z. B. eine Folie kurzfristig deaktivieren).

## 2. Usability-Probleme heute

Screenshot: `docs/design/screenshots/before/web/folien-1440x900.png`.

1. Folien ohne Bild zeigen ein durchgestrichenes Bild-Icon (`image_not_supported_outlined`) — wirkt wie ein
   **Fehler** („Bild konnte nicht geladen werden“), ist aber nur der Normalzustand „keine Bild-Folie“.
2. Anzeigedauer („10 s“) steht als einzige Zeile unter dem Titel in kleiner grauer Schrift — leicht zu
   übersehen, obwohl sie für die Monitor-Rotation die wichtigste Zusatzinformation ist.
3. Kein Hinweis auf den Markdown-Inhalt in der Liste — zwei Folien mit demselben Titel, aber unterschiedlichem
   Text, sind in der Übersicht nicht unterscheidbar ohne jede einzeln zu öffnen.
4. Aktiv-Schalter und Lösch-Icon hängen ohne Abstand rechts von Drag-Handle — wie bei Fahrzeuge zu eng, hohe
   Fehlklick-Gefahr, besonders riskant hier, da Löschen (anders als bei Fahrzeugen) ein **endgültiger** Vorgang
   ist („wird endgültig gelöscht“), kein Soft-Delete.
5. Reihenfolge der Folien bestimmt die Monitor-Rotation, aber nichts auf der Seite sagt das — ohne Kontext
   könnte man die Drag-Funktion für rein kosmetisch halten.

## 3. Neues Layout

```
┌───────────────────────────────────────────────────────────────────────────┐
│ Folien                       Reihenfolge bestimmt die Monitor-Rotation     [+ Folie anlegen] │
├───────────────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ ≡ [🖼]  Willkommen zum BF-Tag                        10 s   [●] 🗑    │ │ Dauer als Chip, primaryContainer
│ │         „Willkommen zu unserem diesjährigen …“                        │ │ Textvorschau, bodyMedium
│ ├─────────────────────────────────────────────────────────────────────┤ │
│ │ ≡ [▢]   Sicherheitshinweise (inaktiv)                  8 s   [○] 🗑    │ │ ▢ = Platzhalter-Icon, kein Fehler-Look
│ │         „Bitte Schutzkleidung beachten …“                             │ │ Zeile gedimmt (inaktiv)
│ └─────────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────────┘
```

Gerenderte Fassung: `web-folien.html`/`.png` (eine Folie mit Bild, eine ohne Bild, eine inaktiv).

Änderungen:

- Platzhalter für Folien ohne Bild wechselt von `image_not_supported_outlined` (Fehler-Konnotation) zu
  `image_outlined` in einer neutralen `surfaceContainer`-Kachel (56×56, `radiusMedium`) — klar als „kein Bild
  hinterlegt“ statt „Bild-Fehler“ lesbar; ein echter Bildladefehler bleibt separat (siehe Zustände).
- Anzeigedauer wird ein kleiner `labelMedium`-Chip (`primaryContainer`-Fläche) rechts in der Zeile statt
  Fließtext darunter — sofort als Kennzahl erkennbar, konsistent mit FMS-Badge-Stil (Designsystem 5.5, hier
  ohne Status-Bedeutung, nur als Metrik-Chip).
- Erste Zeile des Markdown-Texts (Klartext, Formatierung entfernt) als zweite Zeile unter dem Titel
  (`bodyMedium`, `onSurfaceVariant`, einzeiliger Abschnitt mit Ellipsis) — löst Unterscheidbarkeit (Problem 3)
  ohne neuen Dialog.
- Topbar-Hinweistext „Reihenfolge bestimmt die Monitor-Rotation“ (`bodyMedium`, `onSurfaceVariant`) macht die
  Drag-Funktion erklärbar, ohne eine neue UI einzuführen.
- Aktiv-Schalter + Lösch-Icon bekommen 8 px Abstand (`BftagSpacing.sm`); inaktive Zeilen zusätzlich bei 60 %
  Deckkraft + „(inaktiv)“-Suffix im Titel (gleiche Behandlung wie Fahrzeuge, Konsistenz).
- „Folie anlegen“ als Topbar-`FilledButton.icon` statt FAB (gleiche Begründung wie bei Fahrzeuge).

## 4. Alle Zustände

- **Laden:** zentrierter `CircularProgressIndicator`.
- **Leer:** Icon `image` 48 px + „Noch keine Folien angelegt.“ + Primäraktion.
- **Fehler (Laden):** „Folien konnten nicht geladen werden.“ + „Erneut versuchen“.
- **Fehler (Anlegen/Bearbeiten/Löschen/Reihenfolge):** SnackBar mit `describeApiError`-Text.
- **Bild lädt (Thumbnail):** leere Fläche während `FutureBuilder` lädt (bestehendes Verhalten, `SizedBox.
  shrink()`) — akzeptiert, da Thumbnails klein und schnell sind; kein Spinner nötig für 56×56 px.
- **Bild-Ladefehler:** fällt auf den „kein Bild“-Platzhalter zurück (bestehendes `FutureBuilder`-Verhalten bei
  Fehler) — optisch nicht von „kein Bild hinterlegt“ unterscheidbar, das ist für eine Thumbnail-Liste
  akzeptabel (der Bearbeiten-Dialog zeigt den echten Fehler über `slide-form-image-error`).
- **Dialog Anlegen/Bearbeiten:** Titel (Pflicht, ≤ 200 Zeichen), Text (Markdown, ≤ 5000 Zeichen, Vorschau-
  Umschalter), Anzeigedauer (3–300 s), aktiv-Schalter, Bild-Upload/-Entfernen (nur im Bearbeiten-Modus, Bild
  erst nach dem ersten Speichern möglich — bestehende Einschränkung `widget.initial?.id`).
- **Validierungsfehler:** je Feld `errorText` in `warning`-Farbe — leerer/zu langer Titel, zu langer Text,
  Dauer außerhalb 3–300 s (bestehende `_validate()`-Logik, nur Farbmapping auf `warning`-Token).
- **Bild-Upload-Fehler:** zu groß (> 5 MB), falscher Typ (nicht PNG/JPEG/WebP), Server-Fehler — Text unter dem
  Upload-Button (`slide-form-image-error`, `warning`-Farbe).
- **Destructive Confirmation (Löschen):** „Folie löschen“ / „„{Titel}“ wird endgültig gelöscht.“ — Titel/Text
  neutral, nur „Löschen“-Button `alarm`-farben (hier besonders wichtig hervorzuheben, da **kein** Soft-Delete
  wie bei Fahrzeugen, siehe Problem 4).
- **Offline:** kein eigener Zustand (kein Realtime-Abo).
- **Ohne Berechtigung:** Route `/admin/slides` ist für **Mannschaft, Einsatzvorbereitung und Leitstelle**
  gesperrt (`router.dart`: `isSlidesRoute && person.permission != Permission.admin` → Redirect nach `/admin`);
  nur **Administrator** erreicht den Screen. Navigation blendet den Menüpunkt für alle anderen drei
  Berechtigungsstufen aus (`web-navigation.md`).

## 5. Interaktionen

- Tab-Reihenfolge: „Folie anlegen“ → Liste (je Zeile: Drag-Handle → Aktiv-Schalter → Löschen).
- Klick auf eine Zeile (außerhalb Schalter/Löschen/Drag) öffnet den Bearbeiten-Dialog.
- Drag per Maus sortiert; Tastatur-Alternative wie bei Fahrzeuge (`Shift+↑/↓`, ux-03).
- Im Dialog: „Vorschau“-Umschalter wechselt zwischen Markdown-Eingabe und gerenderter Vorschau (bestehend,
  `slide-form-preview-toggle`), Bild-Upload öffnet den nativen Dateidialog (`FilePicker`).

## 6. Testbare Akzeptanzkriterien

1. Liste zeigt alle Folien inkl. inaktiver, mit Titel, Textvorschau, Dauer-Chip, Thumbnail/Platzhalter.
2. „Folie anlegen“ öffnet den Anlegen-Dialog; gültige Eingabe ruft `create()` auf.
3. Leerer Titel, Titel > 200 Zeichen, Text > 5000 Zeichen oder Dauer außerhalb 3–300 zeigen den jeweiligen
   Inline-Fehler und verhindern das Absenden.
4. Klick auf eine Zeile öffnet Bearbeiten vorausgefüllt; Speichern ruft `update()` auf.
5. Aktiv-Schalter ruft `update(active:)` auf, Zeile wird sofort optisch gedimmt/entdimmt.
6. Bild-Upload (im Bearbeiten-Dialog) mit gültiger Datei ruft `uploadImage()` auf und zeigt das neue Bild.
7. Bild-Upload > 5 MB oder falscher Typ zeigt den jeweiligen Fehlertext, ohne `uploadImage()` aufzurufen.
8. „Bild entfernen“ ruft `deleteImage()` auf und zeigt wieder den Platzhalter.
9. Lösch-Icon öffnet die Bestätigung; erst nach Bestätigen wird `delete()` aufgerufen.
10. Ziehen einer Zeile ruft `reorder()` mit der neuen Reihenfolge der Folien-IDs auf.
11. Ladefehler zeigt „Folien konnten nicht geladen werden.“ statt der Liste.
12. Leere Folienliste zeigt den Leerzustand mit Primäraktion.

## 7. Zu erhaltende Keys + Semantics

Aus `apps/web/lib/screens/slides_screen.dart`:

- `create-slide`, `slides-list`, `ValueKey(slide.id)` je Zeile
- `active-switch-${slide.id}`, `delete-slide-${slide.id}`
- `slide-thumbnail` (Thumbnail-`Image.memory`, innerhalb jeder `_SlideThumbnail`-Instanz)
- `slide-form-title`, `slide-form-preview-toggle`, `slide-form-preview`, `slide-form-body`,
  `slide-form-duration`, `slide-form-active`, `slide-form-upload-image`, `slide-form-remove-image`,
  `slide-form-image-error`, `slide-form-submit`
- `confirm-dialog-confirm` (lokale `_confirm`-Hilfsfunktion dieses Screens)

## 8. Flows

Keine Funktion fällt weg. Mapping gegen Regressionsinventar § Folien: anzeigen, anlegen, bearbeiten, löschen,
Fehlerzustand — alle erhalten; Platzhalter-Icon ohne Fehler-Konnotation, Dauer-Chip und Textvorschau sind reine
Darstellungsergänzungen auf bereits vorhandenen Daten (kein neues Feld, keine neue API).
