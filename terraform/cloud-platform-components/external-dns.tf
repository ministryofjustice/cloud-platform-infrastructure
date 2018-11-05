# # data "terraform_remote_state" "cloud-platform" {
# #   backend   = "s3://moj-cp-k8s-investigation-platform-terraform"
# #   workspace = "${terraform.workspace}"

# #   config {
# #     name = "terraform.tfstate"
# #   }
# # }

resource "helm_release" "external_dns" {
  name  = "dns"
  chart = "stable/external-dns"
  namespace = "default"
  values = [<<EOF
sources:
  - service
  - ingress
provider: aws
aws:
  region: eu-west-1
  zoneType: public
domainFilters: 
  - cloud-platform-live-0.k8s.integration.dsd.io
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

