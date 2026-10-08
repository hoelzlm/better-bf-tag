# 16 — Store-Pipeline: Play Internal Testing und TestFlight

**What to build:** Die Mobile-App ist für Tester über Google Play (Internal Testing) und TestFlight (externer Link) installierbar, und neue Builds lassen sich wiederholbar hochladen.

**Blocked by:** 04

**Status:** ready-for-human

> Viele Schritte erfordern Konten, Identitätsprüfung und Konsolen-Klicks, deshalb von Hand erledigen.

- [ ] Play-Developer-Account verifiziert, App mit endgültigem Package-Namen angelegt, Play App Signing, Upload-Key sicher abgelegt
- [ ] Play Console: Datenschutz-URL, Datensicherheits-Fragebogen, Zielgruppe (Families-Richtlinien geprüft), Content Rating
- [ ] Internal-Testing-Track mit Testerliste; Opt-in mit mindestens einem Family-Link-Konto ausprobiert (Ergebnis dokumentiert, ggf. Plan B APK)
- [ ] Parallel Closed Test mit ≥ 12 Testern gestartet (für späteres Production-Release)
- [ ] App Store Connect: Bundle-ID, Push- und Time-Sensitive-Capability, APNs-Key, App-Datenschutzangaben
- [ ] TestFlight-Gruppe mit öffentlichem Link; Demo-Kopplungscode für das Beta-Review hinterlegt
- [ ] Build-Nummer wird pro Upload hochgezählt; Upload-Schritte dokumentiert (optional fastlane)

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
