resource "kubernetes_namespace" "starter-pack" {
  metadata {
    name = "starter-pack"

    labels = {
      "name" = "starter-pack"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"   = "Cloud Platform starter pack test app"
      "cloud-platform.justice.gov.uk/business-unit" = "cloud-platform"
      "cloud-platform.justice.gov.uk/owner"         = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"   = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}


module "starter_pack" {
  source                      = "github.com/ministryofjustice/cloud-platform-starter-pack?ref=1.0"
  cluster_name                = var.cluster_name
  cluster_state_bucket        = var.cluster_state_bucket
  namespace                   = var.namespace

  providers = {
    # Can be either "aws.london" or "aws.ireland"
    aws = aws.london
  }
}