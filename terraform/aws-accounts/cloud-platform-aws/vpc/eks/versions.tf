terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.36.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.23.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }
  required_version = ">= 1.2.5"
}
