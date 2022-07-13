terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "0.33.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.20.1"
    }
    github = {
      source  = "integrations/github"
      version = "4.14.0"
    }
    curl = {
      source  = "anschoewe/curl"
      version = "0.1.4"
    }
  }
  required_version = ">= 0.14"
}
