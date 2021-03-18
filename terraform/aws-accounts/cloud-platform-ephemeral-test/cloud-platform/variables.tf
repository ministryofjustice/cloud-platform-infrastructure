variable "vpc_name" {
  description = "The VPC name where the cluster(s) are going to be provisioned. VPCs are created in cloud-platform-network"
  default     = ""
}

variable "auth0_tenant_domain" {
  description = "This is the auth0 tenant domain"
  default     = "justice-cloud-platform.eu.auth0.com"
}

variable "cluster_node_count_a" {
  description = "The number of worker node in the cluster in Availability Zone eu-west-2a"
  default = {
    live-1  = "9"
    default = "1"
  }
}

variable "cluster_node_count_b" {
  description = "The number of worker node in the cluster in Availability Zone eu-west-2b"
  default = {
    live-1  = "9"
    default = "1"
  }
}

variable "cluster_node_count_c" {
  description = "The number of worker node in the cluster in Availability Zone eu-west-2c"
  default = {
    live-1  = "9"
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

variable "enable_ingress_nodesgroup" {
  description = "Production clusters now have their own dedicated nodes for ingress controllers. By setting this option to true, three new nodes will be created."
  type        = map(bool)
  default = {
    live-1  = true
    default = false
  }
}
