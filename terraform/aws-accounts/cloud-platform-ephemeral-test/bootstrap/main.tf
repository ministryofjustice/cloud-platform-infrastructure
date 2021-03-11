provider "aws" {
  region = "eu-west-2"
}

module "tfstate_backend" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-tfstate-backend?ref=0.0.3"

  s3_bucket_name    = "cloud-platform-ephemeral-test-tfstate"
  region            = "eu-west-2"
  dynamo_table_name = "cloud-platform-ephemeral-test-tfstate"
}
