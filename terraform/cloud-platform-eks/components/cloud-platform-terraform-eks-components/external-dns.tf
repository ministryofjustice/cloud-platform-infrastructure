###############
# ExternalDNS #
###############

#
# HELM
#

resource "helm_release" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name      = "external-dns"
  chart     = "stable/external-dns"
  namespace = "kube-system"
  version   = "2.6.4"

  values = [templatefile("${path.module}/templates/external-dns.yaml.tpl", {
    domainFilters = terraform.workspace == local.live_workspace ? "" : format("- %s", data.terraform_remote_state.cluster.outputs.cluster_domain_name)
    iam_role      = aws_iam_role.externaldns.name
  })]

  depends_on = [
    null_resource.deploy,
  ]
}

#
# IAM
#

resource "aws_iam_role" "externaldns" {
  name = "externaldns.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  assume_role_policy = data.aws_iam_policy_document.allow_to_assume.json
}

resource "aws_iam_role_policy_attachment" "externaldns_attach_policy" {
  role       = aws_iam_role.externaldns.name
  policy_arn = aws_iam_policy.externaldns.arn
}

resource "aws_iam_policy" "externaldns" {
  name        = "externaldns.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  path        = "/"
  description = "Policy that allows change DNS entries for the externalDNS service"
  policy      = data.aws_iam_policy_document.externaldns.json
}

data "aws_iam_policy_document" "externaldns" {

  statement {
    actions = ["route53:ChangeResourceRecordSets"]

    resources = ["${format("arn:aws:route53:::hostedzone/%s", terraform.workspace == local.live_workspace ? "*" : data.aws_route53_zone.selected.zone_id)}"]
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]

    resources = ["*"]
  }
}
