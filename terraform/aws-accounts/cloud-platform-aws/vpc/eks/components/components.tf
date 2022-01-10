
module "concourse" {
  count  = terraform.workspace == "manager" ? 1 : 0
  source = "github.com/ministryofjustice/cloud-platform-terraform-concourse?ref=1.8.1"

  concourse_hostname                                = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  github_auth_client_id                             = var.github_auth_client_id
  github_auth_client_secret                         = var.github_auth_client_secret
  github_org                                        = var.github_org
  github_teams                                      = var.github_teams
  tf_provider_auth0_client_id                       = var.tf_provider_auth0_client_id
  tf_provider_auth0_client_secret                   = var.tf_provider_auth0_client_secret
  cloud_platform_infrastructure_git_crypt_key       = var.cloud_platform_infrastructure_git_crypt_key
  cloud_platform_infrastructure_pr_git_access_token = var.cloud_platform_infrastructure_pr_git_access_token
  slack_hook_id                                     = var.slack_hook_id
  concourse-git-crypt                               = var.concourse-git-crypt
  environments-git-crypt                            = var.environments-git-crypt
  github_token                                      = var.github_token
  pingdom_user                                      = var.pingdom_user
  pingdom_password                                  = var.pingdom_password
  pingdom_api_key                                   = var.pingdom_api_key
  pingdom_api_token                                 = var.pingdom_api_token
  dockerhub_username                                = var.dockerhub_username
  dockerhub_password                                = var.dockerhub_password
  how_out_of_date_are_we_github_token               = var.how_out_of_date_are_we_github_token
  authorized_keys_github_token                      = var.authorized_keys_github_token
  sonarqube_token                                   = var.sonarqube_token
  sonarqube_host                                    = var.sonarqube_host
  dependence_prometheus                             = module.monitoring.helm_prometheus_operator_eks_status
  hoodaw_host                                       = var.hoodaw_host
  hoodaw_api_key                                    = var.hoodaw_api_key
  github_actions_secrets_token                      = var.github_actions_secrets_token
}

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
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=2.0.1"

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
  enable_thanos_compact    = terraform.workspace == "manager" ? true : false

  enable_ecr_exporter        = true
  enable_cloudwatch_exporter = true

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "opa" {
  source     = "github.com/ministryofjustice/cloud-platform-terraform-opa?ref=0.2.1"
  depends_on = [module.monitoring, module.ingress_controllers, module.velero, module.cert_manager]

  cluster_domain_name            = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  enable_invalid_hostname_policy = lookup(local.prod_workspace, terraform.workspace, false) ? false : true
  enable_external_dns_weight     = terraform.workspace == "live" ? true : false
  cluster_color                  = terraform.workspace == "live" ? "green" : "black"
}

module "starter_pack" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-starter-pack?ref=0.1.4"

  enable_starter_pack = lookup(local.prod_workspace, terraform.workspace, false) ? false : true
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
}

module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=0.0.8"

  iam_role_nodes        = data.aws_iam_role.nodes.arn
  dependence_prometheus = module.monitoring.helm_prometheus_operator_eks_status
  cluster_domain_name   = data.terraform_remote_state.cluster.outputs.cluster_domain_name

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "sonarqube" {
  count  = terraform.workspace == "manager" ? 1 : 0
  source = "github.com/ministryofjustice/cloud-platform-terraform-sonarqube?ref=0.0.5"

  vpc_id                        = data.terraform_remote_state.cluster.outputs.vpc_id
  internal_subnets              = data.terraform_remote_state.cluster.outputs.internal_subnets
  internal_subnets_ids          = data.terraform_remote_state.cluster.outputs.internal_subnets_ids
  cluster_domain_name           = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_components_client_id     = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
  oidc_components_client_secret = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url

  # This is to enable sonarqube, by default it is false for test clusters
  enable_sonarqube = lookup(local.prod_workspace, terraform.workspace, false)
}

