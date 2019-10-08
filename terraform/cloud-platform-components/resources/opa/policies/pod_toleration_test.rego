package cloud_platform.admission

# generates a redacted Pod spec
new_pod(namespace, name, toleration) = {
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": name,
    "namespace": namespace
  },
  "spec": {
    "tolerations": {
      "operator": "exists", 
      "effect": "NoSchedule"
    }
  }
} { not toleration }


new_pod(namespace, name, toleration) = {
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": name,
    "namespace": namespace
  },
  "spec": {
    "tolerations": {
      "key": toleration, 
      "effect": "NoSchedule"
    }
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

test_pod_with_toleration_key_denied {
  denied
    with input as new_admission_review("CREATE", new_pod("ns-0", "pod-0", "node-role.kubernetes.io/master"), null)
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace_toleration("ns-0", false)
    }
}

test_pod_with_toleration_key_annotated_allowed {
  not denied
    with input as new_admission_review("CREATE", new_pod("ns-0", "pod-0", "node-role.kubernetes.io/master"), null)
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace_toleration("ns-0", true)
    }
}

test_pod_with_toleration_nullkey_denied {
  denied
    with input as new_admission_review("CREATE", new_pod("ns-0", "pod-0", "null"), null)
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace_toleration("ns-0", false)
    }
}

test_pod_with_toleration_nullkey_annotated_allowed {
  not denied
    with input as new_admission_review("CREATE", new_pod("ns-0", "pod-0", "null"), null)
    with data.kubernetes.namespaces as {
      "ns-0": new_namespace_toleration("ns-0", true)
    }
}

