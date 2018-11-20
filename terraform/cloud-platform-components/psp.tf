resource "null_resource" "pod_security_policy" {
  provisioner "local-exec" {
    command = "kubectl create -f ${path.module}/resources/psp/pod-security-policy.yaml"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete -f ${path.module}/resources/psp/pod-security-policy.yaml"
  }
}
