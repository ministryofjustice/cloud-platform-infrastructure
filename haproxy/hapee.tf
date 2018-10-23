resource "aws_elb" "hapee_elb" {
  name = "hapee-test-elb"

  subnets = ["${aws_subnet.tf_test_subnet.id}"]

  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/haproxy_status"
    interval            = 30
  }

  instances                   = ["${aws_instance.hapee_node.*.id}"]
  cross_zone_load_balancing   = false
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "hapee_elb"
  }
}

resource "aws_proxy_protocol_policy" "proxy_http" {
  load_balancer  = "${aws_elb.hapee_elb.name}"
  instance_ports = ["80"]
}

data "template_file" "hapee-userdata" {
  template = "${file("hapee-userdata.sh.tpl")}"

  vars {}
}

resource "aws_instance" "hapee_node" {
  count = "${var.hapee_cluster_size}"

  instance_type = "${var.aws_hapee_instance_type}"

  ami = "${lookup(var.hapee_aws_amis, var.aws_region)}"

  vpc_security_group_ids = ["${aws_security_group.instance_sg1.id}", "${aws_security_group.instance_sg2.id}"]
  subnet_id              = "${aws_subnet.tf_test_subnet.id}"
  user_data              = "${data.template_file.hapee-userdata.rendered}"
  key_name               = "${aws_key_pair.hapee_key_pair.key_name}"

  tags {
    Name = "hapee_node_${count.index}"
  }
}

resource "tls_private_key" "hapee_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "hapee_key_pair" {
  key_name   = "hapee"
  public_key = "${tls_private_key.hapee_private_key.public_key_openssh}"
}
