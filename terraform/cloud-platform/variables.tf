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
  default     = "21"
}

variable "master_node_machine_type" {
  description = "The AWS EC2 instance types to use for master nodes"
  default     = "c4.4xlarge"
}

variable "worker_node_machine_type" {
  description = "The AWS EC2 instance types to use for worker nodes"
  default     = "r5.2xlarge"
}

