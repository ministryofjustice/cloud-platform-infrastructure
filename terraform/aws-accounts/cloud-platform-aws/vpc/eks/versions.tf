terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.48.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.29.0"
    }
  }
  required_version = ">= 1.2.5"
}
