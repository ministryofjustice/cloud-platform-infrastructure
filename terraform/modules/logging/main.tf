## IF terraform.workspace is live-1 AND loggin_enabled is true,
# then install fluentd with live-1 values
resource "helm_release" "fluentd_es_live" {
  name      = "fluentd-es"
  count     = "${terraform.workspace == local.live_workspace && var.logging_enabled ? 1 : 0}" # 
  chart     = "${path.module}/charts/fluentd-es"
  namespace = "logging"

  values = [
    "${file("environments/live/values.yaml")}"
  ]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}

# if terraform.workspace is not live-1 install this fluentd
# if LOCAL_ELASTICSEARCH is false, then this chart will use the the test-ES values
# if LOCAL_ELASTICSEARCH is true, then this chart will point to the "local_elasticsearch"
resource "helm_release" "fluentd_es_test" {
  name      = "fluentd-es"
  count     = "${terraform.workspace != local.live_workspace && var.logging_enabled == true ? 1 : 0}"
  chart     = "${path.module}/charts/fluentd-es"
  namespace = "logging"

  values = [
    "${var.LOCAL_ELASTICSEARCH ? file("${path.module}/charts/fluentd-es/environments/local/values.yaml") : file("${path.module}/charts/fluentd-es/environments/test/values.yaml")}"
  ]

  depends_on = ["helm_release.local_elasticsearch"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}

data "helm_repository" "stable" {
  name = "elastic"
  url  = "https://helm.elastic.co"
}

resource "helm_release" "local_elasticsearch" {
  name       = "local"
  count      = "${var.LOCAL_ELASTICSEARCH && var.logging_enabled ? 1 : 0}"
  repository = "${data.helm_repository.stable.metadata.0.name}"
  chart      = "elasticsearch"
  namespace  = "logging"
}

locals {
  live_workspace = "live-1"
  live_domain    = "cloud-platform.service.justice.gov.uk"
}