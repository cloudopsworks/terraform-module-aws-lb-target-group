##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
locals {
  # all names are prefixed with tg-
  short_name = var.name_prefix != "" ? format("tg-%s-%s", var.name_prefix, local.system_name_short) : format("tg-%s", local.system_name_short)
  long_name  = var.name_prefix != "" ? format("tg-%s-%s", var.name_prefix, local.system_name) : format("tg-%s", local.system_name)
}

# Target group definition
resource "aws_lb_target_group" "this" {
  name                               = local.short_name
  target_type                        = var.target_type
  port                               = var.port
  preserve_client_ip                 = var.preserve_client_ip
  protocol                           = var.protocol
  protocol_version                   = var.protocol_version
  proxy_protocol_v2                  = var.proxy_protocol_v2
  vpc_id                             = var.vpc_id != "" ? var.vpc_id : null
  connection_termination             = var.connection_termination
  deregistration_delay               = var.deregistration_delay
  slow_start                         = var.slow_start
  ip_address_type                    = var.ip_address_type != "" ? var.ip_address_type : null
  load_balancing_algorithm_type      = var.load_balancing_algorithm_type
  load_balancing_anomaly_mitigation  = var.load_balancing_anomaly_mitigation
  load_balancing_cross_zone_enabled  = var.load_balancing_cross_zone_enabled
  lambda_multi_value_headers_enabled = var.lambda_multi_value_headers_enabled
  dynamic "stickiness" {
    for_each = var.stickness
    content {
      enabled         = try(stickiness.value.enabled, false)
      type            = try(stickiness.value.type, "lb_cookie")
      cookie_duration = try(stickiness.value.cookie_duration, 86400)
      cookie_name     = try(stickiness.value.cookie_name, null)
    }
  }
  dynamic "health_check" {
    for_each = var.health_check
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
    for_each = var.target_failover
    content {
      on_deregistration = try(target_failover.value.on_deregistration, "no_rebalance")
      on_unhealthy      = try(target_failover.value.on_failure, "no_rebalance")
    }
  }
  dynamic "target_health_state" {
    for_each = var.target_health_state
    content {
      enable_unhealthy_connection_termination = try(target_health_state.value.enable_unhealthy_connection_termination, true)
    }
  }
  tags = local.all_tags
}
