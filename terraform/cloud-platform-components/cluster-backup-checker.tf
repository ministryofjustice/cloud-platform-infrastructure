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

resource "kubernetes_cron_job" "cluster-backup-checker-cronjob" {
  metadata {
    name      = "cluster-backup-checker-cronjob"
    namespace = "monitoring"
  }

  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = "*/1 * * * *"
    starting_deadline_seconds     = 10
    successful_jobs_history_limit = 10
    suspend                       = true

    job_template {
      metadata = {}

      spec {
        backoff_limit = 2

        template {
          metadata = {}

          spec {
            container {
              image = "754256621582.dkr.ecr.eu-west-2.amazonaws.com/cp-team/cp-poornima-dev-module:cluster-backup-checker-7.0"
              name  = "snapshot-checker"

              env {
                name  = "AWS_ACCESS_KEY_ID"
                value = "${var.access_key}"
                name  = "AWS_SECRET_ACCESS_KEY"
                value = "${var.secret_key}"
                name  = "SLACK_WEBHOOK"
                value = "${var.slack_webhook}"
                name  = "KUBERNETES_CLUSTER"
                value = "live-1.cloud-platform.service.justice.gov.uk"
                name  = "AWS_REGION"
                value = "eu-west-2"
              }
            }

            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}
