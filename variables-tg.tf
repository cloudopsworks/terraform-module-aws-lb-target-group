##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# lb_arn: "" # (Optional) ARN of the load balancer. Required when listener_rules use
#            # listener_port to look up a listener. When deploying with alb_enabled=true
#            # in boilerplate.yml, this is automatically wired from the ALB dependency.
#            # Default: ""
variable "lb_arn" {
  description = "The ARN of the load balancer. Required when listener_rules reference a listener by port."
  type        = string
  default     = ""
}

# target_groups: {} # (Optional) Map of target group definitions to create.
#                   # Keys become the base name prefix for each target group resource.
#                   # Supports target types: instance | ip | lambda | asg
#                   # See inputs.yaml comments for the full attribute reference.
#                   # Default: {}
variable "target_groups" {
  description = "Map of target group definitions to create. Keys become the base name prefix for each target group."
  type        = any
  default     = {}
}

# listener_rules: {} # (Optional) Map of listener rule definitions to create.
#                    # Rules can match on host header, path pattern, HTTP header,
#                    # query string, or source IP, and support forward, redirect,
#                    # fixed-response, OIDC, and Cognito authentication actions.
#                    # Default: {}
variable "listener_rules" {
  description = "Map of listener rule definitions to create on the load balancer."
  type        = any
  default     = {}
}
