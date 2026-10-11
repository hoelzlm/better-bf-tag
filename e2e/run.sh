#!/usr/bin/env bash
# e2e/run.sh — builds the production images from infra/ and runs the real
# compose stack locally, then runs the API (and later UI) e2e scenario
# against it. Always tears the stack down (trap EXIT), regardless of result.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PROJECT="bftag-e2e"
HTTP_PORT="28080"
HTTPS_PORT="28443"
ENV_FILE="$(mktemp)"
export E2E_ARTIFACT_DIR="${E2E_ARTIFACT_DIR:-$REPO_ROOT/e2e/artifacts}"
mkdir -p "$E2E_ARTIFACT_DIR"

OVERALL_STATUS=0

# shellcheck disable=SC2329 # invoked indirectly via `trap ... EXIT`
cleanup() {
  local status=$?
  if [ "$status" -ne 0 ]; then
    docker compose -p "$PROJECT" -f infra/docker-compose.yml --env-file "$ENV_FILE" logs \
      > "$E2E_ARTIFACT_DIR/compose.log" 2>&1 || true
  fi
  docker compose -p "$PROJECT" -f infra/docker-compose.yml --env-file "$ENV_FILE" down -v --remove-orphans \
    2>/tmp/bftag-e2e-down.log || {
    echo "NOTE: 'docker compose -p $PROJECT down -v' failed." >&2
    cat /tmp/bftag-e2e-down.log >&2 || true
  }
  rm -f "$ENV_FILE" /tmp/bftag-e2e-down.log
  exit "$status"
}
trap cleanup EXIT

# --- 1. build the web app (unless the caller already built it) -------------
PHASE_START=$SECONDS
if [ "${SKIP_WEB_BUILD:-0}" != "1" ]; then
  (cd apps/web && flutter build web --release --base-href /)
fi

# --- 2. build images tagged "e2e" (same names as infra/smoke-test.sh) ------
docker build -f backend/Dockerfile -t ghcr.io/hoelzlm/better-bf-tag-backend:e2e backend
docker build -f infra/web.Dockerfile -t ghcr.io/hoelzlm/better-bf-tag-web:e2e .
echo "TIMING: build phase took $((SECONDS - PHASE_START))s"

# --- 3. temp .env with random secrets ---------------------------------------
POSTGRES_PASSWORD="$(openssl rand -hex 24)"
JWT_SECRET="$(openssl rand -hex 32)"
BOOTSTRAP_ADMIN_USERNAME="e2e-admin"
BOOTSTRAP_ADMIN_PASSWORD="$(openssl rand -hex 16)"

cat > "$ENV_FILE" <<EOF
BFTAG_TAG=e2e
BFTAG_DOMAIN=localhost
ACME_EMAIL=e2e-test@example.invalid
HTTP_PORT=$HTTP_PORT
HTTPS_PORT=$HTTPS_PORT
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
JWT_SECRET=$JWT_SECRET
BOOTSTRAP_ADMIN_USERNAME=$BOOTSTRAP_ADMIN_USERNAME
BOOTSTRAP_ADMIN_PASSWORD=$BOOTSTRAP_ADMIN_PASSWORD
CORS_ORIGINS=
OWN_FIRE_DEPARTMENT_NAME=E2E Test Feuerwehr
AUTH_RATE_LIMIT_MAX=1000
GEOCODING_ENABLED=false
STATION_LATITUDE=48.137
STATION_LONGITUDE=11.575
EOF

# --- 4. bring up the stack --------------------------------------------------
PHASE_START=$SECONDS
docker compose -p "$PROJECT" -f infra/docker-compose.yml --env-file "$ENV_FILE" up -d --wait
echo "TIMING: up phase took $((SECONDS - PHASE_START))s"

# --- 5. install e2e deps + run the scenarios --------------------------------
npm ci --prefix e2e

export E2E_BASE="https://localhost:$HTTPS_PORT"
export E2E_ADMIN_USER="$BOOTSTRAP_ADMIN_USERNAME"
export E2E_ADMIN_PASS="$BOOTSTRAP_ADMIN_PASSWORD"
# Caddy serves a self-signed cert for BFTAG_DOMAIN=localhost.
export NODE_TLS_REJECT_UNAUTHORIZED=0

PHASE_START=$SECONDS
if ! node e2e/api.mjs; then
  OVERALL_STATUS=1
fi
echo "TIMING: api phase took $((SECONDS - PHASE_START))s"

# UI test: runs regardless of the API test's result; overall exit stays
# non-zero if either suite failed.
PHASE_START=$SECONDS
if ! node e2e/ui.mjs; then
  OVERALL_STATUS=1
fi
echo "TIMING: ui phase took $((SECONDS - PHASE_START))s"

exit "$OVERALL_STATUS"
