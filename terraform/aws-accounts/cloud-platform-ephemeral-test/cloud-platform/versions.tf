terraform {
  required_providers {
    auth0 = {
      source  = "alexkappa/auth0"
      version = "= 0.19.0"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 0.13"
}
