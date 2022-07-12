terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "=0.30.3"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "=4.20.1"
    }
    external = {
      source  = "hashicorp/external"
      version = "=2.2.2"
    }
    http = {
      source  = "hashicorp/http"
      version = "=2.2.0"
    }
  }
  required_version = ">= 0.14"
}
