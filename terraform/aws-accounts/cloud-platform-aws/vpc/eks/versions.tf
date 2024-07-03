terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.56.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
  }
  required_version = ">= 1.2.5"
}
