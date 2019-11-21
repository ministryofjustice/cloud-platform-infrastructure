module "cloudwatch_slack" {
  source  = "terraform-aws-modules/notify-slack/aws"
  version = "~> 1.0"

  sns_topic_name = "slack-lower-priority-alarms"

  slack_channel        = "lower-priority-alarms"
  slack_username       = "reporter"
  slack_webhook_url    = var.slack_config_cloudwatch_lp
  lambda_function_name = "cloudwatch_to_slack_lp"
}

resource "aws_cloudwatch_event_rule" "dlm_state" {
  name        = "dlm_policy_state"
  description = "DLM Policy State Change"

  event_pattern = <<PATTERN
	{
  "source": [
    "aws.dlm"
  ],
  "detail-type": [
    "DLM Policy State Change"
  ],
  "detail": {
    "state": [
      "ERROR"
    ]
  }
}
PATTERN


  depends_on = [module.cloudwatch_slack]
}

resource "aws_cloudwatch_event_target" "dlm_sns" {
  rule      = aws_cloudwatch_event_rule.dlm_state.name
  target_id = "SendToSNS"
  arn       = module.cloudwatch_slack.this_slack_topic_arn

  depends_on = [aws_cloudwatch_event_rule.dlm_state]
}

