#!/usr/bin/env bash
set -euo pipefail

BOUNCER_NAME="${CROWDSEC_BOUNCER_NAME:-traefik-bouncer}"
BOUNCER_KEY="${CROWDSEC_BOUNCER_KEY:-}"
SERVICE_NAME="crowdsec_crowdsec"

if [[ -z "$BOUNCER_KEY" ]]; then
  echo "CROWDSEC_BOUNCER_KEY is not set. Export it or source swarm/.env first."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command not found in PATH."
  exit 1
fi

container_id="$(docker ps --filter "label=com.docker.swarm.service.name=${SERVICE_NAME}" --format '{{.ID}}' | head -n1)"

if [[ -z "$container_id" ]]; then
  echo "No running CrowdSec LAPI task found for service ${SERVICE_NAME}."
  echo "Deploy CrowdSec first: make deploy-crowdsec"
  exit 1
fi

if docker exec "$container_id" cscli bouncers list 2>/dev/null | grep -q "$BOUNCER_NAME"; then
  echo "Bouncer '${BOUNCER_NAME}' is already registered."
  exit 0
fi

echo "Registering bouncer '${BOUNCER_NAME}' on ${SERVICE_NAME}..."
docker exec "$container_id" cscli bouncers add "$BOUNCER_NAME" --key "$BOUNCER_KEY"
echo "Bouncer registration complete."
