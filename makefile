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

deploy-core: pull
	{ \
	echo "Deploying the core stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/core.yml core ;\
	}

deploy-portainer: pull
	{ \
	echo "Deploying the portainer stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/portainer.yml portainer ;\
	}

deploy-services: pull
	{ \
	echo "Deploying the services stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/services.yml services ;\
	}

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
	docker stack deploy --compose-file ./swarm/secondary.yml secondary ;\
	}

deploy-ghost: pull
	{ \
	echo "Deploying the ghost stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/ghost.yml ghost ;\
	}

deploy-thelounge: pull
	{ \
	echo "Deploying the thelounge stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/thelounge.yml thelounge ;\
	}
# git submodule update --init --recursive