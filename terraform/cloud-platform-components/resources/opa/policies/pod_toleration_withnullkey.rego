package cloud_platform.admission

import data.kubernetes.namespaces

# The intention of this policy is to not schedule any workload on master node except for required system services which namespaces are annotated.
# This policy prevents using the toleration with empty key or no key.

 deny[msg] {
  toleration := input.request.object.spec.tolerations[_]
  not toleration.key
  not data.kubernetes.namespaces[input.request.object.metadata.namespace].metadata.annotations["cloud-platform.justice.gov.uk/can-tolerate-master-taints"]
  msg := sprintf("Pods %v/%v have tolerations. Pods with tolerations will not be scheduled. Please get in touch with us in #ask-cloud-platform", [input.request.object.metadata.name, input.request.object.metadata.namespace])
 }