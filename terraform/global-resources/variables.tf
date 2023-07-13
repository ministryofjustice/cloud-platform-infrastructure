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

variable "index_pattern_live_2" {
  default = [
    "live-2_kubernetes_cluster*",
    "live-2_kubernetes_ingress*",
    "live-2_eventrouter*",
  ]
  description = "Pattern created in Kibana, policy will apply to matching new indices"
  type        = list(string)
}


# secrets manager variables
variable "team_name" {
  type        = string
  description = "Name of the team that owns the application"
  default = "webops"
}

variable "application" {
  type        = string
  description = "Name of the application"
  default = "global-resources"
}

variable "business_unit" {
  type        = string
  description = "Name of the business unit that owns the application"
  default = "Platforms"
}

variable "is_production" {
  type        = string
  description = "Is this a production application?"
  default = "true"
}

variable "namespace" {
  type        = string
  description = "Namespace of the application"
  default = "monitoring"
}

variable "environment" {
  type        = string
  description = "Environment of the application"
  default = "Production"
}

variable "infrastructure_support" {
  type        = string
  description = "Name of the team that supports the infrastructure"
  default = "cloud-platform"
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default = "live"
}