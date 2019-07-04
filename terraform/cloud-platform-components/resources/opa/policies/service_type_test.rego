package cloud_platform.admission

# generates a redacted Service spec
new_service(namespace, name, type) = {
  "apiVersion": "extensions/v1beta1",
  "kind": "Service",
  "metadata": {
    "name": name,
    "namespace": namespace
  },
  "spec": {
    "type": type
  }
}

new_namespace(name, has_annotation) = {
  "apiVersion": "v1",
  "kind": "Namespace",
  "metadata": {
    "name": name
  }
} { not has_annotation }

new_namespace(name, has_annotation) = {
  "apiVersion": "v1",
  "kind": "Namespace",
  "metadata": {
    "name": name,
    "annotations": {
      "cloud-platform.justice.gov.uk/can-use-loadbalancer-services": ""
    }
  }
} { has_annotation }

# generates a redacted AdmissionReview payload (used to mock `input`)
new_admission_review(namespace, name, type, op) = {
  "kind": "AdmissionReview",
  "apiVersion": "admission.k8s.io/v1beta1",
  "request": {
    "kind": {
      "kind": "Service"
    },
    "operation": op,
    "object": new_service(namespace, name, type),
    "oldObject": null
  }
}

test_service_create_allowed {
  not denied
    with input as new_admission_review("ns-0", "svc-0", "ClusterIP", "CREATE")
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace("ns-0", false)
    }
}

test_service_create_denied {
  denied
    with input as new_admission_review("ns-0", "svc-0", "LoadBalancer", "CREATE")
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace("ns-0", false)
    }
}

test_service_create_allowed_by_annotation {
  not denied
    with input as new_admission_review("ns-0", "svc-0", "LoadBalancer", "CREATE")
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace("ns-0", true)
    }
}
