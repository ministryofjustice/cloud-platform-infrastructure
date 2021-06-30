
resource "kubernetes_pod_security_policy" "privileged" {
  metadata {
    name = "privileged"
    annotations = {
      "seccomp.security.alpha.kubernetes.io/allowedProfileNames" = "*"
    }
    labels = {
      "kubernetes.io/cluster-service" = "true"
    }
  }

  spec {
    privileged                 = true
    allow_privilege_escalation = true

    allowed_capabilities = [
      "NET_BIND_SERVICE",
      "NET_ADMIN"
    ]

    required_drop_capabilities = [
      "NET_RAW"
    ]

    volumes = [
      "*",
    ]


    host_network = true

    host_ipc = true
    host_pid = true




    run_as_user {
      rule = "RunAsAny"
    }

    se_linux {
      rule = "RunAsAny"
    }

    supplemental_groups {
      rule = "RunAsAny"
    }

    fs_group {
      rule = "RunAsAny"
    }
  }
}
