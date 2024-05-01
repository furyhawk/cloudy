
# Makefile for the project

# Variables

# Commands
serve: down
	@echo "Serving the project..."
	docker compose -f production.yml -f ./flarum/docker-compose.yml -f ./emqx-docker/docker-compose.yml -f ./LibreChat/docker-compose.yml -f ./LibreChat/docker-compose.override.yml up --build -d
down: pull
	@echo "Stopping the project..."
	docker compose -f production.yml -f ./flarum/docker-compose.yml -f ./emqx-docker/docker-compose.yml -f ./LibreChat/docker-compose.yml -f ./LibreChat/docker-compose.override.yml down --remove-orphans

pull:
	@echo "Pulling the project..."
	git pull
	git submodule update --init --recursive