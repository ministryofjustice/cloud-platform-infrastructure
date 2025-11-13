# IAM role for Cortex XSIAM to access Cloud Platform logs via SQS/S3

resource "random_uuid" "cortex_xsiam" {}

resource "aws_ssm_parameter" "cortex_xsiam_external_id" {
  name        = "/cortex-xsiam/external-id"
  description = "External ID for Cortex XSIAM role assumption"
  type        = "SecureString"
  value       = random_uuid.cortex_xsiam.result

  tags = {
    business-unit          = var.business_unit
    application            = var.application
    is-production          = var.is_production
    environment-name       = var.environment
    owner                  = var.team_name
    infrastructure-support = var.infrastructure_support
  }
}

data "aws_iam_policy_document" "cortex_xsiam_policy" {
  statement {
    sid    = "SQSQueueReceiveMessages"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ListQueues",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [
      aws_sqs_queue.cp_cloudtrail_log_queue.arn,
      aws_sqs_queue.cp_vpc_flowlogs_log_queue.arn,
      aws_sqs_queue.cp_route53_log_queue.arn,
      aws_sqs_queue.cp_application_logs_queue.arn,
      aws_sqs_queue.cp_cloudfront_logs_queue.arn,
      aws_sqs_queue.cp_modsec_logs_queue.arn,
      aws_sqs_queue.cp_rds_logs_queue.arn
    ]
  }
  statement {
    sid     = "SQSReadLoggingS3"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      module.baselines.cloudtraillogs_bucket_arn[0][0],
      "${module.baselines.cloudtraillogs_bucket_arn[0][0]}/*",
      data.terraform_remote_state.live-1.outputs.vpc_flowlogs_bucket_arn,
      "${data.terraform_remote_state.live-1.outputs.vpc_flowlogs_bucket_arn}/*",
      data.terraform_remote_state.live-1.outputs.route53_query_log_bucket_arn,
      "${data.terraform_remote_state.live-1.outputs.route53_query_log_bucket_arn}/*",
      data.terraform_remote_state.components_live.outputs.s3_bucket_application_logs_arn,
      "${data.terraform_remote_state.components_live.outputs.s3_bucket_application_logs_arn}/*",
      module.cloudfront_cortex_logs.bucket_arn,
      "${module.cloudfront_cortex_logs.bucket_arn}/*",
      data.terraform_remote_state.components_live.outputs.s3_bucket_modsec_logs_arn,
      "${data.terraform_remote_state.components_live.outputs.s3_bucket_modsec_logs_arn}/*",
      data.terraform_remote_state.components_live.outputs.s3_bucket_non_prod_modsec_logs_arn,
      "${data.terraform_remote_state.components_live.outputs.s3_bucket_non_prod_modsec_logs_arn}/*",
      module.rds_logs_to_cortex_s3.bucket_arn,
      "${module.rds_logs_to_cortex_s3.bucket_arn}/*"
    ]
  }
  statement {
    sid       = "KMSDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "cortex_xsiam_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::006742885340:root"]
      # Palo Alto Cortex AWS Account ID
      # Taken from https://docs-cortex.paloaltonetworks.com/r/Cortex-XDR/Cortex-XDR-Pro-Administrator-Guide/Create-an-Assumed-Role
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [sensitive(random_uuid.cortex_xsiam.result)]
    }
  }
}

# IAM policy for Cortex XSIAM
resource "aws_iam_policy" "cortex_xsiam_policy" {
  name        = "cortex-xsiam-log-collection-policy"
  description = "Allows Cortex XSIAM access to SQS queues and S3 log buckets"
  policy      = data.aws_iam_policy_document.cortex_xsiam_policy.json
}

resource "aws_iam_role" "cortex_xsiam_role" {
  name_prefix        = "cortex_xsiam"
  description        = "Role utilised by Palo Alto Cortex XSIAM for log collection"
  assume_role_policy = data.aws_iam_policy_document.cortex_xsiam_trust_policy.json

  tags = {
    business-unit          = var.business_unit
    application            = var.application
    is-production          = var.is_production
    environment-name       = var.environment
    owner                  = var.team_name
    infrastructure-support = var.infrastructure_support
  }
}

resource "aws_iam_role_policy_attachment" "cortex_xsiam_role" {
  role       = aws_iam_role.cortex_xsiam_role.name
  policy_arn = aws_iam_policy.cortex_xsiam_policy.arn
}
