terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.12.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.86.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
  }
  required_version = ">= 1.2.5"
}
