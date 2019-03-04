locals {
  cert-manager-version = "v0.6.6"
}

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

data "http" "cert-manager-crds" {
  url = "https://raw.githubusercontent.com/jetstack/cert-manager/release-${replace(local.cert-manager-version, "/^v?(\\d+\\.\\d+)\\.\\d+$/", "$1")}/deploy/manifests/00-crds.yaml"
}

resource "null_resource" "cert-manager-crds" {
  provisioner "local-exec" {
    command = <<EOS
kubectl apply -n cert-manager -f - <<EOF
${data.http.cert-manager-crds.body}
EOF
EOS
  }

  provisioner "local-exec" {
    when = "destroy"

    command = <<EOS
kubectl delete -n cert-manager -f - <<EOF
${data.http.cert-manager-crds.body}
EOF
EOS
  }

  triggers {
    contents_crds = "${sha1("${data.http.cert-manager-crds.body}")}"
  }
}

resource "helm_release" "cert-manager" {
  name          = "cert-manager"
  chart         = "stable/cert-manager"
  namespace     = "cert-manager"
  version       = "${local.cert-manager-version}"
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

  depends_on = ["null_resource.deploy", "null_resource.cert-manager-crds"]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}

data "template_file" "cert_manager_clusterissuer_production" {
  template = "${file("${path.module}/templates/cert-manager/letsencrypt-production.yaml")}"

  vars {
    dsd_key_id      = "${aws_iam_access_key.cert_manager_dsd.id}"
    dsd_secret_name = "${kubernetes_secret.cert_manager_dsd.metadata.0.name}"
  }
}

data "template_file" "cert_manager_clusterissuer_staging" {
  template = "${file("${path.module}/templates/cert-manager/letsencrypt-staging.yaml")}"

  vars {
    dsd_key_id      = "${aws_iam_access_key.cert_manager_dsd.id}"
    dsd_secret_name = "${kubernetes_secret.cert_manager_dsd.metadata.0.name}"
  }
}

resource "null_resource" "cert_manager_issuers" {
  depends_on = ["helm_release.cert-manager"]

  provisioner "local-exec" {
    command = <<EOS
kubectl apply -n cert-manager -f - <<EOF
${data.template_file.cert_manager_clusterissuer_production.rendered}
EOF
EOS
  }

  provisioner "local-exec" {
    command = <<EOS
kubectl apply -n cert-manager -f - <<EOF
${data.template_file.cert_manager_clusterissuer_staging.rendered}
EOF
EOS
  }

  provisioner "local-exec" {
    when = "destroy"

    command = <<EOS
kubectl delete -n cert-manager -f - <<EOF
${data.template_file.cert_manager_clusterissuer_production.rendered}
EOF
EOS
  }

  provisioner "local-exec" {
    when = "destroy"

    command = <<EOS
kubectl delete -n cert-manager -f - <<EOF
${data.template_file.cert_manager_clusterissuer_staging.rendered}
EOF
EOS
  }

  triggers {
    contents_production = "${sha1(data.template_file.cert_manager_clusterissuer_production.rendered)}"
    contents_staging    = "${sha1(data.template_file.cert_manager_clusterissuer_staging.rendered)}"
  }
}

resource "null_resource" "cert_manager_kiam_annotation" {
  provisioner "local-exec" {
    command = "kubectl annotate --overwrite namespace cert-manager 'iam.amazonaws.com/permitted=${aws_iam_role.cert_manager.name}'"
  }

  depends_on = ["helm_release.cert-manager"]
}

// This is likely not needed beyond the 0.6 upgrade, see:
//   http://docs.cert-manager.io/en/latest/admin/upgrading/upgrading-0.4-0.5.html
resource "null_resource" "cert_manager_webhook_label" {
  provisioner "local-exec" {
    command = "kubectl label --overwrite namespace cert-manager 'certmanager.k8s.io/disable-validation=true'"
  }

  depends_on = ["helm_release.cert-manager"]
}

resource "null_resource" "cert_manager_servicemonitor" {
  depends_on = ["helm_release.prometheus_operator", "helm_release.cert-manager"]

  provisioner "local-exec" {
    command = "kubectl apply -n cert-manager -f ${path.module}/resources/cert-manager/servicemonitor.yaml"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete -n cert-manager -f ${path.module}/resources/cert-manager/servicemonitor.yaml"
  }

  triggers {
    contents = "${sha1(file("${path.module}/resources/cert-manager/servicemonitor.yaml"))}"
  }
}
