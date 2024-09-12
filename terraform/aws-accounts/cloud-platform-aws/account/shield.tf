# Create IAM Role for AWS Shield Advanced SRT (Shield Response Team) support role
resource "aws_iam_role" "srt_role" {
  name = "AWSSRTSupport"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "drt.shield.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "shield_response_team_role_policy_attachment" {
  role       = aws_iam_role.srt_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSShieldDRTAccessPolicy"
}

resource "aws_shield_drt_access_role_arn_association" "main" {
  role_arn = aws_iam_role.srt_role.arn
}

# Shield Advanced Protection for Route 53
resource "aws_shield_protection" "cloud_platform_public_hosted_zone" {
  name         = "cloud-platform-public-hosted-zone"
  resource_arn = aws_route53_zone.cloud_platform_justice_gov_uk.arn
}

# hosted zone DDoS monitoring
# https://docs.aws.amazon.com/waf/latest/developerguide/get-started-fms-shield-cloudwatch.html
# Amazon SNS notifications of potential DDoS activity are not sent in real time and can be delayed. 
# To enable real-time notifications of potential DDoS activity, we need to use a CloudWatch alarm.
resource "aws_cloudwatch_metric_alarm" "ddos_attack_public_hosted_zone" {
  alarm_name          = "DDoSDetected-cloud-platform-public-hosted-zone"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = "1"
  evaluation_periods  = "20"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm for DDoS events detected on resource ${aws_route53_zone.cloud_platform_justice_gov_uk.arn}"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [module.baselines.slack_sns_topic]
  ok_actions          = [module.baselines.slack_sns_topic]
  dimensions = {
    ResourceArn = aws_route53_zone.cloud_platform_justice_gov_uk.arn
  }
}