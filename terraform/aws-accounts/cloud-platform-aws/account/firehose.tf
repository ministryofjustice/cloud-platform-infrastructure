#### AWS Firehose to stream CloudWatch log groups to Cortex XSIAM

# live EKS logs to Cortex XSIAM
module "firehose_eks_live_logs_to_xsiam" {
  source                     = "github.com/ministryofjustice/cloud-platform-terraform-firehose-data-stream?ref=1.1.0"
  cloudwatch_log_group_names = [data.terraform_remote_state.eks_live.outputs.cloudwatch_log_group_name]
  destination_http_endpoint  = data.aws_ssm_parameter.account["cortex_xsiam_endpoint"].value
}

# S3 bucket for RDS logs to Cortex XSIAM
module "rds_logs_to_cortex_s3" {
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

# live RDS DB logs to Cortex XSIAM
module "firehose_rds_test_logs_to_xsiam" {
  source                    = "github.com/ministryofjustice/cloud-platform-terraform-firehose-data-stream?ref=1.1.0"
  destination_http_endpoint = data.aws_ssm_parameter.account["cortex_xsiam_endpoint"].value
}
