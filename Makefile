.DEFAULT_GOAL := help
SHELL := /bin/bash

PAAS_ORG = gds-tech-ops
PAAS_APP_NAME ?= re-whitelist-route-service
PAAS_DOMAIN ?= cloudapps.digital

$(eval export PAAS_APP_NAME=${PAAS_APP_NAME})

.PHONY: help
help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: generate-manifest
generate-manifest: ## Generates the PaaS manifest file
	ALLOWED_IPS=${PROMETHEUS_IP_LIST} erb manifest.yml.erb

.PHONY: paas-login
paas-login: ## Log in to PaaS
	$(if ${PAAS_USERNAME},,$(error Must specify PAAS_USERNAME))
	$(if ${PAAS_PASSWORD},,$(error Must specify PAAS_PASSWORD))

	mkdir -p ${CF_HOME}
	@cf login -a "${PAAS_API}" -u ${PAAS_USERNAME} -p "${PAAS_PASSWORD}" -o "${PAAS_ORG}" -s "${PAAS_SPACE}"

.PHONY: paas-push
paas-push: ## Pushes the app to Cloud Foundry (causes downtime!)
	cf push -f <(make -s generate-manifest)

.PHONY: paas-create-route-service
paas-create-route-service: ## Creates the route service
	cf create-user-provided-service ${PAAS_APP_NAME} -r https://${PAAS_APP_NAME}.cloudapps.digital

.PHONY: paas-bind-route-service
paas-bind-route-service: ## Binds the route service to the given route
	$(if ${PAAS_ROUTE},,$(error Must specify PAAS_ROUTE))
	cf bind-route-service ${PAAS_DOMAIN} ${PAAS_APP_NAME} --hostname ${PAAS_ROUTE}
