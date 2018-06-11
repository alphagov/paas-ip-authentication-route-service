# Reliability Engineering IP Whitelisting Route Service

This application contains a simple Nginx application which acts as a proxy for your web applications and provides an IP restriction layer.

All PaaS traffic will go through the route service therefore we can completely protect and/or filter traffic with this service.

## Requirements

* Cloud Foundry CLI (https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)
* The manifest template is generated using Ruby ERB therefore Ruby needs to be installed.

You should log in using the Cloud Foundry CLI (https://docs.cloud.service.gov.uk/#setting-up-the-command-line).

For all actions you should always have to make sure you selected the space you intend to target.

## Deployment

The default application name is `re-ip-whitelist-service`. If you want to change this (or you want to deploy multiple route services), set the `PAAS_APP_NAME` environment variable for the make commands.

The default domain name is `cloudapps.digital`. If you want to change this (or you want to bind to different domains), set the `PAAS_DOMAIN` environment variable for the make commands.

Before deploying the service, make a copy of the `environment_sample.sh` to `environment.sh`, then set the environment variables:

```
export ENV=<your test environment name, or staging / production>
export IP_WHITELIST=<the range of comma delimited IPs to allow access to the bound app>
```

Set the environment variables by sourcing it: 

`source environment.sh`

The instance count can be set with the `PAAS_INSTANCES` environment variable (1 by default).

## Deploying the route service application

```
make paas-push
```

## Development process

### Registering the application as a user-provided service

You only need to do this once per PaaS space.

```
make paas-create-route-service
```

### Register the application as a route-service for a route

You only need to do this once per PaaS space and for all routes.

```
make paas-bind-route-service PAAS_ROUTE=<route of your application>
```

### Complete installation example

In this example we are deploying the route service to preview and binding two applications to it, which are accessible on `app-01.cloudapps.digital` and `app-02.cloudapps.digital`.

```
# First installation:
make paas-push
make paas-create-route-service

# Run this for every applicaton once:
make paas-bind-route-service PAAS_ROUTE=app-01
make paas-bind-route-service PAAS_ROUTE=app-02
```

### Test that the application is IP whitelisted

`curl` your application to see whether the IP is accessible using a machine within the IP whitelist, and that access is blocked outside of the IP whitelist.

## How to IP whitelist your application with the production route service

### Registering the application as a user-provided service

You only need to do this once per PaaS space.

```
cf create-user-provided-service re-ip-whitelist-service -r https://re-ip-whitelist-service-production.cloudapps.digital
```

### Register the application as a route-service for a route

You need to do this for all routes in your targeted space.

```
cf bind-route-service cloudapps.digital re-ip-whitelist-service --hostname <your paas app route>
```
