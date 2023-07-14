#############################################
# Secrets for use across the Cloud Platform #
#############################################

# Slack Webhook URL
resource "aws_secretsmanager_secret" "slack_webhook_url" {
  name        = "cloud-platform/slack-webhook-url"
  description = "url used for kibana to post alerts to a channel"
}

resource "aws_secretsmanager_secret_version" "slack_webhook_url" {
  secret_id = aws_secretsmanager_secret.slack_webhook_url.id
  secret_string = jsonencode({
    url = "CHANGE_ME_IN_THE_CONSOLE" # change this value manually in the console once the secret is created
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Data call to fetch changed value
data "aws_secretsmanager_secret_version" "slack_webhook_url" {
  secret_id = aws_secretsmanager_secret.slack_webhook_url.id
}