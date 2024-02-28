terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.1.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.38.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.26.0"
    }
  }
  required_version = ">= 1.2.5"
}
