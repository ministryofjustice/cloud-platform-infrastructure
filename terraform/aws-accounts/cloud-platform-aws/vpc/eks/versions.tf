terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.1.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.24.0"
    }
  }
  required_version = ">= 1.2.5"
}
