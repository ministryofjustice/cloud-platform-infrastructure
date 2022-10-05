variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "172.20.0.0/16"
  type        = string
}

variable "internal_subnets" {
  type        = list(string)
  description = "List of subnet CIDR blocks that are not publicly accessible"
  default     = ["172.20.32.0/19", "172.20.64.0/19", "172.20.96.0/19"]
}

variable "external_subnets" {
  type        = list(string)
  description = "List of subnet CIDR blocks that are publicly accessible"
  default     = ["172.20.0.0/22", "172.20.4.0/22", "172.20.8.0/22"]
}

variable "availability_zones" {
  type        = list(string)
  description = "List of EC2 availability zones"
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "cluster_names" {
  description = "List of Clusters within Live-1 VPC test"
  default = {
    live-1 = ["live-1.cloud-platform.service.justice.gov.uk", "manager", "live"]
  }
  type = object({
    live-1 = list(string)
  })
}
