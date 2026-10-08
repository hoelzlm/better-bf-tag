#!/usr/bin/env bash
# infra/deploy.sh — one-command deploy, run from the operator's machine.
# Copies docker-compose.yml/backup.sh/restore.sh to the server, sets the
# image tag in the server's .env, pulls and restarts the stack, then polls
# the health endpoint.
#
# Usage: deploy.sh [--dry-run] [tag]
#
#   tag        image tag to deploy (default: sha-<short origin/main sha>,
#              "latest" is also allowed)
#   --dry-run  print the commands that would run instead of running them
#
# Required environment:
#   BFTAG_SSH      ssh target, e.g. bftag@bf.example.de
#   BFTAG_DOMAIN   domain used for the post-deploy health check
# Optional environment:
#   BFTAG_DIR      remote directory with docker-compose.yml (default /opt/bftag)
set -euo pipefail
set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRY_RUN=0
TAG=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -*)
      echo "deploy.sh: unknown flag: $arg" >&2
      exit 2
      ;;
    *) TAG="$arg" ;;
  esac
done

if [ -z "${BFTAG_SSH:-}" ]; then
  echo "deploy.sh: BFTAG_SSH is not set" >&2
  exit 1
fi
if [ -z "${BFTAG_DOMAIN:-}" ]; then
  echo "deploy.sh: BFTAG_DOMAIN is not set" >&2
  exit 1
fi
BFTAG_DIR="${BFTAG_DIR:-/opt/bftag}"

if [ -z "$TAG" ]; then
  TAG="sha-$(git -C "$REPO_ROOT" rev-parse --short=7 origin/main)"
fi

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

echo "deploy.sh: deploying tag '$TAG' to $BFTAG_SSH:$BFTAG_DIR..."

run scp "$REPO_ROOT/infra/docker-compose.yml" "$REPO_ROOT/infra/backup.sh" "$REPO_ROOT/infra/restore.sh" \
  "$BFTAG_SSH:$BFTAG_DIR/"

REMOTE_CMD=$(cat <<EOF
set -euo pipefail
sed -i.bak '/^BFTAG_TAG=/d' '$BFTAG_DIR/.env'
printf 'BFTAG_TAG=%s\n' '$TAG' >> '$BFTAG_DIR/.env'
rm -f '$BFTAG_DIR/.env.bak'
cd '$BFTAG_DIR'
docker compose pull
docker compose up -d --remove-orphans --wait
docker image prune -f
EOF
)

run ssh "$BFTAG_SSH" "$REMOTE_CMD"

echo "deploy.sh: waiting for https://$BFTAG_DOMAIN/api/v1/health to become healthy (up to 120s)..."

if [ "$DRY_RUN" -eq 1 ]; then
  printf '[dry-run] %s\n' "poll https://$BFTAG_DOMAIN/api/v1/health for up to 120s"
else
  deadline=$((SECONDS + 120))
  until curl -fsS --max-time 5 "https://$BFTAG_DOMAIN/api/v1/health" >/dev/null 2>&1; do
    if [ "$SECONDS" -ge "$deadline" ]; then
      echo "deploy.sh: health check did not succeed within 120s" >&2
      exit 1
    fi
    sleep 3
  done
fi

echo "deploy.sh: deployed tag '$TAG' to $BFTAG_SSH:$BFTAG_DIR, health check OK."
