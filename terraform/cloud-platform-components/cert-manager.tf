variable "cert-manager-ns" {
  default = "cert-manager"
}

resource "helm_release" "cert-manager" {
  name      = "cert-manager"
  chart     = "stable/cert-manager"
  namespace = "${var.cert-manager-ns}"
  version   = "v0.5.2"

  set {
    name  = "image.tag"
    value = "v0.5.2"
  }

  set {
    name  = "ingressShim.defaultIssuerName"
    value = "letsencrypt-staging"
  }

  set {
    name  = "ingressShim.defaultIssuerKind"
    value = "ClusterIssuer"
  }

  set {
    name  = "createCustomResource"
    value = "false"
  }

  depends_on = ["null_resource.deploy"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}
