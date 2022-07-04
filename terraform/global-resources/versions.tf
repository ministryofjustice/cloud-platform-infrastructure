terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 0.30.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.20.1"
    }
    external = {
      source = "hashicorp/external"
    }
    http = {
      source = "hashicorp/http"
    }
  }
  required_version = ">= 0.14"
}
