
# Deploying HELM and Tiller

resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = "tiller"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "kube-system"
    api_group = ""
  }
}

resource "null_resource" "deploy" {
  depends_on = [
    kubernetes_service_account.tiller,
    kubernetes_cluster_role_binding.tiller,
  ]

  provisioner "local-exec" {
    command = "helm init --wait --service-account tiller"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl -n kube-system delete deployment.apps/tiller-deploy service/tiller-deploy"
  }
}
