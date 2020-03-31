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

    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibility in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
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
  version   = "2.6.4"

  values = [
    <<EOF
image:
  tag: 0.5.17-debian-9-r0
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
  module.opa.helm_opa_status,
]

lifecycle {
  ignore_changes = [keyring]
}
}

