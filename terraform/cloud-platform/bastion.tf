
###########
# BASTION #
###########

module "bastion" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-bastion?ref=0.0.2"

  vpc_id       = module.cluster_vpc.vpc_id
  key_name     = aws_key_pair.cluster.key_name
  route53_zone = module.cluster_dns.cluster_dns_zone_name
}