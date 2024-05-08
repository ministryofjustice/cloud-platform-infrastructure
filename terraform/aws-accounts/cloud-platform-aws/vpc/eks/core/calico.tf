module "tigera_calico" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-tigera-calico?ref=0.1.7"

  depends_on = [
    kubectl_manifest.calico_crds
  ]
}
