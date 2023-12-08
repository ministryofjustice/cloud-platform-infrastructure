resource "kubernetes_namespace" "kubernetes-dashboard" {
  metadata {
    name = "kubernetes-dashboard"

    labels = {
      "component"                          = "kubernetes-dashboard"
      "pod-security.kubernetes.io/enforce" = "privileged"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"                = "Kubernetes-Dashboard"
      "cloud-platform.justice.gov.uk/business-unit"              = "Platforms"
      "cloud-platform.justice.gov.uk/owner"                      = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "iam.amazonaws.com/permitted"                              = ".*"
      "cloud-platform.justice.gov.uk/can-tolerate-master-taints" = "true"
      "cloud-platform-out-of-hours-alert"                        = "true"
    }
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "helm_release" "kubernetes-dashboard" {

  name       = "kubernetes-dashboard"
  repository = "https://kubernetes.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  namespace  = "kubernetes-dashboard"
  version    = "7.0.0-alpha1"
  values = [templatefile("${path.module}/templates/kubernetes-dashboard-values.yaml", {

  })]
}

# ###Copied from Concourse
# resource "kubernetes_network_policy" "kubernetes_dashboard_default" {
#   metadata {
#     name      = "default"
#     namespace = kubernetes_namespace.kubernetes-dashboard.id
#   }

#   spec {
#     pod_selector {}

#     ingress {
#       from {
#         pod_selector {}
#       }
#     }

#     policy_types = ["Ingress"]
#   }
# }

# ###Copied from Concourse
# resource "kubernetes_network_policy" "kubernetes_dashboard_allow_ingress_controllers" {
#   metadata {
#     name      = "allow-ingress-controllers"
#     namespace = kubernetes_namespace.kubernetes-dashboard.id
#   }

#   spec {
#     pod_selector {}

#     ingress {
#       from {
#         namespace_selector {
#           match_labels = {
#             component = "ingress-controllers"
#           }
#         }
#       }
#     }

#     policy_types = ["Ingress"]
#   }
# }

# resource "kubernetes_network_policy" "allow_kube_api" {
#   metadata {
#     name      = "allow-kube-api"
#     namespace = kubernetes_namespace.kubernetes-dashboard.id
#   }

#   spec {
#     pod_selector {}
#     ingress {
#       from {
#         namespace_selector {
#           match_labels = {
#             component = "kube-system"
#           }
#         }
#       }
#     }

#     policy_types = ["Ingress"]
#   }
# }


# resource "kubernetes_network_policy" "allow_kubernetes_dashboard" {
#   metadata {
#     name      = "allow-kubernetes-dashboard"
#     namespace = kubernetes_namespace.kubernetes-dashboard.id
#   }

#   spec {
#     pod_selector {}

#     ingress {
#       from {
#         pod_selector {}
#       }
#     }

#     policy_types = ["Ingress"]
#   }
# }

### Creating temp admin user
resource "kubernetes_service_account" "kubernetes_dashboard_admin_user" {
  metadata {
    name      = "admin-user"
    namespace = "kubernetes-dashboard"
  }
}

resource "kubernetes_cluster_role_binding" "kubernetes_dashboard_admin_user" {
  metadata {
    name = "admin-user"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "admin-user"
    namespace = "kubernetes-dashboard"
  }
}

###Oauth2-proxy - copied from Prometheus proxy
locals {
  # oidc_issuer_url = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  # cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  # oidc_components_client_id = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
  # oidc_components_client_secret = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret

  live_workspace = "live"
  live_domain = "cloud-platform.service.justice.gov.uk"

}

data "template_file" "kubernetes_dashboard_proxy" {
  template = file("${path.module}/templates/oauth2-proxy.yaml.tpl")

  vars = {
    upstream = "http://kubernetes-dashboard-web:8000"
    hostname = format(
      "%s.%s",
      "dashboard",
      var.cluster_domain_name,
    )
    exclude_paths        = "^/-/healthy$"
    issuer_url           = var.oidc_issuer_url
    clusterName          = terraform.workspace
    ingress_redirect     = terraform.workspace == local.live_workspace ? true : false
    live_domain_hostname = "dashboard.${local.live_domain}"
  }
}

resource "helm_release" "kubernetes_dashboard_proxy" {
  name       = "kubernetes-dashboard-proxy"
  namespace  = kubernetes_namespace.kubernetes-dashboard.id
  repository = "https://oauth2-proxy.github.io/manifests"
  chart      = "oauth2-proxy"
  version    = "6.2.1"

  values = [
    data.template_file.kubernetes_dashboard_proxy.rendered,
  ]

  set_sensitive {
    name = "config.clientID"
    value = var.oidc_components_client_id
  }

  set_sensitive {
    name = "config.clientSecret"
    value = var.oidc_components_client_secret
  }

  set_sensitive {
    name = "config.cookieSecret"
    value = random_id.session_secret.b64_std
  }


  depends_on = [
    random_id.session_secret,
    var.dependence_ingress_controller
  ]

  lifecycle {
    ignore_changes = [keyring]
  }
}

resource "random_id" "session_secret" {
  byte_length = 16
}
