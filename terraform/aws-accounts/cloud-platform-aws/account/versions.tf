terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 0.30.0"
    }
    aws = {
      source  = "hashicorp/aws"
    }
    github = {
      source = "integrations/github"
    }
    curl = {
      source  = "anschoewe/curl"
      version = "~> 0.1.4"
    }
  }
  required_version = ">= 0.14"
}
