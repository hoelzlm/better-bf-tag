# 14 — App-Onboarding und Testalarm

**What to build:** Nach der Kopplung führt die App durch alle Einstellungen, die für einen zuverlässigen Alarm nötig sind, und lässt die Person einen Testalarm über den echten Push-Weg auslösen.

**Blocked by:** 09

**Status:** ready-for-agent

- [ ] Onboarding-Schritte: Benachrichtigungen erlauben, Nicht stören umgehen (Android-Channel bzw. iOS Time Sensitive), Akku-Optimierung abschalten (mit Hinweis je Hersteller)
- [ ] Testalarm-Button (Onboarding und Einstellungen): Backend schickt einen Push mit Alarmton nur an dieses Gerät, ohne Einsatz
- [ ] Hinweis „Handy beim BF-Tag nicht stumm schalten“ (iOS)
- [ ] Onboarding kann später in den Einstellungen erneut geöffnet werden
- [ ] Tests (Push-Fake): Testalarm erreicht nur das eigene Gerät, erzeugt keinen Einsatz und keine Events für andere

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
