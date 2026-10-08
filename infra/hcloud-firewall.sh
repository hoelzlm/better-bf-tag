#!/usr/bin/env bash
# infra/hcloud-firewall.sh — idempotently create/apply a Hetzner Cloud
# firewall named "bftag" opening ssh (22), http (80) and https (443,
# tcp+udp) to the given server.
#
# Requires: hcloud CLI, HCLOUD_TOKEN
#
# Usage: HCLOUD_TOKEN=... HCLOUD_SERVER=<name-or-id> ./hcloud-firewall.sh
# Optional: SSH_SOURCE (default "0.0.0.0/0,::/0")
set -euo pipefail
set -o pipefail

if [ -z "${HCLOUD_TOKEN:-}" ]; then
  echo "hcloud-firewall.sh: HCLOUD_TOKEN is not set" >&2
  exit 1
fi
if [ -z "${HCLOUD_SERVER:-}" ]; then
  echo "hcloud-firewall.sh: HCLOUD_SERVER is not set" >&2
  exit 1
fi

SSH_SOURCE="${SSH_SOURCE:-0.0.0.0/0,::/0}"
FIREWALL_NAME="bftag"

IFS=',' read -r -a ssh_sources <<< "$SSH_SOURCE"
ssh_rule_args=()
for src in "${ssh_sources[@]}"; do
  ssh_rule_args+=(--source-ips "$src")
done

if hcloud firewall describe "$FIREWALL_NAME" >/dev/null 2>&1; then
  echo "hcloud-firewall.sh: firewall '$FIREWALL_NAME' already exists, skipping creation."
else
  echo "hcloud-firewall.sh: creating firewall '$FIREWALL_NAME'..."
  hcloud firewall create --name "$FIREWALL_NAME"

  hcloud firewall add-rule "$FIREWALL_NAME" --direction in --protocol tcp --port 22 "${ssh_rule_args[@]}"
  hcloud firewall add-rule "$FIREWALL_NAME" --direction in --protocol tcp --port 80 --source-ips 0.0.0.0/0 --source-ips ::/0
  hcloud firewall add-rule "$FIREWALL_NAME" --direction in --protocol tcp --port 443 --source-ips 0.0.0.0/0 --source-ips ::/0
  hcloud firewall add-rule "$FIREWALL_NAME" --direction in --protocol udp --port 443 --source-ips 0.0.0.0/0 --source-ips ::/0
fi

echo "hcloud-firewall.sh: applying firewall '$FIREWALL_NAME' to server '$HCLOUD_SERVER'..."
if hcloud firewall describe "$FIREWALL_NAME" -o json 2>/dev/null | grep -q "\"server\""; then
  echo "hcloud-firewall.sh: firewall already applied to a server, re-applying to ensure target is correct."
fi
hcloud firewall apply-to-resource "$FIREWALL_NAME" --type server --server "$HCLOUD_SERVER" \
  || echo "hcloud-firewall.sh: apply-to-resource failed (likely already applied), continuing." >&2

echo "hcloud-firewall.sh: done."
