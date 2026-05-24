terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.47.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.46.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.1.0"
    }
  }
  required_version = ">= 1.2.5"
}
