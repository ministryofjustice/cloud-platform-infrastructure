terraform {
  backend "s3" {
    bucket  = "cloud-platform-terraform-state"
    key     = "transit-gateway/terraform.tfstate"
    region  = "eu-west-1"
    profile = "moj-cp"
  }
}
