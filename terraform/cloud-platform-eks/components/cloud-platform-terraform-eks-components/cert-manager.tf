
################
# Cert-Manager #
################

#
# K8S
#

locals {
  cert-manager-version = "v0.8.1"
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"

    labels = {
      "name"                                           = "cert-manager"
      "component"                                      = "cert-manager"
      "cloud-platform.justice.gov.uk/environment-name" = "production"
      "cloud-platform.justice.gov.uk/is-production"    = "true"
      "certmanager.k8s.io/disable-validation"          = "true"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"                   = "cert-manager"
      "cloud-platform.justice.gov.uk/business-unit"                 = "cloud-platform"
      "cloud-platform.justice.gov.uk/owner"                         = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                   = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "cloud-platform.justice.gov.uk/can-use-loadbalancer-services" = "true"
      "iam.amazonaws.com/permitted"                                 = aws_iam_role.cert_manager.name
    }
  }
}

data "http" "cert-manager-crds" {
  url = "https://raw.githubusercontent.com/jetstack/cert-manager/${local.cert-manager-version}/deploy/manifests/00-crds.yaml"
}

resource "null_resource" "cert-manager-crds" {
  provisioner "local-exec" {
    command = "kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/${local.cert-manager-version}/deploy/manifests/00-crds.yaml"
  }

  provisioner "local-exec" {
    when = destroy
    command = "kubectl delete -n cert-manager -f https://raw.githubusercontent.com/jetstack/cert-manager/${local.cert-manager-version}/deploy/manifests/00-crds.yaml"
  }

  triggers = {
    contents_crds = sha1(data.http.cert-manager-crds.body)
  }
}

#
# HELM
#

data "helm_repository" "jetstack" {
  name = "jetstack"
  url  = "https://charts.jetstack.io"
}

resource "helm_release" "cert-manager" {
  name          = "cert-manager"
  chart         = "jetstack/cert-manager"
  repository    = data.helm_repository.jetstack.metadata[0].name
  namespace     = kubernetes_namespace.cert_manager.id
  version       = local.cert-manager-version
  recreate_pods = true

  values = [templatefile("${path.module}/templates/cert-manager.yaml.tpl", {
    iam_role = aws_iam_role.cert_manager.name
  })]


  depends_on = [
    null_resource.deploy,
    null_resource.cert-manager-crds,
    kubernetes_namespace.cert_manager,
  ]
}

resource "null_resource" "cert_manager_issuers" {
  depends_on = [helm_release.cert-manager]

  provisioner "local-exec" {
    command = "kubectl apply -n cert-manager -f ${path.module}/templates/cert-manager/letsencrypt-production.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply -n cert-manager -f ${path.module}/templates/cert-manager/letsencrypt-staging.yaml"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -n cert-manager -f ${path.module}/templates/cert-manager/letsencrypt-production.yaml"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -n cert-manager -f ${path.module}/templates/cert-manager/letsencrypt-staging.yaml"
  }

  triggers = {
    contents_production = filesha1(
      "${path.module}/templates/cert-manager/letsencrypt-production.yaml",
    )
    contents_staging = filesha1(
      "${path.module}/templates/cert-manager/letsencrypt-staging.yaml",
    )
  }
}

#
# IAM bits
#

resource "aws_iam_role" "cert_manager" {
  name               = "cert-manager.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  assume_role_policy = data.aws_iam_policy_document.allow_to_assume.json
}

data "aws_iam_policy_document" "cert_manager" {
  statement {
    actions = ["route53:ChangeResourceRecordSets"]
    resources = [format(
      "arn:aws:route53:::hostedzone/%s",
      terraform.workspace == local.live_workspace ? "*" : data.aws_route53_zone.selected.zone_id,
    )]
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

resource "aws_iam_role_policy_attachment" "cert_manager_attach_policy" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.cert_manager.arn
}

resource "aws_iam_policy" "cert_manager" {
  name        = "cert-manager.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  path        = "/"
  description = "Policy that allows change update domains for the certmanager service"
  policy      = data.aws_iam_policy_document.cert_manager.json
}
