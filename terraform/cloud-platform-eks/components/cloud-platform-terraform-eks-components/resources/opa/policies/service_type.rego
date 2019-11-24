package cloud_platform.admission

import data.kubernetes.namespaces

deny[msg] {
  input.request.kind.kind == "Service"
  input.request.object.spec.type == "LoadBalancer"
  not data.kubernetes.namespaces[input.request.object.metadata.namespace].metadata.annotations["cloud-platform.justice.gov.uk/can-use-loadbalancer-services"]
  msg := sprintf("services %v/%v is of type LoadBalancer and is not allowed. Please get in touch with us in #ask-cloud-platform", [input.request.object.metadata.namespace, input.request.object.metadata.name])
}
