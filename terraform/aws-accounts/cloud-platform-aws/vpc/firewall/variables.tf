variable "firewall_external_net" {
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks for Suricata external networks"
  type        = list(string)
}

variable "firewall_home_net" {
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks for Suricata home networks"
  type        = list(string)
}

variable "firewall_log_group_prefix" {
  description = "Name prefix for CloudWatch log group"
  type        = string
}

variable "firewall_subnets" {
  description = "List of subnet IDs to place firewall endpoints into"
  type        = list(string)
}

variable "firewall_vpc" {
  description = "The unique identifier of the VPC where AWS Network Firewall should create the firewall"
  type        = string
}