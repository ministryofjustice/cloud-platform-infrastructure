terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "0.41.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.48.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.16.1"
    }
  }
  required_version = ">= 1.2.5"
}

