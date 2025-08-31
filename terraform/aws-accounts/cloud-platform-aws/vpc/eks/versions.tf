terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.27.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.11.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }
  required_version = ">= 1.2.5"
}
