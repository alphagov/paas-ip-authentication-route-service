# GOV.UK PaaS IP authentication route service

This repo contains a simple Nginx application which acts as a proxy for your
web applications and provides an IP restriction layer.

This repo is a template, which you should customise according to your needs
using the application manifest.

All PaaS traffic will go through the route service to filter traffic.

## Requirements

* Cloud Foundry CLI (https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)

You should log in using the Cloud Foundry CLI
(https://docs.cloud.service.gov.uk/#setting-up-the-command-line).

For all actions you should always make sure you are targeting the correct
space.

## Customisation

Edit the `manifest.yml` and change the `ALLOWED_IPS` as appropriate.

## Deployment

To deploy the app, run `cf push`.

If you have not overwritten the `((app-name))` variables then you will need to
run `cf push --var app-name=my-app`

If you want to add a custom route, add a route definition to the manifest:

``` applications:
  - name: ((app-name))
    routes:
      - route: my-subdomain.my-domain.com
    ...
```

## Use the app as a route service

Please refer to the official GOV.UK PaaS
[documentation on route services](http://localhost:4567/deploying_services/route_services/#user-provided-route-services)
for steps on deploying the route service.

## Checking that it works

The route service exposes two paths for checking the status.

The path `/_route-service-health` is for information and health checking, and
has stats about the number of active connections which exist.

The path `/_route-service-check` is for checking if you may use the route
service. If you are, then you will receive `OK`, if you are not you will
received `Forbidden by ((app-name))`, where `((app-name))` is the value of the
`APP_NAME` environment variable.
