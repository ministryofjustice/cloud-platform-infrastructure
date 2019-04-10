data "template_file" "values" {
  template = "${file("${path.module}/templates/opa/values.yaml.tpl")}"

  vars {
    opa_image_tag       = "0.10.5"
    kube_mgmt_image_tag = "0.8"
  }
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

resource "null_resource" "open-policy-agent_policies" {
  depends_on = ["helm_release.open-policy-agent"]

  provisioner "local-exec" {
    command = "kubectl apply -n opa -f ${path.module}/resources/opa/"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete -n opa --ignore-not-found -f ${path.module}/resources/opa/"
  }
}
