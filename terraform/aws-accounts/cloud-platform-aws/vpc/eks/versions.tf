terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "0.34.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.23.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
    alexkappa = {
      source  = "alexkappa/auth0"
      version = "0.26.2"
    }
  }
  required_version = ">= 0.14"
}
