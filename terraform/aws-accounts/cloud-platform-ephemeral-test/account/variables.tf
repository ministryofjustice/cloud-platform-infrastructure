variable "slack_config_cloudwatch_lp" {
  description = "Add Slack webhook API URL for integration with slack."
  type        = string
}

variable "aws_region" {
  description = "The AWS Account region name"
  type        = string
  default     = "eu-west-2"
}

# variable "auth0_tenant_domain" {
#   description = "Auth0 domain"
#   type        = string
#   default     = "moj-cloud-platforms-dev.eu.auth0.com"
# }

variable "timestamp_field" {
  type        = string
  default     = "@timestamp"
  description = "Field Kibana identifies as Time field, when creating the index pattern"
}

variable "warm_transition" {
  type        = string
  default     = "14d"
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

variable "index_pattern" {
  default = [
    "manager_eventrouter*",
    "live_kubernetes_cluster*",
    "live_kubernetes_ingress*",
    "live_eventrouter*",
    "manager_kubernetes_cluster-*",
    "manager_kubernetes_ingress-*",
    "manager_concourse-*",
  ]
  description = "Pattern created in Kibana, policy will apply to matching new indices"
  type        = list(string)
}

variable "index_pattern_live_modsec_audit" {
  default = [
    "live_k8s_modsec_ingress-*",
  ]
  description = "Pattern created in Kibana, policy will apply to matching new indices"
  type        = list(string)
}
