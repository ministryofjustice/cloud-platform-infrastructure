variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "172.20.0.0/16"
}

variable "internal_subnets" {
  type        = "list"
  description = "list of subnet CIDR blocks that are not publicly acceessibly"
  default     = ["172.20.32.0/19", "172.20.64.0/19", "172.20.96.0/19"]
}

variable "external_subnets" {
  type        = "list"
  description = "list of subnet CIDR blocks that are publicly acceessibly"
  default     = ["172.20.0.0/22", "172.20.4.0/22", "172.20.8.0/22"]
}

variable "availability_zones" {
  type        = "list"
  description = "a list of EC2 availability zones"
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}
