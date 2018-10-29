resource "local_file" "kops" {
  content  = "${data.template_file.kops.rendered}"
  filename = "../../kops/${terraform.workspace}.yaml"
}

data "template_file" "kops" {
  template = "${file("./templates/kops.yaml.tpl")}"

  vars {
    cluster_domain_name = "${terraform.workspace}"
    hosted_zone_id      = "${module.cluster_dns.cluster_dns_zone_id}"
  }
}