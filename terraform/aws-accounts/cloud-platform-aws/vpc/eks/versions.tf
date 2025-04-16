terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.15.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.94.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
  }
  required_version = ">= 1.2.5"
}
