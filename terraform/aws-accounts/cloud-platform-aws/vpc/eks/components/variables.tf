variable "pagerduty_config" {
  description = "Add PagerDuty key to allow integration with a PD service."
  type        = string
}

variable "live1_domain" {
  default     = "live-1.cloud-platform.service.justice.gov.uk"
  description = "cluster domain name for live-1"
  type        = string
}

variable "alertmanager_slack_receivers" {
  description = "A list of configuration values for Slack receivers"
  type        = list(any)
}

variable "elasticsearch_hosts_maps" {
  description = "Cloud Platform ElasticSearch hosts for each Terraform workspace"

  default = {
    manager = "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com"
    live    = "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com"
    live-2  = "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com"
  }

  type = object({
    manager = string
    live    = string
    live-2  = string
  })
}

variable "elasticsearch_audit_hosts_maps" {
  description = "Cloud Platform audit ElasticSearch hosts for each Terraform workspace"

  default = {
    manager = "search-cloud-platform-audit-live-hfclvgaq73cul7ku362rvigti4.eu-west-2.es.amazonaws.com"
    live    = "search-cloud-platform-audit-live-hfclvgaq73cul7ku362rvigti4.eu-west-2.es.amazonaws.com"
    live-2  = "search-cloud-platform-audit-live-hfclvgaq73cul7ku362rvigti4.eu-west-2.es.amazonaws.com"
  }

  type = object({
    manager = string
    live    = string
    live-2  = string
  })
}

# Concourse vars
variable "github_auth_client_id" {
  type        = string
  description = "GitHub client ID"
}

variable "github_auth_client_secret" {
  type        = string
  description = "GitHub client secret"
}

variable "github_org" {
  type        = string
  description = "GitHub organisation (e.g. ministryofjustice) with view access to Concourse"
}

variable "github_teams" {
  type        = string
  description = "GitHub teams with member access to Concourse (should be org:team e.g. ministryofjustice:webops)"
}

variable "tf_provider_auth0_client_id" {
  type        = string
  description = "Auth0 client ID for the provider"
}

variable "tf_provider_auth0_client_secret" {
  type        = string
  description = "Auth0 client secret for the provider"
}

variable "cloud_platform_infrastructure_git_crypt_key" {
  type        = string
  description = "git crypt key for encrypted files in cloud-platform-infrastructure"
}

variable "slack_hook_id" {
  type        = string
  description = "Slack webhook ID for alerts"
}

variable "concourse-git-crypt" {
  type        = string
  description = "git crypt key for encrypted files in Concourse"
}

variable "environments-git-crypt" {
  type        = string
  description = "git crypt key for encrypted files in cloud-platform-environments"
}

variable "github_token" {
  type        = string
  description = "GitHub access token for cloud-platform-environments"
}

variable "pingdom_user" {
  type        = string
  description = "Pingdom username"
}

variable "pingdom_password" {
  type        = string
  description = "Pingdom password"
}

variable "pingdom_api_key" {
  type        = string
  description = "Pingdom API key"
}

variable "pingdom_api_token" {
  type        = string
  description = "Pingdom API token"
}

variable "dockerhub_username" {
  type        = string
  description = "DockerHub username"
}

variable "dockerhub_password" {
  type        = string
  description = "DockerHub password"
}

variable "how_out_of_date_are_we_github_token" {
  type        = string
  description = "How Out Of Date Are We GitHub token"
}

variable "cloud_platform_infrastructure_pr_git_access_token" {
  type        = string
  description = "GitHub token for cloud-platform-infrastructure commits"
}

variable "authorized_keys_github_token" {
  type        = string
  description = "GitHub token for authorized keys"
}

variable "sonarqube_token" {
  type        = string
  default     = ""
  description = "Sonarqube token used to authenticate against sonaqube for scanning repos"
}

variable "sonarqube_host" {
  type        = string
  default     = ""
  description = "The host of the sonarqube"
}

variable "hoodaw_host" {
  type        = string
  default     = ""
  description = "Hostname of the 'how out of date are we' web application. Required when posting JSON data to it."
}

variable "hoodaw_api_key" {
  type        = string
  default     = ""
  description = "API key to authenticate data posts to https://how-out-of-date-are-we.apps.live-1.cloud-platform.service.justice.gov.uk"
}

variable "github_actions_secrets_token" {
  type        = string
  default     = ""
  description = "Github personal access token able to update any MoJ repository. Used to create github actions secrets"
}
