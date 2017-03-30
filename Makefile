.DEFAULT_GOAL := help
SHELL := /bin/bash

PAAS_ORG = govuk-notify
PAAS_APP_NAME ?= route-service
PAAS_DOMAIN ?= cloudapps.digital

$(eval export PAAS_APP_NAME=${PAAS_APP_NAME})

.PHONY: help
help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: generate-manifest
generate-manifest: ## Generates the PaaS manifest file
	$(if ${PAAS_SPACE},,$(error Must specify PAAS_SPACE))
	$(if ${NOTIFY_CREDENTIALS},,$(error Must specify NOTIFY_CREDENTIALS))
	ALLOWED_IPS=$$(PASSWORD_STORE_DIR=${NOTIFY_CREDENTIALS} pass "credentials/${PAAS_SPACE}/paas/allowed_ips") erb manifest.yml.erb

.PHONY: preview
preview: ## Set PaaS space to preview
	$(eval export PAAS_SPACE=preview)
	@true

.PHONY: staging
staging: ## Set PaaS space to staging
	$(eval export PAAS_SPACE=staging)
	$(eval export PAAS_INSTANCES=2)
	@true

.PHONY: production
production: ## Set PaaS space to production
	$(eval export PAAS_SPACE=production)
	$(eval export PAAS_INSTANCES=2)
	@true

.PHONY: paas-login
paas-login: ## Log in to PaaS
	$(if ${PAAS_USERNAME},,$(error Must specify PAAS_USERNAME))
	$(if ${PAAS_PASSWORD},,$(error Must specify PAAS_PASSWORD))
	$(if ${PAAS_SPACE},,$(error Must specify PAAS_SPACE))
	mkdir -p ${CF_HOME}
	@cf login -a "${PAAS_API}" -u ${PAAS_USERNAME} -p "${PAAS_PASSWORD}" -o "${PAAS_ORG}" -s "${PAAS_SPACE}"

.PHONY: paas-push
paas-push: ## Pushes the app to Cloud Foundry (causes downtime!)
	cf push -f <(make -s generate-manifest)

.PHONY: paas-deploy
paas-deploy: ## Deploys the app to Cloud Foundry without downtime
	$(if ${PAAS_SPACE},,$(error Must specify PAAS_SPACE))
	@cf app --guid ${PAAS_APP_NAME} || exit 1
	cf rename ${PAAS_APP_NAME} ${PAAS_APP_NAME}-rollback
	cf push -f <(make -s generate-manifest)
	cf scale -i $$(cf curl /v2/apps/$$(cf app --guid ${PAAS_APP_NAME}) | jq -r ".entity.instances" 2>/dev/null || echo "1") ${PAAS_APP_NAME}
	cf stop ${PAAS_APP_NAME}-rollback
	cf delete -f ${PAAS_APP_NAME}-rollback

.PHONY: paas-rollback
paas-rollback: ## Rollbacks the app to the previous release
	@cf app --guid ${PAAS_APP_NAME}-rollback || exit 1
	@[ $$(cf curl /v2/apps/`cf app --guid ${PAAS_APP_NAME}-rollback` | jq -r ".entity.state") = "STARTED" ] || (echo "Error: rollback is not possible because ${PAAS_APP_NAME}-rollback is not in a started state" && exit 1)
	cf delete -f ${PAAS_APP_NAME} || true
	cf rename ${PAAS_APP_NAME}-rollback ${PAAS_APP_NAME}

.PHONY: paas-create-route-service
paas-create-route-service: ## Creates the route service
	$(if ${PAAS_SPACE},,$(error Must specify PAAS_SPACE))
	cf create-user-provided-service ${PAAS_APP_NAME} -r https://notify-${PAAS_APP_NAME}-${PAAS_SPACE}.cloudapps.digital

.PHONY: paas-bind-route-service
paas-bind-route-service: ## Binds the route service to the given route
	$(if ${PAAS_ROUTE},,$(error Must specify PAAS_ROUTE))
	cf bind-route-service ${PAAS_DOMAIN} ${PAAS_APP_NAME} --hostname ${PAAS_ROUTE}
