terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "0.35.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.27.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "=2.2.2"
    }
    elasticsearch = {
      source  = "phillbaker/elasticsearch"
      version = "2.0.2"
    }
  }
  required_version = ">= 0.14"
}
