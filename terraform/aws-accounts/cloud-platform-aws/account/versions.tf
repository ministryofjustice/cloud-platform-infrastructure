terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.48.0"
    }
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 0.35.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.2.3"
    }
    elasticsearch = {
      source  = "phillbaker/elasticsearch"
      version = "2.0.7"
    }
    curl = {
      source  = "anschoewe/curl"
      version = ">= 1.0.2"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=2.0.0"
    }
  }
  required_version = ">= 1.2.5"
}
