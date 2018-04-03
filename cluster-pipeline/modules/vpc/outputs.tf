// file: modules/vpc/outputs.tf

output "id"                 { value = "${aws_vpc.main.id}" }
output "cidr_block"         { value = "${aws_vpc.main.cidr_block}" }
output "external_subets"    { value = "${aws_subnet.external.*}" }
output "availability_zones" { value = "${var.availability_zones}" }