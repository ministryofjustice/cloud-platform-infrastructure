data "aws_iam_policy_document" "external_dns_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.nodes.arn]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "external-dns.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume.json
}

data "aws_iam_policy_document" "external_dns" {
  statement {
    actions = ["route53:ChangeResourceRecordSets"]

    resources = [format(
      "arn:aws:route53:::hostedzone/%s",
      terraform.workspace == local.live_workspace ? "*" : data.terraform_remote_state.cluster.outputs.hosted_zone_id,
    )]
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "external_dns" {
  name   = "route53"
  role   = aws_iam_role.external_dns.id
  policy = data.aws_iam_policy_document.external_dns.json
}

resource "helm_release" "external_dns" {
  name      = "external-dns"
  chart     = "stable/external-dns"
  namespace = "kube-system"
  version   = "1.7.0"

  values = [
    <<EOF
image:
  tag: v0.5.11
sources:
  - service
  - ingress
provider: aws
aws:
  region: eu-west-2
  zoneType: public
domainFilters:
  ${terraform.workspace == local.live_workspace ? "" : format(
"- %s",
data.terraform_remote_state.cluster.outputs.cluster_domain_name,
)}
rbac:
  create: true
  apiVersion: v1
  serviceAccountName: default
txtPrefix: "_external_dns."
logLevel: info
podAnnotations:
  iam.amazonaws.com/role: "${aws_iam_role.external_dns.name}"
EOF
      ,
      ]

      depends_on = [
        null_resource.deploy,
        helm_release.kiam,
      ]

      lifecycle {
        ignore_changes = [keyring]
      }
    }

