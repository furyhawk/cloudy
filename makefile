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

deploy-services: pull
	@echo "Deploying the services stack..."
	$(loadenvs ./swarm/.env)
	docker stack deploy --compose-file ./swarm/services.yml services

deploy-apps: pull
	@echo "Deploying the apps stack..."
	$(loadenvs ./swarm/.env)
	docker stack deploy --compose-file ./swarm/apps.yml apps

deploy-ghost: pull
	{ \
	echo "Deploying the ghost stack..." ;\
	set -a ;\
	. ./swarm/.env ;\
	set +a ;\
	docker stack deploy --compose-file ./swarm/ghost.yml ghost ;\
	}

deploy-test: pull
	@echo "Deploying the test stack..."
	$(loadenvs ./swarm/.env)
	docker stack deploy --compose-file ./swarm/thelounge.yml thelounge
# git submodule update --init --recursive