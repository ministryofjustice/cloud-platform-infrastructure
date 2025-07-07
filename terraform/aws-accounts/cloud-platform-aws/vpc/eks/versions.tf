terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.23.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
  }
  required_version = ">= 1.2.5"
}
