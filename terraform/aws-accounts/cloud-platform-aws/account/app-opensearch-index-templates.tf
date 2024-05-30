resource "opensearch_index_template" "live_kubernetes_cluster" {
  name = "live_kubernetes_cluster"
  body = <<EOF
{
  "index_patterns": [
    "live_kuberenetes_cluster-*"
  ],
    "settings": {
      "index": {
        "number_of_shards": "15",
        "number_of_replicas": "1"
      }
    }
  }
EOF
}

resource "opensearch_index_template" "live_kubernetes_ingress" {
  name = "live_kubernetes_ingress"
  body = <<EOF
{
  "index_patterns": [
    "live_kuberenetes_ingress-*"
  ],
    "settings": {
      "index": {
        "number_of_shards": "1",
        "number_of_replicas": "1"
      }
    }
}
EOF
}

resource "opensearch_index_template" "live_eventrouter" {
  name = "live_eventrouter"
  body = <<EOF
{
  "index_patterns": [
    "live_eventrouter-*"
  ],
    "settings": {
      "index": {
        "number_of_shards": "1",
        "number_of_replicas": "1"
      }
    }
}
EOF
}

resource "opensearch_index_template" "manager_kubernetes_cluster" {
  name = "manager_kubernetes_cluster"
  body = <<EOF
{
  "index_patterns": [
    "manager_kuberenetes_cluster-*"
  ],
    "settings": {
      "index": {
        "number_of_shards": "1",
        "number_of_replicas": "1"
      }
    }
}
EOF
}

resource "opensearch_index_template" "manager_kubernetes_ingress" {
  name = "manager_kubernetes_ingress"
  body = <<EOF
{
  "index_patterns": [
    "manager_kuberenetes_ingress-*"
  ],
    "settings": {
      "index": {
        "number_of_shards": "1",
        "number_of_replicas": "1"
      }
    }
}
EOF
}

resource "opensearch_index_template" "manager_eventrouter" {
  name = "manager_eventrouter"
  body = <<EOF
{
  "index_patterns": [
    "live_eventrouter-*"
  ],
    "settings": {
      "index": {
        "number_of_shards": "1",
        "number_of_replicas": "1"
      }
    }
  }
EOF
}
