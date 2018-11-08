data "template_file" "backends_weights" {
  template = "${file("${path.module}/weights.tpl")}"
  count    = "${length(var.backends_weights)}"

  vars {
    name   = "${element(keys(var.backends_weights[count.index]), 0)}"
    weight = "${element(values(var.backends_weights[count.index]), 0)}"
  }
}

data "template_file" "haproxy_userdata" {
  template = "${file("${path.module}/userdata.sh.tpl")}"

  vars {
    serverlist = "${join("\n", data.template_file.backends_weights.*.rendered)}"
  }
}

resource "tls_private_key" "haproxy_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "haproxy_key_pair" {
  key_name   = "haproxy-${var.haproxy_host}.${var.haproxy_domain}"
  public_key = "${tls_private_key.haproxy_private_key.public_key_openssh}"
}

resource "aws_instance" "haproxy_node" {
  count = "${var.haproxy_cluster_size * var.aws_az_count}"

  instance_type = "${var.aws_haproxy_instance_type}"

  ami = "${lookup(var.haproxy_aws_amis, var.aws_region)}"

  vpc_security_group_ids = ["${aws_security_group.instance_sg1.id}", "${aws_security_group.instance_sg2.id}"]
  subnet_id              = "${element(aws_subnet.haproxy_subnet.*.id, count.index / var.haproxy_cluster_size)}"

  user_data = "${data.template_file.haproxy_userdata.rendered}"
  key_name  = "${aws_key_pair.haproxy_key_pair.key_name}"

  tags {
    Name = "haproxy-${var.haproxy_host}.${var.haproxy_domain}"
  }
}