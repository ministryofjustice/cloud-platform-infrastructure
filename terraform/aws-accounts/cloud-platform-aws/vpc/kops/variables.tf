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

variable "cluster_node_count_a" {
  description = "The number of worker node in the cluster in Availability Zone eu-west-2a"
  default = {
    live-1  = "1"
    default = "1"
  }
}

variable "cluster_node_count_b" {
  description = "The number of worker node in the cluster in Availability Zone eu-west-2b"
  default = {
    live-1  = "1"
    default = "1"
  }
}

variable "cluster_node_count_c" {
  description = "The number of worker node in the cluster in Availability Zone eu-west-2c"
  default = {
    live-1  = "1"
    default = "1"
  }
}

variable "worker_node_mixed_instance" {
  description = "The AWS mixed EC2 instance types to use for worker nodes, https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#mixedinstancespolicy-aws-only"
  default = {
    live-1  = ["r5.xlarge", "c5.xlarge", "r4.xlarge"]
    default = ["r5.large", "c5.large", "r4.large"]
  }
}

variable "master_node_machine_type" {
  description = "The AWS EC2 instance types to use for master nodes"
  default = {
    live-1  = "c5.4xlarge"
    default = "c5.large"
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

variable "enable_ingress_nodesgroup" {
  description = "Production clusters now have their own dedicated nodes for ingress controllers. By setting this option to true, three new nodes will be created."
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
