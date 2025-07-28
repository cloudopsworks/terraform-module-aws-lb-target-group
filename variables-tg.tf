##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

variable "lb_arn" {
  description = "The load balancer ARN"
  type        = string
  default     = ""
}

variable "target_groups" {
  description = "The target groups to create"
  type        = any
  default     = {}
}

variable "listener_rules" {
  description = "The listener rules to create"
  type        = any
  default     = {}

}
