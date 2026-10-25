#!/usr/bin/env bash
#
# create-k8s-proxmox.sh - provision Kubernetes nodes as Ubuntu cloud-init VMs on
# Proxmox VE, then bootstrap k3s (or hand the nodes to ansible/rke2).
#
# The script is idempotent: missing VMs are created, existing VMs are left alone
# and only their cloud-init network/user settings are (re)applied.
#
# Typical usage from this repo (Proxmox reachable over SSH):
#   PVE_HOST=root@proxmox00.furyhawk.lol ./scripts/create-k8s-proxmox.sh
#
# Running directly on the Proxmox host:
#   ./create-k8s-proxmox.sh
#
# Other examples:
#   ./scripts/create-k8s-proxmox.sh --provision-only   # VMs only, no k3s
#   ./scripts/create-k8s-proxmox.sh --ansible          # VMs + ansible/rke2 inventory
#   ./scripts/create-k8s-proxmox.sh --destroy -y       # remove the VMs again
#
# Requirements:
#   - Proxmox VE 8.x (qm, pvesm) with a thin/dir storage for VM disks
#   - SSH access to the Proxmox host when PVE_HOST is used
#   - an SSH key pair; the public key is injected into the VMs
#
# With PVE_HOST only the VM provisioning runs on the Proxmox host. The k3s
# bootstrap always runs from the machine executing this script (it holds the
# private key), so the VM network has to be reachable from here.

set -euo pipefail

if [[ -n "${BASH_SOURCE[0]:-}" && -e "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"
else
  SCRIPT_PATH=""
fi
SCRIPT_NAME="$(basename -- "${SCRIPT_PATH:-create-k8s-proxmox.sh}")"

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!!\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31mxxx\033[0m %s\n' "$*" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# configuration - every value can be overridden from the environment
# ---------------------------------------------------------------------------
PVE_HOST="${PVE_HOST:-}"                     # e.g. root@192.168.50.10 (remote mode)
K8S_NAME="${K8S_NAME:-k8s}"                  # VM name prefix
NODE_COUNT="${NODE_COUNT:-3}"                # node 1 = k3s server, rest = agents
VMID_START="${VMID_START:-300}"              # first VMID, nodes count upwards
K8S_TAG="${K8S_TAG:-k8s}"                    # Proxmox tag applied to the VMs
PVE_POOL="${PVE_POOL:-}"                     # optional resource pool

TEMPLATE_ID="${TEMPLATE_ID:-9000}"           # cloud-init template VMID
TEMPLATE_NAME="${TEMPLATE_NAME:-ubuntu-2404-cloudinit}"
case "$(uname -m)" in
  x86_64 | amd64) IMAGE_ARCH=amd64 ;;
  aarch64 | arm64) IMAGE_ARCH=arm64 ;;
  *) IMAGE_ARCH=amd64 ;;
esac
IMAGE_URL="${IMAGE_URL:-https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-${IMAGE_ARCH}.img}"
IMAGE_FILE="${IMAGE_FILE:-/var/lib/vz/template/iso/noble-server-cloudimg-${IMAGE_ARCH}.img}"

DISK_STORAGE="${DISK_STORAGE:-local-lvm}"    # storage for VM disks
DISK_SIZE="${DISK_SIZE:-32G}"
CPU_CORES="${CPU_CORES:-4}"
CPU_TYPE="${CPU_TYPE:-host}"
RAM_MB="${RAM_MB:-8192}"
BRIDGE="${BRIDGE:-vmbr0}"
VLAN_TAG="${VLAN_TAG:-}"                     # optional 802.1q tag

IP_PREFIX="${IP_PREFIX:-192.168.50}"         # first three octets
IP_START="${IP_START:-141}"                  # last octet of the first node
CIDR="${CIDR:-24}"
GATEWAY="${GATEWAY:-192.168.50.1}"
NAMESERVER="${NAMESERVER:-}"                 # defaults to GATEWAY

CI_USER="${CI_USER:-ubuntu}"
SSH_KEY="${SSH_KEY:-${HOME}/.ssh/id_rsa.pub}"
SSH_PUBKEY="${SSH_PUBKEY:-}"
SSH_IDENTITY="${SSH_IDENTITY:-}"             # optional -i for bootstrapping
SSH_KEY_FILE=""                              # temp copy created on the PVE host

K8S_VIP="${K8S_VIP:-}"                       # optional API VIP (kube-vip)
K3S_CHANNEL="${K3S_CHANNEL:-stable}"
K3S_VERSION="${K3S_VERSION:-}"
K3S_TOKEN="${K3S_TOKEN:-}"
KUBECONFIG_OUT="${KUBECONFIG_OUT:-${HOME}/.kube/cloudy-proxmox.yaml}"
INVENTORY_OUT="${INVENTORY_OUT:-}"

WAIT_TIMEOUT="${WAIT_TIMEOUT:-420}"          # seconds to wait for cloud-init SSH
FORCE="${FORCE:-0}"                          # 1 = ignore IP-in-use checks

NAMESERVER="${NAMESERVER:-${GATEWAY}}"

MODE=create                                  # create | destroy
BOOTSTRAP=k3s                                # k3s | ansible | none
ASSUME_YES=0
ARGS=("$@")

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR -o BatchMode=yes -o ConnectTimeout=8)
if [[ -n "$SSH_IDENTITY" ]]; then
  SSH_OPTS+=(-i "$SSH_IDENTITY")
fi

declare -a NODE_NAMES=() NODE_IPS=() NODE_VMIDS=()

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Provision Kubernetes nodes as Ubuntu cloud-init VMs on Proxmox VE and
optionally bootstrap k3s on them.

Options:
  --k3s              Create VMs and bootstrap k3s (default)
  --provision-only   Create/start VMs only, do not bootstrap Kubernetes
  --ansible          Create VMs and write an inventory for ansible/rke2
  --destroy          Stop and remove the VMs created by this script
  -y, --yes          Skip the confirmation prompt used by --destroy
  -h, --help         Show this help

Environment (all optional):
  PVE_HOST=root@192.168.50.10  Run the Proxmox steps on a remote host
  K8S_NAME=k8s                 VM name prefix            (default: k8s)
  NODE_COUNT=3                 Number of nodes           (default: 3)
  VMID_START=300               First Proxmox VMID        (default: 300)
  TEMPLATE_ID=9000             Cloud-init template VMID  (default: 9000)
  IP_PREFIX=192.168.50         First three IP octets     (default: 192.168.50)
  IP_START=141                 Last octet of first node  (default: 141)
  GATEWAY=192.168.50.1         Default gateway           (default: 192.168.50.1)
  NAMESERVER=\$GATEWAY         DNS server handed to VMs
  DISK_STORAGE=local-lvm       Storage for VM disks      (default: local-lvm)
  DISK_SIZE=32G                Disk size per VM          (default: 32G)
  CPU_CORES=4  CPU_TYPE=host  RAM_MB=8192
  BRIDGE=vmbr0  VLAN_TAG=      Network settings
  CI_USER=ubuntu               Cloud-init user           (default: ubuntu)
  SSH_KEY=~/.ssh/id_rsa.pub    Public key injected into the VMs
  K8S_VIP=192.168.50.210       Optional API VIP / TLS SAN
  KUBECONFIG_OUT=~/.kube/cloudy-proxmox.yaml
  INVENTORY_OUT=<path>         Inventory path for --ansible
EOF
}

parse_args() {
  while (($#)); do
    case "$1" in
      --k3s) BOOTSTRAP=k3s ;;
      --provision-only | --none) BOOTSTRAP=none ;;
      --ansible) BOOTSTRAP=ansible ;;
      --destroy) MODE=destroy ;;
      -y | --yes) ASSUME_YES=1 ;;
      -h | --help)
        usage
        exit 0
        ;;
      *) die "unknown option: $1 (see --help)" ;;
    esac
    shift
  done
}

validate_config() {
  [[ "$NODE_COUNT" =~ ^[0-9]+$ ]] || die "NODE_COUNT must be a number"
  ((NODE_COUNT >= 1)) || die "NODE_COUNT must be at least 1"
  [[ "$IP_PREFIX" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){2}$ ]] || die "IP_PREFIX must look like 192.168.50"
  [[ "$IP_START" =~ ^[0-9]+$ ]] || die "IP_START must be a number"
  ((IP_START >= 1 && IP_START + NODE_COUNT - 1 <= 254)) ||
    die "IP range ${IP_PREFIX}.${IP_START} (+${NODE_COUNT} nodes) is out of bounds"
  [[ "$CIDR" =~ ^[0-9]+$ ]] || die "CIDR must be a number"
  [[ "$VMID_START" =~ ^[0-9]+$ ]] || die "VMID_START must be a number"
  [[ "$TEMPLATE_ID" =~ ^[0-9]+$ ]] || die "TEMPLATE_ID must be a number"
  [[ "$TEMPLATE_ID" -ge 100 ]] || die "TEMPLATE_ID must be >= 100"
  [[ "$K8S_NAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || die "K8S_NAME must be a DNS-safe name"
}

build_nodes() {
  local i
  NODE_NAMES=() NODE_IPS=() NODE_VMIDS=()
  for ((i = 1; i <= NODE_COUNT; i++)); do
    NODE_NAMES+=("$(printf '%s%02d' "$K8S_NAME" "$i")")
    NODE_VMIDS+=("$((VMID_START + i - 1))")
    NODE_IPS+=("${IP_PREFIX}.$((IP_START + i - 1))")
  done
}

resolve_ssh_pubkey() {
  if [[ -z "$SSH_PUBKEY" ]]; then
    local key="${SSH_KEY/#\~/${HOME}}"
    [[ -f "$key" ]] || die "SSH public key not found: ${key} (set SSH_KEY or SSH_PUBKEY)"
    SSH_PUBKEY="$(head -n1 "$key")"
  fi
  [[ "$SSH_PUBKEY" == ssh-* ]] || die "SSH_PUBKEY does not look like an SSH public key"
}

write_ssh_key_file() {
  SSH_KEY_FILE="$(mktemp "${TMPDIR:-/tmp}/k8s-proxmox-key.XXXXXX")"
  printf '%s\n' "$SSH_PUBKEY" >"$SSH_KEY_FILE"
  # shellcheck disable=SC2064
  trap "rm -f '${SSH_KEY_FILE}'" EXIT
}

remote_mode() {
  [[ -n "$PVE_HOST" && "${PVE_REMOTE:-0}" != "1" ]]
}

forward_env() {
  local -a fwd=()
  local var
  for var in K8S_NAME NODE_COUNT VMID_START K8S_TAG PVE_POOL TEMPLATE_ID TEMPLATE_NAME \
    IMAGE_URL IMAGE_FILE DISK_STORAGE DISK_SIZE CPU_CORES CPU_TYPE RAM_MB BRIDGE VLAN_TAG \
    IP_PREFIX IP_START CIDR GATEWAY NAMESERVER CI_USER SSH_PUBKEY WAIT_TIMEOUT FORCE; do
    if [[ -n "${!var:-}" ]]; then
      fwd+=("${var}=${!var}")
    fi
  done
  if ((${#fwd[@]})); then
    printf '%q ' "${fwd[@]}"
  fi
}

dispatch_remote() {
  log "Provisioning on ${PVE_HOST}"
  local env_str arg_str
  env_str="$(forward_env)"
  arg_str=""
  if ((${#ARGS[@]})); then
    arg_str="$(printf '%q ' "${ARGS[@]}")"
  fi
  # shellcheck disable=SC2029
  ssh "$PVE_HOST" "PVE_REMOTE=1 ${env_str}bash -s -- ${arg_str}" <"$SCRIPT_PATH"
}

# ---------------------------------------------------------------------------
# Proxmox side
# ---------------------------------------------------------------------------
check_proxmox() {
  command -v qm >/dev/null 2>&1 ||
    die "qm not found - run this on a Proxmox VE host or set PVE_HOST"
  [[ -d /etc/pve ]] || die "/etc/pve not found - this does not look like Proxmox VE"
  if command -v pvesm >/dev/null 2>&1; then
    pvesm status --storage "$DISK_STORAGE" >/dev/null 2>&1 ||
      die "storage '${DISK_STORAGE}' is not available (set DISK_STORAGE)"
  fi
  local ver
  ver="$(pveversion 2>/dev/null | sed -n 's|^pve-manager/\([0-9]\+\).*|\1|p' || true)"
  if [[ "$ver" =~ ^[0-9]+$ ]] && ((ver < 8)); then
    warn "Proxmox VE ${ver} detected; 8.x is recommended (--tags may be unsupported)"
  fi
}

ensure_template() {
  if qm status "$TEMPLATE_ID" >/dev/null 2>&1; then
    log "Reusing cloud-init template VM ${TEMPLATE_ID}"
    return 0
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required to download the cloud image"
  mkdir -p -- "$(dirname -- "$IMAGE_FILE")"
  if [[ -s "$IMAGE_FILE" ]]; then
    log "Reusing cloud image ${IMAGE_FILE}"
  else
    log "Downloading cloud image to ${IMAGE_FILE}"
    curl -fL --retry 3 -o "${IMAGE_FILE}.part" "$IMAGE_URL"
    mv -- "${IMAGE_FILE}.part" "$IMAGE_FILE"
  fi

  log "Creating cloud-init template VM ${TEMPLATE_ID} (${TEMPLATE_NAME})"
  qm create "$TEMPLATE_ID" \
    --name "$TEMPLATE_NAME" \
    --ostype l26 \
    --memory 2048 --cores 2 --cpu host \
    --scsihw virtio-scsi-pci \
    --net0 "virtio,bridge=${BRIDGE}" \
    --serial0 socket --vga serial0 \
    --agent enabled=1 \
    --description "cloud-init base image for ${K8S_NAME} nodes (created by ${SCRIPT_NAME})" >/dev/null

  qm importdisk "$TEMPLATE_ID" "$IMAGE_FILE" "$DISK_STORAGE" >/dev/null
  local vol
  vol="$(qm config "$TEMPLATE_ID" | awk -F': ' '/^unused[0-9]+:/ {print $2; exit}')"
  [[ -n "$vol" ]] || die "could not determine imported disk for VM ${TEMPLATE_ID}"

  qm set "$TEMPLATE_ID" \
    --scsi0 "$vol" \
    --ide2 "${DISK_STORAGE}:cloudinit" \
    --boot order=scsi0 \
    --ciuser "$CI_USER" \
    --citype nocloud >/dev/null
  qm template "$TEMPLATE_ID" >/dev/null
  log "Template ${TEMPLATE_ID} is ready"
}

create_node() {
  local idx="$1"
  local name="${NODE_NAMES[$idx]}"
  local vmid="${NODE_VMIDS[$idx]}"
  local ip="${NODE_IPS[$idx]}"

  if qm status "$vmid" >/dev/null 2>&1; then
    log "${name}: VM ${vmid} already exists - only refreshing cloud-init settings"
  else
    if ping -c1 -W1 "$ip" >/dev/null 2>&1 && [[ "$FORCE" != "1" ]]; then
      die "IP ${ip} is already answering; change IP_START or set FORCE=1"
    fi
    log "${name}: creating VM ${vmid} (${ip}/${CIDR})"
    local -a clone_args=(--name "$name" --full --storage "$DISK_STORAGE")
    if [[ -n "$PVE_POOL" ]]; then
      clone_args+=(--pool "$PVE_POOL")
    fi
    qm clone "$TEMPLATE_ID" "$vmid" "${clone_args[@]}" >/dev/null
    qm resize "$vmid" scsi0 "$DISK_SIZE" >/dev/null
    qm set "$vmid" --cores "$CPU_CORES" --memory "$RAM_MB" --cpu "$CPU_TYPE" >/dev/null
  fi

  local -a set_args=(
    --ciuser "$CI_USER"
    --ipconfig0 "ip=${ip}/${CIDR},gw=${GATEWAY}"
    --nameserver "$NAMESERVER"
    --onboot 1
    --description "managed by ${SCRIPT_NAME}: ${name} (${ip})"
  )
  if [[ -n "$SSH_KEY_FILE" ]]; then
    set_args+=(--sshkeys "$SSH_KEY_FILE")
  fi
  if [[ -n "$VLAN_TAG" ]]; then
    set_args+=(--net0 "virtio,bridge=${BRIDGE},tag=${VLAN_TAG}")
  fi
  qm set "$vmid" "${set_args[@]}" >/dev/null

  if [[ -n "$K8S_TAG" ]]; then
    qm set "$vmid" --tags "$K8S_TAG" >/dev/null 2>&1 ||
      warn "${name}: could not set tag '${K8S_TAG}' (ignored)"
  fi

  if ! qm status "$vmid" | grep -q running; then
    qm start "$vmid" >/dev/null
  fi
}

provision_all() {
  check_proxmox
  write_ssh_key_file
  ensure_template
  local i
  for ((i = 0; i < NODE_COUNT; i++)); do
    create_node "$i"
  done
  log "All ${NODE_COUNT} VMs are defined and started"
}

destroy_all() {
  check_proxmox
  log "Removing ${NODE_COUNT} VM(s) starting at VMID ${VMID_START}"
  local i vmid
  for ((i = 0; i < NODE_COUNT; i++)); do
    vmid="${NODE_VMIDS[$i]}"
    if ! qm status "$vmid" >/dev/null 2>&1; then
      log "VM ${vmid} does not exist - skipping"
      continue
    fi
    log "Destroying VM ${vmid}"
    qm stop "$vmid" --timeout 30 >/dev/null 2>&1 || true
    qm destroy "$vmid" --purge >/dev/null
  done
  log "Destroy complete"
}

# ---------------------------------------------------------------------------
# Kubernetes side (runs where the private key lives)
# ---------------------------------------------------------------------------
ssh_run() {
  local host="$1"
  shift
  ssh "${SSH_OPTS[@]}" "${CI_USER}@${host}" "$@"
}

wait_for_ssh() {
  local ip="$1" name="$2" vmid="$3"
  local deadline=$((SECONDS + WAIT_TIMEOUT))
  log "${name}: waiting for cloud-init to finish over SSH (${ip})"
  while ((SECONDS < deadline)); do
    if ssh_run "$ip" 'test -f /var/lib/cloud/instance/boot-finished' >/dev/null 2>&1; then
      log "${name}: ready"
      return 0
    fi
    sleep 5
  done
  die "${name}: SSH/cloud-init not ready after ${WAIT_TIMEOUT}s (inspect VM ${vmid} on the Proxmox host)"
}

bootstrap_k3s() {
  local server_name="${NODE_NAMES[0]}"
  local server_ip="${NODE_IPS[0]}"
  local api_host="${K8S_VIP:-$server_ip}"
  local k3s_env="K3S_TOKEN=${K3S_TOKEN}"
  if [[ -n "$K3S_VERSION" ]]; then
    k3s_env="INSTALL_K3S_VERSION=${K3S_VERSION} ${k3s_env}"
  else
    k3s_env="INSTALL_K3S_CHANNEL=${K3S_CHANNEL} ${k3s_env}"
  fi

  local i
  for ((i = 0; i < NODE_COUNT; i++)); do
    wait_for_ssh "${NODE_IPS[$i]}" "${NODE_NAMES[$i]}" "${NODE_VMIDS[$i]}"
  done

  if ssh_run "$server_ip" 'systemctl is-active --quiet k3s'; then
    log "${server_name}: k3s already active - skipping server install"
  else
    log "${server_name}: installing k3s server"
    local server_args="--write-kubeconfig-mode 644 --node-name ${server_name} --tls-san ${api_host}"
    ssh_run "$server_ip" \
      "curl -sfL https://get.k3s.io | sudo env ${k3s_env} sh -s - server ${server_args}"
  fi

  for ((i = 1; i < NODE_COUNT; i++)); do
    local ip="${NODE_IPS[$i]}"
    local name="${NODE_NAMES[$i]}"
    if ssh_run "$ip" 'systemctl is-active --quiet k3s-agent'; then
      log "${name}: k3s agent already active - skipping"
      continue
    fi
    log "${name}: joining cluster at https://${server_ip}:6443"
    ssh_run "$ip" \
      "curl -sfL https://get.k3s.io | sudo env ${k3s_env} K3S_URL=https://${server_ip}:6443 sh -s - agent --node-name ${name}"
  done

  log "Fetching kubeconfig from ${server_name}"
  local kubeconfig
  kubeconfig="$(ssh_run "$server_ip" 'sudo cat /etc/rancher/k3s/k3s.yaml')"
  [[ -n "$kubeconfig" ]] || die "could not read kubeconfig from ${server_name}"
  mkdir -p -- "$(dirname -- "$KUBECONFIG_OUT")"
  printf '%s\n' "$kubeconfig" |
    sed "s#https://127.0.0.1:6443#https://${api_host}:6443#" >"$KUBECONFIG_OUT"
  chmod 600 "$KUBECONFIG_OUT"
  log "kubeconfig written to ${KUBECONFIG_OUT}"
}

write_ansible_inventory() {
  local out="$INVENTORY_OUT"
  if [[ -z "$out" ]]; then
    [[ -n "$SCRIPT_PATH" ]] || die "set INVENTORY_OUT when the script path is unknown"
    out="$(cd -- "$(dirname -- "$SCRIPT_PATH")/.." && pwd)/ansible/rke2/inventory/proxmox.ini"
  fi
  mkdir -p -- "$(dirname -- "$out")"

  local i
  {
    printf '# generated by %s on %s\n' "$SCRIPT_NAME" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '[servers]\n'
    printf 'server1 ansible_host=%s\n' "${NODE_IPS[0]}"
    printf '\n[agents]\n'
    for ((i = 1; i < NODE_COUNT; i++)); do
      printf 'agent%d ansible_host=%s\n' "$i" "${NODE_IPS[$i]}"
    done
  } >"$out"

  log "Ansible inventory written to ${out}"
  printf '  next: cd ansible/rke2 && ansible-playbook site.yaml -i inventory/%s --key-file ~/.ssh/id_rsa -K\n' \
    "$(basename -- "$out")"
}

print_summary() {
  printf '\n'
  log "Kubernetes VMs (${NODE_COUNT})"
  local i
  for ((i = 0; i < NODE_COUNT; i++)); do
    printf '  %-8s %-16s vmid=%s\n' "${NODE_NAMES[$i]}" "${NODE_IPS[$i]}" "${NODE_VMIDS[$i]}"
  done
  case "$BOOTSTRAP" in
    k3s)
      printf '\n'
      log "Check the cluster with:"
      printf '  kubectl --kubeconfig %s get nodes -o wide\n' "$KUBECONFIG_OUT"
      ;;
    none)
      printf '\n'
      log "VMs only - bootstrap skipped (--provision-only)"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
confirm_destroy() {
  if [[ "$ASSUME_YES" == "1" ]]; then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    die "--destroy needs -y/--yes when there is no interactive terminal"
  fi
  printf 'Destroy VMIDs %s..%s? [y/N] ' "$VMID_START" "$((VMID_START + NODE_COUNT - 1))"
  local reply=""
  read -r reply || die "aborted"
  case "$reply" in
    y | Y | yes | YES) ;;
    *) die "aborted" ;;
  esac
}

main() {
  parse_args "$@"
  validate_config
  build_nodes
  resolve_ssh_pubkey

  # provisioning on a remote host never bootstraps: the Kubernetes steps always
  # run where the private key lives
  if [[ "${PVE_REMOTE:-0}" == "1" ]]; then
    BOOTSTRAP=none
  fi

  if [[ "$MODE" == "destroy" ]]; then
    confirm_destroy
    ASSUME_YES=1
    ARGS+=(-y)
  fi

  # a stable join token keeps re-runs idempotent; override with K3S_TOKEN to pin it
  if [[ -z "$K3S_TOKEN" && "$MODE" == "create" && "$BOOTSTRAP" == "k3s" ]]; then
    K3S_TOKEN="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
  fi

  if remote_mode; then
    dispatch_remote
  else
    case "$MODE" in
      destroy) destroy_all ;;
      create) provision_all ;;
    esac
  fi

  [[ "$MODE" == "create" ]] || exit 0

  case "$BOOTSTRAP" in
    k3s) bootstrap_k3s ;;
    ansible) write_ansible_inventory ;;
    none) ;;
  esac

  # the remote provisioning instance only reports its own work; the summary is
  # printed once by the machine that started the run
  if [[ "${PVE_REMOTE:-0}" != "1" ]]; then
    print_summary
  fi
}

main "$@"
