locals {
  vpa_crd_yamls = {
    vpa_crd  = "https://raw.githubusercontent.com/kubernetes/autoscaler/vpa-release-1.0/vertical-pod-autoscaler/deploy/vpa-v1-crd-gen.yaml"
    vpa_rbac = "https://raw.githubusercontent.com/kubernetes/autoscaler/vpa-release-1.0/vertical-pod-autoscaler/deploy/vpa-rbac.yaml"
  }
  is_manager_workspace = terraform.workspace == "manager"
}

data "http" "vpa_crd_yamls" {
  for_each = local.is_manager_workspace ? local.vpa_crd_yamls : {}
  url      = each.value
}

resource "kubectl_manifest" "vpa_crds" {
  server_side_apply = true
  for_each          = data.http.vpa_crd_yamls
  yaml_body         = each.value["body"]
}
