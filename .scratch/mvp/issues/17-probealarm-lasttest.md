# 17 — Probealarm mit echten Geräten und Lasttest

**What to build:** Vor dem BF-Tag läuft ein vollständiger Probealarm mit echten Geräten auf dem Produktivsystem, und das System trägt die erwartete Last.

**Blocked by:** 09, 11, 14, 15, 16

**Status:** ready-for-human

- [ ] Probealarm mit mehreren Android-Herstellern (u. a. Samsung, Xiaomi) und iPhones; App geschlossen, gesperrt, im Nicht-stören-Modus
- [ ] Ergebnis je Gerät dokumentiert (Push angekommen, Ton, Zeit bis Quittierung); Ziel ≥ 95 % innerhalb von 5 s
- [ ] Geplante Alarmierung und Nachalarmierung im Produktivsystem ausgelöst
- [ ] Monitor 24 h Dauerlauf (Wake Lock, Reconnect nach WLAN-Unterbrechung)
- [ ] Lasttest: 30 Geräte bzw. simulierte Clients, 20 Einsätze; Statusänderungen am Monitor < 1 s
- [ ] Gefundene Probleme als neue Tickets angelegt; Einweisung der Betreuer erfolgt

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
