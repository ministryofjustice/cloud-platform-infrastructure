
###########
# BASTION #
###########

module "bastion" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-bastion?ref=1.0.0"

  vpc_id         = data.aws_vpc.selected.id
  public_subnets = tolist(data.aws_subnet_ids.public.ids)
  key_name       = aws_key_pair.cluster.key_name
  route53_zone   = module.cluster_dns.cluster_dns_zone_name
}
