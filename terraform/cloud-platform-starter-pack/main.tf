
terraform {
  backend "s3" {
  }
}


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

/*
 * Make sure that you use the latest version of the module by changing the
 * `ref=` value in the `source` attribute to the latest version listed on the
 * releases page of this repository.
 *
 */
module "starter_pack" {
  source               = "../../../cloud-platform-terraform-starter-pack/"
  namespace            = kubernetes_namespace.starter-pack.id
}


resource "kubernetes_namespace" "starter-pack-1" {
  metadata {
    name = "starter-pack-1"

    labels = {
      "name" = "starter-pack-1"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"   = "Cloud Platform starter pack test app"
      "cloud-platform.justice.gov.uk/business-unit" = "cloud-platform"
      "cloud-platform.justice.gov.uk/owner"         = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"   = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}

/*
 * Make sure that you use the latest version of the module by changing the
 * `ref=` value in the `source` attribute to the latest version listed on the
 * releases page of this repository.
 *
 */
module "starter_pack_1" {
  source               = "../../../cloud-platform-terraform-starter-pack/"
  namespace            = kubernetes_namespace.starter-pack-1.id
}


