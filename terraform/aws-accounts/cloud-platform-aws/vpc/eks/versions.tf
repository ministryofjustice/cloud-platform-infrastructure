terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.1.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.32.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.25.2"
    }
  }
  required_version = ">= 1.2.5"
}
