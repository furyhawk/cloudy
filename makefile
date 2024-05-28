# Makefile for the project

# Variables

# Commands
serve: down
	@echo "Serving the project..."
	docker compose -f compose.yml up -d --build traefik
	docker compose -f compose.yml up -d
down: pull
	@echo "Stopping the project..."
	docker compose -f compose.yml down --remove-orphans

pull:
	@echo "Pulling the project..."
	git pull
	git submodule update --init --recursive