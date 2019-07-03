resource "helm_release" "fluentd_es" {
  name      = "fluentd-es"
  chart     = "../../helm-charts/fluentd-es"
  namespace = "logging"

  set {
    name  = "fluent_elasticsearch_host"
    value = "${replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com" : "dummy-elasticsearch-client.logging.svc"}"
  }

  set {
    name  = "fluent_elasticsearch_audit_host"
    value = "${replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-audit-dq5bdnjokj4yt7qozshmifug6e.eu-west-2.es.amazonaws.com" : ""}"
  }

  set {
    name  = "fluent_kubernetes_cluster_name"
    value = "${terraform.workspace}"
  }

  depends_on = ["null_resource.deploy", "null_resource.priority_classes", "helm_release.dummy_elasticsearch"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}

data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com"
}

resource "helm_release" "dummy_elasticsearch" {
  name       = "dummy"
  count      = "${var.DUMMY_ELASTICSEARCH}"
  repository = "${data.helm_repository.stable.metadata.0.name}"
  chart      = "elasticsearch"
  namespace  = "logging"
}
