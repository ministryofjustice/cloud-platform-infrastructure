output "network_id"                     { value = "${module.cluster_vpc.id}" }
output "network_cidr_block"             { value = "${module.cluster_vpc.cidr}" }
output "network_availability_zones_csv" { value = "${join(",", module.cluster_vpc.azs)}" }
