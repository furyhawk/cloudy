# Makefile for the project

# Variables

# Log window for `logs-traefik` / `logs-traefik-follow`, override with `make logs-traefik SINCE=30m`
SINCE ?= 10m

# Commands
serve: pull
	@echo "Serving the project..."
	docker compose -f compose.yml up -d --build --pull always
down: pull
	@echo "Stopping the project..."
	docker compose -f compose.yml down --remove-orphans

pull:
	@echo "Pulling the project..."
	git pull

deploy-local-core: pull
	{ \
	echo "Deploying the core stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/local_core.yml core ;\
	}
deploy-core: pull
	{ \
	echo "Deploying the core stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/core.yml core ;\
	}
remove-core:
	docker stack rm core

logs-traefik:
	@echo "Showing Traefik logs since $(SINCE)..."
	docker service logs --since $(SINCE) core_traefik

logs-traefik-follow:
	@echo "Following Traefik logs (Ctrl+C to stop)..."
	docker service logs -f --since $(SINCE) core_traefik

setup-crowdsec:
	{ \
	echo "Setting up crowdsec config on host..." ;\
	mkdir -p /mnt/data/crowdsec /mnt/data/crowdsec/scenarios ;\
	cmp -s ./swarm/crowdsec/acquis.yaml /mnt/data/crowdsec/acquis.yaml 2>/dev/null || cp ./swarm/crowdsec/acquis.yaml /mnt/data/crowdsec/acquis.yaml ;\
	cmp -s ./swarm/crowdsec/whitelists.yaml /mnt/data/crowdsec/whitelists.yaml 2>/dev/null || cp ./swarm/crowdsec/whitelists.yaml /mnt/data/crowdsec/whitelists.yaml ;\
	cmp -s ./swarm/crowdsec/profiles.yaml /mnt/data/crowdsec/profiles.yaml 2>/dev/null || cp ./swarm/crowdsec/profiles.yaml /mnt/data/crowdsec/profiles.yaml ;\
	cmp -s ./swarm/crowdsec/scenarios/http-ai-crawler.yaml /mnt/data/crowdsec/scenarios/http-ai-crawler.yaml 2>/dev/null || cp ./swarm/crowdsec/scenarios/http-ai-crawler.yaml /mnt/data/crowdsec/scenarios/http-ai-crawler.yaml ;\
	}

deploy-crowdsec: pull setup-crowdsec
	{ \
	echo "Deploying the crowdsec stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/crowdsec.yml crowdsec ;\
	}

register-crowdsec-bouncer:
	{ \
	echo "Registering crowdsec traefik bouncer..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	bash ./scripts/register-crowdsec-bouncer.sh ;\
	}

enroll-crowdsec:
	{ \
	echo "Enrolling CrowdSec in the console..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	cid="$$(docker ps --filter label=com.docker.swarm.service.name=crowdsec_crowdsec -q | head -n1)" ;\
	if [ -z "$$cid" ]; then \
		echo "crowdsec_crowdsec is not running, deploy it first: make deploy-crowdsec" ;\
		exit 1 ;\
	fi ;\
	docker exec "$$cid" cscli console enroll \
		--name "$${CROWDSEC_ENROLL_INSTANCE_NAME:-swarm-edge-01}" \
		--tags "$${CROWDSEC_ENROLL_TAGS:-swarm,traefik,production}" \
		"$${CROWDSEC_ENROLL_KEY:?CROWDSEC_ENROLL_KEY is not set in swarm/.env}" ;\
	}

deploy-crowdsec-all: deploy-crowdsec register-crowdsec-bouncer deploy-core
	@echo "CrowdSec + bouncer registration + core deploy completed."

remove-crowdsec:
	docker stack rm crowdsec

deploy-portainer: pull
	{ \
	echo "Deploying the portainer stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/portainer.yml portainer ;\
	}

deploy-swarmpit: pull
	{ \
	echo "Deploying the swarmpit stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/swarmpit.yml swarmpit ;\
	}

deploy-services: pull
	{ \
	echo "Deploying the services stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/services.yml services ;\
	}

deploy-authentik: pull
	{ \
	echo "Deploying the authentik stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/authentik.yml authentik ;\
	}
remove-authentik:
	docker stack rm authentik
deploy-apps: pull
	{ \
	echo "Deploying the apps stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/apps.yml apps ;\
	}
deploy-secondary: pull
	{ \
	echo "Deploying the secondary stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	cp ./swarm/glance/glance.yml /mnt/data/glance.yml ;\
	docker stack deploy --compose-file ./swarm/secondary.yml secondary ;\
	}
deploy-adguardhome: pull
	{ \
	echo "Deploying the adguardhome stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/adguardhome.yml adguardhome ;\
	}
deploy-emqx: pull
	{ \
	echo "Deploying the emqx stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/emqx.yml emqx ;\
	}
deploy-ghost: pull
	{ \
	echo "Deploying the ghost stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/ghost.yml ghost ;\
	}
deploy-librechat: pull
	{ \
	echo "Deploying the librechat stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/librechat.yml librechat ;\
	}
deploy-mailserver: pull
	{ \
	echo "Deploying the mailserver stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/mailserver.yml mailserver ;\
	}
deploy-openwebui: pull
	{ \
	echo "Deploying the openwebui stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/openwebui.yml openwebui ;\
	}
deploy-thelounge: pull
	{ \
	echo "Deploying the thelounge stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/thelounge.yml thelounge ;\
	}
deploy-searxng: pull
	{ \
	echo "Deploying the searxng stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/searxng.yml searxng ;\
	}
deploy-docmost: pull
	{ \
	echo "Deploying the docmost stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/docmost.yml docmost ;\
	}
deploy-outline: pull
	{ \
	echo "Deploying the outline stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/outline.yml outline ;\
	}
deploy-wekan: pull
	{ \
	echo "Deploying the wekan stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/wekan.yml wekan ;\
	}
deploy-semaphore: pull
	{ \
	echo "Deploying the semaphore stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/semaphore.yml semaphore ;\
	}
deploy-seafile: pull
	{ \
	echo "Deploying the seafile stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/seafile.yml seafile ;\
	}
deploy-nextcloud: pull
	{ \
	echo "Deploying the nextcloud stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/nextcloud.yml nextcloud ;\
	}
deploy-jellyfin: pull
	{ \
	echo "Deploying the jellyfin stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/jellyfin.yml jellyfin ;\
	}
deploy-esphome: pull
	{ \
	echo "Deploying the esphome stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/esphome.yml esphome ;\
	}
deploy-homeassistant: pull
	{ \
	echo "Deploying the homeassistant stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/homeassistant.yml homeassistant ;\
	}
deploy-gitea: pull
	{ \
	echo "Deploying the gitea stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/gitea.yml gitea ;\
	}
setup-grafana:
	{ \
	echo "Setting up grafana config on host..." ;\
	mkdir -p /mnt/data/grafana/provisioning/datasources /mnt/data/grafana/provisioning/dashboards /mnt/data/grafana/dashboards ;\
	cmp -s ./swarm/grafana/grafana.ini /mnt/data/grafana/grafana.ini 2>/dev/null || cp ./swarm/grafana/grafana.ini /mnt/data/grafana/grafana.ini ;\
	cmp -s ./swarm/grafana/provisioning/datasources/prometheus.yml /mnt/data/grafana/provisioning/datasources/prometheus.yml 2>/dev/null || cp ./swarm/grafana/provisioning/datasources/prometheus.yml /mnt/data/grafana/provisioning/datasources/prometheus.yml ;\
	cmp -s ./swarm/grafana/provisioning/dashboards/default.yml /mnt/data/grafana/provisioning/dashboards/default.yml 2>/dev/null || cp ./swarm/grafana/provisioning/dashboards/default.yml /mnt/data/grafana/provisioning/dashboards/default.yml ;\
	cmp -s ./swarm/grafana/dashboards/prometheus-overview.json /mnt/data/grafana/dashboards/prometheus-overview.json 2>/dev/null || cp ./swarm/grafana/dashboards/prometheus-overview.json /mnt/data/grafana/dashboards/prometheus-overview.json ;\
	cmp -s ./swarm/grafana/dashboards/crowdsec-overview.json /mnt/data/grafana/dashboards/crowdsec-overview.json 2>/dev/null || cp ./swarm/grafana/dashboards/crowdsec-overview.json /mnt/data/grafana/dashboards/crowdsec-overview.json ;\
	cmp -s ./swarm/grafana/dashboards/traefik-overview.json /mnt/data/grafana/dashboards/traefik-overview.json 2>/dev/null || cp ./swarm/grafana/dashboards/traefik-overview.json /mnt/data/grafana/dashboards/traefik-overview.json ;\
	}
deploy-grafana: pull setup-grafana
	{ \
	echo "Deploying the grafana stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/grafana.yml grafana ;\
	}
deploy-prometheus: pull setup-prometheus
	{ \
	echo "Deploying the prometheus stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/prometheus.yml prometheus ;\
	}
setup-prometheus:
	{ \
	echo "Setting up prometheus config on host..." ;\
	mkdir -p /mnt/data/prometheus ;\
	cmp -s ./swarm/prometheus/prometheus.yml /mnt/data/prometheus/prometheus.yml 2>/dev/null || cp ./swarm/prometheus/prometheus.yml /mnt/data/prometheus/prometheus.yml ;\
	}
deploy-monitoring: pull setup-grafana setup-prometheus
	{ \
	echo "Deploying the monitoring stack (prometheus + grafana)..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/prometheus-grafana.yml monitoring ;\
	}
deploy-nodepad: pull
	{ \
	echo "Building the nodepad image..." ;\
	docker build -t nodepad:latest -f ./swarm/inline.Dockerfile ./swarm ;\
	echo "Deploying the nodepad stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/nodepad.yml nodepad ;\
	}
deploy-cinder: pull
	{ \
	echo "Deploying the cinder stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/cinder.yml cinder ;\
	}

k8s-provision:
	@echo "Provisioning Kubernetes VMs on Proxmox..."
	bash ./scripts/create-k8s-proxmox.sh

k8s-setup:
	@echo "Applying Kubernetes setup phase..."
	kubectl apply -k ./kubernetes/swarm-converted/phases/setup

k8s-up:
	@echo "Applying Kubernetes up phase..."
	kubectl apply -k ./kubernetes/swarm-converted/phases/up
# git submodule update --init --recursive