
#########
# Nginx #
#########

#
# K8S
#

resource "kubernetes_namespace" "ingress_controllers" {
  metadata {
    name = "ingress-controllers"

    labels = {
      "name"                                           = "ingress-controllers"
      "component"                                      = "ingress-controllers"
      "cloud-platform.justice.gov.uk/environment-name" = "production"
      "cloud-platform.justice.gov.uk/is-production"    = "true"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"                   = "Kubernetes Ingress Controllers"
      "cloud-platform.justice.gov.uk/business-unit"                 = "cloud-platform"
      "cloud-platform.justice.gov.uk/owner"                         = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                   = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "cloud-platform.justice.gov.uk/can-use-loadbalancer-services" = "true"
    }
  }
}

#
# HELM
#

resource "helm_release" "nginx_ingress_acme" {
  count = var.enable_nginx_ingress_acme ? 1 : 0

  name       = "nginx-ingress-acme"
  repository = "stable"
  chart      = "stable/nginx-ingress"
  namespace = kubernetes_namespace.ingress_controllers.id
  version   = "v1.24.0"

  values = [templatefile("${path.module}/templates/nginx-ingress-controller.yaml.tpl", {
    cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  })]

  depends_on = [
    null_resource.deploy,
    kubernetes_namespace.ingress_controllers,
  ]
}