resource "aws_elb" "haproxy_elb" {
  name = "haproxy-test-elb"

  subnets = ["${aws_subnet.tf_test_subnet.id}"]

  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 9000
    instance_protocol = "tcp"
    lb_port           = 9000
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/haproxy_status"
    interval            = 30
  }

  instances                   = ["${aws_instance.haproxy_node.*.id}"]
  cross_zone_load_balancing   = false
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "haproxy_elb"
  }
}

resource "aws_proxy_protocol_policy" "proxy_http" {
  load_balancer  = "${aws_elb.haproxy_elb.name}"
  instance_ports = ["80", "8080"]
}

data "template_file" "backends_weights" {
  template = "${file("weights.tpl")}"
  count    = "${length(var.backends_weights)}"
  vars {
    name = "${element(keys(var.backends_weights[count.index]), 0)}"
    weight = "${element(values(var.backends_weights[count.index]), 0)}"
  }
}

data "template_file" "haproxy_userdata" {
  template = "${file("userdata.sh.tpl")}"
  vars {
    serverlist = "${join("\n", data.template_file.backends_weights.*.rendered)}"
  }
}

resource "aws_instance" "haproxy_node" {
  count = "${var.haproxy_cluster_size}"

  instance_type = "${var.aws_haproxy_instance_type}"

  ami = "${lookup(var.haproxy_aws_amis, var.aws_region)}"

  vpc_security_group_ids = ["${aws_security_group.instance_sg1.id}", "${aws_security_group.instance_sg2.id}"]
  subnet_id              = "${aws_subnet.tf_test_subnet.id}"
  user_data              = "${data.template_file.haproxy_userdata.rendered}"
  key_name               = "${aws_key_pair.haproxy_key_pair.key_name}"

  tags {
    Name = "haproxy_node_${count.index}"
  }
}

resource "tls_private_key" "haproxy_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "haproxy_key_pair" {
  key_name   = "haproxy"
  public_key = "${tls_private_key.haproxy_private_key.public_key_openssh}"
}
