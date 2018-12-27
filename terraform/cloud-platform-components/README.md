# cloud-platform-components

## kiam

Example of IAM policy for a user application:

```hcl
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "app" {
  name = "app_role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nodes.${data.terraform_remote_state.cluster.cluster_domain_name}"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "app" {
  name = "policy"
  role = "${aws_iam_role.app.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
```

This can easily be configured as part of a user environment's resources, along with the required namespace annotation (see the [kiam docs](https://github.com/uswitch/kiam#overview)).
