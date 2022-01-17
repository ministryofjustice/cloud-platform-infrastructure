terraform {
  required_providers {
    auth0 = {
      source  = "alexkappa/auth0"
      version = "= 0.19.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.68.0"
    }
  }
  required_version = ">= 0.13"
}
