.PHONY: setup build up down clean shell

REPO_URL=https://github.com/moode-player/moode.git

setup:
	@if [ ! -d "source" ]; then \
		echo "Cloning Moode Audio source..."; \
		git clone --depth 1 $(REPO_URL) source; \
	else \
		echo "Source already present."; \
	fi

build: setup
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

clean:
	docker-compose down -v
	rm -rf source

shell:
	docker-compose exec moode bash
