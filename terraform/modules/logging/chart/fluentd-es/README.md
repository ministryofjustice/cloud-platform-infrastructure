# Cloud Platform - Logging with Fluentd to Elasticsearch

This chart deploys Fluentd on a Cloud Platform cluster.

## Configuration

The following table lists the configurable parameters of the Fluentd chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| image.repository | Docker image repository for the `kuberos` image | `926803513772.dkr.ecr.eu-west-1.amazonaws.com/cloud-platform/kuberos` |
| image.tag | Docker image tag | `latest` |
| fluent_elasticsearch_host  | Elasticsearch host URL | `-` |
| fluent_elasticsearch_audit_host  | Elasticsearch audit host URL | `-` |
| fluent_kubernetes_cluster_name  | The name of the Cloud Platform cluster you are deploying to | `-` |
