terraform {
  required_providers {
    auth0 = {
      source  = "alexkappa/auth0"
      version = "0.26.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.22.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }
  required_version = ">= 0.14"
}
