# How to install auth proxy and access Kibana

## Overview
As the AWS Elasticsearch doesn't allow us to use native authentication we had to use a combination of Auth0 and an OIDC proxy app. The application is managed in Kubernetes and has been used to proxy other applications such as [Prometheus](https://github.com/ministryofjustice/cloud-platform-prometheus#how-to-expose-the-web-interfaces-behind-an-oidc-proxy). 

This is really straight forward to do and instead of replicating documentation, I'd like to point you to the Prometheus OIDC proxy installation [here](https://github.com/ministryofjustice/cloud-platform-prometheus#new-installation).

If you'd like to see a working copy of the configuration, please see [here](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespaces/cloud-platform-live-0.k8s.integration.dsd.io/monitoring/kibana-proxy.yaml) 

