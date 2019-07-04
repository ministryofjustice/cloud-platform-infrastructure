package cloud_platform.admission

import data.kubernetes.ingresses

deny[msg] {
  input.request.kind.kind == "Ingress"
  id := concat("/", [input.request.object.metadata.namespace, input.request.object.metadata.name])
  host := input.request.object.spec.rules[_].host
  other_ingress := data.kubernetes.ingresses[other_namespace][other_name]
  id != concat("/", [other_namespace, other_name])
  host == other_ingress.spec.rules[_].host
  msg := sprintf("ingress host (%v) conflicts with ingress %v/%v", [host, other_namespace, other_name])
}
