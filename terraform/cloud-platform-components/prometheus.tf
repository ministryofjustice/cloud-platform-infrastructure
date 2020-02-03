# Prometheus operator
# Ref: https://github.com/helm/charts/tree/master/stable/prometheus-operator

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"

    labels = {
      "component" = "monitoring"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"                = "Monitoring"
      "cloud-platform.justice.gov.uk/business-unit"              = "cloud-platform"
      "cloud-platform.justice.gov.uk/owner"                      = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "iam.amazonaws.com/permitted"                              = ".*"
      "cloud-platform.justice.gov.uk/can-tolerate-master-taints" = "true"
    }
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "kubernetes_secret" "grafana_secret" {
  depends_on = [kubernetes_namespace.monitoring]

  metadata {
    name      = "grafana-env"
    namespace = "monitoring"
  }

  data = {
    GF_AUTH_GENERIC_OAUTH_CLIENT_ID     = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
    GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
    GF_AUTH_GENERIC_OAUTH_AUTH_URL      = "${data.terraform_remote_state.cluster.outputs.oidc_issuer_url}authorize"
    GF_AUTH_GENERIC_OAUTH_TOKEN_URL     = "${data.terraform_remote_state.cluster.outputs.oidc_issuer_url}oauth/token"
    GF_AUTH_GENERIC_OAUTH_API_URL       = "${data.terraform_remote_state.cluster.outputs.oidc_issuer_url}userinfo"
  }

  type = "Opaque"
}

resource "random_id" "username" {
  byte_length = 8
}

resource "random_id" "password" {
  byte_length = 8
}


data "template_file" "alertmanager_routes" {
  count = length(var.alertmanager_slack_receivers)

  template = <<EOS
- match:
    severity: info-$${severity}
  receiver: slack-info-$${severity}
  continue: true
- match:
    severity: $${severity}
  receiver: slack-$${severity}
EOS


  vars = var.alertmanager_slack_receivers[count.index]
}

data "template_file" "alertmanager_receivers" {
  count = length(var.alertmanager_slack_receivers)

  template = <<EOS
- name: 'slack-$${severity}'
  slack_configs:
  - api_url: "$${webhook}"
    channel: "$${channel}"
    send_resolved: True
    title: '{{ template "slack.cp.title" . }}'
    text: '{{ template "slack.cp.text" . }}'
    footer: ${local.alertmanager_ingress}
    actions:
    - type: button
      text: 'Runbook :blue_book:'
      url: '{{ (index .Alerts 0).Annotations.runbook_url }}'
    - type: button
      text: 'Query :mag:'
      url: '{{ (index .Alerts 0).GeneratorURL }}'
    - type: button
      text: 'Silence :no_bell:'
      url: '{{ template "__alert_silence_link" . }}'
- name: 'slack-info-$${severity}'
  slack_configs:
  - api_url: "$${webhook}"
    channel: "$${channel}"
    send_resolved: False
    title: '{{ template "slack.cp.title" . }}'
    text: '{{ template "slack.cp.text" . }}'
    color: 'good'
    footer: ${local.alertmanager_ingress}
    actions:
    - type: button
      text: 'Query :mag:'
      url: '{{ (index .Alerts 0).GeneratorURL }}'
EOS


  vars = var.alertmanager_slack_receivers[count.index]
}

locals {
  alertmanager_ingress = terraform.workspace == local.live_workspace ? format("%s.%s", "https://alertmanager", local.live_domain) : format(
    "%s.%s",
    "https://alertmanager.apps",
    data.terraform_remote_state.cluster.outputs.cluster_domain_name,
  )
  grafana_ingress = terraform.workspace == local.live_workspace ? format("%s.%s", "grafana", local.live_domain) : format(
    "%s.%s",
    "grafana.apps",
    data.terraform_remote_state.cluster.outputs.cluster_domain_name,
  )
  grafana_root = terraform.workspace == local.live_workspace ? format("%s.%s", "https://grafana", local.live_domain) : format(
    "%s.%s",
    "https://grafana.apps",
    data.terraform_remote_state.cluster.outputs.cluster_domain_name,
  )
  prometheus_ingress = terraform.workspace == local.live_workspace ? format("%s.%s", "https://prometheus", local.live_domain) : format(
    "%s.%s",
    "https://prometheus.apps",
    data.terraform_remote_state.cluster.outputs.cluster_domain_name,
  )
}

resource "helm_release" "prometheus_operator" {
  name         = "prometheus-operator"
  chart        = "stable/prometheus-operator"
  namespace    = "monitoring"
  version      = "7.4.0"
  force_update = "true"

  values = [templatefile("${path.module}/templates/prometheus-operator.yaml.tpl", {
    alertmanager_ingress   = local.alertmanager_ingress
    grafana_ingress        = local.grafana_ingress
    grafana_root           = local.grafana_root
    pagerduty_config       = var.pagerduty_config
    alertmanager_routes    = "${join("", data.template_file.alertmanager_routes.*.rendered)}"
    alertmanager_receivers = "${join("", data.template_file.alertmanager_receivers.*.rendered)}"
    prometheus_ingress     = local.prometheus_ingress
    random_username        = random_id.username.hex
    random_password        = random_id.password.hex
  })]

  # Depends on Helm being installed
  depends_on = [
    null_resource.deploy,
    kubernetes_secret.grafana_secret,
    helm_release.open-policy-agent,
  ]

  provisioner "local-exec" {
    command = "kubectl apply -n monitoring -f ${path.module}/resources/prometheusrule-alerts/"
  }

  # Delete Prometheus leftovers
  # Ref: https://github.com/coreos/prometheus-operator#removal
  # Delete Prometheus leftovers
  # Ref: https://github.com/coreos/prometheus-operator#removal
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete svc -l k8s-app=kubelet -n kube-system"
  }

  lifecycle {
    ignore_changes = [keyring]
  }
}

# Alertmanager and Prometheus proxy
# Ref: https://github.com/evry/docker-oidc-proxy
resource "random_id" "session_secret" {
  byte_length = 16
}

data "template_file" "prometheus_proxy" {
  template = file("${path.module}/templates/oauth2-proxy.yaml.tpl")

  vars = {
    upstream = "http://prometheus-operator-prometheus:9090"
    hostname = terraform.workspace == local.live_workspace ? format("%s.%s", "prometheus", local.live_domain) : format(
      "%s.%s",
      "prometheus.apps",
      data.terraform_remote_state.cluster.outputs.cluster_domain_name,
    )
    exclude_paths = "^/-/healthy$"
    issuer_url    = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
    client_id     = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
    client_secret = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
    cookie_secret = random_id.session_secret.b64_std
  }
}

resource "helm_release" "prometheus_proxy" {
  name      = "prometheus-proxy"
  namespace = "monitoring"
  chart     = "stable/oauth2-proxy"
  version   = "0.9.1"

  values = [
    data.template_file.prometheus_proxy.rendered,
  ]

  depends_on = [
    null_resource.deploy,
    random_id.session_secret,
    helm_release.open-policy-agent,
  ]

  lifecycle {
    ignore_changes = [keyring]
  }
}

data "template_file" "alertmanager_proxy" {
  template = file("${path.module}/templates/oauth2-proxy.yaml.tpl")

  vars = {
    upstream = "http://prometheus-operator-alertmanager:9093"
    hostname = terraform.workspace == local.live_workspace ? format("%s.%s", "alertmanager", local.live_domain) : format(
      "%s.%s",
      "alertmanager.apps",
      data.terraform_remote_state.cluster.outputs.cluster_domain_name,
    )
    exclude_paths = "^/-/healthy$"
    issuer_url    = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
    client_id     = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
    client_secret = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
    cookie_secret = random_id.session_secret.b64_std
  }
}

resource "helm_release" "alertmanager_proxy" {
  name      = "alertmanager-proxy"
  namespace = "monitoring"
  chart     = "stable/oauth2-proxy"
  version   = "0.9.1"

  values = [
    data.template_file.alertmanager_proxy.rendered,
  ]

  depends_on = [
    null_resource.deploy,
    random_id.session_secret,
    helm_release.open-policy-agent,
  ]

  lifecycle {
    ignore_changes = [keyring]
  }
}

