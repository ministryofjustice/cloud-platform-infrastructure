provider "opensearch" {
  alias               = "app_logs"
  url                 = "https://${aws_opensearch_domain.live_app_logs.endpoint}"
  aws_assume_role_arn = aws_iam_role.os_access_role_app_logs.arn
  aws_profile         = "moj-cp"
  sign_aws_requests   = true
  healthcheck         = false
  sniff               = false
}

# Create a channel configuration to replace elasticsearch_opensearch_destination


# Create opensearch monitoring and alert setting
