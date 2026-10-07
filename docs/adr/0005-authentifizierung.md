# ADR 0005 – Gerätekopplung per QR-Code statt E-Mail-Login für Mitglieder

- **Status:** Vorgeschlagen
- **Datum:** 2026-10-07

## Kontext

Die meisten Nutzer sind minderjährig. E-Mail-Adressen und Passwörter verwalten ist umständlich
und widerspricht der Datensparsamkeit. Monitore haben keine Tastatur.

## Entscheidung

- **Admin/Leitstelle:** Benutzername + Passwort (Argon2id). 2FA (TOTP) ist optional für später.
- **Mitglieder und Monitore:** Der Admin erzeugt einen **Einmal-Kopplungscode**
  (QR-Code + 8 Zeichen zum Abtippen, 24 h gültig). Die App bzw. der Monitor löst ihn ein und
  erhält ein langlebiges Refresh-Token (Rotation bei jeder Nutzung) und ein kurzlebiges
  Access-Token (JWT, 15 min).
- Geräte lassen sich im Admin einzeln sperren.
- Die QR-Codes können als Liste gedruckt und beim BF-Tag ausgegeben werden.

## Konsequenzen

- Keine personenbezogenen Login-Daten der Jugendlichen.
- Ein Gerät, das verloren geht, ist bis zur Sperrung „eingeloggt“. Das ist bei simulierten
  Einsätzen ein vertretbares Risiko.
- Für das App-Review (Apple/Google) gibt es einen Demo-Code, der auf einen Demo-Nutzer zeigt.
