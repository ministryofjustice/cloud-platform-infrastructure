resource "aws_iam_role" "dlm_lifecycle_role" {
  name = "dlm-lifecycle-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "dlm.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy" "dlm_policy" {
  name        = "dlm-policy"
  description = "dlm policy to allow snapshot creation"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "ec2:CreateSnapshot",
              "ec2:DeleteSnapshot",
              "ec2:DescribeVolumes",
              "ec2:DescribeSnapshots"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "ec2:CreateTags"
          ],
          "Resource": "arn:aws:ec2:*::snapshot/*"
      }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "dlm_attach" {
  role       = aws_iam_role.dlm_lifecycle_role.name
  policy_arn = aws_iam_policy.dlm_policy.arn
}

resource "aws_dlm_lifecycle_policy" "etcd_backup" {
  description        = "etcd data lifecycle policy"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "Daily 2 week etcd snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["06:00"]
      }

      retain_rule {
        count = 14
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = true
    }

    target_tags = {
      "k8s.io/role/master" = "1"
    }
  }
}

resource "aws_dlm_lifecycle_policy" "persistentvolume_backup" {
  description        = "PersistentVolume lifecycle policy"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "Daily 30 days persistentvolume snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["05:00"]
      }

      retain_rule {
        count = 30
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
        volume_type     = "persistentvolume"
      }

      copy_tags = true
    }

    target_tags = {
      "k8s.io/pvc/persistentvolume" = "daily-backup"
    }
  }
}