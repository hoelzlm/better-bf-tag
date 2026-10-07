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

- Nächtlich `pg_dump` per Cronjob, mit **restic** verschlüsselt auf eine Hetzner Storage Box.
- Aufbewahrung: 7 tägliche, 4 wöchentliche Stände.
- Wiederherstellung **einmal vor dem BF-Tag testen**.

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
