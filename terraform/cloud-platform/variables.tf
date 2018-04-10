variable "region" {
  default = "eu-west-1"
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

variable "availability_zones" {
  type        = "list"
  description = "a list of EC2 availability zones"
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}
