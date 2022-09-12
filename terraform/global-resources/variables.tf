variable "timestamp_field" {
  type        = string
  default     = "last_updated"
  description = "Field Kibana identifies as Time field, when creating the index pattern"
}

variable "warm_transition" {
  type        = string
  default     = "7d"
  description = "Time until transition to warm storage"
}

variable "cold_transition" {
  type        = string
  default     = "30d"
  description = "Time until transition to cold storage"
}

variable "delete_transition" {
  type        = string
  default     = "365d"
  description = "Time until indexes are permanently deleted"
}

variable "index_pattern" {
  default     = [
    "test_data*",
    "test_data_2*"
  ]
  description = "Pattern created in Kibana, policy will apply to matching new indices"
}