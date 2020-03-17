# -----------------------------------------------------------
# enable guard duty
# London - Master
# https://eu-west-2.console.aws.amazon.com/guardduty/home?region=eu-west-2#/findings?macros=current
# -----------------------------------------------------------

resource "aws_guardduty_detector" "master-london" {
  provider = aws.master-london

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# enable guard duty
# Ireland - Master
# https://eu-west-1.console.aws.amazon.com/guardduty/home?region=eu-west-1#/findings?macros=current
# -----------------------------------------------------------

resource "aws_guardduty_detector" "guardduty" {
  provider                     = aws.cloud-platform-ireland
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# set up S3 bucket
# Global
# https://s3.console.aws.amazon.com/s3/buckets/security20190204113202786400000001/?region=eu-west-1&tab=overview
# -----------------------------------------------------------

resource "aws_s3_bucket" "security" {
  provider      = aws.cloud-platform-ireland
  bucket_prefix = var.bucket_prefix
  acl           = "private"
  region        = var.aws_region

  lifecycle {
    prevent_destroy = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    {
      "Name" = "Security Bucket"
    },
    var.tags,
  )
}

resource "aws_s3_bucket_object" "ip_list" {
  provider     = aws.cloud-platform-ireland
  key          = "iplist.txt"
  bucket       = aws_s3_bucket.security.id
  source       = "${path.module}/resources/iplist.txt"
  content_type = "text/plain"
  etag         = filemd5("${path.module}/resources/iplist.txt")
}

# -----------------------------------------------------------
# set up iam group with appropriate iam policy
# Global
# https://console.aws.amazon.com/iam/home?region=eu-west-2#/groups/guardduty-admin
# https://console.aws.amazon.com/iam/home?region=eu-west-2#/roles/AWSServiceRoleForAmazonGuardDuty
# https://console.aws.amazon.com/iam/home?region=eu-west-2#/policies/arn:aws:iam::754256621582:policy/enable-guardduty
# https://console.aws.amazon.com/iam/home?region=eu-west-2#/policies/arn:aws:iam::754256621582:policy/security/access-security-bucket
# -----------------------------------------------------------

resource "aws_iam_policy" "enable_guardduty" {
  provider    = aws.cloud-platform-ireland
  name        = "enable-guardduty"
  path        = "/"
  description = "Allows setup and configuration of GuardDuty"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "guardduty:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "arn:aws:iam::${var.aws_master_account_id}:role/aws-service-role/guardduty.amazonaws.com/AWSServiceRoleForAmazonGuardDuty",
            "Condition": {
                "StringLike": {
                    "iam:AWSServiceName": "guardduty.amazonaws.com"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy"
            ],
            "Resource": "arn:aws:iam::${var.aws_master_account_id}:role/aws-service-role/guardduty.amazonaws.com/AWSServiceRoleForAmazonGuardDuty"
        }
    ]
}
EOF

}

resource "aws_iam_policy" "use_security_bucket" {
  provider    = aws.cloud-platform-ireland
  name        = "access-security-bucket"
  path        = "/security/"
  description = "Allows full access to the contents of the security bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "${aws_s3_bucket.security.arn}",
        "${aws_s3_bucket.security.arn}/*"
      ]
    }
  ]
}
EOF

}

resource "aws_iam_group" "guardduty" {
  provider = aws.cloud-platform-ireland
  name     = var.group_name
  path     = "/"
}

resource "aws_iam_group_policy_attachment" "enable" {
  provider   = aws.cloud-platform-ireland
  group      = aws_iam_group.guardduty.name
  policy_arn = aws_iam_policy.enable_guardduty.arn
}

resource "aws_iam_group_policy_attachment" "useS3bucket" {
  provider   = aws.cloud-platform-ireland
  group      = aws_iam_group.guardduty.name
  policy_arn = aws_iam_policy.use_security_bucket.arn
}

resource "aws_iam_group_policy_attachment" "access" {
  provider   = aws.cloud-platform-ireland
  group      = aws_iam_group.guardduty.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonGuardDutyFullAccess"
}

resource "aws_iam_group_policy_attachment" "s3readonly" {
  provider   = aws.cloud-platform-ireland
  group      = aws_iam_group.guardduty.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_group_membership" "guardduty" {
  provider = aws.cloud-platform-ireland
  name     = "guardduty-admin-members"
  group    = aws_iam_group.guardduty.name
  users    = var.users
}

# -----------------------------------------------------------
# set up AWS Cloudwatch Event rule for Guardduty Findings
# also to set up an event pattern (json file)
# London - Master
# https://eu-west-2.console.aws.amazon.com/cloudwatch/home?region=eu-west-2#rules:name=guardduty-finding-events-london
# -----------------------------------------------------------

resource "aws_cloudwatch_event_rule" "main-london" {
  provider      = aws.cloud-platform
  name          = "guardduty-finding-events-london"
  description   = "AWS GuardDuty event findings"
  event_pattern = file("${path.module}/resources/event-pattern.json")
}

# -----------------------------------------------------------
# set up AWS Cloudwatch Event rule for Guardduty Findings
# also to set up an event pattern (json file)
# Ireland - Master
# https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#rules:name=guardduty-finding-events 
# -----------------------------------------------------------

resource "aws_cloudwatch_event_rule" "main" {
  provider      = aws.cloud-platform-ireland
  name          = "guardduty-finding-events"
  description   = "AWS GuardDuty event findings"
  event_pattern = file("${path.module}/resources/event-pattern.json")
}

# -----------------------------------------------------------
# set up AWS Cloudwatch Event to target an sns topic for above event rule
# London  - Master
# https://eu-west-2.console.aws.amazon.com/cloudwatch/home?region=eu-west-2#rules:name=guardduty-finding-events-london
# -----------------------------------------------------------

resource "aws_cloudwatch_event_target" "main-london" {
  provider  = aws.cloud-platform
  rule      = aws_cloudwatch_event_rule.main-london.name
  target_id = "send-to-sns"
  arn       = aws_sns_topic.GuardDuty-notifications-london.arn
}

# -----------------------------------------------------------
# set up AWS Cloudwatch Event to target an sns topic for above event rule
# Ireland - Master
# https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#rules:name=guardduty-finding-events
# -----------------------------------------------------------

resource "aws_cloudwatch_event_target" "main" {
  provider  = aws.cloud-platform-ireland
  rule      = aws_cloudwatch_event_rule.main.name
  target_id = "send-to-sns"
  arn       = aws_sns_topic.GuardDuty-notifications.arn
}

# -----------------------------------------------------------
# set up AWS sns topic and subscription
# London - Master
# https://eu-west-2.console.aws.amazon.com/sns/v3/home?region=eu-west-2#/topic/arn:aws:sns:eu-west-2:754256621582:GuardDuty-notifications-london
# https://eu-west-2.console.aws.amazon.com/sns/v3/home?region=eu-west-2#/subscriptions
# -----------------------------------------------------------

resource "aws_sns_topic" "GuardDuty-notifications-london" {
  provider = aws.cloud-platform
  name     = "GuardDuty-notifications-london"
}

resource "aws_sns_topic_subscription" "GuardDuty-notifications_sns_subscription-london" {
  provider               = aws.cloud-platform
  topic_arn              = aws_sns_topic.GuardDuty-notifications-london.arn
  protocol               = "https"
  endpoint               = var.endpoint
  endpoint_auto_confirms = true
}

provider "aws" {
  region  = var.aws_region-london
  alias   = "master-london"
  profile = var.aws_master-london_profile
}

# -----------------------------------------------------------
# set up AWS sns topic and subscription
# Ireland - Master
# https://eu-west-1.console.aws.amazon.com/sns/v3/home?region=eu-west-1#/topic/arn:aws:sns:eu-west-1:754256621582:GuardDuty-notifications
# https://eu-west-1.console.aws.amazon.com/sns/v3/home?region=eu-west-1#/subscriptions
# -----------------------------------------------------------

resource "aws_sns_topic" "GuardDuty-notifications" {
  provider = aws.cloud-platform-ireland
  name     = "GuardDuty-notifications"
}

resource "aws_sns_topic_subscription" "GuardDuty-notifications_sns_subscription" {
  provider               = aws.cloud-platform-ireland
  topic_arn              = aws_sns_topic.GuardDuty-notifications.arn
  protocol               = "https"
  endpoint               = var.endpoint
  endpoint_auto_confirms = true
}

provider "aws" {
  region  = var.aws_region
  alias   = "master"
  profile = var.aws_master_profile
}

# All of the following are members in Ireland region
# and can be found at https://eu-west-1.console.aws.amazon.com/guardduty/home?region=eu-west-1#/linked-accounts

# -----------------------------------------------------------
# membership1 account provider
# Ireland
# -----------------------------------------------------------

provider "aws" {
  region  = var.aws_region
  alias   = "member1"
  profile = var.aws_member1_profile
}

# -----------------------------------------------------------
# membership1 account GuardDuty detector
# Ireland
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member1" {
  provider = aws.member1

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership1 account GuardDuty member
# Ireland
# -----------------------------------------------------------

resource "aws_guardduty_member" "member1" {
  provider           = aws.cloud-platform-ireland
  account_id         = aws_guardduty_detector.member1.account_id
  detector_id        = aws_guardduty_detector.guardduty.id
  email              = var.member1_email
  invite             = true
  invitation_message = "please accept guardduty invitation"
}

# -----------------------------------------------------------
# membership2 account provider
# Ireland
# -----------------------------------------------------------

provider "aws" {
  region  = var.aws_region
  alias   = "member2"
  profile = var.aws_member2_profile
}

# -----------------------------------------------------------
# membership2 account GuardDuty detector
# Ireland
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member2" {
  provider = aws.member2

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership2 account GuardDuty member
# Ireland
# -----------------------------------------------------------

resource "aws_guardduty_member" "member2" {
  provider           = aws.cloud-platform-ireland
  account_id         = aws_guardduty_detector.member2.account_id
  detector_id        = aws_guardduty_detector.guardduty.id
  email              = var.member2_email
  invite             = true
  invitation_message = "please accept guardduty invitation"
}

# -----------------------------------------------------------
# membership3 account provider
# Ireland
# -----------------------------------------------------------

provider "aws" {
  region  = var.aws_region
  alias   = "member3"
  profile = var.aws_member3_profile
}

# -----------------------------------------------------------
# membership3 account GuardDuty detector
# Ireland
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member3" {
  provider = aws.member3

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership3 account GuardDuty member
# Ireland
# -----------------------------------------------------------

resource "aws_guardduty_member" "member3" {
  provider           = aws.cloud-platform-ireland
  account_id         = aws_guardduty_detector.member3.account_id
  detector_id        = aws_guardduty_detector.guardduty.id
  email              = var.member3_email
  invite             = true
  invitation_message = "please accept guardduty invitation"
}

# -----------------------------------------------------------
# membership4 account provider
# Ireland
# -----------------------------------------------------------

provider "aws" {
  region  = var.aws_region
  alias   = "member4"
  profile = var.aws_member4_profile
}

# -----------------------------------------------------------
# membership4 account GuardDuty detector
# Ireland
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member4" {
  provider = aws.member4

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership4 account GuardDuty member
# Ireland
# -----------------------------------------------------------

resource "aws_guardduty_member" "member4" {
  provider           = aws.cloud-platform-ireland
  account_id         = aws_guardduty_detector.member4.account_id
  detector_id        = aws_guardduty_detector.guardduty.id
  email              = var.member4_email
  invite             = true
  invitation_message = "please accept guardduty invitation"
}

# -----------------------------------------------------------
# membership5 account provider
# Ireland
# -----------------------------------------------------------

#provider "aws" {
#  region  = var.aws_region
#  alias   = "member5"
#  profile = var.aws_member5_profile
#}

# -----------------------------------------------------------
# membership5 account GuardDuty detector
# Ireland
# -----------------------------------------------------------

#resource "aws_guardduty_detector" "member5" {
#  provider = aws.member5

#  enable                       = true
#  finding_publishing_frequency = "FIFTEEN_MINUTES"
#}

# -----------------------------------------------------------
# membership5 account GuardDuty member
# Ireland
# -----------------------------------------------------------

#resource "aws_guardduty_member" "member5" {
#  provider           = aws.cloud-platform-ireland
#  account_id         = aws_guardduty_detector.member5.account_id
#  detector_id        = aws_guardduty_detector.guardduty.id
#  email              = var.member5_email
#  invite             = true
#  invitation_message = "please accept guardduty invitation"
#}

# -----------------------------------------------------------
# membership6 account provider
# Ireland
# -----------------------------------------------------------

provider "aws" {
  region  = var.aws_region
  alias   = "member6"
  profile = var.aws_member6_profile
}

# -----------------------------------------------------------
# membership6 account GuardDuty detector
# Ireland
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member6" {
  provider = aws.member6

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership6 account GuardDuty member
# Ireland
# -----------------------------------------------------------

resource "aws_guardduty_member" "member6" {
  provider           = aws.cloud-platform-ireland
  account_id         = aws_guardduty_detector.member6.account_id
  detector_id        = aws_guardduty_detector.guardduty.id
  email              = var.member6_email
  invite             = true
  invitation_message = "please accept guardduty invitation"
}

# -----------------------------------------------------------
# membership7 account provider
# Ireland
# -----------------------------------------------------------

provider "aws" {
  region  = var.aws_region
  alias   = "member7"
  profile = var.aws_member7_profile
}

# -----------------------------------------------------------
# membership7 account GuardDuty detector
# Ireland
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member7" {
  provider = aws.member7

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership7 account GuardDuty member
# Ireland
# -----------------------------------------------------------

resource "aws_guardduty_member" "member7" {
  provider           = aws.cloud-platform-ireland
  account_id         = aws_guardduty_detector.member7.account_id
  detector_id        = aws_guardduty_detector.guardduty.id
  email              = var.member7_email
  invite             = true
  invitation_message = "please accept guardduty invitation"
}

resource "aws_guardduty_ipset" "guardduty" {
  provider    = aws.cloud-platform-ireland
  activate    = true
  detector_id = aws_guardduty_detector.guardduty.id
  format      = "TXT"
  location    = "https://s3-eu-west-1.amazonaws.com/${aws_s3_bucket_object.ip_list.bucket}/${aws_s3_bucket_object.ip_list.key}"
  name        = "guardduty"
}

