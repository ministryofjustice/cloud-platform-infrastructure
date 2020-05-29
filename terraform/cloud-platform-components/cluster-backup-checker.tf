# Cluster backup snapshots checker
# KIAM role and policy creation
# monitoring namespace must have an annotation with a regular expression
# expressing which roles are permitted to be assumed within that namespace.
# Correct annotation are added to the Pod to indicate which role should be assumed.
# Without correct Pod annotation Kiam cannot provide access to the Pod to execute required actions.
# Cronjob to schedule the job every day @17:00 UTC to run the script mentioned in the image
#
# Image - Ruby script added to Cloud platform ECR Repository
data "aws_iam_policy_document" "cluster_backup_checker_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.nodes.arn]
    }
  }
}

resource "aws_iam_role" "cluster_backup_checker" {
  name               = "cluster-chckr.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  assume_role_policy = data.aws_iam_policy_document.cluster_backup_checker_assume.json
}

data "aws_iam_policy_document" "cluster_backup_checker" {
  statement {
    actions = [
      "sts:AssumeRole",
      "ec2:DescribeSnapshots",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cluster_backup_checker" {
  name   = "cluster-checker"
  role   = aws_iam_role.cluster_backup_checker.id
  policy = data.aws_iam_policy_document.cluster_backup_checker.json
}

resource "kubernetes_cron_job" "cluster_backup_checker_cronjob" {
  metadata {
    name      = "cluster-backup-checker-cronjob"
    namespace = "monitoring"
  }

  spec {
    schedule = "0 17 * * *"

    job_template {
      metadata {
      }

      spec {
        template {
          metadata {
            annotations = {
              "iam.amazonaws.com/role" = aws_iam_role.cluster_backup_checker.name
            }
          }

          spec {
            container {
              image = "${var.aws_master_account_id}.dkr.ecr.eu-west-2.amazonaws.com/cloud-platform/cluster-backup-checker:1.5"
              name  = "snapshot-checker"

              env {
                name  = "SLACK_WEBHOOK"
                value = var.cloud_platform_slack_webhook
              }

              env {
                name  = "KUBERNETES_CLUSTER"
                value = format("%s.%s", local.live_workspace, local.live_domain)
              }

              env {
                name  = "AWS_REGION"
                value = "eu-west-2"
              }

              env {
                name  = "ROLE_NAME"
                value = aws_iam_role.cluster_backup_checker.name
              }

              env {
                name  = "ACCOUNT_ID"
                value = var.aws_master_account_id
              }
            }
          }
        }
      }
    }
  }
}

