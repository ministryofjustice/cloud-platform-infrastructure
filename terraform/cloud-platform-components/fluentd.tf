resource "helm_release" "fluentd_es" {
  name      = "fluentd-es"
  chart     = "../../helm-charts/fluentd-es"
  namespace = "logging"

  set {
    name  = "fluent_elasticsearch_host"
    value = "search-cloud-platform-live-7qrzc26xexgxtkt5qz72gt6cxa.eu-west-1.es.amazonaws.com"
  }

  set {
    name  = "fluent_elasticsearch_audit_host"
    value = "search-cloud-platform-audit-effm3qdiau42obkarrpvdxioxm.eu-west-1.es.amazonaws.com"
  }

  set {
    name  = "fluent_kubernetes_cluster_name"
    value = "${terraform.workspace}"
  }

  depends_on = ["null_resource.deploy"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}
