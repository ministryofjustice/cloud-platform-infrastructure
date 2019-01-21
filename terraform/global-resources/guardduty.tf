provider "aws.master" {
  region  = "${var.aws_region}"
  profile = "${var.aws_master_profile}"
}

# -----------------------------------------------------------
# enable guard duty
# -----------------------------------------------------------

resource "aws_guardduty_detector" "master" {
  provider                     = "aws.master"
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# set up S3 bucket
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
  key          = "${var.guardduty_assets}/iplist.txt"
  bucket       = "${aws_s3_bucket.security.id}"
  source       = "${path.module}/resources/iplist.txt"
  content_type = "text/plain"
  etag         = "${md5(file("${path.module}/resources/iplist.txt"))}"
}

# -----------------------------------------------------------
# set up iam group with appropriate iam policy
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
  event_pattern = "${file("${path.module}/resources/event-pattern.json")}"
}

# -----------------------------------------------------------
# set up AWS Cloudwatch Event to target an sns topic for above event rule
# -----------------------------------------------------------

resource "aws_cloudwatch_event_target" "main" {
  rule      = "${aws_cloudwatch_event_rule.main.name}"
  target_id = "send-to-sns"
  arn       = "${aws_sns_topic.GuardDuty-notifications.arn}"
}

# -----------------------------------------------------------
# set up AWS sns topic and subscription
# -----------------------------------------------------------

resource "aws_sns_topic" "GuardDuty-notifications" {
  name = "GuardDuty-notifications"
}

resource "aws_sns_topic_subscription" "GuardDuty-notifications_sns_subscription" {
  topic_arn              = "${aws_sns_topic.GuardDuty-notifications.arn}"
  protocol               = "https"
  endpoint               = "${var.endpoint}"
  endpoint_auto_confirms = true
}

# -----------------------------------------------------------
# membership account provider
# -----------------------------------------------------------

provider "aws.member" {
  region  = "${var.aws_region}"
  profile = "${var.aws_member_profile}"
}

# -----------------------------------------------------------
# membership account GuardDuty detector
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member" {
  provider = "aws.member"

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership account GuardDuty member
# -----------------------------------------------------------

resource "aws_guardduty_member" "member" {
  account_id         = "${aws_guardduty_detector.member.account_id}"
  detector_id        = "${aws_guardduty_detector.master.id}"
  email              = "${var.member_email}"
  invite             = true
  invitation_message = "please accept guardduty invitation"
}

# -----------------------------------------------------------
# membership1 account provider
# -----------------------------------------------------------

provider "aws.member1" {
  region  = "${var.aws_region}"
  profile = "${var.aws_member1_profile}"
}

# -----------------------------------------------------------
# membership1 account GuardDuty detector
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member1" {
  provider = "aws.member1"

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership1 account GuardDuty member
# -----------------------------------------------------------

resource "aws_guardduty_member" "member1" {
  account_id         = "${aws_guardduty_detector.member1.account_id}"
  detector_id        = "${aws_guardduty_detector.master.id}"
  email              = "${var.member1_email}"
  invite             = true
  invitation_message = "please accept guardduty invitation"
}

# -----------------------------------------------------------
# membership2 account provider
# -----------------------------------------------------------

provider "aws.member2" {
  region  = "${var.aws_region}"
  profile = "${var.aws_member2_profile}"
}

# -----------------------------------------------------------
# membership2 account GuardDuty detector
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member2" {
  provider = "aws.member2"

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership2 account GuardDuty member
# -----------------------------------------------------------

resource "aws_guardduty_member" "member2" {
  account_id         = "${aws_guardduty_detector.member2.account_id}"
  detector_id        = "${aws_guardduty_detector.master.id}"
  email              = "${var.member2_email}"
  invite             = true
  invitation_message = "please accept guardduty invitation"
}

# -----------------------------------------------------------
# membership3 account provider
# -----------------------------------------------------------

provider "aws.member3" {
  region  = "${var.aws_region}"
  profile = "${var.aws_member3_profile}"
}

# -----------------------------------------------------------
# membership3 account GuardDuty detector
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member3" {
  provider = "aws.member3"

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership3 account GuardDuty member
# -----------------------------------------------------------

resource "aws_guardduty_member" "member3" {
  account_id         = "${aws_guardduty_detector.member3.account_id}"
  detector_id        = "${aws_guardduty_detector.master.id}"
  email              = "${var.member3_email}"
  invite             = true
  invitation_message = "please accept guardduty invitation"
}

# -----------------------------------------------------------
# membership4 account provider
# -----------------------------------------------------------

provider "aws.member4" {
  region  = "${var.aws_region}"
  profile = "${var.aws_member4_profile}"
}

# -----------------------------------------------------------
# membership4 account GuardDuty detector
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member4" {
  provider = "aws.member4"

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership4 account GuardDuty member
# -----------------------------------------------------------

resource "aws_guardduty_member" "member4" {
  account_id         = "${aws_guardduty_detector.member4.account_id}"
  detector_id        = "${aws_guardduty_detector.master.id}"
  email              = "${var.member4_email}"
  invite             = true
  invitation_message = "please accept guardduty invitation"
}

# -----------------------------------------------------------
# membership5 account provider
# -----------------------------------------------------------

provider "aws.member5" {
  region  = "${var.aws_region}"
  profile = "${var.aws_member5_profile}"
}

# -----------------------------------------------------------
# membership5 account GuardDuty detector
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member5" {
  provider = "aws.member5"

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership5 account GuardDuty member
# -----------------------------------------------------------

resource "aws_guardduty_member" "member5" {
  account_id         = "${aws_guardduty_detector.member5.account_id}"
  detector_id        = "${aws_guardduty_detector.master.id}"
  email              = "${var.member5_email}"
  invite             = true
  invitation_message = "please accept guardduty invitation"
}

# -----------------------------------------------------------
# membership6 account provider
# -----------------------------------------------------------

provider "aws.member6" {
  region  = "${var.aws_region}"
  profile = "${var.aws_member6_profile}"
}

# -----------------------------------------------------------
# membership6 account GuardDuty detector
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member6" {
  provider = "aws.member6"

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership6 account GuardDuty member
# -----------------------------------------------------------

resource "aws_guardduty_member" "member6" {
  account_id         = "${aws_guardduty_detector.member6.account_id}"
  detector_id        = "${aws_guardduty_detector.master.id}"
  email              = "${var.member6_email}"
  invite             = true
  invitation_message = "please accept guardduty invitation"
}

# -----------------------------------------------------------
# membership7 account provider
# -----------------------------------------------------------

provider "aws.member7" {
  region  = "${var.aws_region}"
  profile = "${var.aws_member7_profile}"
}

# -----------------------------------------------------------
# membership7 account GuardDuty detector
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member7" {
  provider = "aws.member7"

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership7 account GuardDuty member
# -----------------------------------------------------------

resource "aws_guardduty_member" "member7" {
  account_id         = "${aws_guardduty_detector.member7.account_id}"
  detector_id        = "${aws_guardduty_detector.master.id}"
  email              = "${var.member7_email}"
  invite             = true
  invitation_message = "please accept guardduty invitation"
}
