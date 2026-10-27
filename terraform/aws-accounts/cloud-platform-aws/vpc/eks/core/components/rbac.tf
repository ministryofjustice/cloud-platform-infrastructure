
####################
# Priority Classes #
####################

resource "kubernetes_priority_class" "cluster_critical" {
  metadata {
    name = "cluster-critical"
  }

  value          = 999999000
  description    = "This priority class is meant to be used as the system-cluster-critical class, outside of the kube-system namespace."
  global_default = false
}

resource "kubernetes_priority_class" "node_critical" {
  metadata {
    name = "node-critical"
  }

  value          = 1000000000
  description    = "This priority class is meant to be used as the system-node-critical class, outside of the kube-system namespace."
  global_default = false
}

resource "kubernetes_priority_class" "default" {
  metadata {
    name = "default"
  }

  value          = 0
  description    = "Default priority class for all pods."
  global_default = true
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

resource "kubernetes_service_account" "concourse_build_environments" {
  metadata {
    name      = "concourse-build-environments"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "concourse_build_environments" {
  metadata {
    name = "concourse-build-environments"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "concourse-build-environments"
    namespace = "kube-system"
  }
}

# Wiz read-only access. WizAccess-Role is mapped to the wiz-reader group in vpc/eks/cluster.tf.
# Wiz's connector chart (wiz-sec/charts wiz-kubernetes-connector, clusterReader.rules) grants
# get/list/watch on */*. This keeps those verbs but excludes Secrets, which a wildcard would
# include, so core ("") resources are listed explicitly.
resource "kubernetes_cluster_role" "wiz_reader" {
  metadata {
    # Wiz checks for a ClusterRole with this exact name
    name = "wiz-cluster-reader"
  }

  rule {
    api_groups = [""]
    resources = [
      "bindings",
      "componentstatuses",
      "configmaps",
      "endpoints",
      "events",
      "limitranges",
      "namespaces",
      "nodes",
      "persistentvolumeclaims",
      "persistentvolumes",
      "pods",
      "podtemplates",
      "replicationcontrollers",
      "resourcequotas",
      "serviceaccounts",
      "services",
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = [
      "admissionregistration.k8s.io",
      "apiextensions.k8s.io",
      "apiregistration.k8s.io",
      "apps",
      "autoscaling",
      "batch",
      "certificates.k8s.io",
      "coordination.k8s.io",
      "discovery.k8s.io",
      "events.k8s.io",
      "flowcontrol.apiserver.k8s.io",
      "networking.k8s.io",
      "node.k8s.io",
      "policy",
      "rbac.authorization.k8s.io",
      "scheduling.k8s.io",
      "storage.k8s.io",
      # CRD groups installed on Cloud Platform clusters
      "autoscaling.k8s.io",
      "cert-manager.io",
      "config.gatekeeper.sh",
      "constraints.gatekeeper.sh",
      "crd.projectcalico.org",
      "external-secrets.io",
      "monitoring.coreos.com",
      "snapshot.storage.k8s.io",
      "templates.gatekeeper.sh",
      "velero.io",
    ]
    resources = ["*"]
    verbs     = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "wiz_reader" {
  metadata {
    name = "wiz-reader"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.wiz_reader.metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = "wiz-reader"
    api_group = "rbac.authorization.k8s.io"
  }
}
