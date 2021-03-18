
####################
# Priority Classes #
####################

resource "kubernetes_priority_class" "cluster_critical" {
  metadata {
    name = "cluster-critical"
  }

  value          = 999999000
  global_default = false
  description    = "This priority class is meant to be used as the system-cluster-critical class, outside of the kube-system namespace."
}

resource "kubernetes_priority_class" "node_critical" {
  metadata {
    name = "node-critical"
  }

  value          = 1000000000
  global_default = false
  description    = "This priority class is meant to be used as the system-node-critical class, outside of the kube-system namespace."
}

###################
# Storage Classes #
###################

resource "kubernetes_storage_class" "storageclass" {

  metadata {
    name = "gp2-expand"
  }

  storage_provisioner    = "kubernetes.io/aws-ebs"
  reclaim_policy         = "Delete"
  allow_volume_expansion = "true"

  parameters = {
    type      = "gp2"
    encrypted = "true"
  }
}

#######
# PSP #
#######

# Still kubernetes terraform provider doesn't support pod security policies, 

resource "null_resource" "pod_security_policy" {
  provisioner "local-exec" {
    command = "kubectl create -f ${path.module}/resources/psp/pod-security-policy.yaml"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete --ignore-not-found -f ${path.module}/resources/psp/pod-security-policy.yaml"
  }

  triggers = {
    content = filesha1("${path.module}/resources/psp/pod-security-policy.yaml")
  }
}

########
# RBAC #
########

resource "kubernetes_cluster_role_binding" "webops" {
  metadata {
    name = "webops-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "Group"
    name      = "github:webops"
    api_group = "rbac.authorization.k8s.io"
  }
}
