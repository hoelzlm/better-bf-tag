#!/usr/bin/env bash
# BF-Tag vor Ort: Produktions-Stack auf einem Laptop an der Wache, erreichbar im WLAN.
#
#   just event            # bauen + starten (Daten bleiben erhalten)
#   just event stop       # anhalten (Daten bleiben erhalten)
#   just event status     # Container + Adressen anzeigen
#   just event logs       # Backend-Logs folgen
#   just event backup     # Datenbank-Dump nach ~/bftag-event-backups/
#
# Einstellungen + Passwörter: ~/.config/bftag-event/.env (beim ersten Start erzeugt, chmod 600).
# Ohne Handys: kein Push, keine App. Leitstelle + Admin im Browser, Monitor im Browser des TVs.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
PROJECT="bftag-event"
CONF_DIR="$HOME/.config/bftag-event"
ENV_FILE="$CONF_DIR/.env"
COMPOSE=(docker compose -p "$PROJECT" -f infra/docker-compose.yml --env-file "$ENV_FILE")

# WLAN/LAN addresses only (skips Docker bridges docker0/br-*/veth*).
# Linux: `ip`; macOS has no `ip`, so fall back to `ifconfig`.
lan_ips() {
  if command -v ip >/dev/null 2>&1; then
    ip -4 -o addr show scope global 2>/dev/null | awk '$2 !~ /^(docker|br-|veth|virbr)/ {split($4, a, "/"); print a[1]}'
  else
    ifconfig 2>/dev/null | awk '/^[a-z]/ {iface=$1} $1 == "inet" && $2 != "127.0.0.1" && iface !~ /^(bridge|utun|docker|veth)/ {print $2}'
  fi
}

show_urls() {
  local port; port="$(grep -E '^HTTP_PORT=' "$ENV_FILE" | cut -d= -f2)"
  local suffix=""; [ "$port" != "80" ] && suffix=":$port"
  echo
  echo "Auf diesem Laptop:  http://localhost$suffix/admin"
  for ip in $(lan_ips); do
    echo "Im WLAN:            http://$ip$suffix/admin      (Leitstelle/Admin)"
    echo "                    http://$ip$suffix/monitor    (TV in der Halle)"
  done
  echo "Admin-Login:        $(grep -E '^BOOTSTRAP_ADMIN_USERNAME=' "$ENV_FILE" | cut -d= -f2) / Passwort in $ENV_FILE"
}

ensure_env() {
  [ -f "$ENV_FILE" ] && return
  mkdir -p "$CONF_DIR" && chmod 700 "$CONF_DIR"
  umask 077
  cat > "$ENV_FILE" <<EOF
# BF-Tag vor Ort (scripts/event.sh). Nach Änderungen: just event
BFTAG_TAG=event
# ":80" = Caddy antwortet auf jede Adresse per HTTP (kein Zertifikat im lokalen WLAN)
BFTAG_DOMAIN=:80
ACME_EMAIL=unused@example.invalid
HTTP_PORT=80
HTTPS_PORT=8443
POSTGRES_PASSWORD=$(openssl rand -hex 24)
JWT_SECRET=$(openssl rand -hex 32)
BOOTSTRAP_ADMIN_USERNAME=admin
BOOTSTRAP_ADMIN_PASSWORD=$(openssl rand -base64 12 | tr -d '/+=' | cut -c1-14)
CORS_ORIGINS=
OWN_FIRE_DEPARTMENT_NAME=Jugendfeuerwehr
AUTH_RATE_LIMIT_MAX=1000
# HTTP ohne Zertifikat: Refresh-Cookie darf nicht 'Secure' sein
COOKIE_SECURE=false
# Adresssuche braucht Internet (OpenStreetMap). Ohne Internet: false
GEOCODING_ENABLED=true
# Koordinaten der Wache (Karte auf dem Monitor), z. B. aus Google/OSM kopieren
STATION_LATITUDE=
STATION_LONGITUDE=
EOF
  echo "Neue Einstellungen angelegt: $ENV_FILE (Name der Feuerwehr + Koordinaten der Wache eintragen)"
}

# Ältere Einstellungsdateien nachrüsten
[ -f "$ENV_FILE" ] && ! grep -q '^COOKIE_SECURE=' "$ENV_FILE" && echo 'COOKIE_SECURE=false' >> "$ENV_FILE"

cmd="${1:-up}"
case "$cmd" in
  up)
    ensure_env
    (cd apps/web && flutter build web --release --base-href /)
    docker build -q -f backend/Dockerfile -t ghcr.io/hoelzlm/better-bf-tag-backend:event backend
    docker build -q -f infra/web.Dockerfile -t ghcr.io/hoelzlm/better-bf-tag-web:event .
    "${COMPOSE[@]}" up -d --wait
    show_urls
    ;;
  stop) "${COMPOSE[@]}" stop ;;
  status) "${COMPOSE[@]}" ps; show_urls ;;
  logs) "${COMPOSE[@]}" logs -f --tail 100 backend ;;
  backup)
    mkdir -p "$HOME/bftag-event-backups"
    out="$HOME/bftag-event-backups/bftag-$(date +%F-%H%M).sql.gz"
    "${COMPOSE[@]}" exec -T db sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' | gzip > "$out"
    echo "Backup: $out"
    ;;
  *) echo "Unbekannt: $cmd (up|stop|status|logs|backup)" >&2; exit 2 ;;
esac
