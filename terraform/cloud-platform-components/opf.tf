data "template_file" "values" {
  template = "${file("${path.module}/templates/opa/values.yaml.tpl")}"

  vars {
    opa_image_tag       = "0.10.5"
    kube_mgmt_image_tag = "0.8"
  }
}

resource "helm_release" "open-policy-agent" {
  name          = "opa"
  namespace     = "opa"
  repository    = "stable"
  chart         = "opa"
  version       = "1.3.2"
  recreate_pods = true

  values = [
    "${data.template_file.values.rendered}",
  ]

  lifecycle {
    ignore_changes = ["keyring"]
  }
}
