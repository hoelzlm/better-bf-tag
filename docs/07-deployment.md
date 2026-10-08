# 07 – Deployment (Hetzner-VPS)

## Server

| Punkt | Empfehlung |
|-------|------------|
| Typ | Hetzner Cloud, kleinste Shared-vCPU-Klasse (2 vCPU, 4 GB RAM) reicht |
| Standort | Nürnberg, Falkenstein oder Helsinki (EU) |
| OS | Ubuntu 24.04 LTS |
| Backups | Hetzner-Snapshots **und** eigene DB-Dumps (siehe unten) |
| DNS | `bf.<eigene-domain>.de`, alles unter einer Domain |
| Vertrag | AV-Vertrag (DPA) mit Hetzner in der Hetzner Console abschließen |

## URL-Struktur

Eine Domain, damit es nur ein Zertifikat gibt und kein CORS nötig ist:

| Pfad | Ziel |
|------|------|
| `/admin/*`, `/monitor/*` | Flutter-Web-Build (statisch, im `web`-Image) |
| `/api/*` | Backend |
| `/ws` | Backend (WebSocket) |
| `/` | Weiterleitung auf `/admin` |
| `/datenschutz` | statische Datenschutzerklärung (Pflicht für die Stores) |

## Images (GHCR)

Siehe [ADR 0011](adr/0011-deployment-images-backup.md) für die volle Begründung. Kurzfassung:

- `ghcr.io/hoelzlm/better-bf-tag-backend` — aus `backend/Dockerfile`, läuft als `USER node`.
- `ghcr.io/hoelzlm/better-bf-tag-web` — Caddy (`infra/web.Dockerfile`) mit eingebautem
  Flutter-Web-Build, der statischen Datenschutzseite (`infra/static/`) und dem `Caddyfile`.
  Läuft als Nicht-Root (UID 1000), bindet 80/443 ohne Root-Rechte.
- Beide Images werden von `.github/workflows/release.yml` ("Release images") bei jedem Push auf
  `main` gebaut und mit `sha-<7 Zeichen>` und `latest` nach GHCR gepusht. Pull-Requests bauen nur
  (kein Push), damit der Workflow auch ohne Schreibrechte grün bleibt.
- Der Deploy ist dadurch ein reines `docker compose pull && up -d` auf dem Server — kein
  manuelles Kopieren von Web-Dateien nötig.

## Ersteinrichtung

1. **VPS bestellen**: Hetzner Cloud Server (siehe Tabelle oben), öffentliche IPv4+IPv6. AV-Vertrag
   (DPA) mit Hetzner in der Cloud Console abschließen, falls noch nicht vorhanden.
2. **DNS**: A- und AAAA-Record der eigenen Domain (z. B. `bf.example.de`) auf die Server-IPs
   setzen.
3. **Firewall**: lokal `hcloud` installieren und einloggen, dann
   ```
   HCLOUD_TOKEN=... HCLOUD_SERVER=<server-name-oder-id> ./infra/hcloud-firewall.sh
   ```
   Legt (falls nicht vorhanden) die Hetzner Cloud Firewall `bftag` an (22/80/443, 443/udp) und
   wendet sie auf den Server an. `SSH_SOURCE` optional einschränken (Standard: offen von überall).
4. **Provisionierung**: Repo (oder zumindest `infra/`) auf den Server kopieren, dann als root:
   ```
   ./infra/provision.sh
   ```
   Installiert Docker, legt den Benutzer `bftag` an (Gruppe `docker`, SSH-Key von root
   übernommen), härtet sshd (nur Key, kein Root-Login), aktiviert `unattended-upgrades` und
   `fail2ban` (sshd-Jail), installiert restic, konfiguriert die Docker-Log-Rotation, legt
   `/opt/bftag` und `/etc/bftag` an und installiert/aktiviert den Backup-Timer. Danach nur noch
   als `bftag` einloggen (Key aus `/root/.ssh/authorized_keys`), root-Login ist deaktiviert.
5. **`.env` anlegen**: `infra/.env.example` nach `/opt/bftag/.env` kopieren (Modus 600), Werte
   ausfüllen (`BFTAG_DOMAIN`, `ACME_EMAIL`, `POSTGRES_PASSWORD`, `JWT_SECRET`,
   Bootstrap-Admin, ...). `BFTAG_TAG` setzt `deploy.sh` automatisch.
6. **GHCR-Zugriff**: der Server muss die Images pullen können. Entweder die GHCR-Pakete
   öffentlich stellen (Paket-Einstellungen auf GitHub) oder auf dem Server
   `docker login ghcr.io` mit einem Personal Access Token (Scope `read:packages`) ausführen.
7. **restic/Backup einrichten**: siehe Abschnitt [Backups](#backups) unten
   (`/etc/bftag/restic.env`, `backup.sh --init`, Timer aktivieren).
8. **Erster Deploy**: vom eigenen Rechner aus (siehe [Deploy](#deploy) unten).

## Deploy

Vom Rechner des Betreibers (SSH-Zugriff auf den Server als `bftag` vorausgesetzt):

```
BFTAG_SSH=bftag@bf.example.de BFTAG_DOMAIN=bf.example.de just deploy
```

Das ruft `infra/deploy.sh` auf: kopiert `docker-compose.yml`, `backup.sh` und `restore.sh` per
`scp` nach `$BFTAG_DIR` (Standard `/opt/bftag`), setzt `BFTAG_TAG` in der `.env` auf
`sha-$(git rev-parse --short=7 origin/main)` (oder ein explizit angegebenes Tag), führt
`docker compose pull && up -d --remove-orphans --wait` aus, räumt alte Images auf
(`docker image prune -f`) und wartet bis zu 120 s auf `https://$BFTAG_DOMAIN/api/v1/health`.

Ein bestimmtes Tag deployen: `just deploy sha-abc1234` oder `just deploy latest`.
`./infra/deploy.sh --dry-run [tag]` zeigt die geplanten Kommandos an, ohne sie auszuführen.

## Rollback

Ein älteres, bekanntes gutes Image-Tag erneut deployen:

```
just deploy sha-<älterer-commit-kurz-sha>
```

Verfügbare Tags stehen in den GHCR-Paketen (GitHub → Repo → Packages) bzw. in der
Commit-Historie von `main`. Die Datenbank-Migrationen laufen beim Start des Backends (ADR 0008)
und sind additiv/abwärtskompatibel gehalten; ein Rollback des Images allein reicht in der Regel.

## Monitoring

- `.github/workflows/uptime.yml` läuft alle 10 Minuten (und per `workflow_dispatch`) und prüft
  `${{ vars.BFTAG_URL }}/api/v1/health`. Ohne gesetzte Repo-Variable `BFTAG_URL` endet der Lauf
  erfolgreich mit einem Hinweis (kein Fehlalarm vor dem ersten Deploy). Zum Aktivieren: GitHub →
  Repo → Settings → Secrets and variables → Actions → Variables → `BFTAG_URL` =
  `https://bf.example.de` setzen. Ein Fehlschlag löst die Standard-GitHub-Benachrichtigung aus.
- Logs: `docker compose -p bftag logs [service]` auf dem Server. Rotation ist über den
  `json-file`-Logtreiber mit `max-size: 10m, max-file: 5` für alle drei Services konfiguriert
  (`infra/docker-compose.yml`, `infra/provision.sh` setzt dieselben Defaults auch für neu
  gestartete Container ohne eigene Logging-Konfiguration in `/etc/docker/daemon.json`).
- Am BF-Tag selbst: Admin-Seite „Systemstatus" mit verbundenen Clients und letzten Push-Fehlern.

## Lokale Prüfung

- `just infra-smoke` — baut beide Images (GHCR-Namen, Tag `smoke`), startet den echten
  Compose-Stack lokal und prüft Health, Web-Routing, HSTS, Login, dass `db` keinen Port
  veröffentlicht und dass beide Container als Nicht-Root laufen.
- `just infra-backup-test` — automatisierter lokaler Rundlauf von Backup/Restore
  (`infra/test/backup-restore.sh`, restic als Docker-Image, lokales Repository).

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
   `infra/backup.sh` / `infra/restore.sh`, von `deploy.sh` bei jedem Deploy aktualisiert), die
   systemd-Units `infra/systemd/bftag-backup.{service,timer}` sind nach `/etc/systemd/system/`
   kopiert und der Timer ist aktiviert.
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

## Betreiber-Checkliste (NEEDS HUMAN)

Folgende Punkte kann kein Agent erledigen; sie brauchen eine Entscheidung oder einen Zugang des
Betreibers:

- [ ] VPS bestellt und Domain registriert/verfügbar
- [ ] AV-Vertrag (DPA) mit Hetzner abgeschlossen
- [ ] Hetzner Storage Box angelegt (für restic-Backups)
- [ ] `HCLOUD_TOKEN` erzeugt (für `infra/hcloud-firewall.sh`)
- [ ] GHCR-Zugriff eingerichtet (Pakete öffentlich oder `docker login ghcr.io` mit Token)
- [ ] Repo-Variable `BFTAG_URL` gesetzt (GitHub → Settings → Actions → Variables), damit
      `uptime.yml` den Health-Check durchführt
- [ ] Platzhalter in `/datenschutz` (verantwortliche Stelle, Kontaktdaten) ausgefüllt
      (`infra/static/datenschutz/index.html`, Inhalt nach `docs/09-datenschutz.md`)
- [ ] Restore-Test auf dem echten VPS durchgeführt und in der Tabelle oben protokolliert
