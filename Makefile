.PHONY: setup build up down clean shell

REPO_URL=https://github.com/moode-player/moode.git

setup:
	git submodule update --init --recursive

build: setup
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

clean:
	docker compose down -v
	rm -rf source

shell:
	docker compose exec moode bash
