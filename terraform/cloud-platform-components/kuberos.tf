resource "helm_release" "kuberos" {
  name          = "kuberos"
  namespace     = "kuberos"
  chart         = "../../helm-charts/kuberos"
  recreate_pods = true

  values = [<<EOF
ingress:
  host: "login.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
  tls:
  - hosts:
    - "login.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"

cluster:
  name: "${data.terraform_remote_state.cluster.cluster_domain_name}"
  address: "https://api.${data.terraform_remote_state.cluster.cluster_domain_name}"

oidc:
  issuerUrl: "${data.terraform_remote_state.cluster.oidc_issuer_url}"
  clientId: "${data.terraform_remote_state.cluster.oidc_kubernetes_client_id}"
  clientSecret: "${data.terraform_remote_state.cluster.oidc_kubernetes_client_secret}"

replicaCount: 2
EOF
  ]

  depends_on = ["null_resource.deploy"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}
