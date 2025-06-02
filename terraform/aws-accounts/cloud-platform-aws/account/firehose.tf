#### AWS Firehose to stream CloudWatch log groups to Cortex XSIAM

# test cluster EKS logs to Cortex XSIAM preproduction environment
module "firehose_eks_logs_to_xsiam" {
  source                     = "github.com/ministryofjustice/cloud-platform-terraform-firehose-data-stream?ref=1.0.0"
  cloudwatch_log_group_names = ["/aws/eks/cp-0206-0839/cluster"]
  destination_http_endpoint  = data.aws_ssm_parameter.account["cortex_xsiam_endpoint"].value
}