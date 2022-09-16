
##########
# Calico #
##########

data "kubectl_file_documents" "calico_crds" {
  content = file("${path.module}/resources/calico-crds.yaml")
}

resource "kubectl_manifest" "calico_crds" {
  count     = length(data.kubectl_file_documents.calico_crds.documents)
  yaml_body = element(data.kubectl_file_documents.calico_crds.documents, count.index)
}

resource "helm_release" "calico" {
  name       = "calico"
  chart      = "aws-calico"
  repository = "https://aws.github.io/eks-charts"
  namespace  = "kube-system"
  version    = "0.3.10"

  depends_on = [kubectl_manifest.calico_crds]
  timeout    = "900"

  set {
    name  = "calico.typha.resources.limits.memory"
    value = "256Mi"
  }
  set {
    name  = "calico.typha.resources.limits.cpu"
    value = "200m"
  }
  set {
    name  = "calico.node.resources.limits.memory"
    value = "128Mi"
  }
  set {
    name  = "calico.node.resources.limits.cpu"
    value = "200m"
  }
}

data "kubectl_file_documents" "calico_global_policies" {
  content = file("${path.module}/resources/calico-global-policies.yaml")
}

resource "kubectl_manifest" "calico_global_policies" {
  count     = length(data.kubectl_file_documents.calico_global_policies.documents)
  yaml_body = element(data.kubectl_file_documents.calico_global_policies.documents, count.index)

  depends_on = [helm_release.calico]
}