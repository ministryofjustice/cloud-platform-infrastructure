package cloud_platform.admission

import data.kubernetes.namespaces

 deny[msg] {
  toleration := input.request.object.spec.tolerations[_]
  not toleration.key
  not data.kubernetes.namespaces[input.request.object.metadata.namespace].metadata.annotations["cloud-platform.justice.gov.uk/can-tolerate-master-taints"]
  msg := sprintf("Pods %v/%v have toleration and is not allowed to schedule on master node. Please get in touch with us in #ask-cloud-platform", [input.request.object.metadata.name, input.request.object.metadata.namespace])
 }