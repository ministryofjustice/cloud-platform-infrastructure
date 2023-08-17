variable "timestamp_field" {
  type        = string
  default     = "@timestamp"
  description = "Field Kibana identifies as Time field, when creating the index pattern"
}

variable "warm_transition" {
  type        = string
  default     = "7d"
  description = "Time until transition to warm storage"
}

variable "cold_transition" {
  type        = string
  default     = "14d"
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
