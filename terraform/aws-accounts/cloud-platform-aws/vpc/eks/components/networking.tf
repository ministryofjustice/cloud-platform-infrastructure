
##########
# Calico #
##########

# stopgap before switching to the tigera operator installation (disruptive)
locals {
  calico_crds = {
    bgpconfigurations     = "https://raw.githubusercontent.com/aws/eks-charts/v0.0.108/stable/aws-calico/templates/crds/crd.projectcalico.org_bgpconfigurations.yaml"
    bgppeers              = "https://raw.githubusercontent.com/aws/eks-charts/v0.0.108/stable/aws-calico/templates/crds/crd.projectcalico.org_bgppeers.yaml"
    blockaffinities       = "https://raw.githubusercontent.com/aws/eks-charts/v0.0.108/stable/aws-calico/templates/crds/crd.projectcalico.org_blockaffinities.yaml"
    clusterinformations   = "https://raw.githubusercontent.com/aws/eks-charts/v0.0.108/stable/aws-calico/templates/crds/crd.projectcalico.org_clusterinformations.yaml"
    felixconfigurations   = "https://raw.githubusercontent.com/aws/eks-charts/v0.0.108/stable/aws-calico/templates/crds/crd.projectcalico.org_felixconfigurations.yaml"
    globalnetworkpolicies = "https://raw.githubusercontent.com/aws/eks-charts/v0.0.108/stable/aws-calico/templates/crds/crd.projectcalico.org_globalnetworkpolicies.yaml"
    globalnetworksets     = "https://raw.githubusercontent.com/aws/eks-charts/v0.0.108/stable/aws-calico/templates/crds/crd.projectcalico.org_globalnetworksets.yaml"
    hostendpoints         = "https://raw.githubusercontent.com/aws/eks-charts/v0.0.108/stable/aws-calico/templates/crds/crd.projectcalico.org_hostendpoints.yaml"
    ipamblocks            = "https://raw.githubusercontent.com/aws/eks-charts/v0.0.108/stable/aws-calico/templates/crds/crd.projectcalico.org_ipamblocks.yaml"
    ippools               = "https://raw.githubusercontent.com/aws/eks-charts/v0.0.108/stable/aws-calico/templates/crds/crd.projectcalico.org_ippools.yaml"
    networkpolicies       = "https://raw.githubusercontent.com/aws/eks-charts/v0.0.108/stable/aws-calico/templates/crds/crd.projectcalico.org_networkpolicies.yaml"
    networksets           = "https://raw.githubusercontent.com/aws/eks-charts/v0.0.108/stable/aws-calico/templates/crds/crd.projectcalico.org_networksets.yaml"
  }
}

data "http" "calico_crds" {
  for_each = local.calico_crds
  url      = each.value
}

resource "kubectl_manifest" "calico_crds" {
  server_side_apply = true
  for_each          = data.http.calico_crds
  yaml_body         = each.value["body"]
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