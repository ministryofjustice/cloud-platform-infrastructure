variable "vpc_name" {
  description = "The VPC name where the cluster(s) are going to be provisioned. VPCs are created in cloud-platform-network"
  default     = ""
}

variable "cluster_node_count" {
  description = "The number of worker node in the cluster"
  default     = "4"
}

variable "worker_node_machine_type" {
  description = "The AWS EC2 instance types to use for worker nodes"
  default     = "m4.large"
}

