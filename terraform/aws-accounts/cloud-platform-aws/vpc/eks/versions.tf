terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.9.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.23.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
  }
  required_version = ">= 1.5.7"
}
