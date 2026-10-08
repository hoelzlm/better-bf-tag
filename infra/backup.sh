#!/usr/bin/env bash
# infra/backup.sh — nightly encrypted DB backup, run on the VPS host as root via
# systemd (bftag-backup.service/.timer). Dumps the "db" service's Postgres
# database and pushes it into a restic repository, then prunes old snapshots.
#
# Config via environment (systemd EnvironmentFile=/etc/bftag/restic.env):
#   RESTIC_REPOSITORY   restic repository (e.g. sftp:uXXXXXX@...your-storagebox.de:23/bftag)
#   RESTIC_PASSWORD_FILE or RESTIC_PASSWORD   restic repository password
#   BFTAG_DIR           directory with docker-compose.yml (default /opt/bftag)
#   COMPOSE_PROJECT     docker compose project name (default bftag)
#   RESTIC_BIN          restic binary/wrapper (default "restic"; tests override
#                        this with a `docker run restic/restic` wrapper)
#
# Usage: backup.sh [--init]
#   --init   initialize the restic repository first if it is not yet readable
#            (checked via `restic snapshots`).
set -euo pipefail
set -o pipefail

BFTAG_DIR="${BFTAG_DIR:-/opt/bftag}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-bftag}"
RESTIC_BIN="${RESTIC_BIN:-restic}"
COMPOSE_FILE="$BFTAG_DIR/docker-compose.yml"

INIT=0
for arg in "$@"; do
  case "$arg" in
    --init) INIT=1 ;;
    *)
      echo "backup.sh: unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

if [ -z "${RESTIC_REPOSITORY:-}" ]; then
  echo "backup.sh: RESTIC_REPOSITORY is not set" >&2
  exit 1
fi
if [ -z "${RESTIC_PASSWORD_FILE:-}" ] && [ -z "${RESTIC_PASSWORD:-}" ]; then
  echo "backup.sh: neither RESTIC_PASSWORD_FILE nor RESTIC_PASSWORD is set" >&2
  exit 1
fi

# shellcheck disable=SC2086
if [ "$INIT" -eq 1 ]; then
  if ! $RESTIC_BIN snapshots >/dev/null 2>&1; then
    echo "backup.sh: repository not reachable, initializing..."
    $RESTIC_BIN init
  else
    echo "backup.sh: --init given but repository already initialized, skipping init."
  fi
fi

echo "backup.sh: dumping database via 'docker compose -p $COMPOSE_PROJECT exec db pg_dump' and sending to restic..."
docker compose -p "$COMPOSE_PROJECT" -f "$COMPOSE_FILE" exec -T db \
  pg_dump -U bftag -d bftag -Fc \
  | $RESTIC_BIN backup --stdin --stdin-filename bftag.dump --tag db

echo "backup.sh: pruning old snapshots (keep 7 daily, 4 weekly)..."
$RESTIC_BIN forget --tag db --keep-daily 7 --keep-weekly 4 --prune

echo "backup.sh: done."
