terraform {
  required_version = ">= 1.2.5"
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.36.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.5"
    }
    elasticsearch = {
      source  = "phillbaker/elasticsearch"
      version = "2.0.7"
    }
  }
}
