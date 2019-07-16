# Cluster backup snapshots checker
# KIAM role creation
data "aws_iam_policy_document" "cluster_backup_checker_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_iam_role.nodes.arn}"]
    }
  }
}

resource "aws_iam_role" "cluster_backup_checker" {
  name               = "cluster-checker.${data.terraform_remote_state.cluster.cluster_domain_name}"
  assume_role_policy = "${data.aws_iam_policy_document.cluster_backup_checker_assume.json}"
}

data "aws_iam_policy_document" "cluster_backup_checker" {
  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cluster_backup_checker" {
  name   = "cluster-checker"
  role   = "${aws_iam_role.cluster_backup_checker.id}"
  policy = "${data.aws_iam_policy_document.cluster_backup_checker.json}"
}
