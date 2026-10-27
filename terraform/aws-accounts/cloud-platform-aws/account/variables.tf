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

variable "legal_hold_delete_transition" {
  type        = string
  default     = "3650d"
  description = "Index age (from creation) at which indices on the legal-hold-retain policy are deleted. Lowering it deletes every held index older than the new value on the next ISM run - preview with scripts/opensearch/legal-hold/change_policy_cold.sh preview-lift first."
}

variable "enable_silas_log_restore" {
  type        = bool
  default     = true
  description = "Create the temporary cp-silas-log-restore OpenSearch domain (app-opensearch-silas-restore.tf). Set to false to tear it down."
}

variable "silas_log_restore_instance_type" {
  type        = string
  default     = "r6g.large.search"
  description = "Data node instance type for the cp-silas-log-restore domain (3 nodes)."
}

variable "silas_log_restore_volume_size" {
  type        = number
  default     = 1000
  description = "gp3 storage (GB) per data node for the cp-silas-log-restore domain. Must hold the largest restored index (~1.6 TB) across all nodes."
}

variable "silas_log_restore_audit_log_retention_days" {
  type        = number
  default     = 400
  description = "CloudWatch retention for cp-silas-log-restore audit logs."
}

variable "silas_log_restore_reader_teams" {
  type        = list(string)
  default     = ["laa-portal-stabilisation-tech"]
  description = "GitHub teams with read-only access to silas150-extract-* on cp-silas-log-restore."
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
