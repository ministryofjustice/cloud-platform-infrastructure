# Prometheus operator
# Ref: https://github.com/helm/charts/tree/master/stable/prometheus-operator

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"

    annotations {
      "iam.amazonaws.com/permitted" = ".*"
    }
  }
}

resource "kubernetes_secret" "grafana_secret" {
  metadata {
    name      = "grafana-env"
    namespace = "monitoring"
  }

  data {
    GF_AUTH_GENERIC_OAUTH_CLIENT_ID     = "${data.terraform_remote_state.cluster.oidc_components_client_id}"
    GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = "${data.terraform_remote_state.cluster.oidc_components_client_secret}"
    GF_AUTH_GENERIC_OAUTH_AUTH_URL      = "${data.terraform_remote_state.cluster.oidc_issuer_url}authorize"
    GF_AUTH_GENERIC_OAUTH_TOKEN_URL     = "${data.terraform_remote_state.cluster.oidc_issuer_url}oauth/token"
    GF_AUTH_GENERIC_OAUTH_API_URL       = "${data.terraform_remote_state.cluster.oidc_issuer_url}userinfo"
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
    alertmanager_ingress                     = "${terraform.workspace == local.live_workspace ? format("%s.%s", "https://alertmanager", local.live_domain) : format("%s.%s", "https://alertmanager.apps", data.terraform_remote_state.cluster.cluster_domain_name)}"
    grafana_ingress                          = "${terraform.workspace == local.live_workspace ? format("%s.%s", "grafana", local.live_domain) : format("%s.%s", "grafana.apps", data.terraform_remote_state.cluster.cluster_domain_name)}"
    grafana_root                             = "${terraform.workspace == local.live_workspace ? format("%s.%s", "https://grafana", local.live_domain) : format("%s.%s", "https://grafana.apps", data.terraform_remote_state.cluster.cluster_domain_name)}"
    pagerduty_config                         = "${ var.pagerduty_config }"
    slack_config                             = "${ var.slack_config }"
    slack_config_apply-for-legal-aid-prod    = "${var.slack_config_apply-for-legal-aid-prod}"
    slack_config_apply-for-legal-aid-staging = "${var.slack_config_apply-for-legal-aid-staging}"
    slack_config_apply-for-legal-aid-uat     = "${var.slack_config_apply-for-legal-aid-uat}"
    slack_config_cica-dev-team               = "${var.slack_config_cica-dev-team}"
    slack_config_form-builder                = "${var.slack_config_form-builder}"
    slack_config_laa-cla-fala                = "${var.slack_config_laa-cla-fala}"
    slack_config_prisoner-money              = "${var.slack_config_prisoner-money}"
    prometheus_ingress                       = "${terraform.workspace == local.live_workspace ? format("%s.%s", "https://prometheus", local.live_domain) : format("%s.%s", "https://prometheus.apps", data.terraform_remote_state.cluster.cluster_domain_name)}"
    random_username                          = "${ random_id.username.hex }"
    random_password                          = "${ random_id.password.hex }"
  }
}

resource "helm_release" "prometheus_operator" {
  name      = "prometheus-operator"
  chart     = "stable/prometheus-operator"
  namespace = "monitoring"
  version   = "3.0.0"

  values = [
    "${ data.template_file.prometheus_operator.rendered }",
  ]

  # Depends on Helm being installed
  depends_on = [
    "null_resource.deploy",
  ]

  provisioner "local-exec" {
    command = "kubectl apply -n monitoring -f ${path.module}/resources/prometheusrule-alerts/"
  }

  # Delete Prometheus leftovers
  # Ref: https://github.com/coreos/prometheus-operator#removal
  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete svc -l k8s-app=kubelet -n kube-system"
  }

  lifecycle {
    ignore_changes = ["keyring"]
  }
}

# Alertmanager and Prometheus proxy
# Ref: https://github.com/evry/docker-oidc-proxy
resource "random_id" "session_secret" {
  byte_length = 16
}

data "template_file" "prometheus_proxy" {
  template = "${file("${path.module}/templates/oauth2-proxy.yaml.tpl")}"

  vars {
    upstream      = "http://prometheus-operator-prometheus:9090"
    hostname      = "${terraform.workspace == local.live_workspace ? format("%s.%s", "prometheus", local.live_domain) : format("%s.%s", "prometheus.apps", data.terraform_remote_state.cluster.cluster_domain_name)}"
    exclude_paths = "^/-/healthy$"
    issuer_url    = "${data.terraform_remote_state.cluster.oidc_issuer_url}"
    client_id     = "${data.terraform_remote_state.cluster.oidc_components_client_id}"
    client_secret = "${data.terraform_remote_state.cluster.oidc_components_client_secret}"
    cookie_secret = "${random_id.session_secret.b64_std}"
  }
}

resource "helm_release" "prometheus_proxy" {
  name      = "prometheus-proxy"
  namespace = "monitoring"
  chart     = "stable/oauth2-proxy"
  version   = "0.9.1"

  values = [
    "${data.template_file.prometheus_proxy.rendered}",
  ]

  depends_on = [
    "null_resource.deploy",
    "random_id.session_secret",
  ]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}

data "template_file" "alertmanager_proxy" {
  template = "${file("${path.module}/templates/oauth2-proxy.yaml.tpl")}"

  vars {
    upstream      = "http://prometheus-operator-alertmanager:9093"
    hostname      = "${terraform.workspace == local.live_workspace ? format("%s.%s", "alertmanager", local.live_domain) : format("%s.%s", "alertmanager.apps", data.terraform_remote_state.cluster.cluster_domain_name)}"
    exclude_paths = "^/-/healthy$"
    issuer_url    = "${data.terraform_remote_state.cluster.oidc_issuer_url}"
    client_id     = "${data.terraform_remote_state.cluster.oidc_components_client_id}"
    client_secret = "${data.terraform_remote_state.cluster.oidc_components_client_secret}"
    cookie_secret = "${random_id.session_secret.b64_std}"
  }
}

resource "helm_release" "alertmanager_proxy" {
  name      = "alertmanager-proxy"
  namespace = "monitoring"
  chart     = "stable/oauth2-proxy"
  version   = "0.9.1"

  values = [
    "${data.template_file.alertmanager_proxy.rendered}",
  ]

  depends_on = [
    "null_resource.deploy",
    "random_id.session_secret",
  ]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}
