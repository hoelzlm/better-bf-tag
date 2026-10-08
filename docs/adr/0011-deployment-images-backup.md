# ADR 0011 – Deployment: zwei Images, Deploy per Tag, Backup auf dem Host

- **Status:** Angenommen
- **Datum:** 2026-10-08

## Kontext

Ticket 15 bringt das System auf den Hetzner-VPS. `docs/07-deployment.md` enthält Entwürfe, lässt
aber offen, wie der Web-Build auf den Server kommt, wo Domain und Secrets stehen, wie Caddy ohne
Root läuft, wo das Backup läuft und wer den Uptime-Check macht.

## Entscheidung

### Images (GHCR)

- `ghcr.io/hoelzlm/better-bf-tag-backend` aus `backend/Dockerfile`, läuft als `USER node`.
- `ghcr.io/hoelzlm/better-bf-tag-web`: **Caddy mit eingebautem Flutter-Web-Build**
  (`infra/web.Dockerfile`, Basis `caddy:2-alpine`). Das Image enthält `Caddyfile`, den Web-Build
  unter `/srv/web` und die statische Datenschutzerklärung unter `/srv/static`. Es läuft als
  Nicht-Root-Benutzer (UID 1000); `/data` und `/config` gehören im Image diesem Benutzer, damit
  benannte Volumes die Rechte übernehmen. Ports 80/443 binden ohne Root, weil Docker
  `net.ipv4.ip_unprivileged_port_start=0` setzt.
  Damit ist der Deploy ein reines `docker compose pull && up -d` – kein rsync von Web-Dateien
  (Abweichung vom Entwurf in `docs/07-deployment.md`).
- Tags: `sha-<7 Zeichen>` und `latest` bei jedem Push auf `main`. Pull-Requests bauen nur
  (kein Push). Der Web-Build nutzt `--base-href /` und `API_BASE_URL` leer (gleiche Origin).

### Server-Layout

- Verzeichnis `/opt/bftag` mit `docker-compose.yml` (aus `infra/docker-compose.yml`) und `.env`
  (Modus 600, nie im Repo; Vorlage `infra/.env.example`). Domain (`BFTAG_DOMAIN`), ACME-E-Mail,
  DB-Passwort, `JWT_SECRET`, Bootstrap-Admin und `BFTAG_TAG` stehen in der `.env`.
- `db` (postgres:17) hat kein `ports:`. Alle Dienste nutzen den `json-file`-Logtreiber mit
  `max-size: 10m`, `max-file: 5`.
- Das Backend bekommt `TRUST_PROXY` (Standard `false`, in Produktion `true`), damit das
  Rate-Limiting die echte Client-IP aus `X-Forwarded-For` von Caddy sieht.

### Deploy

- `infra/deploy.sh [tag]` läuft auf dem Rechner des Betreibers: kopiert `docker-compose.yml`
  per `scp` nach `$BFTAG_SSH:/opt/bftag`, setzt `BFTAG_TAG`, führt `docker compose pull` und
  `up -d --remove-orphans` aus und wartet, bis `https://$BFTAG_DOMAIN/api/v1/health` 200 liefert.
- Migrationen laufen beim Start des Backends (ADR 0008).

### Backup

- Läuft auf dem **Host** per systemd-Timer (`bftag-backup.timer`, täglich 03:15), nicht als
  Container: `docker compose exec -T db pg_dump -Fc` → `restic backup --stdin` auf die Storage Box
  (`sftp:`-Repository), danach `restic forget --keep-daily 7 --keep-weekly 4 --prune`.
  Zugangsdaten in `/etc/bftag/restic.env` (Modus 600).
- `infra/restore.sh` holt einen Stand (`restic dump`) und spielt ihn mit
  `pg_restore --clean --if-exists` ein. Ein automatisierter lokaler Test
  (`infra/test/backup-restore.sh`, restic als Docker-Image, lokales Repository) beweist den
  Rundlauf; der Test auf dem echten VPS wird in `docs/07-deployment.md` protokolliert.

### Härtung und Betrieb

- `infra/provision.sh`: idempotentes Einrichtungsskript für ein frisches Ubuntu 24.04 (als root):
  Docker aus dem offiziellen Repository, Benutzer `bftag` (Gruppe `docker`), sshd-Drop-in
  (nur Key, kein Root-Login), `unattended-upgrades`, `fail2ban` (sshd), restic, `/opt/bftag`,
  systemd-Units für das Backup, Docker-`daemon.json` mit Log-Rotation.
- Hetzner Cloud Firewall (22/80/443) per `infra/hcloud-firewall.sh` (hcloud CLI) – braucht ein
  API-Token des Betreibers.
- Uptime-Check: GitHub-Actions-Workflow `uptime.yml` alle 10 Minuten gegen
  `${{ vars.BFTAG_URL }}/api/v1/health`; ein Fehlschlag löst die GitHub-Benachrichtigung aus. Ohne
  gesetzte Variable endet der Workflow erfolgreich mit Hinweis.
- `/datenschutz` ist eine statische HTML-Seite aus `infra/static/datenschutz/index.html` mit
  Platzhaltern für die verantwortliche Stelle (Inhalt nach `docs/09-datenschutz.md`).

## Konsequenzen

- Der Server braucht Lesezugriff auf GHCR: Pakete öffentlich stellen oder `docker login ghcr.io`
  mit einem Token (`read:packages`).
- Wer den Web-Build ändert, deployt ein neues Web-Image; Caddy-Konfiguration und Web-Build sind
  immer konsistent versioniert.
- Echte Domain, VPS, Storage Box, Firewall-Token und der Restore-Test auf dem VPS bleiben
  Aufgaben des Betreibers.
