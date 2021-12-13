module "cert_manager" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-certmanager?ref=1.4.0"

  iam_role_nodes      = data.aws_iam_role.nodes.arn
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(var.cluster_r53_resource_maps, terraform.workspace, ["arn:aws:route53:::hostedzone/${data.terraform_remote_state.cluster.outputs.hosted_zone_id}"])

  dependence_prometheus = module.prometheus.helm_prometheus_operator_status
  dependence_opa        = "ignore"
}

module "external_dns" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-external-dns?ref=1.7.1"

  iam_role_nodes      = data.aws_iam_role.nodes.arn
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(var.cluster_r53_resource_maps, terraform.workspace, ["arn:aws:route53:::hostedzone/${data.terraform_remote_state.cluster.outputs.hosted_zone_id}"])

  dependence_kiam = module.kiam.helm_kiam_status
  depends_on      = [module.prometheus]
  # dependence_kiam = helm_release.kiam

  # This section is for EKS
  eks = false
}

module "kiam" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kiam?ref=1.0.0"

  # This module requires prometheus
  dependence_prometheus = module.prometheus.helm_prometheus_operator_status
  dependence_opa        = "ignore"
}

module "kuberos" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kuberos?ref=0.3.3"

  cluster_domain_name           = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_kubernetes_client_id     = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_id
  oidc_kubernetes_client_secret = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  cluster_address               = "https://api.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  create_aws_redirect           = terraform.workspace == local.live_workspace ? true : false
}


module "logging" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-logging?ref=1.1.8"

  # if you need to connect to the test elasticsearch cluster, replace "placeholder-elasticsearch" with "search-cloud-platform-test-zradqd7twglkaydvgwhpuypzy4.eu-west-2.es.amazonaws.com"
  # -> value = "${replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com" : "search-cloud-platform-test-zradqd7twglkaydvgwhpuypzy4.eu-west-2.es.amazonaws.com"
  # Your cluster will need to be added to the allow list.
  elasticsearch_host       = replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com" : "placeholder-elasticsearch"
  elasticsearch_audit_host = replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-audit-live-hfclvgaq73cul7ku362rvigti4.eu-west-2.es.amazonaws.com" : "placeholder-elasticsearch-audit"

  dependence_prometheus  = module.prometheus.helm_prometheus_operator_status
  enable_curator_cronjob = terraform.workspace == local.live_workspace ? true : false
}

module "prometheus" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=2.0.1"

  alertmanager_slack_receivers               = var.alertmanager_slack_receivers
  iam_role_nodes                             = data.aws_iam_role.nodes.arn
  pagerduty_config                           = var.pagerduty_config
  enable_ecr_exporter                        = terraform.workspace == local.live_workspace ? true : false
  enable_cloudwatch_exporter                 = terraform.workspace == local.live_workspace ? true : false
  enable_thanos_helm_chart                   = terraform.workspace == local.live_workspace ? true : false
  enable_thanos_sidecar                      = terraform.workspace == local.live_workspace ? true : false
  enable_prometheus_affinity_and_tolerations = terraform.workspace == local.live_workspace ? true : false
  enable_kibana_audit_proxy                  = terraform.workspace == local.live_workspace ? true : false
  enable_kibana_proxy                        = terraform.workspace == local.live_workspace ? true : false

  cluster_domain_name           = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_components_client_id     = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
  oidc_components_client_secret = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  enable_large_nodesgroup       = terraform.workspace == local.live_workspace ? true : false
}

module "modsec_ingress_controllers" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-modsec-ingress-controller?ref=0.3.2"

  controller_name = "modsec01"
  replica_count   = "6"

  depends_on = [module.ingress_controllers]
}

module "ingress_controllers" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=0.3.4"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster     = terraform.workspace == local.live_workspace ? true : false

  dependence_certmanager = module.cert_manager.helm_cert_manager_status
  dependence_opa         = "ignore"
  # already set by cert-manager
  dependence_prometheus = "ignore"
  # This module requires cert-manager module
  depends_on = [module.cert_manager]
}

module "opa" {
  source     = "github.com/ministryofjustice/cloud-platform-terraform-opa?ref=0.2.1"
  depends_on = [module.prometheus, module.ingress_controllers, module.velero, module.kiam, module.cert_manager]

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  # boolean expression for applying opa valid hostname for test clusters only.
  enable_invalid_hostname_policy = terraform.workspace == local.live_workspace ? false : true
}

module "starter_pack" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-starter-pack?ref=0.1.4"

  enable_starter_pack = terraform.workspace == local.live_workspace ? false : true
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
}

module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=0.0.8"

  iam_role_nodes        = data.aws_iam_role.nodes.arn
  dependence_prometheus = module.prometheus.helm_prometheus_operator_status
  cluster_domain_name   = data.terraform_remote_state.cluster.outputs.cluster_domain_name
}

