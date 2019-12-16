resource "helm_release" "metrics_server" {
  name      = "metrics-server"
  chart     = "stable/metrics-server"
  namespace = "monitoring"
  version   = "2.8.8"

  depends_on = [null_resource.deploy]

  lifecycle {
    ignore_changes = [keyring]
  }

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  set {
    name  = "args[1]"
    value = "--kubelet-preferred-address-types=InternalIP"
  }

  set {
    name  = "hostNetwork.enabled"
    value = "true"
  }

}

