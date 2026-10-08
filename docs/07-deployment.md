# 07 – Deployment (Hetzner-VPS)

## Server

| Punkt | Empfehlung |
|-------|------------|
| Typ | Hetzner Cloud, kleinste Shared-vCPU-Klasse (2 vCPU, 4 GB RAM) reicht |
| Standort | Nürnberg, Falkenstein oder Helsinki (EU) |
| OS | Ubuntu 24.04 LTS oder Debian 12 |
| Backups | Hetzner-Snapshots **und** eigene DB-Dumps (siehe unten) |
| DNS | `bf.<eigene-domain>.de`, alles unter einer Domain |
| Vertrag | AV-Vertrag (DPA) mit Hetzner in der Hetzner Console abschließen |

## URL-Struktur

Eine Domain, damit es nur ein Zertifikat gibt und kein CORS nötig ist:

| Pfad | Ziel |
|------|------|
| `/admin/*`, `/monitor/*` | Flutter-Web-Build (statisch) |
| `/api/*` | Backend |
| `/ws` | Backend (WebSocket) |
| `/` | Weiterleitung auf `/admin` |
| `/datenschutz` | statische Datenschutzerklärung (Pflicht für die Stores) |

## Docker Compose (Entwurf)

```yaml
# infra/docker-compose.yml – Entwurf, noch nicht lauffähig
services:
  caddy:
    image: caddy:2
    ports: ["80:80", "443:443"]
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./web:/srv/web:ro            # Flutter-Web-Build
      - caddy_data:/data
    restart: unless-stopped

  backend:
    image: ghcr.io/<user>/better-bf-tag-backend:latest
    env_file: .env
    depends_on: [db]
    restart: unless-stopped

  db:
    image: postgres:17
    environment:
      POSTGRES_DB: bftag
      POSTGRES_USER: bftag
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    volumes: [db_data:/var/lib/postgresql/data]
    secrets: [db_password]
    restart: unless-stopped

volumes: { caddy_data: {}, db_data: {} }
secrets:
  db_password: { file: ./secrets/db_password }
```

```
# infra/Caddyfile – Entwurf
bf.example.de {
    encode zstd gzip
    handle /api/* { reverse_proxy backend:3000 }
    handle /ws    { reverse_proxy backend:3000 }
    handle {
        root * /srv/web
        try_files {path} /index.html
        file_server
    }
}
```

## Secrets (`.env`, nie committen)

| Variable | Inhalt |
|----------|--------|
| `DATABASE_URL` | Postgres-Verbindung |
| `JWT_SECRET` | ≥ 32 Byte zufällig |
| `FCM_SERVICE_ACCOUNT_JSON` | Pfad zur Service-Account-Datei |
| `APNS_KEY_P8`, `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_BUNDLE_ID`, `APNS_PRODUCTION` | APNs |
| `ADMIN_BOOTSTRAP_USER`, `ADMIN_BOOTSTRAP_PASSWORD` | erster Admin; nach dem ersten Start entfernen |

## Härtung

- SSH nur mit Key, `PasswordAuthentication no`, Root-Login aus
- Hetzner Cloud Firewall: eingehend nur 22 (am besten nur von der eigenen IP), 80, 443
- `unattended-upgrades` für Sicherheitsupdates
- Postgres nicht nach außen veröffentlichen (kein `ports:` am `db`-Service)
- `fail2ban` für SSH
- Container als Non-Root-User laufen lassen

## Backups

Jede Nacht um 03:15 Uhr (systemd-Timer `bftag-backup.timer`, mit zufälliger Verzögerung
bis zu 10 Minuten) läuft `/opt/bftag/backup.sh` als root auf dem Host (nicht im Container):
Ein `pg_dump -Fc` der Datenbank wird per Pipe direkt an `restic backup --stdin` auf eine
Hetzner Storage Box geschickt (`sftp:`-Repository). Alte Stände werden danach mit
`restic forget --keep-daily 7 --keep-weekly 4 --prune` aufgeräumt: 7 tägliche und
4 wöchentliche Stände bleiben erhalten.

### Einrichtung

1. Eine Hetzner Storage Box anlegen (Typ reicht klein, z. B. BX11) und SSH-Keys dafür
   aktivieren (Storage-Box-Konsole → "SSH-Unterstützung aktivieren", eigenen Public Key
   hinterlegen). Die Box ist unter `uXXXXXX.your-storagebox.de`, Port `23` erreichbar.
2. Auf dem Server (als root, via `infra/provision.sh` bereits installiert): restic ist
   vorhanden, `/opt/bftag/backup.sh` und `/opt/bftag/restore.sh` liegen bereit (Kopie aus
   `infra/backup.sh` / `infra/restore.sh`), die systemd-Units
   `infra/systemd/bftag-backup.{service,timer}` sind nach `/etc/systemd/system/` kopiert.
3. `/etc/bftag/restic.env` (Modus 600) aus `infra/restic.env.example` anlegen: Repository-URL
   der eigenen Storage Box eintragen (`RESTIC_REPOSITORY=sftp:uXXXXXX@uXXXXXX.your-storagebox.de:23/bftag`),
   ein zufälliges restic-Passwort erzeugen (`openssl rand -base64 32`) und in
   `/etc/bftag/restic-password` (Modus 600) ablegen, `RESTIC_PASSWORD_FILE` darauf zeigen lassen.
4. Repository einmalig initialisieren: `/opt/bftag/backup.sh --init` (legt das restic-Repository
   an, falls `restic snapshots` fehlschlägt, und macht direkt das erste Backup).

### Timer aktivieren

```
systemctl daemon-reload
systemctl enable --now bftag-backup.timer
systemctl list-timers bftag-backup.timer   # nächste Ausführung prüfen
```

### Manuelles Backup

```
systemctl start bftag-backup.service       # läuft synchron, Ausgabe über journald
journalctl -u bftag-backup.service -n 50
```

Oder direkt: `/opt/bftag/backup.sh` (Umgebungsvariablen aus `/etc/bftag/restic.env` müssen
dafür manuell geladen werden, z. B. `set -a; source /etc/bftag/restic.env; set +a`).

### Wiederherstellung

1. Verfügbare Stände ansehen: `set -a; source /etc/bftag/restic.env; set +a; restic snapshots --tag db`.
2. Backend kurz anhalten lassen (macht `restore.sh` automatisch) und den gewünschten Stand
   einspielen:
   ```
   set -a; source /etc/bftag/restic.env; set +a
   /opt/bftag/restore.sh latest --yes       # oder eine konkrete Snapshot-ID statt "latest"
   ```
   `restore.sh` verlangt die Flag `--yes`, weil die aktuelle Datenbank dabei überschrieben
   wird (`pg_restore --clean --if-exists`). Ohne `--yes` bricht das Skript sofort ab.
3. Nach dem Lauf prüfen, ob das Backend wieder erreichbar ist
   (`curl https://$BFTAG_DOMAIN/api/v1/health`) und stichprobenartig Daten in der Oberfläche
   kontrollieren.

### Aufbewahrung

7 tägliche und 4 wöchentliche Stände (`restic forget --keep-daily 7 --keep-weekly 4 --prune`,
läuft nach jedem Backup automatisch).

### Wiederherstellungstest

| Datum | Umgebung | Ergebnis |
|-------|----------|----------|
| 2026-10-08 | lokal, `infra/test/backup-restore.sh` | PASS – Backup (restic/restic-Docker-Image, lokales Repository), Restore und Tabelleninhalt nach Restore identisch zum Original; zweiter Backup-Lauf (forget/prune) ebenfalls erfolgreich. |
| | VPS – vom Betreiber vor dem BF-Tag auszufüllen | |

## Deploy-Ablauf

1. GitHub Actions baut das Backend-Image und pusht es nach GHCR.
2. GitHub Actions baut `flutter build web` und legt das Ergebnis als Artefakt ab.
3. Auf dem Server: `docker compose pull && docker compose up -d`, Web-Build nach `infra/web/`
   kopieren (per Skript oder rsync).
4. Die Datenbank-Migrationen laufen beim Start des Backends.

Für den Anfang reicht ein Shell-Skript `infra/deploy.sh` (rsync + ssh). Watchtower oder
Ähnliches ist unnötig.

## Monitoring

- Uptime-Check von außen (z. B. Uptime Kuma auf einem anderen Rechner oder ein kostenloser
  Dienst) auf `/api/v1/health`
- Logs: `docker compose logs`, Rotation über die Docker-Log-Optionen (`max-size`)
- Am BF-Tag selbst: Admin-Seite „Systemstatus“ mit verbundenen Clients und letzten Push-Fehlern
