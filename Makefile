#!/usr/bin/make
# Makefile readme (ru): <http://linux.yaroslavl.ru/docs/prog/gnu_make_3-79_russian_manual.html>
# Makefile readme (en): <https://www.gnu.org/software/make/manual/html_node/index.html#SEC_Contents>

dc_bin := $(shell command -v docker-compose 2> /dev/null)
dc_app_name = app
cwd = $(shell pwd)

SHELL = /bin/bash
RUN_APP_ARGS = --rm --user "$(shell id -u):$(shell id -g)" "$(dc_app_name)"

.PHONY : help install 'shell' migrate test test-cover up down restart logs clean
.SILENT : help install up down 'shell'
.DEFAULT_GOAL : help

# This will output the help for each task. thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Show this help
	@printf "\033[33m%s:\033[0m\n" 'Available commands'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[32m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install all app dependencies
	$(dc_bin) run -e $(RUN_APP_ARGS) composer install --no-interaction --ansi --no-suggest --prefer-dist

shell: ## Start shell into app container
	$(dc_bin) run -e $(RUN_APP_ARGS) sh

migrate: ## Migrate application database and generate seeds
	$(dc_bin) run -e $(RUN_APP_ARGS) ./artisan migrate --force --seed

test: ## Execute app tests
	$(dc_bin) run $(RUN_APP_ARGS) composer test

test-cover: ## Execute app tests with coverage
	$(dc_bin) run --rm --user "0:0" "$(dc_app_name)" sh -c '\
		apk --no-cache add autoconf make g++ && pecl install xdebug-2.9.1 && docker-php-ext-enable xdebug \
		&& su $(shell whoami) -s /bin/sh -c "composer phpunit-cover"'

up: ## Create and start containers
	$(dc_bin) up --detach
	@printf "\n   \e[30;42m %s \033[0m\n\n" 'Navigate your browser to ⇒ http://127.0.0.1:4001';

down: ## Stop and remove containers, networks, images, and volumes
	$(dc_bin) down -t 5

restart: down up ## Restart all containers

logs: ## Show docker logs
	$(dc_bin) logs --follow

clean: ## Make some clean
	-$(dc_bin) run -e $(RUN_APP_ARGS) composer clear
	$(dc_bin) down -v -t 5
