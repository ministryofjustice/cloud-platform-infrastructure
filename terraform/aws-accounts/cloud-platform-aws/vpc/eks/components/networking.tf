
##########
# Calico 
##########

locals {
  calico_crds = {
    tigera_apiserver = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/charts/tigera-operator/crds/operator.tigera.io_apiservers_crd.yaml"
    tigera_imagesets = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/charts/tigera-operator/crds/operator.tigera.io_imagesets_crd.yaml"
    tigera_installations = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/charts/tigera-operator/crds/operator.tigera.io_imagesets_crd.yaml"
    tigera_statues = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/charts/tigera-operator/crds/operator.tigera.io_tigerastatuses_crd.yaml"
    caliconodestatues = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_caliconodestatuses.yaml"
    bgpconfigurations     = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_bgpconfigurations.yaml"
    bgppeers              = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_bgppeers.yaml"
    blockaffinities       = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_blockaffinities.yaml"
    clusterinformations   = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_clusterinformations.yaml"
    felixconfigurations   = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_felixconfigurations.yaml"
    globalnetworkpolicies = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_globalnetworkpolicies.yaml"
    globalnetworksets     = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_globalnetworksets.yaml"
    hostendpoints         = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_hostendpoints.yaml"
    ipamblocks            = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_ipamblocks.yaml"
    ipamconfigs = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_ipamconfigs.yaml"
    ipamhandles = "https://raw.githubusercontent.com/projectcalico/calico/master/libcalico-go/config/crd/crd.projectcalico.org_ipamhandles.yaml"
    ippools               = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_ippools.yaml"
    ipreservations = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_ipreservations.yaml"
    kubecontrollersconfigurations = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_kubecontrollersconfigurations.yaml"
    networkpolicies       = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_networkpolicies.yaml"
    networksets           = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_networksets.yaml"
  }
}

data "http" "calico_crds" {
  for_each = local.calico_crds
  url      = each.value
}

resource "kubectl_manifest" "calico_crds" {
  server_side_apply = true
  for_each          = data.http.calico_crds
  yaml_body         = each.value["body"]
}

data "kubectl_file_documents" "calico_global_policies" {
  content = file("${path.module}/resources/calico-global-policies.yaml")
}

resource "kubectl_manifest" "calico_global_policies" {
  count     = length(data.kubectl_file_documents.calico_global_policies.documents)
  yaml_body = element(data.kubectl_file_documents.calico_global_policies.documents, count.index)


  depends_on = [helm_release.tigera_calico]
}

resource "kubernetes_namespace" "calico_system" {
  metadata {
    name = "calico-system"

    labels = {
      "component" = "calico"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"                = "tigera-operator-calico"
      "cloud-platform.justice.gov.uk/business-unit"              = "Platforms"
      "cloud-platform.justice.gov.uk/owner"                      = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "cloud-platform.justice.gov.uk/can-tolerate-master-taints" = "true"
      "cloud-platform-out-of-hours-alert"                        = "true"
    }
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "kubernetes_namespace" "calico_apiserver" {
  metadata {
    name = "calico-apiserver"

    labels = {
      "component" = "calico"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"                = "tigera-operator-calico"
      "cloud-platform.justice.gov.uk/business-unit"              = "Platforms"
      "cloud-platform.justice.gov.uk/owner"                      = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "cloud-platform.justice.gov.uk/can-tolerate-master-taints" = "true"
      "cloud-platform-out-of-hours-alert"                        = "true"
    }
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "kubernetes_namespace" "tigera_operator" {
  metadata {
    name = "tigera-operator"

    labels = {
      "component" = "calico"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"                = "tigera-operator-calico"
      "cloud-platform.justice.gov.uk/business-unit"              = "Platforms"
      "cloud-platform.justice.gov.uk/owner"                      = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "cloud-platform.justice.gov.uk/can-tolerate-master-taints" = "true"
      "cloud-platform-out-of-hours-alert"                        = "true"
    }
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

# Calico Helm release cannot be deleted because of finalizers and installation issues, this can be removed once the below issue is fixed.
# https://github.com/projectcalico/calico/issues/6629
resource "null_resource" "remove_installation" {
  depends_on = [helm_release.tigera_calico]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl delete installations.operator.tigera.io default
    EOT
  }

  triggers = {
    helm_tigera = helm_release.tigera_calico.status
  }
}


resource "helm_release" "tigera_calico" {
  name       = "tigera-calico-release"
  chart      = "tigera-operator"
  repository = "https://projectcalico.docs.tigera.io/charts"
  namespace  = "tigera-operator"
  timeout    = 300
  version    = "3.25.0"
  skip_crds = true


  depends_on = [
    kubernetes_namespace.tigera_operator,
    kubernetes_namespace.calico_system,
    kubernetes_namespace.calico_apiserver,
    kubectl_manifest.calico_crds
    ]

  set {
    name  = "installation.kubernetesProvider"
    value = "EKS"
  }
}
