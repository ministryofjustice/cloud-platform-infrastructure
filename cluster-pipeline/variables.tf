// file: variables.tf

variable "fabric_name" {
  description = "the name of this fabric"
}

variable "fabric_region" {
  description = "the AWS region to provision the fabric into"
}

variable "domain_name" {
  description = "the base domain name (e.g. example.org)"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.10.0.0/16"
}

variable "internal_subnets" {
  type        = "list"
  description = "list of subnet CIDR blocks that are not publicly acceessibly"
  default     = ["10.10.160.0/20", "10.10.176.0/20", "10.10.192.0/20", "10.10.208.0/20"]
}

variable "external_subnets" {
  type        = "list"
  description = "list of subnet CIDR blocks that are publicly acceessibly"
  default     = []
}

variable "fabric_availability_zones" {
  type        = "list"
  description = "a list of EC2 availability zones"
}
