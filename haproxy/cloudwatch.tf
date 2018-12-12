module "alb_alarms" {
  source                         = "git::https://github.com/cloudposse/terraform-aws-alb-target-group-cloudwatch-sns-alarms.git?ref=0.5.1"
  name                           = "haproxy-${random_id.id.hex}"
  namespace                      = "cp-haproxy-"
  stage                          = "prod"
  alb_name                       = "${aws_lb.haproxy_alb.name}"
  alb_arn_suffix                 = "${aws_lb.haproxy_alb.arn_suffix}"
  target_group_name              = "${aws_lb_target_group.haproxy_alb_target.name}"
  target_group_arn_suffix        = "${aws_lb_target_group.haproxy_alb_target.arn_suffix}"
  notify_arns                    = "${var.sns_arns}"
  target_3xx_count_threshold     = "-1"
  target_response_time_threshold = "2"
  treat_missing_data             = "ignore"
}
