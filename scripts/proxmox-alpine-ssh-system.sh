#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/proxmox-alpine-ssh-system.sh <LXC_ID> [SSH_PUBLIC_KEY_FILE]

Create the 'system' user inside an Alpine LXC on Proxmox, install OpenSSH,
configure SSH access for that user, and ensure the service is enabled.

Examples:
  SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" ./scripts/proxmox-alpine-ssh-system.sh 200
  ./scripts/proxmox-alpine-ssh-system.sh 200 ~/.ssh/id_ed25519.pub

Environment:
  SSH_PUBLIC_KEY   Optional inline public key to add to /home/system/.ssh/authorized_keys
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

LXC_ID="$1"
SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY:-}"

if [[ $# -ge 2 ]]; then
  SSH_PUBLIC_KEY_FILE="$2"
  if [[ ! -f "$SSH_PUBLIC_KEY_FILE" ]]; then
    echo "SSH public key file not found: $SSH_PUBLIC_KEY_FILE" >&2
    exit 1
  fi
  SSH_PUBLIC_KEY="$(cat "$SSH_PUBLIC_KEY_FILE")"
fi

if ! command -v pct >/dev/null 2>&1; then
  echo "Error: pct is required and was not found in PATH. Run this on the Proxmox host." >&2
  exit 1
fi

SSH_PUBLIC_KEY_ESCAPED="${SSH_PUBLIC_KEY//\'/\'\\'\'}"

pct exec "$LXC_ID" -- ash -eu -c "
  if ! id -u system >/dev/null 2>&1; then
    adduser -D -s /bin/ash system
  fi

  if ! command -v sshd >/dev/null 2>&1; then
    apk add --no-cache openssh
  fi

  mkdir -p /home/system/.ssh
  chown -R system:system /home/system
  chmod 700 /home/system/.ssh

  if [ -n '${SSH_PUBLIC_KEY_ESCAPED}' ]; then
    printf '%s\\n' '${SSH_PUBLIC_KEY_ESCAPED}' > /home/system/.ssh/authorized_keys
    chown system:system /home/system/.ssh/authorized_keys
    chmod 600 /home/system/.ssh/authorized_keys
  fi

  if [ ! -f /etc/ssh/sshd_config ]; then
    echo 'Error: /etc/ssh/sshd_config does not exist after installing OpenSSH.' >&2
    exit 1
  fi

  mkdir -p /run/sshd
  ssh-keygen -A 2>/dev/null || true

  sed -i -E 's/^#?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  sed -i -E 's/^#?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
  sed -i -E 's/^#?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
  sed -i -E '/^#?UsePAM /d' /etc/ssh/sshd_config

  grep -q '^PasswordAuthentication ' /etc/ssh/sshd_config || echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
  grep -q '^PubkeyAuthentication ' /etc/ssh/sshd_config || echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config
  grep -q '^PermitRootLogin ' /etc/ssh/sshd_config || echo 'PermitRootLogin no' >> /etc/ssh/sshd_config

  sshd -t
  rc-update add sshd default 2>/dev/null || true
  rc-service sshd start 2>/dev/null || true
"

echo "OK: user 'system' is configured for SSH in LXC ${LXC_ID}."
