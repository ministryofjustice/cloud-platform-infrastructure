resource "helm_repository" "coreos" {
  name = "coreos"
  url  = "https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/"
}

resource "kubernetes_storage_class" "prometheus" {
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

resource "helm_release" "kube_prometheus" {
  name          = "kube-prometheus"
  chart         = "coreos/kube-prometheus"
  namespace     = "monitoring"
  recreate_pods = "true"

  values = [
    "${file("../../helm-charts/prometheus-operator/kube-prometheus/values.yaml")}",
  ]

  set {
    name  = "grafana.extraVars[0].value"
    value = "https://grafana.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
  }

  set {
    name  = "grafana.ingress.host"
    value = "https://grafana.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
  }

  set {
    name  = "alertmanager.externalUrl"
    value = "https://alertmanager.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
  }

  set {
    name  = "prometheus.externalUrl"
    value = "https://prometheus.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
  }

  set {
    name  = "alertmanager.config.receivers[1].pagerduty_configs[0].service_key"
    value = "${var.pager_duty_config}"
  }

  set {
    name  = "alertmanager.config.receivers[2].slack_configs[0].api_url"
    value = "${var.slack_config}"
  }

  depends_on = [
    "null_resource.deploy",
    "helm_repository.coreos",
  ]
}
