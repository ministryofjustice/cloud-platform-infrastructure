resource "opensearch_index_template" "live_kubernetes_cluster" {
  provider = opensearch.app_logs
  name     = "live_kubernetes_cluster"
  body     = <<EOF
{
  "index_patterns": [
    "live_kubernetes_cluster-*"
  ],
  "template": {
    "settings": {
      "index": {
        "number_of_shards": "15",
        "number_of_replicas": "1"
      }
    }
  }
}
EOF
}

resource "opensearch_index_template" "live_kubernetes_ingress" {
  provider = opensearch.app_logs
  name     = "live_kubernetes_ingress"
  body     = <<EOF
{
  "index_patterns": [
    "live_kuberenetes_ingress-*"
  ],
  "template": {
    "settings": {
      "index": {
        "number_of_shards": "1",
        "number_of_replicas": "1"
      }
    }
  }
}
EOF
}

resource "opensearch_index_template" "live_eventrouter" {
  provider = opensearch.app_logs

  name = "live_eventrouter"
  body = <<EOF
{
  "index_patterns": [
    "live_eventrouter-*"
  ],
  "template": {
    "settings": {
      "index": {
        "number_of_shards": "1",
        "number_of_replicas": "1"
      }
    }
  }
}
EOF
}

resource "opensearch_index_template" "manager_kubernetes_cluster" {
  provider = opensearch.app_logs

  name = "manager_kubernetes_cluster"
  body = <<EOF
{
  "index_patterns": [
    "manager_kuberenetes_cluster-*"
  ],
  "template": {
    "settings": {
      "index": {
        "number_of_shards": "1",
        "number_of_replicas": "1"
      }
    }
  }
}
EOF
}

resource "opensearch_index_template" "manager_kubernetes_ingress" {
  provider = opensearch.app_logs
  name     = "manager_kubernetes_ingress"
  body     = <<EOF
{
  "index_patterns": [
    "manager_kuberenetes_ingress-*"
  ],
  "template": {
    "settings": {
      "index": {
        "number_of_shards": "1",
        "number_of_replicas": "1"
      }
    }
  }
}
EOF
}

resource "opensearch_index_template" "manager_eventrouter" {
  provider = opensearch.app_logs
  name     = "manager_eventrouter"
  body     = <<EOF
{
  "index_patterns": [
    "manager_eventrouter-*"
  ],
  "template": {
    "settings": {
      "index": {
        "number_of_shards": "1",
        "number_of_replicas": "1"
      }
    }
  }
}
EOF
}
