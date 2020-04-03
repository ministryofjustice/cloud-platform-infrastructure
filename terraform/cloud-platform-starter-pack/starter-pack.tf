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
  source                      = "github.com/ministryofjustice/cloud-platform-terraform-starter-pack?ref=0.0.1"
  namespace                   = kubernetes_namespace.starter-pack.id
}

