module "concourse" {
  count  = lookup(local.manager_workspace, terraform.workspace, false) ? 1 : 0
  source = "github.com/ministryofjustice/cloud-platform-terraform-concourse?ref=1.35.1"

  concourse_hostname                                = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  github_auth_client_id                             = data.aws_ssm_parameter.components["github_auth_client_id"].value
  github_auth_client_secret                         = data.aws_ssm_parameter.components["github_auth_client_secret"].value
  github_org                                        = data.aws_ssm_parameter.components["github_org"].value
  github_teams                                      = data.aws_ssm_parameter.components["github_teams"].value
  tf_provider_auth0_client_id                       = data.aws_ssm_parameter.components["tf_provider_auth0_client_id"].value
  tf_provider_auth0_client_secret                   = data.aws_ssm_parameter.components["tf_provider_auth0_client_secret"].value
  cloud_platform_infrastructure_git_crypt_key       = data.aws_ssm_parameter.components["cloud_platform_infrastructure_git_crypt_key"].value
  cloud_platform_infrastructure_pr_git_access_token = data.aws_ssm_parameter.components["cloud_platform_infrastructure_pr_git_access_token"].value
  slack_hook_id                                     = lookup(local.manager_workspace, terraform.workspace, false) ? data.aws_ssm_parameter.components["slack_hook_id"].value : "dummydummy"
  slack_bot_token                                   = data.aws_ssm_parameter.components["slack_bot_token"].value
  slack_webhook_url                                 = data.aws_ssm_parameter.components["slack_webhook_url"].value
  concourse-git-crypt                               = data.aws_ssm_parameter.components["concourse_git_crypt"].value
  environments-git-crypt                            = data.aws_ssm_parameter.components["environments_git_crypt"].value
  github_token                                      = data.aws_ssm_parameter.components["github_token"].value # switched
  pingdom_user                                      = data.aws_ssm_parameter.components["pingdom_user"].value
  pingdom_password                                  = data.aws_ssm_parameter.components["pingdom_password"].value
  pingdom_api_key                                   = data.aws_ssm_parameter.components["pingdom_api_key"].value
  pingdom_api_token                                 = data.aws_ssm_parameter.components["pingdom_api_token"].value
  dockerhub_username                                = data.aws_ssm_parameter.components["dockerhub_username"].value
  dockerhub_password                                = data.aws_ssm_parameter.components["dockerhub_password"].value
  how_out_of_date_are_we_github_token               = data.aws_ssm_parameter.components["how_out_of_date_are_we_github_token"].value
  authorized_keys_github_token                      = data.aws_ssm_parameter.components["authorized_keys_github_token"].value
  teams_filter_api_key                              = data.terraform_remote_state.account.outputs.github_teams_filter_api_key
  limit_active_tasks                                = 2
  environments_live_reports_s3_bucket               = data.terraform_remote_state.account.outputs.concourse_environments_live-reports_bucket

  hoodaw_host                  = data.aws_ssm_parameter.components["hoodaw_host"].value
  hoodaw_api_key               = data.aws_ssm_parameter.components["hoodaw_api_key"].value
  github_actions_secrets_token = data.aws_ssm_parameter.components["github_actions_secrets_token"].value # switched
  hoodaw_irsa_enabled          = var.hoodaw_irsa_enabled
  eks_cluster_name             = terraform.workspace

  depends_on = [
    module.monitoring,
    module.ingress_controllers_v1
  ]
}
