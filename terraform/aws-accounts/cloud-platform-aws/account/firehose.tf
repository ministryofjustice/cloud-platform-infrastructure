#### AWS Firehose to stream CloudWatch log groups to Cortex XSIAM

# live EKS logs to Cortex XSIAM
module "firehose_eks_live_logs_to_xsiam" {
  source                     = "github.com/ministryofjustice/cloud-platform-terraform-firehose-data-stream?ref=1.0.0"
  cloudwatch_log_group_names = [data.terraform_remote_state.eks_live.outputs.cloudwatch_log_group_name]
  destination_http_endpoint  = data.aws_ssm_parameter.account["cortex_xsiam_endpoint"].value
}

module "test_firehose_eks_app_logs_to_xsiam" {
  source                     = "github.com/ministryofjustice/cloud-platform-terraform-firehose-data-stream?ref=no-loggroup"
  destination_http_endpoint  = data.aws_ssm_parameter.account["cortex_xsiam_endpoint_preprod"].value
}