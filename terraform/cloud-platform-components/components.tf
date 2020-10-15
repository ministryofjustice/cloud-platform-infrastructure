module "cert_manager" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-certmanager?ref=0.0.8"

  iam_role_nodes      = data.aws_iam_role.nodes.arn
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(var.cluster_r53_resource_maps, terraform.workspace, ["arn:aws:route53:::hostedzone/${data.terraform_remote_state.cluster.outputs.hosted_zone_id}"])
  is_live_cluster     = terraform.workspace == local.live_workspace ? true : false

  # This module requires helm and OPA already deployed
  dependence_prometheus = module.prometheus.helm_prometheus_operator_status
  dependence_opa        = module.opa.helm_opa_status
}

module "external_dns" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-external-dns?ref=1.1.0"

  iam_role_nodes      = data.aws_iam_role.nodes.arn
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(var.cluster_r53_resource_maps, terraform.workspace, ["arn:aws:route53:::hostedzone/${data.terraform_remote_state.cluster.outputs.hosted_zone_id}"])

  dependence_kiam = module.kiam.helm_kiam_status
  # dependence_kiam = helm_release.kiam

  # This section is for EKS
  eks = false
}

module "kiam" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kiam?ref=0.0.2"

  # This module requires prometheus and OPA already deployed
  dependence_prometheus = module.prometheus.helm_prometheus_operator_status
  dependence_opa        = module.opa.helm_opa_status
}

module "kuberos" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kuberos?ref=0.1.0"

  cluster_domain_name           = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_kubernetes_client_id     = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_id
  oidc_kubernetes_client_secret = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  cluster_address               = "https://api.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  create_aws_redirect           = terraform.workspace == local.live_workspace ? true : false
}


module "logging" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-logging?ref=0.1.9"

  # if you need to connect to the test elasticsearch cluster, replace "placeholder-elasticsearch" with "search-cloud-platform-test-zradqd7twglkaydvgwhpuypzy4.eu-west-2.es.amazonaws.com"
  # -> value = "${replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com" : "search-cloud-platform-test-zradqd7twglkaydvgwhpuypzy4.eu-west-2.es.amazonaws.com"
  # Your cluster will need to be added to the allow list.
  elasticsearch_host       = replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com" : "placeholder-elasticsearch"
  elasticsearch_audit_host = replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-audit-dq5bdnjokj4yt7qozshmifug6e.eu-west-2.es.amazonaws.com" : ""

  dependence_prometheus       = module.prometheus.helm_prometheus_operator_status
  dependence_priority_classes = kubernetes_priority_class.node_critical
  enable_curator_cronjob      = terraform.workspace == local.live_workspace ? true : false
  enable_fluent_bit           = true
}

module "prometheus" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=0.5.5"

  alertmanager_slack_receivers               = var.alertmanager_slack_receivers
  iam_role_nodes                             = data.aws_iam_role.nodes.arn
  pagerduty_config                           = var.pagerduty_config
  enable_ecr_exporter                        = terraform.workspace == local.live_workspace ? true : false
  enable_cloudwatch_exporter                 = terraform.workspace == local.live_workspace ? true : false
  enable_thanos_helm_chart                   = false
  enable_prometheus_affinity_and_tolerations = terraform.workspace == local.live_workspace ? true : false
  split_prometheus                           = terraform.workspace == local.live_workspace ? true : false

  cluster_domain_name           = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_components_client_id     = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
  oidc_components_client_secret = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url

  dependence_opa = module.opa.helm_opa_status
}


module "ingress_controller_integration_test" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-teams-ingress-controller?ref=0.1.2"

  namespace = "integration-test"
  # This module requires prometheus and cert-manager already deployed
  dependence_prometheus  = module.prometheus.helm_prometheus_operator_status
  dependence_certmanager = module.cert_manager.helm_cert_manager_status
}

module "ingress_controllers_k8snginx_fallback" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-k8s-ingress-controller?ref=0.0.1"

  # boolean expression for applying standby ingress-controller for live-1 cluster only.
  enable_fallback_ingress_controller     = terraform.workspace == local.live_workspace ? true : false
  # Will be used as the ingress controller name and the class annotation
  controller_name        = "k8snginx"
  replica_count          = "3"

  # This module requires prometheus and certmanager
  dependence_prometheus  = module.prometheus.helm_prometheus_operator_status
  dependence_certmanager = module.cert_manager.helm_cert_manager_status
}


module "modsec_ingress_controllers" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-modsec-ingress-controller?ref=0.0.2"

  controller_name = "modsec01"
  replica_count   = "3"

  dependence_prometheus  = module.prometheus.helm_prometheus_operator_status
  dependence_certmanager = module.cert_manager.helm_cert_manager_status
}

module "ingress_controllers" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=0.0.7"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster     = terraform.workspace == local.live_workspace ? true : false

  # This module requires helm and OPA already deployed
  dependence_prometheus  = module.prometheus.helm_prometheus_operator_status
  dependence_opa         = module.opa.helm_opa_status
  dependence_certmanager = module.cert_manager.helm_cert_manager_status
}

module "opa" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-opa?ref=0.0.7"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  # boolean expression for applying opa valid hostname for test clusters only.
  enable_invalid_hostname_policy = terraform.workspace == local.live_workspace ? false : true
}

module "starter_pack" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-starter-pack?ref=0.0.9"

  enable_starter_pack = terraform.workspace == local.live_workspace ? false : true
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  multi_container_app = false
}

module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=0.0.4"

  iam_role_nodes        = data.aws_iam_role.nodes.arn
  dependence_prometheus = module.prometheus.helm_prometheus_operator_status
  cluster_domain_name   = data.terraform_remote_state.cluster.outputs.cluster_domain_name
}
