package cloud_platform.admission.ingress

# generates a redacted Ingress spec
new_ingress(namespace, name, host) = {
  "apiVersion": "extensions/v1beta1",
  "kind": "Ingress",
  "metadata": {
    "name": name,
    "namespace": namespace
  },
  "spec": {
    "rules": [{ "host": host }]
  }
}

# generates a redacted AdmissionReview payload (used to mock `input`)
new_admission_review(namespace, name, host, op) = {
  "kind": "AdmissionReview",
  "apiVersion": "admission.k8s.io/v1beta1",
  "request": {
    "kind": {
      "kind": "Ingress"
    },
    "operation": op,
    "object": new_ingress(namespace, name, host),
    "oldObject": null
  }
}

test_ingress_create_allowed {
  not denied
    with input as new_admission_review("ns-0", "ing-1", "ing-1.example.com", "CREATE")
    with data.kubernetes.ingresses as {
      "ns-0": {
        "ing-0": new_ingress("ns-0", "ing-0", "ing-0.example.com")
      }
    }
}

test_ingress_create_conflict {
  denied
    with input as new_admission_review("ns-0", "ing-1", "ing-0.example.com", "CREATE")
    with data.kubernetes.ingresses as {
      "ns-0": {
        "ing-0": new_ingress("ns-0", "ing-0", "ing-0.example.com")
      }
    }
}

test_ingress_update_same_host {
  not denied
    with input as new_admission_review("ns-0", "ing-0", "ing-0.example.com", "UPDATE")
    with data.kubernetes.ingresses as {
      "ns-0": {
        "ing-0": new_ingress("ns-0", "ing-0", "ing-0.example.com")
      }
    }
}

test_ingress_update_new_host {
  not denied
    with input as new_admission_review("ns-0", "ing-0", "ing-1.example.com", "UPDATE")
    with data.kubernetes.ingresses as {
      "ns-0": {
        "ing-0": new_ingress("ns-0", "ing-0", "ing-0.example.com")
      }
    }
}

test_ingress_update_existing_host {
  denied
    with input as new_admission_review("ns-0", "ing-0", "ing-1.example.com", "UPDATE")
    with data.kubernetes.ingresses as {
      "ns-0": {
        "ing-0": new_ingress("ns-0", "ing-0", "ing-0.example.com"),
        "ing-1": new_ingress("ns-0", "ing-1", "ing-1.example.com")
      }
    }
}

test_ingress_update_existing_host_other_namespace {
  denied
    with input as new_admission_review("ns-0", "ing-0", "ing-1.example.com", "UPDATE")
    with data.kubernetes.ingresses as {
      "ns-0": {
        "ing-0": new_ingress("ns-0", "ing-0", "ing-0.example.com"),
      },
      "ns-1": {
        "ing-1": new_ingress("ns-1", "ing-1", "ing-1.example.com")
      }
    }
}
