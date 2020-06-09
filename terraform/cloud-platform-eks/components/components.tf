
module "cert_manager" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-certmanager?ref=0.0.6"

  iam_role_nodes      = data.aws_iam_role.nodes.arn
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(var.cluster_r53_resource_maps, terraform.workspace, ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}"])

  # This module requires helm and OPA already deployed
  dependence_prometheus = module.monitoring.helm_prometheus_operator_status
  dependence_opa        = module.opa.helm_opa_status

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "cluster_autoscaler" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-cluster-autoscaler?ref=0.0.3"

  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_id              = data.terraform_remote_state.cluster.outputs.cluster_id
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "external_dns" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-external-dns?ref=1.1.0"

  iam_role_nodes      = data.aws_iam_role.nodes.arn
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(var.cluster_r53_resource_maps, terraform.workspace, ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}"])

  # EKS doesn't use KIAM but it is a requirement for the module.
  dependence_kiam = ""

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "ingress_controllers" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=0.0.5"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster     = false

  # This module requires helm and OPA already deployed
  dependence_prometheus  = module.monitoring.helm_prometheus_operator_status
  dependence_opa         = module.opa.helm_opa_status
  dependence_certmanager = module.cert_manager.helm_cert_manager_status
}

module "logging" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-logging?ref=0.0.4"

  elasticsearch_host       = lookup(var.elasticsearch_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  elasticsearch_audit_host = lookup(var.elasticsearch_audit_hosts_maps, terraform.workspace, "placeholder-elasticsearch")

  dependence_prometheus       = module.monitoring.helm_prometheus_operator_status
  dependence_priority_classes = kubernetes_priority_class.cluster_critical
}

module "monitoring" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=0.3.4"

  alertmanager_slack_receivers = var.alertmanager_slack_receivers
  iam_role_nodes               = data.aws_iam_role.nodes.arn
  pagerduty_config             = var.pagerduty_config

  cluster_domain_name           = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_components_client_id     = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
  oidc_components_client_secret = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url

  dependence_opa = module.opa.helm_opa_status

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "opa" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-opa?ref=0.0.3"

  cluster_domain_name            = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  enable_invalid_hostname_policy = terraform.workspace == local.live_workspace ? false : true
}

module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=0.0.4"

  iam_role_nodes        = data.aws_iam_role.nodes.arn
  dependence_prometheus = module.monitoring.helm_prometheus_operator_status
  cluster_domain_name   = data.terraform_remote_state.cluster.outputs.cluster_domain_name

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

