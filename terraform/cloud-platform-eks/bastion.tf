
###########
# BASTION #
###########

module "bastion" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-bastion?ref=0.0.1"

  vpc_id                   = module.cluster_vpc.vpc_id
  key_name                 = aws_key_pair.cluster.key_name
  cluster_base_domain_name = "${local.cluster_name}.cloud-platform.service.justice.gov.uk"
  bastion_depends_on       = [aws_route53_zone.cluster.zone_id]
}
