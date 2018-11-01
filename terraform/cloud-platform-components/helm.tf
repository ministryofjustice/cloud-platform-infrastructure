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

resource "kubernetes_deployment" "helm" {
  metadata {
    name      = "tiller-deploy"
    namespace = "kube-system"

    labels {
      app  = "helm"
      name = "tiller"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels {
        app  = "helm"
        name = "tiller"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = "1"
        max_unavailable = "1"
      }
    }

    template {
      metadata {
        labels {
          app  = "helm"
          name = "tiller"
        }
      }

      spec {
        restart_policy                   = "Always"
        service_account_name             = "tiller"
        termination_grace_period_seconds = "30"

        container {
          image             = "gcr.io/kubernetes-helm/tiller:v2.11.0"
          name              = "tiller"
          image_pull_policy = "IfNotPresent"

          env {
            name  = "TILLER_NAMESPACE"
            value = "kube-system"
          }

          env {
            name  = "TILLER_HISTORY_MAX"
            value = "0"
          }

          port {
            name           = "tiller"
            protocol       = "TCP"
            container_port = 44134
          }

          port {
            name           = "http"
            protocol       = "TCP"
            container_port = 44135
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "helm" {
  metadata {
    name      = "tiller-deploy"
    namespace = "kube-system"
    labels {
        app = "helm"
        name = "tiller"
    }
  }

  spec {
    selector {
      app  = "helm"
      name = "tiller"
    }

    port {
      name        = "tiller"
      port        = 44134
      target_port = "tiller"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
