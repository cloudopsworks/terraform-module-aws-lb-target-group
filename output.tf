##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

output "target_groups" {
  value = {
    for tg in aws_lb_target_group.this : tg.name => {
      name               = tg.name
      arn                = tg.arn
      port               = tg.port
      protocol           = tg.protocol
      target_type        = tg.target_type
      load_balancer_arns = tg.load_balancer_arns
    }
  }
}

output "target_group_attachments" {
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

output "listener_rules" {
  value = {
    for rule in aws_lb_listener_rule.lb_rule : rule.id => {
      id           = rule.id
      listener_arn = rule.listener_arn
      priority     = rule.priority
      actions      = rule.action
      conditions   = rule.condition
    }
  }
}