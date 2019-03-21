data "aws_route53_zone" "external_dns_dsd" {
  provider = "aws.dsd"
  count    = "${length(local.dsd_zones)}"
  name     = "${local.dsd_zones[count.index]}"
}

resource "aws_iam_user" "external_dns_dsd" {
  provider = "aws.dsd"
  name     = "external-dns.${data.terraform_remote_state.cluster.cluster_domain_name}"
  path     = "/cloud-platform/"
}

resource "aws_iam_access_key" "external_dns_dsd" {
  provider = "aws.dsd"
  user     = "${aws_iam_user.external_dns_dsd.name}"
}

resource "aws_iam_user_policy" "external_dns_dsd" {
  provider = "aws.dsd"
  name     = "route53-hostedzones"
  policy   = "${data.aws_iam_policy_document.external_dns_dsd.json}"
  user     = "${aws_iam_user.external_dns_dsd.name}"
}

data "aws_iam_policy_document" "external_dns_dsd" {
  statement {
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = ["${formatlist("arn:aws:route53:::hostedzone/%s", data.aws_route53_zone.external_dns_dsd.*.zone_id)}"]
  }

  statement {
    actions   = ["route53:ListResourceRecordSets", "route53:ListHostedZones"]
    resources = ["*"]
  }
}

resource "helm_release" "external_dns_dsd" {
  name      = "external-dns-dsd"
  chart     = "stable/external-dns"
  namespace = "kube-system"

  values = [<<EOF
sources:
  - service
  - ingress
provider: aws
aws:
  accessKey: ${aws_iam_access_key.external_dns_dsd.id}
  secretKey: ${aws_iam_access_key.external_dns_dsd.secret}
  region: eu-west-1
  zoneType: public
domainFilters:
  - ${indent(2, join("\n- ", local.dsd_zones))}
rbac:
  create: true
  apiVersion: v1
  serviceAccountName: default
txtPrefix: "_external_dns."
logLevel: info
EOF
  ]

  depends_on = ["null_resource.deploy"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}
