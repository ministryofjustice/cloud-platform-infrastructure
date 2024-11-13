terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.7.3"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.75.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.33.0"
    }
  }
  required_version = ">= 1.2.5"
}
