resource "local_file" "kops" {
  content  = "${data.template_file.kops.rendered}"
  filename = "../../kops/${terraform.workspace}.yaml"
}

data "template_file" "kops" {
  template = "${file("./templates/kops.yaml.tpl")}"

  vars {
    cluster_domain_name   = "${terraform.workspace}"
    hosted_zone_id        = "${module.cluster_dns.cluster_dns_zone_id}"
    cluster_dns_zone_id   = "${aws_key_pair.cluster.key_name}"
    kops_state_store      = "${data.terraform_remote_state.global.kops_state_store}"
    oidc_issuer_url       = "${local.oidc_issuer_url}"
    oidc_client_id        = "${auth0_client.kubernetes.client_id}"
    network_cidr_block    = "${module.cluster_vpc.vpc_cidr_block}"
    internal_subnets_id_a = "${module.cluster_vpc.private_subnets[0]}"
    internal_subnets_id_b = "${module.cluster_vpc.private_subnets[1]}"
    internal_subnets_id_c = "${module.cluster_vpc.private_subnets[2]}"
    external_subnets_id_a = "${module.cluster_vpc.public_subnets[0]}"
    external_subnets_id_b = "${module.cluster_vpc.public_subnets[1]}"
    external_subnets_id_c = "${module.cluster_vpc.public_subnets[2]}"
  }
}
