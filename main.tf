##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# Target group definition
resource "aws_lb_target_group" "this" {
  for_each                           = var.target_groups
  name                               = format("%s-%s", each.key, local.system_name_short)
  target_type                        = try(each.value.target_type, "instance") == "asg" ? "instance" : each.value.target_type
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
  target_control_port                = try(each.value.target_control_port, null)
  dynamic "stickiness" {
    for_each = length(try(each.value.stickiness, {})) > 0 ? [each.value.stickiness] : []
    content {
      enabled         = try(stickiness.value.enabled, false)
      type            = try(stickiness.value.type, "lb_cookie")
      cookie_duration = try(stickiness.value.cookie_duration, 86400)
      cookie_name     = try(stickiness.value.cookie_name, null)
    }
  }
  dynamic "health_check" {
    for_each = length(try(each.value.health_check, {})) > 0 ? [each.value.health_check] : []
    content {
      enabled             = try(health_check.value.enabled, true)
      healthy_threshold   = try(health_check.value.healthy_threshold, null)
      interval            = try(health_check.value.interval, null)
      matcher             = try(health_check.value.matcher, null)
      path                = try(health_check.value.path, null)
      port                = try(health_check.value.port, "traffic-port")
      protocol            = try(health_check.value.protocol, null)
      timeout             = try(health_check.value.timeout, null)
      unhealthy_threshold = try(health_check.value.unhealthy_threshold, null)
    }
  }
  dynamic "target_failover" {
    for_each = length(try(each.value.target_failover, {})) > 0 ? [each.value.target_failover] : []
    content {
      on_deregistration = try(target_failover.value.on_deregistration, "no_rebalance")
      # on_failure is kept as a deprecated alias of on_unhealthy for backwards compatibility
      on_unhealthy = try(target_failover.value.on_unhealthy, target_failover.value.on_failure, "no_rebalance")
    }
  }
  dynamic "target_health_state" {
    for_each = length(try(each.value.target_health_state, {})) > 0 ? [each.value.target_health_state] : []
    content {
      enable_unhealthy_connection_termination = try(target_health_state.value.enable_unhealthy_connection_termination, true)
      unhealthy_draining_interval             = try(target_health_state.value.unhealthy_draining_interval, null)
    }
  }
  dynamic "target_group_health" {
    for_each = length(try(each.value.target_group_health, {})) > 0 ? [each.value.target_group_health] : []
    content {
      dynamic "dns_failover" {
        for_each = length(try(target_group_health.value.dns_failover, {})) > 0 ? [target_group_health.value.dns_failover] : []
        content {
          minimum_healthy_targets_count      = try(tostring(dns_failover.value.minimum_healthy_targets_count), null)
          minimum_healthy_targets_percentage = try(tostring(dns_failover.value.minimum_healthy_targets_percentage), null)
        }
      }
      dynamic "unhealthy_state_routing" {
        for_each = length(try(target_group_health.value.unhealthy_state_routing, {})) > 0 ? [target_group_health.value.unhealthy_state_routing] : []
        content {
          minimum_healthy_targets_count      = try(unhealthy_state_routing.value.minimum_healthy_targets_count, null)
          minimum_healthy_targets_percentage = try(tostring(unhealthy_state_routing.value.minimum_healthy_targets_percentage), null)
        }
      }
    }
  }
  lifecycle {
    # this will work well only if rule when recreated has diffent name
    create_before_destroy = true
  }
  tags = local.all_tags
}

resource "aws_autoscaling_traffic_source_attachment" "this" {
  for_each = merge([
    for k, v in var.target_groups : {
      for target in try(v.targets, []) : "${k}-${target.target_id}" => {
        target_group_arn = aws_lb_target_group.this[k].arn
        target_id        = target.target_id
      } if try(v.target_type, "") == "asg"
    }
  ]...)
  autoscaling_group_name = data.aws_autoscaling_group.asg[each.key].name
  traffic_source {
    identifier = each.value.target_group_arn
    type       = "elbv2"
  }
}

# Target group attachment - with target IDs
resource "aws_lb_target_group_attachment" "this" {
  for_each = merge([
    for k, v in var.target_groups : {
      for target in try(v.targets, []) : "${k}-${target.target_id}" => {
        target_group_arn  = aws_lb_target_group.this[k].arn
        target_type       = aws_lb_target_group.this[k].target_type
        target_id         = target.target_id
        availability_zone = try(target.availability_zone, null)
        port              = try(target.port, null)
        quic_server_id    = try(target.quic_server_id, null)
      } if try(v.target_type, "") != "asg"
    }
  ]...)
  target_group_arn = each.value.target_group_arn
  target_id = each.value.target_type == "lambda" ? (
    startswith(each.value.target_id, "arn:aws:lambda") ? each.value.target_id : data.aws_lambda_function.lambda[each.key].arn
  ) : each.value.target_id
  availability_zone = each.value.availability_zone
  port              = each.value.port
  quic_server_id    = each.value.quic_server_id
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
      order            = try(action.value.order, null)
      target_group_arn = try(action.value.tg_ref, "") != "" ? aws_lb_target_group.this[action.value.tg_ref].arn : try(action.value.target_group_arn, null)
      dynamic "authenticate_cognito" {
        for_each = length(try(action.value.authenticate_cognito, {})) > 0 ? [action.value.authenticate_cognito] : []
        content {
          authentication_request_extra_params = try(authenticate_cognito.value.authentication_request_extra_params, null)
          on_unauthenticated_request          = try(authenticate_cognito.value.on_unauthenticated_request, null)
          scope                               = try(authenticate_cognito.value.scope, null)
          session_cookie_name                 = try(authenticate_cognito.value.session_cookie_name, null)
          session_timeout                     = try(authenticate_cognito.value.session_timeout, null)
          user_pool_arn                       = authenticate_cognito.value.user_pool_arn
          user_pool_client_id                 = authenticate_cognito.value.user_pool_client_id
          user_pool_domain                    = authenticate_cognito.value.user_pool_domain
        }

      }
      dynamic "authenticate_oidc" {
        for_each = length(try(action.value.authenticate_oidc, {})) > 0 ? [action.value.authenticate_oidc] : []
        content {
          authentication_request_extra_params = try(authenticate_oidc.value.authentication_request_extra_params, null)
          authorization_endpoint              = authenticate_oidc.value.authorization_endpoint
          client_id                           = authenticate_oidc.value.client_id
          client_secret                       = authenticate_oidc.value.client_secret
          issuer                              = authenticate_oidc.value.issuer
          on_unauthenticated_request          = try(authenticate_oidc.value.on_unauthenticated_request, null)
          scope                               = try(authenticate_oidc.value.scope, null)
          session_cookie_name                 = try(authenticate_oidc.value.session_cookie_name, null)
          session_timeout                     = try(authenticate_oidc.value.session_timeout, null)
          token_endpoint                      = authenticate_oidc.value.token_endpoint
          user_info_endpoint                  = authenticate_oidc.value.user_info_endpoint
        }
      }
      dynamic "fixed_response" {
        for_each = length(try(action.value.fixed_response, {})) > 0 ? [action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = try(fixed_response.value.message_body, null)
          status_code  = try(fixed_response.value.status_code, null)
        }
      }
      dynamic "forward" {
        for_each = length(try(action.value.forward, {})) > 0 ? [action.value.forward] : []
        content {
          dynamic "target_group" {
            for_each = try(forward.value.target_group, [])
            content {
              arn    = try(target_group.value.tg_ref, "") != "" ? aws_lb_target_group.this[target_group.value.tg_ref].arn : target_group.value.arn
              weight = try(target_group.value.weight, null)
            }
          }
          dynamic "stickiness" {
            for_each = length(try(forward.value.stickiness, {})) > 0 ? [forward.value.stickiness] : []
            content {
              enabled  = try(stickiness.value.enabled, false)
              duration = try(stickiness.value.duration, 3600)
            }
          }
        }
      }
      dynamic "jwt_validation" {
        for_each = length(try(action.value.jwt_validation, {})) > 0 ? [action.value.jwt_validation] : []
        content {
          issuer        = jwt_validation.value.issuer
          jwks_endpoint = jwt_validation.value.jwks_endpoint
          dynamic "additional_claim" {
            for_each = try(jwt_validation.value.additional_claims, [])
            content {
              format = additional_claim.value.format
              name   = additional_claim.value.name
              values = additional_claim.value.values
            }
          }
        }
      }
      dynamic "redirect" {
        for_each = length(try(action.value.redirect, {})) > 0 ? [action.value.redirect] : []
        content {
          host        = try(redirect.value.host, "#{host}")
          path        = try(redirect.value.path, "/#{path}")
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
          values       = try(host_header.value.values, null)
          regex_values = try(host_header.value.regex_values, null)
        }
      }
      dynamic "http_header" {
        for_each = try(condition.value.http_header, [])
        content {
          http_header_name = http_header.value.http_header_name
          values           = try(http_header.value.values, null)
          regex_values     = try(http_header.value.regex_values, null)
        }
      }
      dynamic "http_request_method" {
        for_each = try(condition.value.http_request_method, [])
        content {
          values = http_request_method.value.values
        }
      }
      dynamic "path_pattern" {
        for_each = try(condition.value.path_pattern, [])
        content {
          values       = try(path_pattern.value.values, null)
          regex_values = try(path_pattern.value.regex_values, null)
        }
      }
      dynamic "query_string" {
        # query_strings is kept as a deprecated alias for backwards compatibility
        for_each = try(condition.value.query_string, condition.value.query_strings, [])
        content {
          key   = try(query_string.value.key, null)
          value = try(query_string.value.value, query_string.value.values)
        }
      }
      dynamic "source_ip" {
        for_each = try(condition.value.source_ip, [])
        content {
          values          = source_ip.value.values
          ip_address_type = try(source_ip.value.ip_address_type, null)
        }
      }
    }
  }
  dynamic "transform" {
    for_each = try(each.value.transforms, [])
    content {
      type = transform.value.type
      dynamic "host_header_rewrite_config" {
        for_each = length(try(transform.value.host_header_rewrite_config, {})) > 0 ? [transform.value.host_header_rewrite_config] : []
        content {
          dynamic "rewrite" {
            for_each = length(try(host_header_rewrite_config.value.rewrite, {})) > 0 ? [host_header_rewrite_config.value.rewrite] : []
            content {
              regex   = rewrite.value.regex
              replace = rewrite.value.replace
            }
          }
        }
      }
      dynamic "url_rewrite_config" {
        for_each = length(try(transform.value.url_rewrite_config, {})) > 0 ? [transform.value.url_rewrite_config] : []
        content {
          dynamic "rewrite" {
            for_each = length(try(url_rewrite_config.value.rewrite, {})) > 0 ? [url_rewrite_config.value.rewrite] : []
            content {
              regex   = rewrite.value.regex
              replace = rewrite.value.replace
            }
          }
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
        target_id = target.target_id
      } if !startswith(target.target_id, "arn:aws:lambda")
    } if try(v.target_type, "instance") == "lambda"
  ]...)
  function_name = each.value.target_id
}

data "aws_autoscaling_group" "asg" {
  for_each = merge([
    for k, v in var.target_groups : {
      for target in try(v.targets, []) : "${k}-${target.target_id}" => {
        target_id = target.target_id
      } if try(v.target_type, "instance") == "asg"
    }
  ]...)
  name = each.value.target_id
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
  principal           = "elasticloadbalancing.amazonaws.com"
  source_arn          = each.value.target_group_arn
  function_name       = startswith(each.value.target_id, "arn:aws:lambda") ? each.value.target_id : data.aws_lambda_function.lambda[each.key].arn
  statement_id_prefix = "${each.key}-"
}
