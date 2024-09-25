terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.6.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.68.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
  }
  required_version = ">= 1.2.5"
}
