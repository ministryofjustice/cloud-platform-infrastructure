locals {
  c2s_create = "${length(var.slack_webhook) > 0 ? 1 : 0}"
}

data "archive_file" "c2s" {
  count = "${local.c2s_create}"

  type        = "zip"
  output_path = "${path.module}/resources/cloudwatch2slack.zip"

  source {
    content  = "${file("${path.module}/resources/cloudwatch2slack.js")}"
    filename = "index.js"
  }
}

data "aws_iam_policy_document" "c2s_assume" {
  count = "${local.c2s_create}"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "c2s" {
  count = "${local.c2s_create}"

  name               = "haproxy-${random_id.id.hex}-cloudwatch2slack"
  assume_role_policy = "${data.aws_iam_policy_document.c2s_assume.json}"
}

resource "aws_lambda_permission" "c2s" {
  count = "${local.c2s_create}"

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.c2s.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.c2s.arn}"
}

resource "aws_lambda_function" "c2s" {
  count = "${local.c2s_create}"

  function_name    = "haproxy-${random_id.id.hex}-cloudwatch2slack"
  handler          = "index.handler"
  runtime          = "nodejs8.10"
  role             = "${aws_iam_role.c2s.arn}"
  filename         = "${data.archive_file.c2s.output_path}"
  source_code_hash = "${data.archive_file.c2s.output_base64sha256}"

  environment {
    variables = {
      SLACK_WEBHOOK = "${var.slack_webhook}"
      SLACK_CHANNEL = "${var.slack_channel}"
    }
  }
}

resource "aws_sns_topic" "c2s" {
  count = "${local.c2s_create}"

  name = "haproxy-${random_id.id.hex}-cloudwatch2slack"
}

resource "aws_sns_topic_subscription" "c2s" {
  count = "${local.c2s_create}"

  topic_arn = "${aws_sns_topic.c2s.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.c2s.arn}"
}

module "alb_alarms" {
  source                         = "git::https://github.com/cloudposse/terraform-aws-alb-target-group-cloudwatch-sns-alarms.git?ref=0.5.1"
  name                           = "haproxy-${random_id.id.hex}"
  namespace                      = "${var.haproxy_domain}"
  stage                          = "prod"
  alb_name                       = "${aws_lb.haproxy_alb.name}"
  alb_arn_suffix                 = "${aws_lb.haproxy_alb.arn_suffix}"
  target_group_name              = "${aws_lb_target_group.haproxy_alb_target.name}"
  target_group_arn_suffix        = "${aws_lb_target_group.haproxy_alb_target.arn_suffix}"
  notify_arns                    = "${compact(concat(var.sns_arns, aws_sns_topic.c2s.*.arn))}"
  target_3xx_count_threshold     = "${var.alarm_target_3xx_count_threshold}"
  target_4xx_count_threshold     = "${var.alarm_target_4xx_count_threshold}"
  target_5xx_count_threshold     = "${var.alarm_target_5xx_count_threshold}"
  elb_5xx_count_threshold        = "${var.alarm_elb_5xx_count_threshold}"
  target_response_time_threshold = "${var.alarm_target_response_time_threshold}"
  treat_missing_data             = "notBreaching"
}
