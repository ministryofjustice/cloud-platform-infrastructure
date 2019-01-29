data "aws_iam_policy_document" "cert_manager_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_iam_role.nodes.arn}"]
    }
  }
}

resource "aws_iam_role" "cert_manager" {
  name               = "cert-manager.${data.terraform_remote_state.cluster.cluster_domain_name}"
  assume_role_policy = "${data.aws_iam_policy_document.cert_manager_assume.json}"
}

data "aws_iam_policy_document" "cert_manager" {
  statement {
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = ["arn:aws:route53:::hostedzone/${data.terraform_remote_state.cluster.hosted_zone_id}"]
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

resource "aws_iam_role_policy" "cert_manager" {
  name   = "route53"
  role   = "${aws_iam_role.cert_manager.id}"
  policy = "${data.aws_iam_policy_document.cert_manager.json}"
}

resource "helm_release" "cert-manager" {
  name          = "cert-manager"
  chart         = "stable/cert-manager"
  namespace     = "cert-manager"
  version       = "v0.6.0"
  recreate_pods = true

  values = [<<EOF
ingressShim:
  defaultIssuerName: letsencrypt-production
  defaultIssuerKind: ClusterIssuer
  defaultACMEChallengeType: dns01
  defaultACMEDNS01ChallengeProvider: route53

securityContext:
  enabled: false

podAnnotations:
  iam.amazonaws.com/role: "${aws_iam_role.cert_manager.name}"
EOF
  ]

  depends_on = ["null_resource.deploy"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}

resource "null_resource" "cert-manager-issuers" {
  depends_on = ["helm_release.cert-manager"]

  provisioner "local-exec" {
    command = "kubectl apply -n cert-manager -f ${path.module}/resources/cert-manager/"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete -n cert-manager -f ${path.module}/resources/cert-manager/"
  }

  triggers {
    contents_production = "${sha1(file("${path.module}/resources/cert-manager/letsencrypt-production.yaml"))}"
    contents_staging    = "${sha1(file("${path.module}/resources/cert-manager/letsencrypt-staging.yaml"))}"
  }
}

resource "null_resource" "cert_manager_kiam_annotation" {
  provisioner "local-exec" {
    command = "kubectl annotate --overwrite namespace cert-manager 'iam.amazonaws.com/permitted=${aws_iam_role.cert_manager.name}'"
  }

  depends_on = ["helm_release.cert-manager"]
}

resource "null_resource" "cert_manager_webhook_label" {
  provisioner "local-exec" {
    command = "kubectl label --overwrite namespace cert-manager 'certmanager.k8s.io/disable-validation=true'"
  }

  depends_on = ["helm_release.cert-manager"]
}
