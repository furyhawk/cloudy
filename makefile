# Makefile for the project

# Variables

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
	cp ./swarm/glance/glance.yml /var/data/glance.yml ;\
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

# git submodule update --init --recursive