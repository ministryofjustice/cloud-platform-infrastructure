package cloud_platform.admission

import data.kubernetes.namespaces

deny[msg] {
  input.request.kind.kind == "Pod"
  not data.kubernetes.namespaces[input.request.object.metadata.namespace].metadata.annotations["cloud-platform.justice.gov.uk/can-tolerate-master-taints"]
  msg := sprintf("Pods %v/%v dont have the toleration and is not allowed to schedule on master node. Please get in touch with us in #ask-cloud-platform", [input.request.object.metadata.namespace, input.request.object.metadata.name])
}
