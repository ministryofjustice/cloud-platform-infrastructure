terraform {
  required_version = ">= 1.2.5"
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.9.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.80.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.4"
    }
    elasticsearch = {
      source  = "phillbaker/elasticsearch"
      version = "2.0.7"
    }
  }
}
