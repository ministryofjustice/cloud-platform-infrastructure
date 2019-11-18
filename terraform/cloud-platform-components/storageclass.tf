resource "null_resource" "storageclass" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/resources/storageclass.yaml"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f ${path.module}/resources/storageclass.yaml"
  }
}

