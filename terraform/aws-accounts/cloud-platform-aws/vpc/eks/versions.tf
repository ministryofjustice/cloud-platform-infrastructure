terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "0.41.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.8.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
  }
  required_version = ">= 1.2.5"
}
