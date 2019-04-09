# Cloud Platform - Logging with Fluentd to Elasticsearch

This chart deploys Fluentd on a Cloud Platform cluster; source of inspiration was https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch

## Configuration

The following table lists the configurable parameters of the Fluentd chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| image.repository | Docker image repository for the `fluentd` image | `gcr.io/fluentd-elasticsearch/fluentd` |
| image.tag | Docker image tag | `v2.5.1` |
| fluent_elasticsearch_host  | Elasticsearch host URL | `-` |
| fluent_elasticsearch_audit_host  | Elasticsearch audit host URL | `-` |
| fluent_kubernetes_cluster_name  | The name of the Cloud Platform cluster you are deploying to | `-` |
