# OIDC Proxy Helm Chart

Installing this chart will deploy an OIDC Proxy into your cluster, fronting your
defined application via an ingress rule.

## Installing the Chart

To install the chart:

```bash
helm install . \
  --name $APPLICATION_NAME \
  --namespace $NAMESPACE
  --set application.hostName=$APPLICATION_HOSTNAME \
  --set application.port=$APPLICATION_PORT \
  --set application.serviceName=$APPLICATION_SVC \
  --set oidc.clientId=$OIDC_CLIENT \
  --set oidc.clientSecret=$OIDC_SECRET \
  --set oidc.sessionSecret=$OIDC_SESSION_SECRET
```

## Configuration

The following table lists the configurable parameters of the oidc-proxy chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| fullnameOverride | Override the full name of the deployment | `""` |
| replicaCount | The number of replicas in the oidc-proxy `Deployment` | `1` |
| image.repository | Docker image repository for the `oidc-proxy` image | `evry/oidc-proxy` |
| image.tag | Docker image tag | `v1.3.0` |
| image.pullPolicy | The container's `imagePullPolicy` | `Always` |
| service.type | oidc-proxy `Service` type | `ClusterIP` |
| service.port | oidc-proxy `Service` port | `80` |
| application.hostName | The application `Ingress` hostname e.g. `prometheus.cluster.net`| `kuberos.cluster.local` |
| application.serviceName | The application `Service` name e.g. `kube-prometheus` | `""` |
| application.healthCheck.enabled | Application healthchecks are enabled | `false` |
| application.healthCheck.path | Healthcheck path | `""` |
| oidc.issuerUrl | OIDC Issuer URL | `""` |
| oidc.clientId | OIDC Client ID | `""` |
| oidc.clientSecret | OIDC Client Secret | `""` |
| oidc.sessionSecret | OIDC Cookie Secret. To generate a cookie-secret use: `head -c 32 /dev/urandom | base64` | `""` |
| oidc.discovery  | OIDC configutation URL | `https://moj-cloud-platforms-dev.eu.auth0.com/.well-known/openid-configuration` |
| oidc.renewToken  | OIDC Enable silent renew of access token | `false` |
| oidc.sessionName  | OIDC session name| `oidc_proxy` |

