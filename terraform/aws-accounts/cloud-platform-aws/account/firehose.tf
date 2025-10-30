#### AWS Firehose to stream CloudWatch log groups to Cortex XSIAM

# live EKS logs to Cortex XSIAM
module "firehose_eks_live_logs_to_xsiam" {
  source                     = "github.com/ministryofjustice/cloud-platform-terraform-firehose-data-stream?ref=1.1.0"
  cloudwatch_log_group_names = [data.terraform_remote_state.eks_live.outputs.cloudwatch_log_group_name]
  destination_http_endpoint  = data.aws_ssm_parameter.account["cortex_xsiam_endpoint"].value
}

# live RDS DB logs to Cortex XSIAM via S3 bucket (testing)
module "s3" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-s3-bucket?ref=5.3.0"

  # S3 configuration
  versioning = true

  # Tags
  namespace              = "cloud-platform"
  business_unit          = var.business_unit
  application            = var.application
  is_production          = var.is_production
  team_name              = var.team_name
  environment_name       = var.environment
  infrastructure_support = var.infrastructure_support
}

module "firehose_rds_live_logs_to_xsiam" {
  source                    = "github.com/ministryofjustice/cloud-platform-terraform-firehose-data-stream?ref=1.1.0"
  destination_bucket_arn    = module.s3.bucket_arn

  depends_on = [
    module.s3
  ]
}

# Current live RDS setup from firehose --> XSIAM https endpoint
module "firehose_rds_test_logs_to_xsiam" {
  source                    = "github.com/ministryofjustice/cloud-platform-terraform-firehose-data-stream?ref=1.1.0"
  destination_http_endpoint = data.aws_ssm_parameter.account["cortex_xsiam_endpoint"].value
}