// file: vpc/variables.tf

variable "cidr_block" {
  description = "CIDR block range for the VPC"
}

variable "external_subnets" {
  description = "List of external subnets"
  type        = "list"
}

variable "internal_subnets" {
  description = "List of internal subnets"
  type        = "list"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = "list"
}

variable "name" {
  description = "VPC name (e.g. myvpc)"
}