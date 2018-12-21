resource "helm_repository" "coreos" {
  name = "coreos"
  url  = "https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/"
}

resource "kubernetes_storage_class" "prometheus_storage" {
  metadata {
    name = "prometheus-storage"
  }

  storage_provisioner = "kubernetes.io/aws-ebs"

  parameters {
    type = "gp2"
  }
}

data "template_file" "prometheus_operator" {
  template = "${file("${path.module}/templates/prometheus-operator.yaml.tpl")}"
  vars     = {}
}

resource "helm_release" "prometheus_operator" {
  name          = "prometheus-operator"
  chart         = "prometheus-operator"
  repository    = "${helm_repository.coreos.metadata.0.name}"
  namespace     = "monitoring"
  recreate_pods = "true"

  values = [
    "${data.template_file.prometheus_operator.rendered}",
  ]

  depends_on = [
    "null_resource.deploy",
  ]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}

resource "random_id" "username" {
  byte_length = 8
}

resource "random_id" "password" {
  byte_length = 8
}

data "template_file" "kube_prometheus" {
  template = "${file("${path.module}/templates/kube-prometheus.yaml.tpl")}"

  vars {
    alertmanager_ingress = "https://alertmanager.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
    grafana_ingress      = "grafana.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
    grafana_root         = "https://grafana.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
    pagerduty_config     = "${var.pagerduty_config}"
    slack_config         = "${var.slack_config}"
    promtheus_ingress    = "https://prometheus.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
    random_username      = "${random_id.username.hex}"
    random_password      = "${random_id.password.hex}"
  }
}

resource "helm_release" "kube_prometheus" {
  name          = "kube-prometheus"
  chart         = "kube-prometheus"
  repository    = "${helm_repository.coreos.metadata.0.name}"
  namespace     = "monitoring"
  recreate_pods = "true"

  values = [
    "${data.template_file.kube_prometheus.rendered}",
  ]

  depends_on = [
    "null_resource.deploy",
    "helm_release.prometheus_operator",
  ]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}
