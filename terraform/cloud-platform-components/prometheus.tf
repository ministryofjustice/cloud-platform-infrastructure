# Prometheus operator
# Ref: https://github.com/helm/charts/tree/master/stable/prometheus-operator

resource "kubernetes_secret" "grafana_secret" {
  metadata {
    name      = "grafana-env"
    namespace = "monitoring"
  }

  data {
    GF_AUTH_GITHUB_CLIENT_ID     = "${ var.github_client_id }"
    GF_AUTH_GITHUB_CLIENT_SECRET = "${ var.github_client_secret }"
    GF_SECURITY_SECRET_KEY       = "${ var.github_secret_key }"
  }

  type = "Opaque"
}

resource "random_id" "username" {
  byte_length = 8
}

resource "random_id" "password" {
  byte_length = 8
}

data "template_file" "prometheus_operator" {
  template = "${file("${ path.module }/templates/prometheus-operator.yaml.tpl")}"

  vars {
    alertmanager_ingress = "https://alertmanager.apps.${ data.terraform_remote_state.cluster.cluster_domain_name }"
    grafana_ingress      = "grafana.apps.${ data.terraform_remote_state.cluster.cluster_domain_name }"
    grafana_root         = "https://grafana.apps.${ data.terraform_remote_state.cluster.cluster_domain_name }"
    pagerduty_config     = "${ var.pagerduty_config }"
    slack_config         = "${ var.slack_config }"
    promtheus_ingress    = "https://prometheus.apps.${ data.terraform_remote_state.cluster.cluster_domain_name }"
    random_username      = "${ random_id.username.hex }"
    random_password      = "${ random_id.password.hex }"
  }
}

resource "helm_release" "prometheus_operator" {
  name          = "prometheus-operator"
  chart         = "stable/prometheus-operator"
  namespace     = "monitoring"
  recreate_pods = "true"

  values = [
    "${ data.template_file.prometheus_operator.rendered }",
  ]

  # Depends on Helm being installed
  depends_on = [
    "null_resource.deploy",
  ]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}

# Delete Prometheus leftovers
# Ref: https://github.com/coreos/prometheus-operator#removal
resource "null_resource" "destroy_prometheus" {
  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete --ignore-not-found --all crd && kubectl delete svc -l k8s-app=kubelet -n kube-system"
  }
}

# Alertmanager and Prometheus proxy
# Ref: https://github.com/evry/docker-oidc-proxy
resource "random_id" "session_secret" {
  byte_length = 16
}

data "template_file" "prometheus_proxy" {
  template = "${file("${path.module}/templates/oidc-proxy.yaml.tpl")}"

  vars {
    application_service_name     = "prometheus-operated"
    application_port             = "9090"
    application_hostname         = "prometheus.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
    application_healthcheck      = "enabled"
    application_healthcheck_port = "/-/healthy"
    oidc_client_id               = "${data.terraform_remote_state.cluster.oidc_client_id}"
    oidc_client_secret           = "${data.terraform_remote_state.cluster.oidc_client_secret}"
    oidc_session_secret          = "${random_id.session_secret.hex}"
  }
}

resource "helm_release" "prometheus_proxy" {
  name          = "prometheus"
  namespace     = "monitoring"
  chart         = "../../helm-charts/oidc-proxy"
  recreate_pods = true

  values = [
    "${data.template_file.prometheus_proxy.rendered}",
  ]

  depends_on = [
    "null_resource.deploy",
    "helm_release.prometheus_operator",
    "random_id.session_secret",
  ]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}

data "template_file" "alertmanager_proxy" {
  template = "${file("${path.module}/templates/oidc-proxy.yaml.tpl")}"

  vars {
    application_service_name     = "alertmanager-operated"
    application_port             = "9093"
    application_hostname         = "alertmanager.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
    application_healthcheck      = "enabled"
    application_healthcheck_port = "/-/healthy"
    oidc_client_id               = "${data.terraform_remote_state.cluster.oidc_client_id}"
    oidc_client_secret           = "${data.terraform_remote_state.cluster.oidc_client_secret}"
    oidc_session_secret          = "${random_id.session_secret.hex}"
  }
}

resource "helm_release" "alertmanager_proxy" {
  name          = "alertmanager"
  namespace     = "monitoring"
  chart         = "../../helm-charts/oidc-proxy"
  recreate_pods = true

  values = [
    "${data.template_file.alertmanager_proxy.rendered}",
  ]

  depends_on = [
    "null_resource.deploy",
    "helm_release.prometheus_operator",
    "random_id.session_secret",
  ]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}
