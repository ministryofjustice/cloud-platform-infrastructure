variable "slack_config_cloudwatch_lp" {
  description = "Add Slack webhook API URL for integration with slack."
  type        = string
}

variable "aws_region" {
  description = "Region where components and resources are going to be deployed"
  default     = "eu-west-2"
  type        = string
}

variable "kubeconfig_clusters" {
  description = "Cluster(s) credentials used by concourse pipelines to run terraform"
  type        = any
}

variable "auth0_tenant_domain" {
  description = "Auth0 domain"
  type        = string
  default     = "justice-cloud-platform.eu.auth0.com"
}

variable "timestamp_field" {
  type        = string
  default     = "@timestamp"
  description = "Field Kibana identifies as Time field, when creating the index pattern"
}

variable "warm_transition" {
  type        = string
  default     = "1d"
  description = "Time until transition to warm storage"
}

variable "cold_transition" {
  type        = string
  default     = "30d"
  description = "Time until transition to cold storage"
}

variable "delete_transition" {
  type        = string
  default     = "366d"
  description = "Time until indexes are permanently deleted"
}

variable "index_pattern_live_modsec_audit" {
  default = [
    "live_k8s_modsec_ingress-*",
  ]
  description = "Pattern created in Kibana, policy will apply to matching new indices"
  type        = list(string)
}

variable "github_owner" {
  description = "The GitHub organization or individual user account containing the app's code repo. Used by the Github Terraform provider. See: https://user-guide.cloud-platform.service.justice.gov.uk/documentation/getting-started/ecr-setup.html#accessing-the-credentials"
  default     = "ministryofjustice"
  type        = string
}

variable "github_token" {
  description = "Required by the Github Terraform provider"
  default     = ""
  type        = string
}

variable "business_unit" {
  type    = string
  default = "Platforms"
}

variable "application" {
  type    = string
  default = "cloud-platform-aws/account"
}

variable "is_production" {
  type    = string
  default = "true"
}

variable "team_name" {
  type    = string
  default = "webops"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "infrastructure_support" {
  type    = string
  default = "Cloud Platform: platforms@digital.justice.gov.uk"
}

variable "index_pattern_live_app_logs" {
  default = [
    "manager_eventrouter*",
    "live_kubernetes_cluster*",
    "live_kubernetes_ingress*",
    "live_eventrouter*",
    "manager_kubernetes_cluster-*",
    "manager_kubernetes_ingress-*",
    "manager_concourse-*",
    "live_ipamd-*",
    "manager_ipamd-*",
  ]
  description = "Pattern created in Kibana, policy will apply to matching new indices"
  type        = list(string)
}

variable "index_pattern_live_2_app_logs" {
  default = [
    "live_2_kubernetes_cluster*",
    "live_2_kubernetes_ingress*",
    "live_2_eventrouter*",
    "live_2_ipamd-*",
  ]
  description = "Pattern created in Kibana, policy will apply to matching new indices"
  type        = list(string)
}
