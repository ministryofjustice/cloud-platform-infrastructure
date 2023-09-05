
##########
# Calico 
##########

locals {
  calico_crds = {
    tigera_apiserver              = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/charts/tigera-operator/crds/operator.tigera.io_apiservers_crd.yaml"
    tigera_imagesets              = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/charts/tigera-operator/crds/operator.tigera.io_imagesets_crd.yaml"
    tigera_installations          = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/charts/tigera-operator/crds/operator.tigera.io_installations_crd.yaml"
    tigera_statues                = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/charts/tigera-operator/crds/operator.tigera.io_tigerastatuses_crd.yaml"
    caliconodestatues             = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_caliconodestatuses.yaml"
    bgpconfigurations             = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_bgpconfigurations.yaml"
    bgppeers                      = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_bgppeers.yaml"
    blockaffinities               = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_blockaffinities.yaml"
    clusterinformations           = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_clusterinformations.yaml"
    felixconfigurations           = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_felixconfigurations.yaml"
    globalnetworkpolicies         = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_globalnetworkpolicies.yaml"
    globalnetworksets             = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_globalnetworksets.yaml"
    hostendpoints                 = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_hostendpoints.yaml"
    ipamblocks                    = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_ipamblocks.yaml"
    ipamconfigs                   = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_ipamconfigs.yaml"
    ipamhandles                   = "https://raw.githubusercontent.com/projectcalico/calico/master/libcalico-go/config/crd/crd.projectcalico.org_ipamhandles.yaml"
    ippools                       = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_ippools.yaml"
    ipreservations                = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_ipreservations.yaml"
    kubecontrollersconfigurations = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_kubecontrollersconfigurations.yaml"
    networkpolicies               = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_networkpolicies.yaml"
    networksets                   = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/libcalico-go/config/crd/crd.projectcalico.org_networksets.yaml"
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

module "tigera_calico" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-tigera-calico?ref=add-otel-namespace"

  depends_on = [
    kubectl_manifest.calico_crds
  ]
}

