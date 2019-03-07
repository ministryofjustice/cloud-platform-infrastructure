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
  set {
    name  = "ingress.host"
    value = "login.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
  }
  
  set {
    name  = "ingress.tls.secretName.host"
    value = "login.apps.${data.terraform_remote_state.cluster.cluster_domain_name}"
  }

  set {
    name  = "cluster.name"
    value = "${data.terraform_remote_state.cluster.cluster_domain_name}"
  }

  set {
    name  = "cluster.address"
    value = "https://api.${data.terraform_remote_state.cluster.cluster_domain_name}"
  }

  set {
    name  = "oidc.issuerUrl"
    value = "${data.terraform_remote_state.cluster.oidc_issuer_url}"
  }

  set {
    name  = "oidc.clientId"
    value = "${data.terraform_remote_state.cluster.oidc_kubernetes_client_id}"
  }

  set {
    name  = "oidc.clientSecret"
    value = "${data.terraform_remote_state.cluster.oidc_kubernetes_client_secret}"
  }

  set {
    name  = "replicaCount"
    value = "2"
  }

  depends_on = ["null_resource.deploy"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}
