#####################################
# Kube-system annotation and labels #
#####################################

resource "kubernetes_annotations" "kube_system_ns" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = "kube-system"
  }
  field_manager = "TerraformAnnotations"
  annotations = {
    "cloud-platform.justice.gov.uk/business-unit" = "Platforms"
    "cloud-platform.justice.gov.uk/application"   = "Cloud Platform"
    "cloud-platform.justice.gov.uk/owner"         = "Cloud Platform: platforms@digital.justice.gov.uk"
    "cloud-platform.justice.gov.uk/source-code"   = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
    "cloud-platform.justice.gov.uk/slack-channel" = "cloud-platform"
    "cloud-platform-out-of-hours-alert"           = "true"
  }
}

resource "kubernetes_labels" "kube_system_ns" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = "kube-system"
  }
  field_manager = "TerraformLabels"
  labels = {
    "component"                                      = "kube-system"
    "cloud-platform.justice.gov.uk/slack-channel"    = "cloud-platform"
    "cloud-platform.justice.gov.uk/is-production"    = "true"
    "cloud-platform.justice.gov.uk/environment-name" = "production"
    "pod-security.kubernetes.io/enforce"             = "privileged"
  }
}

################################
# Default namespace PSA labels #
################################

resource "kubernetes_labels" "default_ns" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = "default"
  }
  labels = {
    "pod-security.kubernetes.io/enforce" = "restricted"
  }
}

resource "kubernetes_labels" "kube_public_ns" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = "kube-public"
  }
  labels = {
    "pod-security.kubernetes.io/enforce" = "restricted"
  }
}

resource "kubernetes_labels" "kube_node_lease_ns" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = "kube-node-lease"
  }
  labels = {
    "pod-security.kubernetes.io/enforce" = "restricted"
  }
}