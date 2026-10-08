# infra

Deployment-Dateien für den Hetzner-VPS (siehe [docs/07-deployment.md](../docs/07-deployment.md)
und [ADR 0011](../docs/adr/0011-deployment-images-backup.md)).

## Dateien

- `docker-compose.yml` — Stack für den Server: `web` (Caddy + Flutter-Web-Build), `backend`,
  `db` (Postgres 17). Images kommen aus GHCR, Tag über `BFTAG_TAG` in `.env`.
- `web.Dockerfile` — Caddy-Image mit eingebautem Flutter-Web-Build und der statischen
  Datenschutzseite. Build-Kontext muss der Repo-Root sein:
  `docker build -f infra/web.Dockerfile .` (nach `flutter build web --release --base-href /`).
- `Caddyfile` — TLS (automatisch via Let's Encrypt), Routing für `/api`, `/ws`, `/datenschutz`
  und den statischen Web-Build.
- `static/` — statische Seiten, die Caddy ausliefert (aktuell `/datenschutz`).
- `.env.example` — Vorlage für `/opt/bftag/.env` (Domain, Secrets, Bootstrap-Admin, ...).
- `restic.env.example` — Vorlage für `/etc/bftag/restic.env` (restic-Repository + Passwort).
- `backup.sh` / `restore.sh` — nächtliches `pg_dump` + restic-Backup auf die Storage Box bzw.
  Wiederherstellung daraus. Laufen auf dem Host via systemd (`systemd/bftag-backup.*`).
- `systemd/` — `bftag-backup.service` + `.timer` für den nächtlichen Backup-Lauf.
- `deploy.sh` — ein-Kommando-Deploy vom Rechner des Betreibers (`just deploy [tag]`):
  kopiert Compose-Datei + Backup-Skripte, setzt das Image-Tag, pullt und startet den Stack,
  wartet auf den Health-Check. Unterstützt `--dry-run`.
- `provision.sh` — idempotente Ersteinrichtung/Härtung eines frischen Ubuntu-24.04-Servers
  (Docker, Benutzer `bftag`, sshd-Härtung, `unattended-upgrades`, `fail2ban`, restic,
  Docker-Log-Rotation, Backup-Timer). Als root ausführen.
- `hcloud-firewall.sh` — legt die Hetzner Cloud Firewall `bftag` an (22/80/443, 443/udp) und
  wendet sie auf den Server an (braucht `hcloud` CLI + `HCLOUD_TOKEN`).
- `smoke-test.sh` — baut die Produktions-Images und prüft den echten Compose-Stack lokal
  (`just infra-smoke`).
- `test/backup-restore.sh` — lokaler Rundlauf-Test für Backup/Restore (`just infra-backup-test`).
