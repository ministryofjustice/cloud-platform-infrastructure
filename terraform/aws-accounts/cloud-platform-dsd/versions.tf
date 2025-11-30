terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.23.0"
    }
  }
  required_version = ">= 1.2.5"
}
