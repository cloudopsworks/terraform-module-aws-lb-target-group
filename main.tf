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
  port                               = try(each.value.port, null)
  preserve_client_ip                 = try(each.value.preserve_client_ip, null)
  protocol                           = try(each.value.protocol, "HTTP")
  protocol_version                   = try(each.value.protocol_version, null)
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
    for_each = length(try(each.value.stickiness, {})) > 0 ? [each.value.stickiness] : []
    content {
      enabled         = try(stickiness.value.enabled, false)
      type            = try(stickiness.value.type, "lb_cookie")
      cookie_duration = try(stickiness.value.cookie_duration, 86400)
      cookie_name     = try(stickiness.value.cookie_name, null)
    }
  }
  health_check {
    enabled             = try(each.value.health_check.enabled, false)
    healthy_threshold   = try(each.value.health_check.healthy_threshold, null)
    interval            = try(each.value.health_check.interval, 30)
    matcher             = try(each.value.health_check.matcher, null)
    path                = try(each.value.health_check.path, "/")
    port                = try(each.value.health_check.port, "traffic-port")
    protocol            = try(each.value.health_check.protocol, null)
    timeout             = try(each.value.health_check.timeout, null)
    unhealthy_threshold = try(each.value.health_check.unhealthy_threshold, null)
  }
  dynamic "target_failover" {
    for_each = length(try(each.value.target_failover, {})) > 0 ? [each.value.target_failover] : []
    content {
      on_deregistration = try(target_failover.value.on_deregistration, "no_rebalance")
      on_unhealthy      = try(target_failover.value.on_failure, "no_rebalance")
    }
  }
  dynamic "target_health_state" {
    for_each = length(try(each.value.target_health_state, {})) > 0 ? [each.value.target_health_state] : []
    content {
      enable_unhealthy_connection_termination = try(target_health_state.value.enable_unhealthy_connection_termination, true)
    }
  }
  lifecycle {
    # this will work well only if rule when recreated has diffent name
    create_before_destroy = true
  }
  tags = local.all_tags
}

# Target group attachment - with target IDs
resource "aws_lb_target_group_attachment" "this" {
  for_each = merge([
    for k, v in var.target_groups : {
      for target in try(v.targets, []) : "${k}-${target.target_id}" => {
        target_group_arn  = aws_lb_target_group.this[k].arn
        target_id         = target.target_id
        availability_zone = try(target.availability_zone, null)
        port              = try(target.port, null)
      }
    }
  ]...)
  target_group_arn  = each.value.target_group_arn
  target_id         = each.value.target_id
  availability_zone = each.value.availability_zone
  port              = each.value.port
}

data "aws_lb_listener" "listener" {
  for_each = {
    for id, rule in var.listener_rules : id => rule
    if try(rule.listener_port, "") != ""
  }
  load_balancer_arn = var.lb_arn
  port              = each.value.listener_port
}

# Listener rule specific for ALB
resource "aws_lb_listener_rule" "lb_rule" {
  depends_on   = [aws_lb_target_group.this]
  for_each     = var.listener_rules
  listener_arn = try(each.value.listener_port, "") != "" ? data.aws_lb_listener.listener[each.key].arn : each.value.listener_arn
  priority     = try(each.value.priority, 100)
  dynamic "action" {
    for_each = try(each.value.actions, [])
    content {
      type             = action.value.type
      target_group_arn = action.value.tg_ref != "" ? aws_lb_target_group.this[action.value.tg_ref].arn : null
      dynamic "authenticate_cognito" {
        for_each = try(action.value.authenticate_cognito, [])
        content {
          authentication_request_extra_params = authenticate_cognito.value.authentication_request_extra_params
          on_unauthenticated_request          = authenticate_cognito.value.on_unauthenticated_request
          scope                               = authenticate_cognito.value.scope
          session_cookie_name                 = authenticate_cognito.value.session_cookie_name
          session_timeout                     = authenticate_cognito.value.session_timeout
          user_pool_arn                       = authenticate_cognito.value.user_pool_arn
          user_pool_client_id                 = authenticate_cognito.value.user_pool_client_id
          user_pool_domain                    = authenticate_cognito.value.user_pool_domain
        }

      }
      dynamic "authenticate_oidc" {
        for_each = try(action.value.authenticate_oidc, [])
        content {
          authentication_request_extra_params = authenticate_oidc.value.authentication_request_extra_params
          authorization_endpoint              = authenticate_oidc.value.authorization_endpoint
          client_id                           = authenticate_oidc.value.client_id
          client_secret                       = authenticate_oidc.value.client_secret
          issuer                              = authenticate_oidc.value.issuer
          on_unauthenticated_request          = authenticate_oidc.value.on_unauthenticated_request
          scope                               = authenticate_oidc.value.scope
          session_cookie_name                 = authenticate_oidc.value.session_cookie_name
          session_timeout                     = authenticate_oidc.value.session_timeout
          token_endpoint                      = authenticate_oidc.value.token_endpoint
          user_info_endpoint                  = authenticate_oidc.value.user_info_endpoint
        }
      }
      dynamic "fixed_response" {
        for_each = try(action.value.fixed_response, [])
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }
      dynamic "forward" {
        for_each = try(action.value.forward, [])
        content {
          dynamic "target_group" {
            for_each = try(forward.value.target_group, [])
            content {
              arn    = target_group.value.arn
              weight = target_group.value.arn
            }
          }
          dynamic "stickiness" {
            for_each = try(forward.value.stickiness, [])
            content {
              enabled  = stickiness.value.enabled
              duration = stickness.value.duration
            }

          }
        }
      }
      dynamic "redirect" {
        for_each = try(action.value.redirect, [])
        content {
          host        = try(redirect.value.host, "#{host}")
          path        = try(redirect.value.path, "#{path}")
          port        = try(redirect.value.port, "#{port}")
          protocol    = try(redirect.value.protocol, "#{protocol}")
          query       = try(redirect.value.query, "#{query}")
          status_code = try(redirect.value.status_code, "HTTP_302")
        }

      }
    }
  }
  dynamic "condition" {
    for_each = try(each.value.conditions, [])
    content {
      dynamic "host_header" {
        for_each = try(condition.value.host_header, [])
        content {
          values = host_header.value.values
        }
      }
      dynamic "http_header" {
        for_each = try(condition.value.http_header, [])
        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }
      dynamic "path_pattern" {
        for_each = try(condition.value.path_pattern, [])
        content {
          values = path_pattern.value.values
        }
      }
      dynamic "query_string" {
        for_each = try(condition.value.query_strings, [])
        content {
          key   = query_string.value.key
          value = query_string.value.values
        }
      }
      dynamic "source_ip" {
        for_each = try(condition.value.source_ip, [])
        content {
          values = source_ip.value.values
        }
      }
    }
  }

  tags = merge(
    {
      Name = try(each.value.name, format("%s/%s", each.key, local.system_name))
    },
    local.all_tags
  )
}

data "aws_lambda_function" "lambda" {
  for_each = merge([
    for k, v in var.target_groups : {
      for target in try(v.targets, []) : "${k}-${target.target_id}" => {
        target_group_arn = aws_lb_target_group.this[k].arn
        target_id        = target.target_id
      } if !startswith(target.target_id, "arn:aws:lambda")
    } if try(v.target_type, "instance") == "lambda"
  ]...)
  function_name = each.value.target_id
}

resource "aws_lambda_permission" "lambda" {
  for_each = merge([
    for k, v in var.target_groups : {
      for target in try(v.targets, []) : "${k}-${target.target_id}" => {
        target_group_arn = aws_lb_target_group.this[k].arn
        target_id        = target.target_id
      }
    } if try(v.target_type, "instance") == "lambda"
  ]...)
  action              = "lambda:InvokeFunction"
  principal           = "apigateway.amazonaws.com"
  source_arn          = each.value.target_group_arn
  function_name       = startswith(each.value.target_id, "arn:aws:lambda") ? each.value.target_id : data.aws_lambda_function.lambda[each.key].arn
  statement_id_prefix = "${each.key}-"
}
