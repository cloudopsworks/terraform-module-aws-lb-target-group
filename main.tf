##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

# Target group definition
resource "aws_lb_target_group" "this" {
  for_each                           = var.target_groups
  name                               = format("%s-%s", each.key, local.system_name_short)
  target_type                        = try(each.value.target_type, "instance")
  port                               = try(each.value.port, 80)
  preserve_client_ip                 = try(each.value.preserve_client_ip, null)
  protocol                           = try(each.value.protocol, "HTTP")
  protocol_version                   = try(each.value.protocol_version, "HTTP1")
  proxy_protocol_v2                  = try(each.value.proxy_protocol_v2, false)
  vpc_id                             = try(each.value.vpc_id, null)
  connection_termination             = try(each.value.connection_termination, false)
  deregistration_delay               = try(each.value.deregistration_delay, 300)
  slow_start                         = try(each.value.slow_start, 0)
  ip_address_type                    = try(each.value.ip_address_type, "ipv4")
  load_balancing_algorithm_type      = try(each.value.load_balancing_algorithm_type, "round_robin")
  load_balancing_anomaly_mitigation  = try(each.value.load_balancing_anomaly_mitigation, null)
  load_balancing_cross_zone_enabled  = try(each.value.load_balancing_cross_zone_enabled, false)
  lambda_multi_value_headers_enabled = try(each.value.lambda_multi_value_headers_enabled, null)
  dynamic "stickiness" {
    for_each = try(each.value.stickness, [])
    content {
      enabled         = try(stickiness.value.enabled, false)
      type            = try(stickiness.value.type, "lb_cookie")
      cookie_duration = try(stickiness.value.cookie_duration, 86400)
      cookie_name     = try(stickiness.value.cookie_name, null)
    }
  }
  dynamic "health_check" {
    for_each = try(each.value.health_check, [])
    content {
      enabled             = try(health_check.value.enabled, false)
      healthy_threshold   = try(health_check.value.healthy_threshold, 3)
      interval            = try(health_check.value.interval, 30)
      matcher             = try(health_check.value.matcher, null)
      path                = try(health_check.value.path, "/")
      port                = try(health_check.value.port, "traffic-port")
      protocol            = try(health_check.value.protocol, null)
      timeout             = try(health_check.value.timeout, 30)
      unhealthy_threshold = try(health_check.value.unhealthy_threshold, 3)
    }
  }
  dynamic "target_failover" {
    for_each = try(each.value.target_failover, [])
    content {
      on_deregistration = try(target_failover.value.on_deregistration, "no_rebalance")
      on_unhealthy      = try(target_failover.value.on_failure, "no_rebalance")
    }
  }
  dynamic "target_health_state" {
    for_each = try(each.value.target_health_state, [])
    content {
      enable_unhealthy_connection_termination = try(target_health_state.value.enable_unhealthy_connection_termination, true)
    }
  }
  tags = local.all_tags
}


resource "aws_lb_target_group_attachment" "this" {
  for_each = merge([
    for k, v in var.target_groups : {
      for target_id in try(v.target_ids, []) : "${k}-${target_id}" => {
        target_group_arn = aws_lb_target_group.this[k].arn
        target_id        = target_id
      }
    }
  ]...)
  target_group_arn = each.value.target_group_arn
  target_id        = each.value.target_id
}