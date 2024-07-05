##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "name_prefix" {
  description = "The prefix to use for the name of the load balancer"
  type        = string
  default     = ""
}

variable "target_type" {
  description = "The type of target that you must specify when registering targets with this target group. The possible values are instance (targets are specified by instance ID) or ip (targets are specified by IP address). The default is instance. (instance|ip|"
  type        = string
  default     = "instance"
}

variable "port" {
  description = "The port on which targets receive traffic, unless overridden when registering a specific target. Required if the target type is instance, the default is traffic-port."
  type        = number
  default     = 80
}

variable "protocol" {
  description = "The protocol to use for routing traffic to the targets. The default is HTTP. (TCP|TCP_UDP|HTTP|HTTPS|TLS|GENEVE)"
  type        = string
  default     = "HTTP"
}

variable "protocol_version" {
  description = "The protocol version to use. The possible values are GRPC and HTTP1. The default is HTTP1."
  type        = string
  default     = "HTTP1"
}

variable "preserve_client_ip" {
  description = "Indicates whether client IP preservation is enabled. The default is false."
  type        = bool
  default     = false
}

variable "proxy_protocol_v2" {
  description = "Indicates whether Proxy Protocol version 2 is enabled. The default is false."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "The identifier of the VPC in which to create the target group."
  type        = string
  default     = ""
}

variable "connection_termination" {
  description = "The connection termination settings."
  type        = bool
  default     = false
}

variable "deregistration_delay" {
  description = "The amount of time, in seconds, for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. The default is 300 seconds."
  type        = number
  default     = 300
}

variable "lambda_multi_value_headers_enabled" {
  description = "Indicates whether HTTP/2 and gRPC requests are processed by the Lambda function. The default is false."
  type        = bool
  default     = false
}

variable "slow_start" {
  description = "The time period, in seconds, during which a newly registered target receives a linearly increasing share of the traffic to the target group. After this time period ends, the target receives its full share of the traffic. The range is 30-900 seconds (15 minutes). The default is 0 seconds."
  type        = number
  default     = 0
}

variable "ip_address_type" {
  description = "The IP address type. The possible values are ipv4 and dualstack. The default is ipv4."
  type        = string
  default     = "ipv4"
}

variable "load_balancing_algorithm_type" {
  description = "The load balancing algorithm determines how the load balancer selects targets when routing requests. The value is round_robin or least_outstanding_requests. The default is round_robin."
  type        = string
  default     = "round_robin"
}

variable "load_balancing_anomaly_mitigation" {
  description = "Determines whether to enable target anomaly mitigation. The default is 'off'"
  type        = string
  default     = "off"
}

variable "load_balancing_cross_zone_enabled" {
  description = "Indicates whether cross-zone load balancing is enabled. The default is false."
  type        = bool
  default     = false
}

variable "stickness" {
  description = "The stickiness configuration."
  type        = any
  default     = []
}

variable "health_check" {
  description = "The health check configuration."
  type        = any
  default     = []
}

variable "target_failover" {
  description = "The target failover configuration."
  type        = any
  default     = []
}

variable "target_health_state" {
  description = "The target health state configuration."
  type        = any
  default     = []
}