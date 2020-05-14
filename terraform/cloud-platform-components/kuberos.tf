#############
# Namespace #
#############

resource "kubernetes_namespace" "kuberos" {
  metadata {
    name = "kuberos"

    labels = {
      "name"                                           = "kuberos"
      "cloud-platform.justice.gov.uk/environment-name" = "production"
      "cloud-platform.justice.gov.uk/is-production"    = "true"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"   = "Kuberos"
      "cloud-platform.justice.gov.uk/business-unit" = "cloud-platform"
      "cloud-platform.justice.gov.uk/owner"         = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"   = "https://github.com/ministryofjustice/kuberos"
    }
  }
}

resource "helm_release" "kuberos" {
  name          = "kuberos"
  namespace     = kubernetes_namespace.kuberos.id
  chart         = "kuberos"
  repository    = data.helm_repository.cloud_platform.metadata[0].name
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

  lifecycle {
    ignore_changes = [keyring]
  }
}

