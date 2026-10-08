#!/usr/bin/env bash
# infra/provision.sh — idempotent hardening/setup for a fresh Ubuntu 24.04
# VPS. Run as root. Expects to be run from a checkout of this repo (or after
# scp'ing the infra/ directory) so it can install infra/systemd/* and
# docker-compose.yml alongside it.
#
# Usage: provision.sh   (as root)
set -euo pipefail
set -o pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "provision.sh: must be run as root" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -s /root/.ssh/authorized_keys ]; then
  echo "provision.sh: refusing to run, /root/.ssh/authorized_keys is missing or empty" >&2
  echo "              (would lock out ssh access once root login is disabled)" >&2
  exit 1
fi

echo "provision.sh: updating packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade

echo "provision.sh: installing Docker Engine + compose plugin..."
if ! command -v docker >/dev/null 2>&1; then
  apt-get -y install ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
  fi
  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" \
      > /etc/apt/sources.list.d/docker.list
  fi
  apt-get update
  apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  echo "provision.sh: docker already installed, skipping."
fi

echo "provision.sh: creating user 'bftag'..."
if ! id bftag >/dev/null 2>&1; then
  useradd -m -s /bin/bash -G docker bftag
else
  echo "provision.sh: user 'bftag' already exists, skipping creation."
  usermod -aG docker bftag
fi

install -d -m 0700 -o bftag -g bftag /home/bftag/.ssh
install -m 0600 -o bftag -g bftag /root/.ssh/authorized_keys /home/bftag/.ssh/authorized_keys

echo "provision.sh: hardening sshd..."
cat > /etc/ssh/sshd_config.d/10-bftag.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
EOF
sshd -t
systemctl reload ssh || systemctl reload sshd

echo "provision.sh: enabling unattended-upgrades..."
apt-get -y install unattended-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
systemctl enable --now unattended-upgrades

echo "provision.sh: installing and configuring fail2ban..."
apt-get -y install fail2ban
install -d -m 0755 /etc/fail2ban/jail.d
cat > /etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled = true
backend = systemd
maxretry = 5
bantime = 1h
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban

echo "provision.sh: installing restic..."
apt-get -y install restic

echo "provision.sh: configuring Docker log rotation..."
install -d -m 0755 /etc/docker
if [ ! -f /etc/docker/daemon.json ]; then
  cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5"
  }
}
EOF
  systemctl restart docker || true
else
  echo "provision.sh: /etc/docker/daemon.json already exists, leaving it untouched."
fi

echo "provision.sh: creating directories..."
install -d -m 0755 -o bftag -g bftag /opt/bftag
install -d -m 0700 /etc/bftag

echo "provision.sh: installing systemd units..."
install -m 0644 "$SCRIPT_DIR/systemd/bftag-backup.service" /etc/systemd/system/bftag-backup.service
install -m 0644 "$SCRIPT_DIR/systemd/bftag-backup.timer" /etc/systemd/system/bftag-backup.timer
systemctl daemon-reload
systemctl enable bftag-backup.timer

echo "provision.sh: done."
