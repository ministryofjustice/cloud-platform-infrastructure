# cloud-platform kuberos

This chart deploys [`kuberos`](https://github.com/ministryofjustice/kuberos) on a cloud-platform cluster.

## Configuration

The following table lists the configurable parameters of the kuberos chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| fullnameOverride | Override the full name of the deployment | `""` |
| replicaCount | The number of replicas in the kuberos `Deployment` | `1` |
| image.repository | Docker image repository for the `kuberos` image | `926803513772.dkr.ecr.eu-west-1.amazonaws.com/cloud-platform/kuberos` |
| image.tag | Docker image tag | `latest` |
| image.pullPolicy | The container's `imagePullPolicy` | `IfNotPresent` |
| service.type | Kuberos `Service` type | `ClusterIP` |
| service.port | Kuberos `Service` port | `80` |
| ingress.host | Kuberos `Ingress` hostname | `kuberos.cluster.local` |
| ingress.annotations | Kuberos `Ingress` annotations | `{kubernetes.io/ingress.class: "nginx"}` |
| oidc.issuerUrl | OIDC Issuer URL | `""` |
| oidc.clientId | OIDC Client ID | `""` |
| oidc.clientSecret | OIDC Client Secret | `""` |
| cluster.name | The name of the cluster | `"kubernetes-cluster"` |
| cluster.address | The address where the API is exposed | `""` |
| cluster.ca | The CA certificate (base64 encoded) of the cluster. Leave empty to use the current cluster's certificate | `""` |

The chart also supports `resources` definitions and placement options (`nodeSelector`, `tolerations`, `affinity`). See `values.yaml`.
