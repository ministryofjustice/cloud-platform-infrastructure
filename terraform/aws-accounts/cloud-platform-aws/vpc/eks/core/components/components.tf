module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=2.5.1"

  enable_velero               = lookup(local.prod_2_workspace, terraform.workspace, false)
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  node_agent_cpu_requests     = "2m"

  depends_on = [
    module.label_pods_controller
  ]
}

module "trivy-operator" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-trivy-operator?ref=0.13.0"

  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  # job concurrency limit and scanner report ttl need balancing to
  # ensure report completeness across the cluster
  job_concurrency_limit = 4
  scanner_report_ttl    = "48h"

  scan_job_timeout    = "10m"
  trivy_timeout       = "10m0s"
  severity_list       = "HIGH,CRITICAL"
  enable_trivy_server = "true"

  depends_on = [
    module.label_pods_controller
  ]
}

module "github-teams-filter" {
  source = "github.com/ministryofjustice/cloud-platform-github-teams-filter?ref=1.2.0"

  count          = terraform.workspace == "live" ? 1 : 0
  chart_version  = "1.0.1"
  ecr_url        = "754256621582.dkr.ecr.eu-west-2.amazonaws.com/webops/cloud-platform-github-teams-filter"
  image_tag      = "7d8e836a0685bd50fcc23f3b824a0aed892cf9b4"
  replica_count  = 2
  hostname       = "github-teams-filter.apps.${data.aws_route53_zone.selected.name}"
  filter_api_key = data.terraform_remote_state.account.outputs.github_teams_filter_api_key

}
