data "template_file" "values" {
  template = "${file("${path.module}/templates/opa/values.yaml.tpl")}"
}

resource "helm_release" "open-policy-agent" {
  name       = "opa"
  namespace  = "opa"
  repository = "stable"
  chart      = "opa"
  version    = "1.3.2"

  values = [
    "${data.template_file.values.rendered}",
  ]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}

resource "kubernetes_config_map" "policy_default" {
  metadata {
    name      = "policy-default"
    namespace = "${helm_release.open-policy-agent.namespace}"

    labels {
      "openpolicyagent.org/policy" = "rego"
    }
  }

  data {
    main.rego = "${file("${path.module}/resources/opa/policies/main.rego")}"
  }

  lifecycle {
    ignore_changes = ["metadata.0.annotations"]
  }
}

resource "kubernetes_config_map" "policy_cloud_platform_admission" {
  metadata {
    name      = "policy-cloud-platform-admission"
    namespace = "${helm_release.open-policy-agent.namespace}"

    labels {
      "openpolicyagent.org/policy" = "rego"
    }
  }

  data {
    main.rego = "${file("${path.module}/resources/opa/policies/cloud_platform_admission.rego")}"
  }

  lifecycle {
    ignore_changes = ["metadata.0.annotations"]
  }
}

resource "kubernetes_config_map" "policy_ingress_clash" {
  metadata {
    name      = "policy-ingress-clash"
    namespace = "${helm_release.open-policy-agent.namespace}"

    labels {
      "openpolicyagent.org/policy" = "rego"
    }
  }

  data {
    main.rego = "${file("${path.module}/resources/opa/policies/ingress_clash.rego")}"
  }

  lifecycle {
    ignore_changes = ["metadata.0.annotations"]
  }
}

resource "kubernetes_config_map" "policy_service_type" {
  metadata {
    name      = "policy-service-type"
    namespace = "${helm_release.open-policy-agent.namespace}"

    labels {
      "openpolicyagent.org/policy" = "rego"
    }
  }

  data {
    main.rego = "${file("${path.module}/resources/opa/policies/service_type.rego")}"
  }

  lifecycle {
    ignore_changes = ["metadata.0.annotations"]
  }
}
