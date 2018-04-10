output "network_id"                     { value = "${module.cluster_vpc.vpc_id}" }
output "network_cidr_block"             { value = "${module.cluster_vpc.vpc_cidr_block}" }
#output "network_availability_zones_csv" { value = "${join(",", module.cluster_vpc.azs)}" }
