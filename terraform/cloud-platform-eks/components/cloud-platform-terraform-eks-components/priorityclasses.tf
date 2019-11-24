
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
