# NOTE: When it happens the K8S upgrade to 1.14 we'll be able to use kubernetes_priority_class terraform
#       resource, for the time being is not possible. Please check: 
#       https://github.com/terraform-providers/terraform-provider-kubernetes/issues/681

resource "null_resource" "priority_classes" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/resources/priorityclasses.yaml"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f ${path.module}/resources/priorityclasses.yaml"
  }

  triggers = {
    contents = filesha1("${path.module}/resources/priorityclasses.yaml")
  }
}

