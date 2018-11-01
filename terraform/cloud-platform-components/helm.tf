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
    api_group = ""
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "kube-system"
    api_group = ""
  }
}
resource "null_resource" "deploy" {
    provisioner "local-exec" {
        command = "helm init --service-account tiller"
    }
    provisioner "local-exec" {
        when = "destroy"
        command= "kubectl -n kube-system delete deployment.apps/tiller-deploy service/tiller-deploy "
    }
}
