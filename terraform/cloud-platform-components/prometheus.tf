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

resource "helm_release" "prometheus_operator" {
  name          = "prometheus-operator"
  chart         = "coreos/prometheus-operator"
  namespace     = "monitoring"
  recreate_pods = "true"

  depends_on = [
    "null_resource.deploy",
    "helm_repository.coreos",
  ]
}

data "template_file" "kube_prometheus" {
  template = "${file("../../helm-charts/kube-prometheus/values.yaml.tpl")}"

  vars {
    alertmanager_ingress = "https://alertmanager.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
    grafana_ingress      = "grafana.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
    grafana_root         = "https://grafana.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
    pagerduty_config     = "${var.pagerduty_config}"
    slack_config         = "${var.slack_config}"
    promtheus_ingress    = "https://prometheus.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
  }
}

resource "local_file" "kube_prometheus" {
  filename = "../../helm-charts/kube-prometheus/values.yml"
  content  = "${data.template_file.kube_prometheus.rendered}"
}

resource "helm_release" "kube_prometheus" {
  name          = "kube-prometheus"
  chart         = "coreos/kube-prometheus"
  namespace     = "monitoring"
  recreate_pods = "true"

  values = [
    "${file("../../helm-charts/kube-prometheus/values.yml")}",
  ]

  depends_on = [
    "null_resource.deploy",
    "helm_repository.coreos",
  ]
}
