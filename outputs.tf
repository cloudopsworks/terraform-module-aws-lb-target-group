##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

output "target_groups" {
  description = "Map of created target groups keyed by target group name, with name, ARN, ARN suffix, port, protocol, target type and attached load balancer ARNs."
  value = {
    for tg in aws_lb_target_group.this : tg.name => {
      name               = tg.name
      arn                = tg.arn
      arn_suffix         = tg.arn_suffix
      port               = tg.port
      protocol           = tg.protocol
      target_type        = tg.target_type
      load_balancer_arns = tg.load_balancer_arns
    }
  }
}

output "target_group_arns" {
  description = "Map of target group ARNs keyed by the target_groups input key, for referencing target groups from other modules."
  value       = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}

output "target_group_attachments" {
  description = "Map of target group attachments keyed by attachment ID, with the target group ARN, target ID, availability zone and port."
  value = {
    for attachment in aws_lb_target_group_attachment.this : attachment.id => {
      id                = attachment.id
      target_group_arn  = attachment.target_group_arn
      target_id         = attachment.target_id
      availability_zone = attachment.availability_zone
      port              = attachment.port
    }
  }
}

output "autoscaling_traffic_source_attachments" {
  description = "Map of Auto Scaling Group traffic source attachments keyed by attachment ID, with the Auto Scaling Group name."
  value = {
    for attachment in aws_autoscaling_traffic_source_attachment.this : attachment.id => {
      id                     = attachment.id
      autoscaling_group_name = attachment.autoscaling_group_name
    }
  }
}

output "listener_rules" {
  description = "Map of created listener rules keyed by rule ID, with the rule ARN, listener ARN, priority, actions and conditions."
  value = {
    for rule in aws_lb_listener_rule.lb_rule : rule.id => {
      id           = rule.id
      arn          = rule.arn
      listener_arn = rule.listener_arn
      priority     = rule.priority
      actions      = rule.action
      conditions   = rule.condition
    }
  }
}

output "listener_rule_arns" {
  description = "Map of listener rule ARNs keyed by the listener_rules input key, for referencing rules from other modules."
  value       = { for k, rule in aws_lb_listener_rule.lb_rule : k => rule.arn }
}
