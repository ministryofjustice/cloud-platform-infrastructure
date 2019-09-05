package cloud_platform.admission

# generates a redacted Pod spec
new_pod(namespace, name, toleration) = {
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": name,
    "namespace": namespace
  },
} { not toleration }

new_pod(namespace, name, toleration) = {
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": name,
    "namespace": namespace,
    "tolerations": toleration
  }
} { toleration }


new_namespace_toleration(name, annotation) = {
  "apiVersion": "v1",
  "kind": "Namespace",
  "metadata": {
    "name": name
  }
} { not annotation }

new_namespace_toleration(name, annotation) = {
  "apiVersion": "v1",
  "kind": "Namespace",
  "metadata": {
    "name": name,
    "annotations": {
      "cloud-platform.justice.gov.uk/can-tolerate-master-taints": annotation
    }
  }
} { annotation }

test_pod_create_allowed {
  not denied
    with input as new_admission_review("CREATE", new_pod("ns-0", "pod-0", false), null)
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace_toleration("ns-0", true)
    }
}

test_pod_create_toleration_allowed {
  not denied
    with input as new_admission_review("CREATE", new_pod("ns-0", "pod-0", "foobar"), null)
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace_toleration("ns-0", true)
    }
}

test_pod_create_toleration_master_denied {
  not denied
    with input as new_admission_review("CREATE", new_pod("ns-0", "pod-0", "node-role.kubernetes.io/master:NoSchedule"), null)
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace_toleration("ns-0", true)
    }
}

test_pod_create_allowed_by_annotation {
  denied
    with input as new_admission_review("CREATE", new_pod("ns-0", "pod-0", "node-role.kubernetes.io/master:NoSchedule"), null)
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace_toleration("ns-0", false)
    }
}

# test_pod_create_allowed_by_annotation_with_value {
#   not denied
#     with input as new_admission_review("CREATE", new_pod("ns-0", "pod-0", false), null)
#     with data.kubernetes.namespaces as {
#       "ns-0": new_namespace_toleration("ns-0", "foobar")
#     }
# }
