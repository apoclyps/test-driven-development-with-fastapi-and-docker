.PHONY: help build run start debug stop clean logs shell network lint test package artifact publish release migrate deploy docs

default: help

HEROKU_DEPLOYMENT = "tdd-fastapi-with-docker"
USERNAME = "apoclyps"

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

db.upgrade:  ## upgrade the database schema
	@docker-compose run --rm web aerich upgrade

db.downgrade:  ## upgrade the database schema
	@docker-compose run --rm web aerich downgrade

shell: ## shell into a development container
	@docker-compose build web
	@docker-compose run --rm web sh

network: ## Create the network if it doesn't exist
	docker network create --driver bridge ttdwithfastapi || true

lint: ## lint and autocorrect the code
	@docker-compose build web
	@docker-compose run --rm --no-deps web sh -c "black . && isort . && flake8 ."

test: build network unit-test integration-test ## Run the unit tests and linters
	@echo "Test run complete"

unit-test: build network ## Run the unit tests and linters
	@echo "Running unit tests"
	@docker-compose run --rm web sh -c "pytest tests/unit -s -vvv -n auto --cov="." tests && black --check --diff . && isort --check-only --diff . && flake8 ."

integration-test: build network ## Run the unit tests and linters
	@echo "Running integration tests"
	@docker-compose run --rm web sh -c "pytest tests/integration -s -vvv  --cov="." tests && black --check --diff . && isort --check-only --diff . && flake8 ."

test-shell: ## Spin up a shell in a container
	@docker-compose build web
	@docker-compose run --rm web sh

unit: ## Run a single unittest or file e.g. `make unit test=test.py::test`
	@docker-compose run --rm web pytest -s -vvv $(test)

package:  # Publish Image to Github Registry
	@docker build -f src/Dockerfile.prod -t docker.pkg.github.com/apoclyps/test-driven-development-with-fastapi-and-docker/summarizer:latest ./src
	@docker login docker.pkg.github.com -u ${USERNAME} -p ${CI_TOKEN}
	@docker push docker.pkg.github.com/apoclyps/test-driven-development-with-fastapi-and-docker/summarizer:latest

artifact: ## Build a production container (to be publish to the Heroku Container Registry)
	@echo "Building the application"
	@docker build -f src/Dockerfile.prod -t registry.heroku.com/$(HEROKU_DEPLOYMENT)/web ./src

publish: ## Publish the latest version of the application to Heroku Container Registry
	@echo "Pushing the application"
	@docker tag registry.heroku.com/$(HEROKU_DEPLOYMENT)/web registry.heroku.com/$(HEROKU_DEPLOYMENT)/web:latest
	@docker push registry.heroku.com/$(HEROKU_DEPLOYMENT)/web:latest

release: ## Deploy the latest version of the application to Heroku
	@echo "Deploying the application"
	@heroku container:release web --app $(HEROKU_DEPLOYMENT)

migrate: ## Run the database migrations
	@echo "Running migrations"
	@heroku run aerich upgrade --app $(HEROKU_DEPLOYMENT)

deploy: artifact publish release migrate ## Performs a deployment to Heroku
	@echo "Deployment complete"

docs: ## Open the documentation in the browser
	@echo "Opening the documentation"
	@heroku open --app $(HEROKU_DEPLOYMENT) /docs
