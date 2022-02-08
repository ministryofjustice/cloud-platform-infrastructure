resource "null_resource" "tzcronjobber" {
  provisioner "local-exec" {
    command = "kubectl apply -n kube-system -f ${path.module}/resources/tzcronjobber/"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -n kube-system --ignore-not-found -f ${path.module}/resources/tzcronjobber/"
  }
}
