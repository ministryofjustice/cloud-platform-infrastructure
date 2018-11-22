resource "helm_release" "metrics_server" {
  name      = "metrics-server"
  chart     = "stable/metrics-server"
  namespace = "kube-system"
  keyring   = ""
  version   = "2.0.4"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  set {
    name  = "args[1]"
    value = "--logtostderr"
  }

  depends_on = ["null_resource.deploy"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}
