resource "helm_release" "external_dns" {
  name      = "external-dns"
  chart     = "stable/external-dns"
  namespace = "kube-system"

  values = [<<EOF
sources:
  - service
  - ingress
provider: aws
aws:
  region: eu-west-1
  zoneType: public
domainFilters:
  - "${data.terraform_remote_state.cluster.cluster_domain_name}"
rbac:
  create: true
  apiVersion: v1
  serviceAccountName: default
logLevel: debug
EOF
  ]

  depends_on = [
    "kubernetes_service_account.tiller",
    "kubernetes_cluster_role_binding.tiller",
    "null_resource.deploy",
  ]
}
