##########
# Locals #
##########

locals {
  # prod_2_workspace is a temporary workspace to include live-2 on the modules that are tested.
  # Once all the modules are tested, this list will replace the prod_workspace
  prod_2_workspace = {
    manager = true
    live    = true
    live-2  = true
    default = false
  }
}
