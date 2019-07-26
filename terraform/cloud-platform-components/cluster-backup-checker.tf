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

# resource "kubernetes_pod" "cluster_backup_pod" {
#   metadata {
#     name      = "cluster-backup-checker-pod"
#     namespace = "monitoring"

#     annotations {
#       "iam.amazonaws.com/role" = "cluster-checker.pk-test-2.cloud-platform.service.justice.gov.uk"
#     }
#   }

#   spec {
#     container {
#       image = "754256621582.dkr.ecr.eu-west-2.amazonaws.com/cp-team/cp-poornima-dev-module:8.1"
#       name  = "snapshot-checker"

#       env {
#         name  = "SLACK_WEBHOOK"
#         value = "${var.slack_webhook}"
#         name  = "KUBERNETES_CLUSTER"
#         value = "live-1.cloud-platform.service.justice.gov.uk"
#         name  = "AWS_PROFILE"
#         value = "moj-cp"
#         name  = "AWS_REGION"
#         value = "eu-west-2"
#       }
#     }
#   }
# }

resource "kubernetes_cron_job" "cluster_backup_checker_cronjob" {
  metadata {
    name      = "cluster-backup-checker-cronjob"
    namespace = "monitoring"
  }

  spec {
    schedule = "*/1 * * * *"

    job_template {
      metadata = {}

      spec {
        template {
          metadata = {
            annotations {
              "iam.amazonaws.com/role" = "${aws_iam_role.cluster_backup_checker.name}"
            }
          }

          spec {
            container {
              image = "754256621582.dkr.ecr.eu-west-2.amazonaws.com/cp-team/cp-poornima-dev-module:9.0"
              name  = "snapshot-checker"

              env {
                name  = "SLACK_WEBHOOK"
                value = "https://hooks.slack.com/services/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"
              }

              env {
                name  = "KUBERNETES_CLUSTER"
                value = "live-1.cloud-platform.service.justice.gov.uk"
              }

              env {
                name  = "AWS_REGION"
                value = "eu-west-2"
              }

              env {
                name  = "ROLE_NAME"
                value = "${aws_iam_role.cluster_backup_checker.name}"
              }

              env {
                name  = "ACCOUNT_ID"
                value = "${var.aws_master_account_id}"
              }
            }
          }
        }
      }
    }
  }
}
