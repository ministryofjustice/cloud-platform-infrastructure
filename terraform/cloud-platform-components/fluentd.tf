resource "kubernetes_service_account" "fluentd_service_account" {
  metadata {
    name = "fluentd-es"
    namespace = "logging"
    labels {
        k8s-app = "fluentd-es"
        kubernetes.io/cluster-service = "true"
        addonmanager.kubernetes.io/mode = "Reconcile"
    }
  }
}