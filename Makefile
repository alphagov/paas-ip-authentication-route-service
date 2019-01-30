.DEFAULT_GOAL := help
SHELL := /bin/bash

export PAAS_APP_NAME ?= re-ip-whitelist-service
export PAAS_DOMAIN ?= cloudapps.digital
export PAAS_INSTANCES ?= 1

.PHONY: help
help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: generate-manifest
generate-manifest: ## Generates the PaaS manifest file
	ALLOWED_IPS=${IP_WHITELIST} erb manifest.yml.erb

.PHONY: paas-push
paas-push: ## Pushes the app to Cloud Foundry (causes downtime!)
	# Make sure that the ENV environment variable is set either to a test environment name or staging/production
	$(if ${ENV},,$(error Must specify ENV))
	cf push -f <(make -s generate-manifest)

.PHONY: paas-teardown
paas-teardown: ## Removes the routing service (causes downtime!)
	$(if ${PAAS_ROUTE},,$(error Must specify PAAS_ROUTE))
	cf unbind-route-service ${PAAS_DOMAIN} ${PAAS_APP_NAME} --hostname ${PAAS_ROUTE}
	cf delete ${PAAS_APP_NAME}

.PHONY: staging-paas-push
staging-paas-push: ## Pushes the app to prometheus-staging in Cloud Foundry (causes downtime!)
	cf target -s prometheus-staging
	make paas-push ENV=staging

.PHONY: prod-paas-push
prod-paas-push: ## Pushes the app to prometheus-production in Cloud Foundry (causes downtime!)
	cf target -s prometheus-production
	make paas-push ENV=production

.PHONY: paas-create-route-service
paas-create-route-service: ## Creates the route service
	# Make sure that the ENV environment variable is set either to a test environment name or staging/production
	$(if ${ENV},,$(error Must specify ENV))
	# For the production environment don't set it as part of the app name
	$(if $(filter ${ENV},production),,$(eval export PAAS_APP_NAME=${PAAS_APP_NAME}-${ENV}))
	cf create-user-provided-service ${PAAS_APP_NAME} -r https://${PAAS_APP_NAME}.${PAAS_DOMAIN}

.PHONY: staging-paas-create-route-service
staging-paas-create-route-service: ## Creates the staging route service
	cf target -s prometheus-staging
	make paas-create-route-service ENV=staging

.PHONY: prod-paas-create-route-service
prod-paas-create-route-service: ## Creates the production route service
	cf target -s prometheus-production
	make paas-create-route-service ENV=production

.PHONY: paas-bind-route-service
paas-bind-route-service: ## Binds the route service to the given route
	$(if ${PAAS_ROUTE},,$(error Must specify PAAS_ROUTE))
	# Make sure that the ENV environment variable is set either to a test environment name or staging/production
	$(if ${ENV},,$(error Must specify ENV))
	# For the production environment don't set it as part of the app name
	$(if $(filter ${ENV},production),,$(eval export PAAS_APP_NAME=${PAAS_APP_NAME}-${ENV}))
	cf bind-route-service ${PAAS_DOMAIN} ${PAAS_APP_NAME} --hostname ${PAAS_ROUTE}
