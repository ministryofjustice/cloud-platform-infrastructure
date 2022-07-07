variable "pagerduty_config" {
  description = "Add PagerDuty key to allow integration with a PD service."
}

variable "live1_domain" {
  default     = "live-1.cloud-platform.service.justice.gov.uk"
  description = "cluster domain name for live-1"
}

variable "alertmanager_slack_receivers" {
  description = "A list of configuration values for Slack receivers"
  type        = list(any)
}

variable "cloud_platform_slack_webhook" {
  description = "Slack webhook to pass it to  script to send alerts"
}

variable "elasticsearch_hosts_maps" {
  default = {
    manager = "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com"
    live    = "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com"
  }
}

variable "elasticsearch_audit_hosts_maps" {
  default = {
    manager = "search-cloud-platform-audit-live-hfclvgaq73cul7ku362rvigti4.eu-west-2.es.amazonaws.com"
    live    = "search-cloud-platform-audit-live-hfclvgaq73cul7ku362rvigti4.eu-west-2.es.amazonaws.com"
  }
}

variable "cluster_r53_domainfilters" {
  default = {
    live-1  = ["*"]
    manager = ["manager.cloud-platform.service.justice.gov.uk.", "cloud-platform.service.justice.gov.uk."]
  }
}

#Concourse vars
variable "kops_or_eks" {}
variable "github_auth_client_id" {}
variable "github_auth_client_secret" {}
variable "github_org" {}
variable "github_teams" {}
variable "tf_provider_auth0_client_id" {}
variable "tf_provider_auth0_client_secret" {}
variable "cloud_platform_infrastructure_git_crypt_key" {}
variable "slack_hook_id" {}
variable "concourse-git-crypt" {}
variable "environments-git-crypt" {}
variable "github_token" {}
variable "pingdom_user" {}
variable "pingdom_password" {}
variable "pingdom_api_key" {}
variable "pingdom_api_token" {}
variable "dockerhub_username" {}
variable "dockerhub_password" {}
variable "how_out_of_date_are_we_github_token" {}
variable "cloud_platform_infrastructure_pr_git_access_token" {}
variable "authorized_keys_github_token" {}
variable "sonarqube_token" {
  default     = ""
  description = "Sonarqube token used to authenticate against sonaqube for scanning repos"
}
variable "sonarqube_host" {
  default     = ""
  description = "The host of the sonarqube"
}
variable "hoodaw_host" {
  default     = ""
  description = "Hostname of the 'how out of date are we' web application. Required when posting JSON data to it."
}
variable "hoodaw_api_key" {
  default     = ""
  description = "API key to authenticate data posts to https://how-out-of-date-are-we.apps.live-1.cloud-platform.service.justice.gov.uk"
}
variable "github_actions_secrets_token" {
  default     = ""
  description = "Github personal access token able to update any MoJ repository. Used to create github actions secrets"
}
variable "sentry_token" {
  default     = ""
  description = "see https://grafana.com/grafana/plugins/grafana-sentry-datasource/"
}
 