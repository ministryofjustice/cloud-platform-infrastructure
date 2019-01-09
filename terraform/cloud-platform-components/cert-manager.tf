resource "helm_release" "cert-manager" {
  name      = "cert-manager"
  chart     = "stable/cert-manager"
  namespace = "cert-manager"
  version   = "v0.5.2"

  set {
    name  = "image.tag"
    value = "v0.5.2"
  }

  set {
    name  = "ingressShim.defaultIssuerName"
    value = "letsencrypt-production"
  }

  set {
    name  = "ingressShim.defaultIssuerKind"
    value = "ClusterIssuer"
  }

  depends_on = ["null_resource.deploy"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}

resource "null_resource" "cert-manager-issuers" {
  depends_on = ["helm_release.cert-manager"]

  provisioner "local-exec" {
    command = "kubectl apply -n cert-manager -f ${path.module}/resources/cert-manager/"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete -n cert-manager -f ${path.module}/resources/cert-manager/"
  }
}
