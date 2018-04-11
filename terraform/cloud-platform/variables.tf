variable "vpc_cidr" {
  description = "CIDR block for the VPC"
}

variable "internal_subnets" {
  type        = "list"
  description = "list of subnet CIDR blocks that are not publicly acceessibly"
}

variable "external_subnets" {
  type        = "list"
  description = "list of subnet CIDR blocks that are publicly acceessibly"
}

variable "availability_zones" {
  type        = "list"
  description = "a list of EC2 availability zones"
}
