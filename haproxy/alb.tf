resource "aws_lb" "haproxy_alb" {
  name            = "haproxy-alb-${random_id.id.hex}"
  internal        = false
  subnets         = ["${aws_subnet.haproxy_subnet.*.id}"]
  security_groups = ["${aws_security_group.alb.id}"]

  tags {
    Name = "haproxy_alb"
  }
}

resource "aws_lb_target_group" "haproxy_alb_target" {
  name     = "haproxy-alb-tg-${random_id.id.hex}"
  vpc_id   = "${aws_vpc.default.id}"
  protocol = "HTTP"
  port     = 80

  health_check {
    interval            = 30
    path                = "/haproxy_status"
    port                = 8080
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200,202"
  }

  tags {
    Name = "haproxy_alb_tg"
  }
}

resource "aws_lb_listener" "haproxy_alb_listener" {
  load_balancer_arn = "${aws_lb.haproxy_alb.arn}"
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = "${aws_acm_certificate_validation.cert.certificate_arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.haproxy_alb_target.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = "${aws_lb.haproxy_alb.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group_attachment" "haproxy_nodes" {
  count            = "${var.haproxy_cluster_size * var.aws_az_count}"
  target_group_arn = "${aws_lb_target_group.haproxy_alb_target.arn}"
  target_id        = "${element(aws_instance.haproxy_node.*.id, count.index)}"
  port             = 80
}
