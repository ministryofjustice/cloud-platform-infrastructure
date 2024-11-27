terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.78.0"
    }
  }
  required_version = ">= 1.2.5"
}
