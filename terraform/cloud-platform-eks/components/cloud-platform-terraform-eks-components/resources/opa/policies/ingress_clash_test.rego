package cloud_platform.admission

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

test_ingress_create_allowed {
  not denied
    with input as new_admission_review("CREATE", new_ingress("ns-0", "ing-1", "ing-1.example.com"), null)
    with data.kubernetes.ingresses as {
      "ns-0": {
        "ing-0": new_ingress("ns-0", "ing-0", "ing-0.example.com")
      }
    }
}

test_ingress_create_conflict {
  denied
    with input as new_admission_review("CREATE", new_ingress("ns-0", "ing-1", "ing-0.example.com"), null)
    with data.kubernetes.ingresses as {
      "ns-0": {
        "ing-0": new_ingress("ns-0", "ing-0", "ing-0.example.com")
      }
    }
}

test_ingress_update_same_host {
  not denied
    with input as new_admission_review("UPDATE", new_ingress("ns-0", "ing-0", "ing-0.example.com"), null)
    with data.kubernetes.ingresses as {
      "ns-0": {
        "ing-0": new_ingress("ns-0", "ing-0", "ing-0.example.com")
      }
    }
}

test_ingress_update_new_host {
  not denied
    with input as new_admission_review("UPDATE", new_ingress("ns-0", "ing-0", "ing-1.example.com"), null)
    with data.kubernetes.ingresses as {
      "ns-0": {
        "ing-0": new_ingress("ns-0", "ing-0", "ing-0.example.com")
      }
    }
}

test_ingress_update_existing_host {
  denied
    with input as new_admission_review("UPDATE", new_ingress("ns-0", "ing-0", "ing-1.example.com"), null)
    with data.kubernetes.ingresses as {
      "ns-0": {
        "ing-0": new_ingress("ns-0", "ing-0", "ing-0.example.com"),
        "ing-1": new_ingress("ns-0", "ing-1", "ing-1.example.com")
      }
    }
}

test_ingress_update_existing_host_other_namespace {
  denied
    with input as new_admission_review("UPDATE", new_ingress("ns-0", "ing-0", "ing-1.example.com"), null)
    with data.kubernetes.ingresses as {
      "ns-0": {
        "ing-0": new_ingress("ns-0", "ing-0", "ing-0.example.com"),
      },
      "ns-1": {
        "ing-1": new_ingress("ns-1", "ing-1", "ing-1.example.com")
      }
    }
}
