resource "helm_release" "fluentd_es" {
    name      = "fluentd-es"
    chart     = "./fluentd-es"

    set {
        name  = "namespace"
        value = "logging"
    }

    set {
        name = "version"
        value = "v2.2.0"
    }

    set {
        name = "FLUENT_ELASTICSEARCH_HOST"
        value = "search-cloud-platform-test-o2m2taivvjpovbcl63mlytnpua.eu-west-1.es.amazonaws.com"
    }

    set {
        name = "FLUENT_ELASTICSEARCH_AUDIT_HOST"
        value = "search-cloud-platform-audit-effm3qdiau42obkarrpvdxioxm.eu-west-1.es.amazonaws.com"
    }

    set {
        name = "FLUENT_KUBERNETES_CLUSTER_NAME"
        value = "cloud-platform-test-1"
    }
}