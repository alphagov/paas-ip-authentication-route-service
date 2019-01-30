# Reliability Engineering IP Whitelisting Route Service

This application contains a simple Nginx application which acts as a proxy for your web applications and provides an IP restriction layer.

All PaaS traffic will go through the route service therefore we can completely protect and/or filter traffic with this service.

## Requirements

* Cloud Foundry CLI (https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)
* The manifest template is generated using Ruby ERB therefore Ruby needs to be installed.

You should log in using the Cloud Foundry CLI (https://docs.cloud.service.gov.uk/#setting-up-the-command-line).

For all actions you should always make sure you selected the space you intend to target.

## Quick demo

This example uses the Python Flask example from the [hello world examples](https://github.com/18f/cf-hello-worlds),
`flask-example` deployed with `cf push --random-route`. Test it with `curl`, for example:

```sh
CURRENT_APP=flask-example
URL=$(cf curl /v2/apps/$(cf app --guid $CURRENT_APP)/summary | jq -r '.routes[0] | @uri "https://\(.host).\(.domain.name)"')
curl $URL
```

Copy `environment_samples.sh` to `environment.sh`. Edit it for cloud.gov so it looks something like this:

```sh
### environment.sh ###
# Hope for a unique route by using your current username
export ENV=$(whoami | sed -e 's/\.//g')

# Allow all ipv4 addresses
export IP_WHITELIST=0.0.0.0/0 

# Or, allow current IP address
# export IP_WHITELIST=$(dig +short myip.opendns.com)

# Override `cloudapps.digital` default
export PAAS_DOMAIN=app.cloud.gov

# Set CURRENT_APP to name of app you want provide IP filtering for
CURRENT_APP=flask-example

# This sets PAAS_ROUTE to current route for CURRENT_APP (don't change)
export PAAS_ROUTE=$(cf curl /v2/apps/$(cf app --guid $CURRENT_APP)/summary | jq -r '.routes[0].host')
```

Now you can `source` the environment file, push the route service and bind it:

```sh
source environment.sh
make paas-push
make paas-create-route-service
make paas-bind-route-service
```

You can now test the whitelisting. If you've selected `IP_WHITELIST=0.0.0.0/0` you can change it
to just allow your current IP addreess with:

```sh
export IP_WHITELIST=$(dig +short myip.opendns.com)
make paas-push
```


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

```shell
make paas-push

# or to deploy to staging
make staging-paas-push

# or to deploy to production
make prod-paas-push
```

## Development process

### Registering the application as a user-provided service

You only need to do this once per PaaS space.

```shell
make paas-create-route-service

# or to register the staging route service
make staging-paas-create-route-service

# or to register the production route service
make prod-paas-create-route-service
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
