terraform {
  required_providers {
    auth0 = {
      source  = "alexkappa/auth0"
      version = "0.26.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.68.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.9.0"
    }
  }
  required_version = ">= 0.14"
}
