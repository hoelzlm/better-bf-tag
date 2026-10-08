#!/usr/bin/env bash
# infra/restore.sh — restore the Postgres database from a restic snapshot.
# Stops the backend before restoring (so it doesn't hold connections open or
# serve stale data mid-restore) and starts it again afterwards.
#
# Usage: restore.sh [snapshot-id|latest] --yes [--no-backend]
#
#   snapshot-id|latest   restic snapshot to restore from (default: latest)
#   --yes                required confirmation flag; restore.sh refuses to run
#                         without it since this destroys the current database.
#   --no-backend          skip stopping/starting the "backend" service (for
#                         environments where it isn't running, e.g. tests)
#
# Config via environment (same as backup.sh):
#   RESTIC_REPOSITORY, RESTIC_PASSWORD_FILE/RESTIC_PASSWORD, BFTAG_DIR,
#   COMPOSE_PROJECT, RESTIC_BIN
set -euo pipefail
set -o pipefail

BFTAG_DIR="${BFTAG_DIR:-/opt/bftag}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-bftag}"
RESTIC_BIN="${RESTIC_BIN:-restic}"
COMPOSE_FILE="$BFTAG_DIR/docker-compose.yml"

SNAPSHOT="latest"
CONFIRMED=0
NO_BACKEND=0

for arg in "$@"; do
  case "$arg" in
    --yes) CONFIRMED=1 ;;
    --no-backend) NO_BACKEND=1 ;;
    -*)
      echo "restore.sh: unknown flag: $arg" >&2
      exit 2
      ;;
    *) SNAPSHOT="$arg" ;;
  esac
done

if [ "$CONFIRMED" -ne 1 ]; then
  echo "restore.sh: refusing to restore without --yes (this overwrites the current database)." >&2
  echo "Usage: restore.sh [snapshot-id|latest] --yes [--no-backend]" >&2
  exit 1
fi

if [ -z "${RESTIC_REPOSITORY:-}" ]; then
  echo "restore.sh: RESTIC_REPOSITORY is not set" >&2
  exit 1
fi
if [ -z "${RESTIC_PASSWORD_FILE:-}" ] && [ -z "${RESTIC_PASSWORD:-}" ]; then
  echo "restore.sh: neither RESTIC_PASSWORD_FILE nor RESTIC_PASSWORD is set" >&2
  exit 1
fi

compose() {
  docker compose -p "$COMPOSE_PROJECT" -f "$COMPOSE_FILE" "$@"
}

if [ "$NO_BACKEND" -ne 1 ]; then
  echo "restore.sh: stopping backend..."
  if ! compose stop backend; then
    echo "restore.sh: 'compose stop backend' failed (service absent?), continuing." >&2
  fi
fi

echo "restore.sh: restoring snapshot '$SNAPSHOT' into the database..."
# shellcheck disable=SC2086
$RESTIC_BIN dump "$SNAPSHOT" bftag.dump \
  | compose exec -T db pg_restore -U bftag -d bftag --clean --if-exists --no-owner

if [ "$NO_BACKEND" -ne 1 ]; then
  echo "restore.sh: starting backend..."
  if ! compose start backend; then
    echo "restore.sh: 'compose start backend' failed (service absent?)." >&2
  fi
fi

echo "restore.sh: done."
