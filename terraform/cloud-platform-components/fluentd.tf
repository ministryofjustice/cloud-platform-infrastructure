resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"

<<<<<<< HEAD
    labels {
      "component" = "logging"
    }

=======
>>>>>>> 48a29fdb9261b3a5cbbca1676490335c4bc1e40e
    annotations {
      "cloud-platform.justice.gov.uk/application"                = "Logging"
      "cloud-platform.justice.gov.uk/business-unit"              = "cloud-platform"
      "cloud-platform.justice.gov.uk/owner"                      = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "iam.amazonaws.com/permitted"                              = ".*"
      "cloud-platform.justice.gov.uk/can-tolerate-master-taints" = "true"
    }
  }
}

resource "helm_release" "fluentd_es" {
  name      = "fluentd-es"
  chart     = "../../helm-charts/fluentd-es"
  namespace = "logging"

  set {
    name  = "fluent_elasticsearch_host"
    value = "${replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com" : "placeholder-elasticsearch"}"

    # if you need to connect to the test elasticsearch cluster, replace "placeholder-elasticsearch" with "search-cloud-platform-test-zradqd7twglkaydvgwhpuypzy4.eu-west-2.es.amazonaws.com"
    # -> value = "${replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com" : "search-cloud-platform-test-zradqd7twglkaydvgwhpuypzy4.eu-west-2.es.amazonaws.com"
    # Your cluster will need to be whitelisted.
  }

  set {
    name  = "fluent_elasticsearch_audit_host"
    value = "${replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-audit-dq5bdnjokj4yt7qozshmifug6e.eu-west-2.es.amazonaws.com" : ""}"
  }

  set {
    name  = "fluent_kubernetes_cluster_name"
    value = "${terraform.workspace}"
  }

  set {
    name  = "serviceMonitor.enabled"
    value = true
  }

  depends_on = [
    "kubernetes_namespace.logging",
    "null_resource.deploy",
    "null_resource.priority_classes",
  ]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}
