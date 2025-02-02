terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.11.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
  }
  required_version = ">= 1.2.5"
}
