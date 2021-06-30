
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

    host_ports {
      min = 0
      max = 65535
    }

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

resource "kubernetes_pod_security_policy" "restricted" {
  metadata {
    name = "restricted"
    annotations = {
      "seccomp.security.alpha.kubernetes.io/allowedProfileNames" = "docker/default,runtime/default"
      "seccomp.security.alpha.kubernetes.io/defaultProfileName" = "runtime/default"
    }
  }

  spec {
    privileged                 = false
    allow_privilege_escalation = false

    required_drop_capabilities = [
      "ALL",
    ]

    volumes = [
      "configMap",
      "emptyDir",
      "projected",
      "secret",
      "downwardAPI",
      # Assume that persistentVolumes set up by the cluster admin are safe to use.
      "persistentVolumeClaim",
    ]

    host_network = false
    host_ipc = false
    host_pid = false

    run_as_user {
      rule = "MustRunAsNonRoot"
    }

    se_linux {
      rule = "RunAsAny"
    }

    supplemental_groups {
      rule = "MustRunAs"
      range {
        min = 1
        max = 65535
      }
    }

    fs_group {
      rule = "MustRunAs"
      range {
        min = 1
        max = 65535
      }
    }

    read_only_root_filesystem = true
  }
}

resource "kubernetes_pod_security_policy" "aws_node" {
  metadata {
    name = "aws-node"
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

    volumes = [
      "*",
    ]

    host_ports {
      min = 0
      max = 65535
    }

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
