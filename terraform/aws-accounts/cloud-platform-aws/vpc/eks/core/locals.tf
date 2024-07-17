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

  hostzones = {
    default = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}",
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.integrationtest.zone_id}"
    ]
    manager = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}",
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.cloud_platform.zone_id}",
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.integrationtest.zone_id}"
    ]
    live   = ["arn:aws:route53:::hostedzone/*"]
    live-2 = ["arn:aws:route53:::hostedzone/*"]
  }
}
