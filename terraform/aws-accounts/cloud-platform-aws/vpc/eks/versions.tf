terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.44.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.28.1"
    }
  }
  required_version = ">= 1.2.5"
}
