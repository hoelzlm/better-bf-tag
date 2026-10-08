#!/usr/bin/env bash
# infra/smoke-test.sh — builds the production images from infra/ and runs the
# real compose stack locally, asserting the routes/headers described in
# docs/adr/0011-deployment-images-backup.md. Always tears the stack down.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PROJECT="bftag-smoke"
HTTP_PORT="18080"
HTTPS_PORT="18443"
ENV_FILE="$(mktemp)"
FAILURES=0

log_pass() { printf 'PASS: %s\n' "$1"; }
log_fail() {
  printf 'FAIL: %s\n' "$1"
  FAILURES=$((FAILURES + 1))
}

# shellcheck disable=SC2329 # invoked indirectly via `trap ... EXIT`
cleanup() {
  local status=$?
  if ! docker compose -p "$PROJECT" -f infra/docker-compose.yml --env-file "$ENV_FILE" down -v 2>/tmp/bftag-smoke-down.log; then
    echo "NOTE: 'docker compose -p $PROJECT down -v' failed (sandbox may block it)." >&2
    echo "      Project name for manual teardown: $PROJECT" >&2
    cat /tmp/bftag-smoke-down.log >&2 || true
  fi
  rm -f "$ENV_FILE" /tmp/bftag-smoke-down.log
  exit "$status"
}
trap cleanup EXIT

# --- 1. build the web app (unless the caller already built it) -------------
if [ "${SKIP_WEB_BUILD:-0}" != "1" ]; then
  (cd apps/web && flutter build web --release --base-href /)
fi

# --- 2. build images with the GHCR names, tagged "smoke" -------------------
docker build -f backend/Dockerfile -t ghcr.io/hoelzlm/better-bf-tag-backend:smoke backend
docker build -f infra/web.Dockerfile -t ghcr.io/hoelzlm/better-bf-tag-web:smoke .

# --- 3. temp .env with random passwords -------------------------------------
POSTGRES_PASSWORD="$(openssl rand -hex 24)"
JWT_SECRET="$(openssl rand -hex 32)"
BOOTSTRAP_ADMIN_USERNAME="smoke-admin"
BOOTSTRAP_ADMIN_PASSWORD="$(openssl rand -hex 16)"

cat > "$ENV_FILE" <<EOF
BFTAG_TAG=smoke
BFTAG_DOMAIN=localhost
ACME_EMAIL=smoke-test@example.invalid
HTTP_PORT=$HTTP_PORT
HTTPS_PORT=$HTTPS_PORT
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
JWT_SECRET=$JWT_SECRET
BOOTSTRAP_ADMIN_USERNAME=$BOOTSTRAP_ADMIN_USERNAME
BOOTSTRAP_ADMIN_PASSWORD=$BOOTSTRAP_ADMIN_PASSWORD
CORS_ORIGINS=
OWN_FIRE_DEPARTMENT_NAME=Smoke Test Feuerwehr
EOF

# --- 4. bring up the stack --------------------------------------------------
docker compose -p "$PROJECT" -f infra/docker-compose.yml --env-file "$ENV_FILE" up -d --wait

BASE_URL="https://localhost:$HTTPS_PORT"
CURL=(curl -sk --max-time 10)

# --- 5. assertions -----------------------------------------------------------

# GET /api/v1/health -> 200 with "ok"
health_body="$("${CURL[@]}" -o - -w '' "$BASE_URL/api/v1/health" || true)"
health_status="$("${CURL[@]}" -o /dev/null -w '%{http_code}' "$BASE_URL/api/v1/health" || true)"
if [ "$health_status" = "200" ] && printf '%s' "$health_body" | grep -q 'ok'; then
  log_pass "GET /api/v1/health -> 200 containing 'ok'"
else
  log_fail "GET /api/v1/health -> got status=$health_status body=$health_body"
fi

# GET /admin -> 200 contains <base href="/">
admin_body="$("${CURL[@]}" "$BASE_URL/admin" || true)"
admin_status="$("${CURL[@]}" -o /dev/null -w '%{http_code}' "$BASE_URL/admin" || true)"
if [ "$admin_status" = "200" ] && printf '%s' "$admin_body" | grep -qF '<base href="/">'; then
  log_pass 'GET /admin -> 200 containing <base href="/">'
else
  log_fail "GET /admin -> got status=$admin_status"
fi

# GET /admin/login (deep link) -> 200 HTML
login_status="$("${CURL[@]}" -o /dev/null -w '%{http_code}' "$BASE_URL/admin/login" || true)"
login_body="$("${CURL[@]}" "$BASE_URL/admin/login" || true)"
if [ "$login_status" = "200" ] && printf '%s' "$login_body" | grep -qi '<html'; then
  log_pass "GET /admin/login -> 200 HTML (deep link via try_files)"
else
  log_fail "GET /admin/login -> got status=$login_status"
fi

# GET /datenschutz/ -> 200 contains "Datenschutz"
dsz_status="$("${CURL[@]}" -o /dev/null -w '%{http_code}' "$BASE_URL/datenschutz/" || true)"
dsz_body="$("${CURL[@]}" "$BASE_URL/datenschutz/" || true)"
if [ "$dsz_status" = "200" ] && printf '%s' "$dsz_body" | grep -q 'Datenschutz'; then
  log_pass "GET /datenschutz/ -> 200 containing 'Datenschutz'"
else
  log_fail "GET /datenschutz/ -> got status=$dsz_status"
fi

# GET / -> 30x Location /admin
root_headers="$("${CURL[@]}" -D - -o /dev/null "$BASE_URL/" || true)"
root_status="$(printf '%s' "$root_headers" | head -1 | grep -oE '[0-9]{3}' || true)"
if printf '%s' "$root_status" | grep -qE '^30[0-9]$' && printf '%s' "$root_headers" | grep -qi 'location: /admin'; then
  log_pass "GET / -> 30x Location: /admin"
else
  log_fail "GET / -> got status=$root_status headers=$root_headers"
fi

# HSTS header present
if printf '%s' "$root_headers" | grep -qi 'strict-transport-security'; then
  log_pass "Strict-Transport-Security header present"
else
  # HSTS is set at the site level; check against a 200 response too.
  hsts_check="$("${CURL[@]}" -D - -o /dev/null "$BASE_URL/api/v1/health" || true)"
  if printf '%s' "$hsts_check" | grep -qi 'strict-transport-security'; then
    log_pass "Strict-Transport-Security header present"
  else
    log_fail "Strict-Transport-Security header missing"
  fi
fi

# POST /api/v1/auth/login with bootstrap admin -> 200
login_post_status="$("${CURL[@]}" -o /dev/null -w '%{http_code}' -X POST \
  -H 'content-type: application/json' \
  -d "{\"username\":\"$BOOTSTRAP_ADMIN_USERNAME\",\"password\":\"$BOOTSTRAP_ADMIN_PASSWORD\"}" \
  "$BASE_URL/api/v1/auth/login" || true)"
if [ "$login_post_status" = "200" ]; then
  log_pass "POST /api/v1/auth/login with bootstrap admin -> 200"
else
  log_fail "POST /api/v1/auth/login -> got status=$login_post_status"
fi

# db has no published port
db_port_output="$(docker compose -p "$PROJECT" -f infra/docker-compose.yml --env-file "$ENV_FILE" port db 5432 2>&1 || true)"
db_port_value="${db_port_output##*:}"
if [ -z "$db_port_output" ] || [ "$db_port_value" = "0" ] || ! printf '%s' "$db_port_output" | grep -qE ':[0-9]+$'; then
  log_pass "db service has no published port (compose port db 5432: '$db_port_output')"
else
  log_fail "db service has a published port: $db_port_output"
fi

# non-root users inside backend and web containers
backend_uid="$(docker compose -p "$PROJECT" -f infra/docker-compose.yml --env-file "$ENV_FILE" exec -T backend id -u || true)"
if [ -n "$backend_uid" ] && [ "$backend_uid" != "0" ]; then
  log_pass "backend container runs as non-root (uid=$backend_uid)"
else
  log_fail "backend container runs as uid=$backend_uid"
fi

web_uid="$(docker compose -p "$PROJECT" -f infra/docker-compose.yml --env-file "$ENV_FILE" exec -T web id -u || true)"
if [ -n "$web_uid" ] && [ "$web_uid" != "0" ]; then
  log_pass "web container runs as non-root (uid=$web_uid)"
else
  log_fail "web container runs as uid=$web_uid"
fi

# --- 6. summary --------------------------------------------------------------
if [ "$FAILURES" -eq 0 ]; then
  echo "All smoke checks PASSED."
  exit 0
else
  echo "$FAILURES smoke check(s) FAILED."
  exit 1
fi
