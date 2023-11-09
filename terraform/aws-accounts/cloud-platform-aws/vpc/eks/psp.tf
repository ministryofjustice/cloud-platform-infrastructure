## Pod Security Policy: 0-super-privileged
resource "kubernetes_pod_security_policy" "super_privileged" {
  metadata {
    name = "0-super-privileged"
    annotations = {
      "seccomp.security.alpha.kubernetes.io/allowedProfileNames" = "*"
    }
    labels = {
      "kubernetes.io/cluster-service" = "true"
    }
  }

  spec {
    privileged                         = true
    allow_privilege_escalation         = true
    default_allow_privilege_escalation = true

    allowed_capabilities = ["*"]

    volumes = [
      "*",
    ]

    host_ports {
      min = 0
      max = 65535
    }

    host_network = true
    host_ipc     = true
    host_pid     = true

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


## ClusterRole: 0-super-privileged
resource "kubernetes_cluster_role" "super-privileged" {
  metadata {
    name = "psp:0-super-privileged"
  }

  rule {
    api_groups     = ["policy"]
    resources      = ["podsecuritypolicies"]
    verbs          = ["use"]
    resource_names = ["0-super-privileged"]
  }

}


## Pod Security Policy: privileged
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
    privileged                         = true
    allow_privilege_escalation         = true
    default_allow_privilege_escalation = true

    allowed_capabilities = [
      "NET_BIND_SERVICE",
      "NET_ADMIN",
      "SYS_CHROOT"
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
    host_ipc     = true
    host_pid     = true

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

## ClusterRoleBinding: super-privileged
resource "kubernetes_cluster_role_binding" "super_privileged" {
  metadata {
    name = "default:0-super-privileged"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "psp:0-super-privileged"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "metrics-server"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "coredns"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "kube-proxy"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "tigera-operator"
    namespace = "tigera-operator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "calico-node"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "cluster-autoscaler-aws-cluster-autoscaler"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "calico-typha-cpha"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "typha-cpha"
    namespace = "kube-system"
  }

  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:cert-manager"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:concourse"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:ingress-controllers"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:kuberos"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:logging"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:monitoring"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:opa"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "ebs-csi-node-sa"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "efs-csi-controller-sa"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "efs-csi-node-sa"
    namespace = "kube-system"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:trivy-system"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "aws-node"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "external-dns"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    namespace = "gatekeeper-system"
    name      = "gatekeeper-admin"
  }
}



## ClusterRole: privileged
resource "kubernetes_cluster_role" "privileged" {
  metadata {
    name = "psp:privileged"
  }

  rule {
    api_groups     = ["policy"]
    resources      = ["podsecuritypolicies"]
    verbs          = ["use"]
    resource_names = ["privileged"]
  }

}

## ClusterRoleBinding: privileged
resource "kubernetes_cluster_role_binding" "privileged" {
  metadata {
    name = "default:privileged"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "psp:privileged"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "metrics-server"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "coredns"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "kube-proxy"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "tigera-operator"
    namespace = "tigera-operator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "calico-node"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "cluster-autoscaler-aws-cluster-autoscaler"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "calico-typha-cpha"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "typha-cpha"
    namespace = "kube-system"
  }

  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:cert-manager"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:concourse"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:ingress-controllers"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:kuberos"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:logging"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:monitoring"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:opa"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "ebs-csi-node-sa"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "efs-csi-controller-sa"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "efs-csi-node-sa"
    namespace = "kube-system"
  }
  subject {
    kind      = "Group"
    name      = "system:serviceaccounts:trivy-system"
    api_group = "rbac.authorization.k8s.io"
  }
}

## Pod Security Policy: restricted
resource "kubernetes_pod_security_policy" "restricted" {
  metadata {
    name = "restricted"
    annotations = {
      "seccomp.security.alpha.kubernetes.io/allowedProfileNames" = "docker/default,runtime/default"
      "seccomp.security.alpha.kubernetes.io/defaultProfileName"  = "runtime/default"
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
    host_ipc     = false
    host_pid     = false

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

    read_only_root_filesystem = false
  }
}


## ClusterRole: restricted
resource "kubernetes_cluster_role" "restricted" {
  metadata {
    name = "psp:restricted"
  }

  rule {
    api_groups     = ["policy"]
    resources      = ["podsecuritypolicies"]
    verbs          = ["use"]
    resource_names = ["restricted"]
  }

}

## ClusterRoleBinding: restricted
resource "kubernetes_cluster_role_binding" "restricted" {
  metadata {
    name = "default:restricted"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "psp:restricted"
  }
  subject {
    kind      = "Group"
    name      = "system:authenticated"
    api_group = "rbac.authorization.k8s.io"
  }


}

# Pod Security Policy: aws-node
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
    privileged                         = true
    allow_privilege_escalation         = true
    default_allow_privilege_escalation = true

    allowed_capabilities = [
      "NET_BIND_SERVICE",
      "NET_ADMIN",
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
    host_ipc     = true
    host_pid     = true

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


## ClusterRole: aws-node
resource "kubernetes_cluster_role" "aws_node" {
  metadata {
    name = "psp:aws-node"
  }

  rule {
    api_groups     = ["policy"]
    resources      = ["podsecuritypolicies"]
    verbs          = ["use"]
    resource_names = ["aws-node"]
  }

}

## ClusterRoleBinding: aws-node
resource "kubernetes_cluster_role_binding" "aws_node" {
  metadata {
    name = "default:aws-node"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "psp:aws-node"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "aws-node"
    namespace = "kube-system"
  }
}

