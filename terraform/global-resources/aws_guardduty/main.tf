provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

# -----------------------------------------------------------
# enable guard duty
# -----------------------------------------------------------

resource "aws_guardduty_detector" "guardduty" {
  enable = true
}

#resource "aws_guardduty_ipset" "IPSet" {
#  activate    = true
#  detector_id = "${aws_guardduty_detector.guardduty.id}"
#  format      = "TXT"
#  location    = "s3://${aws_s3_bucket_object.ip_list.bucket}/${aws_s3_bucket_object.ip_list.key}"
#  name        = "IPSet"
#}

# -----------------------------------------------------------
# set up S3 bucket to hold things of interest
# -----------------------------------------------------------

resource "aws_s3_bucket" "security" {
  bucket_prefix = "${var.bucket_prefix}"
  acl           = "private"
  region        = "${var.aws_region}"

  lifecycle {
    prevent_destroy = true
  }

  tags = "${merge(map("Name","Security Bucket"), var.tags)}"
}

resource "aws_s3_bucket_object" "ip_list" {
  key        = "${var.guardduty_assets}/iplist.txt"
  bucket     = "${aws_s3_bucket.security.id}"
  source     = "${path.module}/iplist.txt"
  content_type = "text/plain"
  etag   = "${md5(file("${path.module}/iplist.txt"))}"
}

# -----------------------------------------------------------
# set up group with appropriate policy
# -----------------------------------------------------------

resource "aws_iam_policy" "enable_guardduty" {
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
            "Resource": "arn:aws:iam::${var.aws_account_id}:role/aws-service-role/guardduty.amazonaws.com/AWSServiceRoleForAmazonGuardDuty",
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
            "Resource": "arn:aws:iam::${var.aws_account_id}:role/aws-service-role/guardduty.amazonaws.com/AWSServiceRoleForAmazonGuardDuty"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "use_security_bucket" {
  name        = "access-security-bucket"
  path        = "/security/"
  description = "Allows full access to the contents of the security bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "arn:aws:s3:::*"
    },
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
  name = "${var.group_name}"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "enable" {
  group      = "${aws_iam_group.guardduty.name}"
  policy_arn = "${aws_iam_policy.enable_guardduty.arn}"
}

resource "aws_iam_group_policy_attachment" "useS3bucket" {
  group      = "${aws_iam_group.guardduty.name}"
  policy_arn = "${aws_iam_policy.use_security_bucket.arn}"
}

resource "aws_iam_group_policy_attachment" "access" {
  group      = "${aws_iam_group.guardduty.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonGuardDutyFullAccess"
}

resource "aws_iam_group_policy_attachment" "s3readonly" {
  group      = "${aws_iam_group.guardduty.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_group_membership" "guardduty" {
  name  = "guardduty-admin-members"
  group = "${aws_iam_group.guardduty.name}"
  users = "${var.users}"
}

# -----------------------------------------------------------
# set up AWS Cloudwatch Event rule for Guardduty Findings
# also to set up an event pattern (json file)
# -----------------------------------------------------------

resource "aws_cloudwatch_event_rule" "main" {
  name          = "guardduty-finding-events"
  description   = "AWS GuardDuty event findings"
  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

# -----------------------------------------------------------
# set up AWS Cloudwatch Event to target an sns topic for above event rule
# -----------------------------------------------------------

resource "aws_cloudwatch_event_target" "main" {
  rule      = "${aws_cloudwatch_event_rule.main.name}"
  target_id = "send-to-sns"
  arn       = "${data.aws_sns_topic.main.arn}"

  input_transformer = {
    input_paths {
      title = "$.detail.title"
    }

    input_template = "\"GuardDuty finding: <title>\""
  }
}

# -----------------------------------------------------------
# set up AWS sns topic and subscription
# -----------------------------------------------------------
 
data "aws_sns_topic" "main" {
   name = "${var.sns_topic_name}"
 }

resource "aws_sns_topic" "GuardDuty-notifications" {
  name = "GuardDuty-notifications"
}

resource "aws_sns_topic_subscription" "GuardDuty-notifications_sns_subscription" {
  topic_arn = "arn:aws:sns:eu-west-1:${var.aws_account_id}:GuardDuty-notifications"
  protocol  = "https"
  endpoint  = "https://events.pagerduty.com/integration/${var.integration_key}/enqueue"
  endpoint_auto_confirms = true
}
