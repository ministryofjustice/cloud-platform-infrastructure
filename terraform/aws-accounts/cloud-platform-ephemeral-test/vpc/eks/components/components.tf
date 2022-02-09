
module "cert_manager" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-certmanager?ref=1.4.0"

  iam_role_nodes      = data.aws_iam_role.nodes.arn
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(local.hostzones, terraform.workspace, local.hostzones["default"])

  # Requiring Prometheus taints the default cert null_resource on any monitoring upgrade, 
  # but cluster creation fails without, so will have to be temporarily disabled when upgrading
  dependence_prometheus = module.monitoring.helm_prometheus_operator_eks_status
  dependence_opa        = "ignore"

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "external_dns" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-external-dns?ref=1.7.1"

  iam_role_nodes      = data.aws_iam_role.nodes.arn
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(local.hostzones, terraform.workspace, local.hostzones["default"])

  # EKS doesn't use KIAM but it is a requirement for the module.
  dependence_kiam = ""
  depends_on      = [module.monitoring]

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "ingress_controllers" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=0.3.4"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster     = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name = lookup(local.live1_cert_dns_name, terraform.workspace, "")

  # This module requires prometheus and cert-manager
  dependence_prometheus  = "ignore"
  dependence_certmanager = module.cert_manager.helm_cert_manager_status
  dependence_opa         = "ignore"
  # It depends on complete cert-manager module
  depends_on = [module.cert_manager]
}

module "modsec_ingress_controllers" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-modsec-ingress-controller?ref=0.3.2"

  controller_name = "modsec01"
  replica_count   = "6"

  depends_on = [module.ingress_controllers]
}

module "kuberos" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kuberos?ref=0.3.3"

  cluster_domain_name           = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_kubernetes_client_id     = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_id
  oidc_kubernetes_client_secret = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  cluster_address               = data.terraform_remote_state.cluster.outputs.cluster_endpoint
  create_aws_redirect           = false
}

module "logging" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-logging?ref=1.1.8"

  elasticsearch_host       = lookup(var.elasticsearch_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  elasticsearch_audit_host = lookup(var.elasticsearch_audit_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  dependence_prometheus    = module.monitoring.helm_prometheus_operator_eks_status
  eks                      = true
}

module "monitoring" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=2.0.8"

  alertmanager_slack_receivers               = var.alertmanager_slack_receivers
  iam_role_nodes                             = data.aws_iam_role.nodes.arn
  pagerduty_config                           = var.pagerduty_config
  cluster_domain_name                        = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_components_client_id                  = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
  oidc_components_client_secret              = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
  oidc_issuer_url                            = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  enable_thanos_sidecar                      = lookup(local.prod_workspace, terraform.workspace, false)
  enable_large_nodesgroup                    = terraform.workspace == "live" ? true : false
  enable_prometheus_affinity_and_tolerations = true

  enable_thanos_helm_chart = lookup(local.prod_workspace, terraform.workspace, false)
  enable_thanos_compact    = lookup(local.manager_workspace, terraform.workspace, false)

  enable_ecr_exporter        = lookup(local.cloudwatch_workspace, terraform.workspace, false)
  enable_cloudwatch_exporter = lookup(local.cloudwatch_workspace, terraform.workspace, false)

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "opa" {
  source     = "github.com/ministryofjustice/cloud-platform-terraform-opa?ref=0.2.3"
  depends_on = [module.monitoring, module.ingress_controllers, module.velero, module.cert_manager]

  cluster_domain_name            = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  enable_invalid_hostname_policy = lookup(local.prod_workspace, terraform.workspace, false) ? false : true
  enable_external_dns_weight     = terraform.workspace == "live" ? true : false
  cluster_color                  = terraform.workspace == "live" ? "green" : "black"
 // integration_test_zone          = data.aws_route53_zone.integrationtest.name
}

module "starter_pack" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-starter-pack?ref=0.1.4"

  enable_starter_pack = lookup(local.prod_workspace, terraform.workspace, false) ? false : true
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
}

module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=1.7.2"

  iam_role_nodes        = data.aws_iam_role.nodes.arn
  dependence_prometheus = module.monitoring.helm_prometheus_operator_eks_status
  cluster_domain_name   = data.terraform_remote_state.cluster.outputs.cluster_domain_name

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

