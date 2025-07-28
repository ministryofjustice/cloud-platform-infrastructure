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
