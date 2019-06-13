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

