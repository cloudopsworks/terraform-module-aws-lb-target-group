##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

output "target_groups" {
  value = {
    for tg in aws_lb_target_group.this : tg.name => {
      id                 = tg.id
      arn                = tg.arn
      load_balancer_arns = tg.load_balancer_arns
    }
  }
}