terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 0.35.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.25.0"
    }
    github = {
      source = "integrations/github"
    }
    curl = {
      source  = "anschoewe/curl"
      version = "~> 1.0.2"
    }
  }
  required_version = ">= 0.14"
}
