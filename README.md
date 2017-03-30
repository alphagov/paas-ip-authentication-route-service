# Notiy PaaS Route Service

This application contains a simple Nginx application which acts as a proxy for all Notify PaaS web applications and provides an IP restriction layer

All PaaS traffic will go through the route service therefore we can completely protect and/or filter traffic with this service.

## Requirements

* Cloud Foundry CLI (https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)
* The manifest template is generated using Ruby ERB therefore Ruby needs to be installed.

You should log in using the Cloud Foundry CLI (https://docs.cloud.service.gov.uk/#setting-up-the-command-line).

For all actions you should always have to make sure you selected the space you intend to target.

## Deployment

The default application name is "route-service". If you want to change this (or you want to deploy multiple route services), set the PAAS_APP_NAME environment variable for the make commands.

The default domain name is "cloudapps.digital". If you want to change this (or you want to bind to different domains), set the PAAS_DOMAIN environment variable for the make commands.

The secret values are read from the notifications-credentials repository using pass, so you have to set the NOTIFY_CREDENTIALS environment variable to your local credentials repository path. The values are read from paas/route-service-env.enc.

The instance count can be set with the PAAS_INSTANCES environment variable (1 by default).

## Deploying the route service application

If you're deploying the very first time, simply run:

```
make <PaaS space> paas-push
```

For zero-downtime deployments use the following command:

```
make <PaaS space> paas-deploy
```

If the zero-downtime deployment couldn't finish you can rollback to the previous version:

```
make <PaaS space> paas-rollback
```

## Registering the application as a user-provided service

You only need to do this once per PaaS space.

```
make <PaaS space> paas-create-route-service
```

## Register the application as a route-service for a route

You only need to do this once per PaaS space and for all routes.

make <PaaS space> paas-bind-route-service PAAS_ROUTE=<route of your application>

## Complete installation example

In this example we are deploying the route service to preview and binding two applications to it, which are accessible on app-01.cloudapps.digital and app-02.cloudapps.digital.

```
# First installation:
make preview paas-push
make preview paas-create-route-service

# Run this for every applicaton once
make preview paas-bind-route-service PAAS_ROUTE=app-01
make preview paas-bind-route-service PAAS_ROUTE=app-02

# For any future deployments only run:
make preview paas-deploy
```
