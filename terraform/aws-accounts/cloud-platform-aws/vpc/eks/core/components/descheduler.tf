module "descheduler" {
  count  = lookup(local.manager_workspace, terraform.workspace, false) ? 0 : 1
  source = "github.com/ministryofjustice/cloud-platform-terraform-descheduler?ref=0.9.2"

  depends_on = [
    module.monitoring,
    module.label_pods_controller
  ]
}
