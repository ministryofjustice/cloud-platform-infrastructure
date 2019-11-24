##################
# Metrics Server #
##################

resource "helm_release" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  name       = "metrics-server"
  repository = "stable"
  chart      = "metrics-server"

  namespace  = "kube-system"
  version    = "2.8.8"
  depends_on = [null_resource.deploy]

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  set {
    name  = "args[1]"
    value = "--kubelet-preferred-address-types=InternalIP"
  }
}