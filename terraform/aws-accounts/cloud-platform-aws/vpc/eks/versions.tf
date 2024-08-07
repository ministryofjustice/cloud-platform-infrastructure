terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.61.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
  }
  required_version = ">= 1.2.5"
}
