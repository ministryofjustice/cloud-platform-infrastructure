variable "vpc_name" {
  description = "The VPC name where the cluster(s) are going to be provisioned. VPCs are created in cloud-platform-network"
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "172.20.0.0/16"
}

variable "internal_subnets" {
  type        = list(string)
  description = "list of subnet CIDR blocks that are not publicly acceessibly"
  default     = ["172.20.32.0/19", "172.20.64.0/19", "172.20.96.0/19"]
}

variable "external_subnets" {
  type        = list(string)
  description = "list of subnet CIDR blocks that are publicly acceessibly"
  default     = ["172.20.0.0/22", "172.20.4.0/22", "172.20.8.0/22"]
}

variable "availability_zones" {
  type        = list(string)
  description = "a list of EC2 availability zones"
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "cluster_node_count" {
  description = "The number of worker node in the cluster"
  default = {
    live-1  = "21"
    default = "3"
  }
}

variable "master_node_machine_type" {
  description = "The AWS EC2 instance types to use for master nodes"
  default = {
    live-1  = "c4.4xlarge"
    default = "c4.large"
  }
}

variable "worker_node_machine_type" {
  description = "The AWS EC2 instance types to use for worker nodes"
  default = {
    live-1  = "r5.xlarge"
    default = "r5.large"
  }
}

variable "enable_large_nodesgroup" {
  description = "Due to Prometheus resource consumption we added a larger node groups (r5.2xlarge), this variable you enable the creation of it"
  type        = map(bool)
  default = {
    live-1  = true
    default = false
  }
}

variable "auth0_tenant_domain" {
  description = "The auth0 domain/tenant used, same for live/test clusters"
  default     = "justice-cloud-platform.eu.auth0.com"
}
