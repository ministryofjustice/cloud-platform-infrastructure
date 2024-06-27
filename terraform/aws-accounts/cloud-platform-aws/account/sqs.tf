#### This covers the SQS and related infrastructure that allows Cortex XSIAM service to access updates to the cloudtrail logging bucket

# SQS Queue to present the logging bucket updates
resource "aws_sqs_queue" "cp_cloudtrail_log_queue" {
  name                       = "cp_cloudtrail_log_queue"
  sqs_managed_sse_enabled    = true   # Using managed encryption
  delay_seconds              = 0      # The default is 0 but can be up to 15 minutes
  max_message_size           = 262144 # 256k which is the max size
  message_retention_seconds  = 345600 # This is 4 days. The max is 14 days
  visibility_timeout_seconds = 30     # This is only useful for queues that have multiple subscribers
}

# This policy grants queue send message from the cloudtrail logging bucket
resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.cp_cloudtrail_log_queue.id
  policy    = data.aws_iam_policy_document.queue_policy_document.json
}

data "aws_iam_policy_document" "queue_policy_document" {
  statement {
    sid    = "AllowSendMessage"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = ["sqs:SendMessage"]
    resources = [
      aws_sqs_queue.cp_cloudtrail_log_queue.arn
    ]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.baselines.cloudtraillogs_bucket_arn[0][0]]
    }
  }
}

# S3 bucket event notification for updates from the cloudtrail logging bucket
resource "aws_s3_bucket_notification" "logging_bucket_notification" {
  bucket = module.baselines.logging_buckets[0][0]
  queue {
    queue_arn = aws_sqs_queue.cp_cloudtrail_log_queue.arn
    events    = ["s3:ObjectCreated:*"] # Events to trigger the notification
  }
}

#### This covers the SQS and related infrastructure that allows Cortex XSIAM service to access updates to live-1 VPC Flowlogs logging bucket

# SQS Queue to present the VPC flowlogs bucket updates
resource "aws_sqs_queue" "cp_vpc_flowlogs_log_queue" {
  name                       = "cp_vpc_flowlogs_log_queue"
  sqs_managed_sse_enabled    = true   # Using managed encryption
  delay_seconds              = 0      # The default is 0 but can be up to 15 minutes
  max_message_size           = 262144 # 256k which is the max size
  message_retention_seconds  = 345600 # This is 4 days. The max is 14 days
  visibility_timeout_seconds = 30     # This is only useful for queues that have multiple subscribers
}

# This policy grants queue send message from the VPC flowlogs bucket
resource "aws_sqs_queue_policy" "vpc_flowlogs_queue_policy" {
  queue_url = aws_sqs_queue.cp_vpc_flowlogs_log_queue.id
  policy    = data.aws_iam_policy_document.vpc_flowlogs_queue_policy_document.json
}

data "aws_iam_policy_document" "vpc_flowlogs_queue_policy_document" {
  statement {
    sid    = "AllowSendMessage"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = ["sqs:SendMessage"]
    resources = [
      aws_sqs_queue.cp_vpc_flowlogs_log_queue.arn
    ]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["${data.terraform_remote_state.live-1.outputs.vpc_flowlogs_bucket_arn}"]
    }
  }
}

# S3 bucket event notification for updates from the VPC flowlogs bucket
resource "aws_s3_bucket_notification" "vpc_flowlogs_bucket_notification" {
  bucket = data.terraform_remote_state.live-1.outputs.vpc_flowlogs_bucket_arn
  queue {
    queue_arn = aws_sqs_queue.cp_vpc_flowlogs_log_queue.arn
    events    = ["s3:ObjectCreated:*"] # Events to trigger the notification
  }
}

##### IAM User & Resources to access the sqs queue and read cloudtrail bucket

# Create an IAM policy document to allow access to the SQS Queue and cloudtrail bucket
data "aws_iam_policy_document" "sqs_queue_read_document" {
  statement {
    sid    = "SQSQueueReceiveMessages"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ListQueues"
    ]
    resources = [
      aws_sqs_queue.cp_cloudtrail_log_queue.arn,
      aws_sqs_queue.cp_vpc_flowlogs_log_queue.arn
      ]
  }
  statement {
    sid       = "SQSReadLoggingS3"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [
      module.baselines.cloudtraillogs_bucket_arn[0][0], 
      "${module.baselines.cloudtraillogs_bucket_arn[0][0]}/*",
      "${data.terraform_remote_state.live-1.outputs.vpc_flowlogs_bucket_arn}",
      "${data.terraform_remote_state.live-1.outputs.vpc_flowlogs_bucket_arn}/*"
      ]
  }
}

# IAM policy to read the SQS queue and read Cloudtrail bucket
resource "aws_iam_policy" "sqs_queue_read_policy" {
  name        = "sqs-queue-read-policy"
  description = "Allows the access to the created SQS queue"
  policy      = data.aws_iam_policy_document.sqs_queue_read_document.json
}

# Creates an IAM user that will access the sqs queue and read Cloudtrail bucket
resource "aws_iam_user" "cortex_xsiam_user" {
  name = "cortex_xsiam_user"
  path = "/cloud-platform/soc/"
}

resource "aws_iam_user_policy_attachment" "sqs_queue_read_policy_attachment" {
  user       = "cortex_xsiam_user"
  policy_arn = aws_iam_policy.sqs_queue_read_policy.arn
}