.PHONY: help build run start debug stop clean logs shell network lint test

default: help

build: ## Build the web container
	@docker-compose build web

help: ## show this help
	@echo
	@fgrep -h " ## " $(MAKEFILE_LIST) | fgrep -v fgrep | sed -Ee 's/([a-z.]*):[^#]*##(.*)/\1##\2/' | column -t -s "##"
	@echo

run: start logs ## run the application locally

start: ## run the application locally in the background
	@docker-compose up --build --detach web

debug: start ## run the application locally in debug mode
	@docker attach $$(docker-compose ps --quiet web)

stop: ## stop the application
	@docker-compose down --remove-orphans

clean: ## delete all data from the local database
	@docker-compose down --remove-orphans --volumes

logs: ## show the application logs
	@docker-compose logs --follow web

shell: ## shell into a development container
	@docker-compose build web
	@docker-compose run --rm web sh

network: ## Create the network if it doesn't exist
	docker network create --driver bridge ttdwithfastapi || true

lint: ## lint and autocorrect the code
	@docker-compose build web
	@docker-compose run --rm --no-deps web sh -c "black . && isort . && flake8 ."

test: build network ## Run the unit tests and linters
	@docker-compose run --rm web sh -c "pytest -s -vvv tests && black --check --diff . && isort --check-only --diff . && flake8 ."

test-shell: ## Spin up a shell in the test container
	@docker-compose build web
	@docker-compose run --rm web sh

unit: ## Run a single unittest or file e.g. `make unit test=test.py::test`
	@docker-compose run --rm web pytest -s -vvv $(test)
