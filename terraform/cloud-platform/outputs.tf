output "cluster_name"                   { value = "${local.cluster_name}" }
output "cluster_domain_name"            { value = "${local.cluster_base_domain_name}" }
output "network_id"                     { value = "${module.cluster_vpc.vpc_id}" }
output "network_cidr_block"             { value = "${module.cluster_vpc.vpc_cidr_block}" }
