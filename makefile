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


deploy-apps: pull
	@echo "Deploying the apps stack..."
	$(loadenvs ./swarm/.env) && docker stack deploy --compose-file ./swarm/apps.yml apps

deploy-test: pull
	@echo "Deploying the apps stack..."
	$(loadenvs ./swarm/.env)
	docker stack deploy --compose-file ./swarm/thelounge.yml thelounge
# git submodule update --init --recursive