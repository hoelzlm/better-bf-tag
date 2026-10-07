# 08 – Store-Veröffentlichung

## Google Play

### Die wichtigste Einschränkung

**Private** Developer-Accounts, die nach dem 13.11.2023 angelegt wurden, dürfen erst in
**Production** veröffentlichen, wenn ein **Closed Test mit mindestens 12 Testern über
14 Tage am Stück** gelaufen ist. Fällt die Zahl der Tester unter 12, startet die Frist neu.
Erst danach kann man in der Play Console den Production-Zugang beantragen (Prüfung dauert zusätzlich).
Organisations-Accounts sind davon ausgenommen.
Quelle: [Play Console Hilfe – Testanforderungen](https://support.google.com/googleplay/android-developer/answer/14151465)

**Folge: Ein öffentliches Production-Release ist mit einem neuen privaten Account in 2 Wochen
nicht zu schaffen.**

### Empfehlung: Internal Testing reicht für die eigene JF

| Track | Max. Tester | Review | Verfügbar | Passt? |
|-------|-------------|--------|-----------|--------|
| **Internal testing** | 100 | keins bzw. nur kurz | sofort nach Upload | **Ja, für den BF-Tag** |
| Closed testing | unbegrenzt (Listen/Gruppen) | ja | nach Review | als Zwischenschritt zu Production |
| Production | alle | ja | erst nach 12×14-Regel | Nein, nicht in 2 Wochen |

- Die Tester werden per E-Mail-Adresse (Google-Konto) in eine Liste eingetragen und öffnen einmal
  den Opt-in-Link. Danach installieren sie die App ganz normal aus dem Play Store, Updates kommen
  automatisch.
- Parallel kann direkt ein **Closed Test** mit ≥ 12 Leuten (Betreuer, Eltern, JF-Mitglieder)
  starten. Nach 14 Tagen ist dann auch Production möglich.
- **Achtung Minderjährige:** Kinder unter 13 (bzw. dem Landesalter) haben oft nur ein von den
  Eltern verwaltetes Google-Konto (Family Link). Testtracks und Opt-in können damit Probleme
  machen. Vorab mit 1–2 Kindern ausprobieren. Plan B: Jugendliche bekommen die App über die
  Eltern-Konten oder es gibt zusätzlich eine signierte APK (Sideload).

### Alternative: Organisations-Account

Ein Organisations-Account entfällt die 12×14-Regel, braucht aber eine **D-U-N-S-Nummer**
(kostenlos, Vergabe dauert oft 1–4 Wochen) und eine juristische Person, z. B. den Förderverein
der Feuerwehr. Für die 2 Wochen wohl zu langsam, langfristig aber sauberer.

### Checkliste Play Console (Tag 1 starten)

- [ ] Developer-Account anlegen (einmalig 25 USD) und Identitätsprüfung abschließen; das kann
      einige Tage dauern
- [ ] App anlegen, Package-Name festlegen (z. B. `de.<domain>.bftag`). Der lässt sich später
      nicht mehr ändern
- [ ] Play App Signing aktivieren, Upload-Key erzeugen und sicher sichern
- [ ] Datenschutzerklärung-URL (`https://<domain>/datenschutz`)
- [ ] Fragebogen Datensicherheit (Data safety): Name, Gerätekennung/Push-Token, keine Weitergabe
- [ ] Zielgruppe und Inhalte: Bei Zielgruppe unter 13 gelten die **Families-Richtlinien**
      (strengere Regeln, z. B. für SDKs). Die tatsächliche Altersgruppe angeben und Folgen prüfen
- [ ] Content Rating (IARC-Fragebogen)
- [ ] Erste AAB per `flutter build appbundle` in den Internal-Track hochladen; ein leeres Gerüst
      reicht, um die Pipeline früh zu testen
- [ ] Testerliste anlegen, Opt-in-Link verteilen

## Apple App Store

Der Developer Account ist vorhanden.

| Weg | Vorteil | Nachteil |
|-----|---------|----------|
| **TestFlight (extern)** | bis zu 10.000 Tester per öffentlichem Link, schnell | erste Build-Version braucht eine Beta-Review (meist < 1 Tag), Builds laufen nach 90 Tagen ab |
| TestFlight (intern) | ohne Review | nur Mitglieder des App-Store-Connect-Teams (max. 100) |
| App Store, öffentlich | normal installierbar | volles App-Review, die App ist für alle sichtbar |
| App Store, **Unlisted** | nur per Link auffindbar, normale Installation | gesonderter Antrag bei Apple, volles Review |

**Empfehlung:** Für den ersten BF-Tag TestFlight mit externem Link. Danach eine Unlisted-App
beantragen.

### Review-Risiken

- Apple lehnt Apps ab, die nur aus einem Login bestehen und von Reviewern nicht getestet werden
  können. Deshalb einen **Demo-Kopplungscode** für das Review bereitstellen
  (App Review Information → Notes).
- Den Hinweis „nur für Übungszwecke, kein echter Notruf/Einsatz“ in Beschreibung und App
  aufnehmen.

### Checkliste App Store Connect

- [ ] App-ID / Bundle-ID anlegen (gleich wie Android, z. B. `de.<domain>.bftag`)
- [ ] Capabilities: Push Notifications, Time Sensitive Notifications
- [ ] APNs-Auth-Key (`.p8`) erzeugen; er gilt für alle Apps des Teams
- [ ] App in App Store Connect anlegen, Datenschutz-Angaben („Privacy Nutrition Label“)
- [ ] Erste Build per `flutter build ipa` bzw. Xcode/Transporter hochladen
- [ ] TestFlight-Gruppe „JF“ mit öffentlichem Link

## Versionierung

`pubspec.yaml` `version: 1.2.3+45`. Die Build-Nummer (`+45`) wird bei jedem Upload in **beiden**
Stores erhöht. Optional fastlane (`supply` für Play, `pilot` für TestFlight) in GitHub Actions.
