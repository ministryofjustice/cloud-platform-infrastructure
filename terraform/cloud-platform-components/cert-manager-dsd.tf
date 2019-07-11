data "aws_route53_zone" "cert_manager_dsd" {
  provider = "aws.dsd"
  count    = "${length(local.dsd_zones)}"
  name     = "${local.dsd_zones[count.index]}"
}

resource "aws_iam_user" "cert_manager_dsd" {
  provider = "aws.dsd"
  name     = "cert-manager.${data.terraform_remote_state.cluster.cluster_domain_name}"
  path     = "/cloud-platform/"
}

resource "aws_iam_access_key" "cert_manager_dsd" {
  provider = "aws.dsd"
  user     = "${aws_iam_user.cert_manager_dsd.name}"
}

resource "aws_iam_user_policy" "cert_manager_dsd" {
  provider = "aws.dsd"
  name     = "route53-hostedzones"
  policy   = "${data.aws_iam_policy_document.cert_manager_dsd.json}"
  user     = "${aws_iam_user.cert_manager_dsd.name}"
}

data "aws_iam_policy_document" "cert_manager_dsd" {
  statement {
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = ["${formatlist("arn:aws:route53:::hostedzone/%s", data.aws_route53_zone.cert_manager_dsd.*.zone_id)}"]
  }

  statement {
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    actions   = ["route53:ListHostedZonesByName"]
    resources = ["*"]
  }
}

resource "kubernetes_secret" "cert_manager_dsd" {
  depends_on = [
    "helm_release.cert-manager",
  ]

  type = "Opaque"

  metadata {
    name      = "iam-dsd-route53"
    namespace = "cert-manager"
  }

  data {
    access_key_id     = "${aws_iam_access_key.cert_manager_dsd.id}"
    secret_access_key = "${aws_iam_access_key.cert_manager_dsd.secret}"
  }
}
