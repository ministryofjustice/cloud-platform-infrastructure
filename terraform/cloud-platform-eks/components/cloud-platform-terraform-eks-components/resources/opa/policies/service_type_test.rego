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

new_namespace(name, annotation) = {
  "apiVersion": "v1",
  "kind": "Namespace",
  "metadata": {
    "name": name
  }
} { not annotation }

new_namespace(name, annotation) = {
  "apiVersion": "v1",
  "kind": "Namespace",
  "metadata": {
    "name": name,
    "annotations": {
      "cloud-platform.justice.gov.uk/can-use-loadbalancer-services": annotation
    }
  }
} { annotation }

test_service_create_allowed {
  not denied
    with input as new_admission_review("CREATE", new_service("ns-0", "svc-0", "ClusterIP"), null)
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace("ns-0", false)
    }
}

test_service_create_denied {
  denied
    with input as new_admission_review("CREATE", new_service("ns-0", "svc-0", "LoadBalancer"), null)
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace("ns-0", false)
    }
}

test_service_create_allowed_by_annotation {
  not denied
    with input as new_admission_review("CREATE", new_service("ns-0", "svc-0", "LoadBalancer"), null)
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace("ns-0", "")
    }
}

test_service_create_allowed_by_annotation_with_value {
  not denied
    with input as new_admission_review("CREATE", new_service("ns-0", "svc-0", "LoadBalancer"), null)
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace("ns-0", "foobar")
    }
}
