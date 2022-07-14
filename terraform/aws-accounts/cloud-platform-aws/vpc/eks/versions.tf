terraform {
  required_providers {
    auth0 = {
      source  = "alexkappa/auth0"
      version = "0.19.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.20.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }
  required_version = ">= 0.14"
}
