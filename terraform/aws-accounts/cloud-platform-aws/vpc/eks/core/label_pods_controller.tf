module "label_pods_controller" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-label-pods?ref=1.2.0"

  chart_version = "1.0.2"
  # https://github.com/ministryofjustice/cloud-platform-infrastructure/blob/main/terraform/aws-accounts/cloud-platform-aws/account/ecr.tf
  ecr_url   = "754256621582.dkr.ecr.eu-west-2.amazonaws.com/webops/cloud-platform-terraform-label-pods"
  image_tag = "1.2.0"

  depends_on = [
    "cert_manager"
  ]
}
