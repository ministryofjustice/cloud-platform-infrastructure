terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.36.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
  }
  required_version = ">= 1.2.5"
}
