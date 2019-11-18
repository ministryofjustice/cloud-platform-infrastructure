resource "helm_release" "kuberos" {
  name          = "kuberos"
  namespace     = "kuberos"
  chart         = "../../helm-charts/kuberos"
  recreate_pods = true

  set {
    name = "ingress.host"
    value = terraform.workspace == local.live_workspace ? format("%s.%s", "login", local.live_domain) : format(
      "%s.%s",
      "login.apps",
      data.terraform_remote_state.cluster.outputs.cluster_domain_name,
    )
  }

  set {
    name = "ingress.tls.secretName.host"
    value = terraform.workspace == local.live_workspace ? format("%s.%s", "login", local.live_domain) : format(
      "%s.%s",
      "login.apps",
      data.terraform_remote_state.cluster.outputs.cluster_domain_name,
    )
  }

  set {
    name  = "cluster.name"
    value = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  }

  set {
    name  = "cluster.address"
    value = "https://api.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  }

  set {
    name  = "oidc.issuerUrl"
    value = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  }

  set {
    name  = "oidc.clientId"
    value = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_id
  }

  set {
    name  = "oidc.clientSecret"
    value = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_secret
  }

  set {
    name  = "replicaCount"
    value = "2"
  }

  depends_on = [null_resource.deploy]

  lifecycle {
    ignore_changes = [keyring]
  }
}

