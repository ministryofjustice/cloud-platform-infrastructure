#### AWS Firehose to stream CloudWatch log groups to Cortex XSIAM

data "aws_cloudwatch_log_groups" "rds_cloud_platform_logs" {
  log_group_name_prefix = "/aws/rds/instance/cloud-platform"
}

# live EKS logs to Cortex XSIAM
module "firehose_eks_live_logs_to_xsiam" {
  source                     = "github.com/ministryofjustice/cloud-platform-terraform-firehose-data-stream?ref=1.0.0"
  cloudwatch_log_group_names = [data.terraform_remote_state.eks_live.outputs.cloudwatch_log_group_name]
  destination_http_endpoint  = data.aws_ssm_parameter.account["cortex_xsiam_endpoint"].value
}

# RDS DB logs to Cortex XSIAM
module "firehose_rds_test_logs_to_xsiam" {
  source                     = "github.com/ministryofjustice/cloud-platform-terraform-firehose-data-stream?ref=1.0.0"
  cloudwatch_log_group_names = data.aws_cloudwatch_log_groups.rds_cloud_platform_logs.log_group_names
  destination_http_endpoint  = data.aws_ssm_parameter.account["cortex_xsiam_endpoint"].value
}
