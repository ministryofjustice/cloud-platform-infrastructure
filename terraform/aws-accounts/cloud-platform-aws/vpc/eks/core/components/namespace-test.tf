variable "team_name" {
  type        = string
  default = "Cloud Platform"
}

variable "business_unit" {
  type        = string
  default = "Platforms"
}

variable "application" {
  type        = string
  default = "Testing"
}

variable "is_production" {
  type        = bool
  default     = false
}

variable "environment" {
  type        = string
  default     = "test"
}

variable "infrastructure_support" {
  type        = string
  default     = "Testing"
}

variable "eks_cluster_name" {
  type        = string
  default     = "cp-0408-0811"
}

resource "kubernetes_namespace" "test-engress" {
  metadata {
    name = "test-egress"

    labels = {
      "component"                          = "cloud-platform-testing"
      "pod-security.kubernetes.io/enforce" = "restricted"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"                = "Cloud Platform Testing"
      "cloud-platform.justice.gov.uk/business-unit"              = "Platforms"
      "cloud-platform.justice.gov.uk/owner"                      = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "cloud-platform.justice.gov.uk/can-tolerate-master-taints" = "true"
      "cloud-platform-out-of-hours-alert"                        = "true"
    }
  }    
}

module "s3_bucket" {

  source                 = "github.com/ministryofjustice/cloud-platform-terraform-s3-bucket?ref=5.3.0"
  team_name              = var.team_name
  business_unit          = var.business_unit
  application            = var.application
  is_production          = var.is_production
  environment_name       = var.environment
  infrastructure_support = var.infrastructure_support
  namespace              = kubernetes_namespace.test-engress.metadata[0].name

}

module "irsa" {
  #always replace with latest version from Github
  source = "github.com/ministryofjustice/cloud-platform-terraform-irsa?ref=2.1.0"

  eks_cluster_name = var.eks_cluster_name

  service_account_name = "irsa-service-account"
  namespace            = kubernetes_namespace.test-engress.metadata[0].name
  role_policy_arns = {
    s3     = module.s3_bucket.irsa_policy_arn
  }

  business_unit          = var.business_unit
  application            = var.application
  is_production          = var.is_production
  team_name              = var.team_name
  environment_name       = var.environment
  infrastructure_support = var.infrastructure_support
}

module "service_pod" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-service-pod?ref=1.2.0" # use the latest release

  namespace            = kubernetes_namespace.test-engress.metadata[0].name
  service_account_name = module.irsa.service_account.name
}

resource "kubernetes_secret" "s3_bucket" {
  metadata {
    name      = "s3-bucket-output"
    namespace = kubernetes_namespace.test-engress.metadata[0].name
  }

  data = {
    bucket_arn  = module.s3_bucket.bucket_arn
    bucket_name = module.s3_bucket.bucket_name
  }
}