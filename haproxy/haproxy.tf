data "template_file" "backends_weights" {
  template = "${file("weights.tpl")}"
  count    = "${length(var.backends_weights)}"

  vars {
    name   = "${element(keys(var.backends_weights[count.index]), 0)}"
    weight = "${element(values(var.backends_weights[count.index]), 0)}"
  }
}

data "template_file" "haproxy_userdata" {
  template = "${file("userdata.sh.tpl")}"

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

resource "aws_launch_template" "haproxy_node" {
  name                                 = "haproxy-${var.haproxy_host}.${var.haproxy_domain}"
  image_id                             = "${lookup(var.haproxy_aws_amis, var.aws_region)}"
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "${var.aws_haproxy_instance_type}"
  key_name                             = "${aws_key_pair.haproxy_key_pair.key_name}"
  user_data                            = "${base64encode(data.template_file.haproxy_userdata.rendered)}"
  vpc_security_group_ids               = ["${aws_security_group.instance_sg1.id}", "${aws_security_group.instance_sg2.id}"]

  tag_specifications {
    resource_type = "instance"

    tags {
      Name = "haproxy-${var.haproxy_host}.${var.haproxy_domain}"
    }
  }
}

data "aws_instances" "workers" {
  instance_tags {
    Name = "haproxy-${var.haproxy_host}.${var.haproxy_domain}"
  }
}

resource "aws_autoscaling_group" "haproxy" {
  name                = "haproxy-${var.haproxy_host}.${var.haproxy_domain}"
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = ["${aws_subnet.haproxy_subnet.*.id}"]
  target_group_arns   = ["${aws_lb_target_group.haproxy_alb_target.arn}"]

  launch_template = {
    id      = "${aws_launch_template.haproxy_node.id}"
    version = "$$Latest"
  }
}

resource "aws_autoscaling_policy" "haproxy" {
  name                   = "haproxy-${var.haproxy_host}.${var.haproxy_domain}"
  autoscaling_group_name = "${aws_autoscaling_group.haproxy.name}"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}
