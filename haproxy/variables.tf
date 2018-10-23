variable "aws_region" {
  description = "Home AWS region"
  default     = "eu-west-1"
}

variable "aws_hapee_instance_type" {
  description = "Default AWS instance type for HAPEE nodes"
  default     = "t2.micro"
}

variable "hapee_cluster_size" {
  description = "Size of HAPEE nodes cluster"
  default     = 1
}

# HAPEE 1.7 Ubuntu
variable "hapee_aws_amis" {
  default = {
    "eu-west-1" = "ami-7b6a3a02"
  }
}
