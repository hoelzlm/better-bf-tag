#!/usr/bin/env bash
# infra/test/backup-restore.sh — automated local round-trip test for
# infra/backup.sh and infra/restore.sh. No external services: restic runs as
# a throwaway Docker container (restic/restic image) against a local
# directory repository, and only the "db" service of infra/docker-compose.yml
# is started. Always tears the stack down.
set -euo pipefail
set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

PROJECT="bftag-backup-test"
ENV_FILE="$(mktemp)"
REPO_DIR="$(mktemp -d)"
HOST_RESTIC_PASSWORD_FILE="$(mktemp)"
printf 'test-restic-password\n' > "$HOST_RESTIC_PASSWORD_FILE"
FAILURES=0

log_pass() { printf 'PASS: %s\n' "$1"; }
log_fail() {
  printf 'FAIL: %s\n' "$1"
  FAILURES=$((FAILURES + 1))
}

# shellcheck disable=SC2329 # invoked indirectly via `trap ... EXIT`
cleanup() {
  local status=$?
  if ! docker compose -p "$PROJECT" -f infra/docker-compose.yml --env-file "$ENV_FILE" down -v 2>/tmp/bftag-backup-test-down.log; then
    echo "NOTE: 'docker compose -p $PROJECT down -v' failed (sandbox may block it)." >&2
    echo "      Project name for manual teardown: $PROJECT" >&2
    cat /tmp/bftag-backup-test-down.log >&2 || true
  fi
  rm -f "$ENV_FILE" "$HOST_RESTIC_PASSWORD_FILE" /tmp/bftag-backup-test-down.log || true
  # Files inside REPO_DIR were written by restic running as root inside the
  # restic/restic container; remove them the same way if the plain rm fails.
  rm -rf "$REPO_DIR" 2>/dev/null || docker run --rm -v "$REPO_DIR:/d" restic/restic sh -c 'rm -rf /d/*' 2>/dev/null || true
  rm -rf "$REPO_DIR" 2>/dev/null || true
  exit "$status"
}
trap cleanup EXIT

# --- 1. temp .env + bring up only the db service ----------------------------
POSTGRES_PASSWORD="$(openssl rand -hex 24)"
JWT_SECRET="$(openssl rand -hex 32)"

cat > "$ENV_FILE" <<EOF
BFTAG_TAG=smoke
BFTAG_DOMAIN=localhost
ACME_EMAIL=backup-test@example.invalid
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
JWT_SECRET=$JWT_SECRET
CORS_ORIGINS=
OWN_FIRE_DEPARTMENT_NAME=Backup Test Feuerwehr
EOF

docker compose -p "$PROJECT" -f infra/docker-compose.yml --env-file "$ENV_FILE" up -d --wait db

psql_exec() {
  docker compose -p "$PROJECT" -f infra/docker-compose.yml --env-file "$ENV_FILE" exec -T db \
    psql -U bftag -d bftag -v ON_ERROR_STOP=1 "$@"
}

# --- 2. seed a table + rows --------------------------------------------------
psql_exec -c "CREATE TABLE backup_test (id serial primary key, note text);"
psql_exec -c "INSERT INTO backup_test (note) VALUES ('alpha'), ('bravo'), ('charlie');"

before_rows="$(psql_exec -t -A -c "SELECT id, note FROM backup_test ORDER BY id;")"

# --- 3. run backup.sh with a restic-docker wrapper against a local repo ----
export RESTIC_REPOSITORY=/repo
export RESTIC_PASSWORD_FILE=/restic-password
export COMPOSE_PROJECT="$PROJECT"

# backup.sh/restore.sh invoke "$RESTIC_BIN <args...>"; use a thin wrapper
# script so that works as a plain command (docker run restic/restic ...).
RESTIC_WRAPPER="$(mktemp)"
cat > "$RESTIC_WRAPPER" <<EOF
#!/usr/bin/env bash
exec docker run --rm -i \\
  -v "$REPO_DIR:/repo" \\
  -v "$HOST_RESTIC_PASSWORD_FILE:/restic-password:ro" \\
  -e RESTIC_REPOSITORY=/repo \\
  -e RESTIC_PASSWORD_FILE=/restic-password \\
  restic/restic "\$@"
EOF
chmod +x "$RESTIC_WRAPPER"
RESTIC_BIN="$RESTIC_WRAPPER"
export RESTIC_BIN

export BFTAG_DIR="$REPO_ROOT/infra"

if ./infra/backup.sh --init; then
  log_pass "backup.sh --init ran successfully"
else
  log_fail "backup.sh --init failed"
fi

snapshot_count="$("$RESTIC_WRAPPER" snapshots --tag db --json | grep -c '"id"' || true)"
if [ "$snapshot_count" -eq 1 ]; then
  log_pass "restic repository has exactly 1 db snapshot after first backup"
else
  log_fail "expected 1 db snapshot, got $snapshot_count"
fi

# --- 4. drop the table, restore, verify rows are back -----------------------
psql_exec -c "DROP TABLE backup_test;"

if ./infra/restore.sh latest --yes --no-backend; then
  log_pass "restore.sh latest --yes --no-backend ran successfully"
else
  log_fail "restore.sh failed"
fi

after_rows="$(psql_exec -t -A -c "SELECT id, note FROM backup_test ORDER BY id;" 2>/dev/null || true)"
if [ "$after_rows" = "$before_rows" ]; then
  log_pass "restored rows match original content"
else
  log_fail "restored rows differ: before=[$before_rows] after=[$after_rows]"
fi

# --- 5. run backup a second time, assert forget/prune ran without error ----
if ./infra/backup.sh; then
  log_pass "second backup.sh run (forget/prune) succeeded"
else
  log_fail "second backup.sh run failed"
fi

second_snapshot_count="$("$RESTIC_WRAPPER" snapshots --tag db --json | grep -c '"id"' || true)"
if [ "$second_snapshot_count" -ge 1 ]; then
  log_pass "restic repository still has snapshot(s) after forget/prune ($second_snapshot_count)"
else
  log_fail "expected at least 1 snapshot after forget/prune, got $second_snapshot_count"
fi

rm -f "$RESTIC_WRAPPER"

# --- 6. summary --------------------------------------------------------------
if [ "$FAILURES" -eq 0 ]; then
  echo "All backup/restore round-trip checks PASSED."
  exit 0
else
  echo "$FAILURES backup/restore check(s) FAILED."
  exit 1
fi
