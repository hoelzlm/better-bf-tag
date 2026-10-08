# 15 — Deployment auf den Hetzner-VPS

**What to build:** Das System läuft unter der eigenen Domain mit TLS auf dem Hetzner-VPS. Jeder Stand lässt sich mit einem Befehl deployen, die Datenbank wird nächtlich verschlüsselt gesichert, und die Wiederherstellung ist einmal erprobt.

**Blocked by:** 01

**Status:** done

- [x] Docker Compose mit Caddy (automatisches TLS, statische Web-Builds, Proxy für `/api` und `/ws`), Backend, PostgreSQL ohne öffentlichen Port
- [x] Secrets über `.env` bzw. Docker Secrets; nichts davon im Repo
- [x] Härtung: SSH nur mit Key, Hetzner-Firewall (22/80/443), unattended-upgrades, fail2ban, Container ohne Root
- [x] CI baut das Backend-Image und den Web-Build; Deploy-Skript zieht und startet neu
- [x] Nächtliches `pg_dump` + restic auf eine Storage Box (7 tägliche, 4 wöchentliche Stände); Wiederherstellung einmal getestet und dokumentiert
- [x] Uptime-Check auf den Health-Endpunkt; Log-Rotation
- [x] Statische Datenschutzerklärung unter `/datenschutz`

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
