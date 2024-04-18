locals {
  # Disable alerts to test clusters by default
  enable_alerts = lookup(local.prod_2_workspace, terraform.workspace, false)

  # live_workspace refer to all production workspaces which have users workload in it
  live_workspace = {
    live    = true
    live-2  = true
    default = false
  }
  
  # prod_2_workspace is a temporary workspace to include live-2 on the modules that are tested.
  # Once all the modules are tested, this list will replace the prod_workspace
  prod_2_workspace = {
    manager = true
    live    = true
    live-2  = true
    default = false
  }

  manager_workspace = {
    manager = true
    default = false
  }

}
