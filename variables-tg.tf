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

# target_groups: # (Optional) Map of target group definitions to create. Default: {}
#                # Keys become the base name prefix for each target group resource; the
#                # final name is "<key>-<system_name_short>".
#   <tg_key>:
#     target_type: "instance"    # (Optional) Target type. One of: instance | ip | lambda | alb | asg. Default: instance
#                                #            "asg" is a module-level alias: the target group is created as "instance"
#                                #            and each target_id is attached as an Auto Scaling Group traffic source.
#     port: 8080                 # (Optional) Port on which targets receive traffic. Omit for lambda. Default: null
#     protocol: "HTTP"           # (Optional) One of: GENEVE | HTTP | HTTPS | TCP | TCP_UDP | TLS | UDP. Default: HTTP
#     protocol_version: "HTTP1"  # (Optional) One of: GRPC | HTTP1 | HTTP2. Default: null (provider default HTTP1)
#     preserve_client_ip: true   # (Optional) Whether client IP preservation is enabled (NLB). Default: null
#     proxy_protocol_v2: false   # (Optional) Enable Proxy Protocol v2 (NLB only). Default: false
#     vpc_id: "vpc-0abc123"      # (Optional) VPC identifier. Required for instance, ip, alb and asg target types. Default: null
#     connection_termination: false # (Optional) Terminate connections at the end of the deregistration timeout (NLB). Default: false
#     deregistration_delay: 300     # (Optional) Seconds to wait before changing a target to unused (0-3600). Default: 300
#     slow_start: 0                 # (Optional) Slow start duration in seconds (0, or 30-900). Default: 0
#     ip_address_type: "ipv4"       # (Optional) One of: ipv4 | ipv6. Default: ipv4
#     load_balancing_algorithm_type: "round_robin" # (Optional) One of: round_robin | least_outstanding_requests | weighted_random. Default: round_robin
#     load_balancing_anomaly_mitigation: "off"     # (Optional) One of: on | off. Only valid with weighted_random. Default: null
#     load_balancing_cross_zone_enabled: false     # (Optional) One of: true | false | use_load_balancer_configuration. Default: false
#     lambda_multi_value_headers_enabled: false    # (Optional) Multi-value headers for lambda targets. Default: null
#     target_control_port: 4444     # (Optional) Port used by the load balancer for target control traffic. Default: null
#     stickiness:                   # (Optional) Sticky session configuration. Omit the block to keep provider defaults.
#       enabled: false              # (Optional) Enable sticky sessions. Default: false
#       type: "lb_cookie"           # (Optional) One of: lb_cookie | app_cookie | source_ip | source_ip_dest_ip | source_ip_dest_ip_proto. Default: lb_cookie
#       cookie_duration: 86400      # (Optional) Cookie TTL in seconds (1-604800). Only for lb_cookie/app_cookie. Default: 86400
#       cookie_name: null           # (Optional) Application cookie name. Required when type is app_cookie. Default: null
#     health_check:                 # (Optional) Health check configuration. Omit the block to keep provider defaults.
#       enabled: true               # (Optional) Enable health checks. Must be true for ALB target groups. Default: true
#       healthy_threshold: 3        # (Optional) Consecutive successes before healthy (2-10). Default: null (provider default)
#       interval: 30                # (Optional) Seconds between health checks (5-300). Default: null (provider default 30)
#       matcher: "200-399"          # (Optional) HTTP/gRPC codes considered healthy. Default: null
#       path: "/health"             # (Optional) Destination path for the health check request. Default: null (provider default /)
#       port: "traffic-port"        # (Optional) traffic-port, or a port number. Default: traffic-port
#       protocol: "HTTP"            # (Optional) One of: TCP | HTTP | HTTPS. Default: null (inherits target group protocol)
#       timeout: 5                  # (Optional) Seconds before a health check times out (2-120). Default: null (provider default)
#       unhealthy_threshold: 3      # (Optional) Consecutive failures before unhealthy (2-10). Default: null (provider default)
#     target_failover:              # (Optional) Target failover policy (GENEVE target groups only).
#       on_deregistration: "no_rebalance" # (Optional) One of: rebalance | no_rebalance. Default: no_rebalance
#       on_unhealthy: "no_rebalance"      # (Optional) One of: rebalance | no_rebalance. Default: no_rebalance
#                                         #            "on_failure" is accepted as a deprecated alias.
#     target_health_state:          # (Optional) Target health state settings (TCP/TLS target groups only).
#       enable_unhealthy_connection_termination: true # (Optional) Terminate connections to unhealthy targets. Default: true
#       unhealthy_draining_interval: 300              # (Optional) Seconds an unhealthy target stays draining (0-360000).
#                                                     #            Only valid when termination is disabled. Default: null
#     target_group_health:          # (Optional) Target group health requirements (ALB/NLB).
#       dns_failover:               # (Optional) DNS failover requirements.
#         minimum_healthy_targets_count: "1"      # (Optional) Minimum healthy targets, or "off". Default: null (provider default 1)
#         minimum_healthy_targets_percentage: "off" # (Optional) Percentage 1-100, or "off". Default: null (provider default off)
#       unhealthy_state_routing:    # (Optional) Unhealthy state routing requirements.
#         minimum_healthy_targets_count: 1          # (Optional) Minimum healthy targets (1-max). Default: null (provider default 1)
#         minimum_healthy_targets_percentage: "off" # (Optional) Percentage 1-100, or "off". Default: null (provider default off)
#     targets:                      # (Optional) List of targets to register in this target group. Default: []
#       - target_id: "i-0abc123"    # (Required) Instance ID, IP address, Lambda name/ARN, ALB ARN, or Auto Scaling Group name.
#         availability_zone: null   # (Optional) AZ for ip targets, or "all" for cross-zone registration. Default: null
#         port: 8080                # (Optional) Port override for this target. Default: null
#         quic_server_id: null      # (Optional) QUIC server identifier for UDP/QUIC targets. Default: null
variable "target_groups" {
  description = "Map of target group definitions to create. Keys become the base name prefix for each target group."
  type        = any
  default     = {}
}

# listener_rules: # (Optional) Map of listener rule definitions to create. Default: {}
#   <rule_key>:
#     name: "my-rule"        # (Optional) Value of the Name tag on the rule. Default: "<rule_key>/<system_name>"
#     listener_port: 443     # (Optional) Port used to look up the listener on lb_arn. Mutually exclusive with listener_arn.
#     listener_arn: ""       # (Optional) ARN of the listener. Mutually exclusive with listener_port.
#     priority: 100          # (Optional) Rule evaluation priority (1-50000); lower is evaluated first. Default: 100
#     actions:               # (Required) Ordered list of actions applied when the conditions match.
#       - type: "forward"    # (Required) One of: forward | redirect | fixed-response | authenticate-cognito | authenticate-oidc
#         order: 1           # (Optional) Action evaluation order (1-50000). Default: null (declaration order)
#         tg_ref: "api"      # (Optional) Key into target_groups; resolved to that target group ARN. Default: null
#         target_group_arn: "" # (Optional) Explicit target group ARN when the target group is not created by this module.
#         forward:           # (Optional) Weighted forward configuration for type=forward (up to 5 target groups).
#           target_group:
#             - tg_ref: "api"  # (Optional) Key into target_groups. Mutually exclusive with arn.
#               arn: ""        # (Optional) Explicit target group ARN. Required when tg_ref is not set.
#               weight: 100    # (Optional) Traffic weight (0-999). Default: null (provider default 1)
#           stickiness:
#             enabled: true    # (Optional) Enable target group stickiness for the forward action. Default: false
#             duration: 3600   # (Optional) Stickiness duration in seconds (1-604800). Default: 3600
#         fixed_response:    # (Optional) For type=fixed-response.
#           content_type: "text/plain" # (Required) One of: text/plain | text/css | text/html | application/javascript | application/json
#           message_body: "Not Found"  # (Optional) Response body. Default: null
#           status_code: "404"         # (Optional) HTTP response code (2XX, 4XX, 5XX). Default: null (provider default 200)
#         redirect:          # (Optional) For type=redirect. Supports the tokens #{host}, #{path}, #{port}, #{protocol}, #{query}.
#           host: "#{host}"        # (Optional) Redirect hostname. Default: #{host}
#           path: "/#{path}"       # (Optional) Redirect path. Default: /#{path}
#           port: "#{port}"        # (Optional) Redirect port. Default: #{port}
#           protocol: "#{protocol}" # (Optional) One of: HTTP | HTTPS | #{protocol}. Default: #{protocol}
#           query: "#{query}"      # (Optional) Redirect query string. Default: #{query}
#           status_code: "HTTP_302" # (Optional) One of: HTTP_301 | HTTP_302. Default: HTTP_302
#         authenticate_oidc: # (Optional) For type=authenticate-oidc.
#           authorization_endpoint: "" # (Required) OIDC authorization endpoint URL.
#           token_endpoint: ""         # (Required) OIDC token endpoint URL.
#           user_info_endpoint: ""     # (Required) OIDC user info endpoint URL.
#           issuer: ""                 # (Required) OIDC issuer identifier.
#           client_id: ""              # (Required) OAuth 2.0 client identifier.
#           client_secret: ""          # (Required) OAuth 2.0 client secret.
#           scope: "openid"            # (Optional) Space-separated OIDC scopes. Default: null (provider default openid)
#           on_unauthenticated_request: "authenticate" # (Optional) One of: deny | allow | authenticate. Default: authenticate
#           session_cookie_name: "AWSELBAuthSessionCookie" # (Optional) Session cookie name. Default: provider default
#           session_timeout: 604800    # (Optional) Session timeout in seconds. Default: null (provider default 604800)
#           authentication_request_extra_params: {} # (Optional) Extra query parameters for the authorization endpoint. Default: null
#         authenticate_cognito: # (Optional) For type=authenticate-cognito.
#           user_pool_arn: ""       # (Required) Cognito user pool ARN.
#           user_pool_client_id: "" # (Required) Cognito user pool client identifier.
#           user_pool_domain: ""    # (Required) Cognito user pool domain prefix or full domain.
#           scope: "openid"         # (Optional) Space-separated OIDC scopes. Default: null (provider default openid)
#           on_unauthenticated_request: "authenticate" # (Optional) One of: deny | allow | authenticate. Default: authenticate
#           session_cookie_name: "AWSELBAuthSessionCookie" # (Optional) Session cookie name. Default: provider default
#           session_timeout: 604800 # (Optional) Session timeout in seconds. Default: null (provider default 604800)
#           authentication_request_extra_params: {} # (Optional) Extra query parameters for the authorization endpoint. Default: null
#         jwt_validation:    # (Optional) Native JWT validation performed by the load balancer.
#           issuer: "https://issuer.example.com"                    # (Required) Expected JWT issuer.
#           jwks_endpoint: "https://issuer.example.com/.well-known/jwks.json" # (Required) JWKS endpoint URL.
#           additional_claims:   # (Optional) Up to 10 additional claims that must match. Default: []
#             - name: "role"     # (Required) Claim name.
#               format: "single-string" # (Required) One of: single-string | string-array | space-separated-values
#               values: ["admin"] # (Required) Accepted claim values.
#     conditions:            # (Required) List of conditions; every condition must match for the rule to apply.
#       - host_header:
#           - values: ["app.example.com"]     # (Optional) Host header values (wildcards allowed). Mutually exclusive with regex_values.
#             regex_values: []                # (Optional) Regular expressions matched against the host header. Default: null
#       - path_pattern:
#           - values: ["/api/*"]              # (Optional) Path patterns (wildcards allowed). Mutually exclusive with regex_values.
#             regex_values: []                # (Optional) Regular expressions matched against the path. Default: null
#       - http_header:
#           - http_header_name: "X-Custom"    # (Required) HTTP header name.
#             values: ["abc"]                 # (Optional) Header values (wildcards allowed). Mutually exclusive with regex_values.
#             regex_values: []                # (Optional) Regular expressions matched against the header value. Default: null
#       - http_request_method:
#           - values: ["GET", "POST"]         # (Required) HTTP methods to match (uppercase, A-Z, hyphen and underscore).
#       - query_string:
#           - key: "version"                  # (Optional) Query string key. Default: null (matches any key)
#             value: "v2"                     # (Required) Query string value to match.
#       - source_ip:
#           - values: ["10.0.0.0/8"]          # (Required) Source IP CIDR blocks to match.
#             ip_address_type: "ipv4"         # (Optional) One of: ipv4 | ipv6. Default: null (provider default)
#     transforms:            # (Optional) Up to 2 request transforms applied before forwarding. Default: []
#       - type: "url-rewrite"                 # (Required) One of: url-rewrite | host-header-rewrite
#         url_rewrite_config:                 # (Optional) Required when type is url-rewrite.
#           rewrite:
#             regex: "^/api/(.*)$"            # (Required) Regular expression matched against the request path.
#             replace: "/$1"                  # (Required) Replacement path.
#         host_header_rewrite_config:         # (Optional) Required when type is host-header-rewrite.
#           rewrite:
#             regex: "^(.*)\\.example\\.com$" # (Required) Regular expression matched against the host header.
#             replace: "$1.internal"          # (Required) Replacement host header.
variable "listener_rules" {
  description = "Map of listener rule definitions to create on the load balancer."
  type        = any
  default     = {}
}
