##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

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
