variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which to create the Access Tier"
}

variable "healthcheck_cidrs" {
  type        = list(string)
  description = "CIDR blocks to allow health check connections from (recommended to use the VPC CIDR range)"
  default     = ["0.0.0.0/0"]
}

variable "management_cidrs" {
  type        = list(string)
  description = "CIDR blocks to allow SSH connections from"
  default     = ["0.0.0.0/0"]
}

variable "shield_cidrs" {
  type        = list(string)
  description = "CIDR blocks to allow Shield (Cluster Coordinator) connections to"
  default     = ["0.0.0.0/0"]
}

variable "shield_port" {
  type        = number
  description = "TCP port number to allow Shield (Cluster Coordinator) connections to"
  default     = 0
}

variable "command_center_cidrs" {
  type        = list(string)
  description = "CIDR blocks to allow Command Center connections to"
  default     = ["0.0.0.0/0"]
}

variable "trustprovider_cidrs" {
  type        = list(string)
  description = "CIDR blocks to allow TrustProvider connections to"
  default     = ["0.0.0.0/0"]
}

variable "managed_internal_cidrs" {
  type        = list(string)
  description = "CIDR blocks to allow managed internal services connections to"
  default     = ["0.0.0.0/0"]
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "IDs of the subnets where the load balancer should create endpoints"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "IDs of the subnets where the Access Tier should create instances"
}

variable "package_name" {
  type        = string
  description = "Override to use a specific version of netagent (e.g. `banyan-netagent-1.5.0`)"
  default     = "banyan-netagent"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type to use when creating Access Tier instances"
  default     = "t3.large"
}

variable "site_name" {
  type        = string
  description = "Name to use when registering this Access Tier with the console"
}

variable "cluster_name" {
  type        = string
  description = "Name of an existing Shield cluster to register this Access Tier with"
}

variable "refresh_token" {
  type        = string
  description = "API token generated from the Banyan console"
}

variable "site_domain_names" {
  type        = list(string)
  description = "List of aliases or CNAMEs that will direct traffic to this Access Tier"
  default     = []
}

variable "api_server" {
  type        = string
  description = "URL to the Banyan API server"
  default     = "https://net.banyanops.com/api/v1"
}

variable "ssh_key_name" {
  type        = string
  description = "Name of an SSH key stored in AWS to allow management access"
  default     = ""
}

variable "cross_zone_enabled" {
  type        = bool
  description = "Allow load balancer to distribute traffic to other zones"
  default     = true
}

variable "min_instances" {
  type        = number
  description = "Minimum number of Access Tier instances to keep alive"
  default     = 2
}

variable "custom_user_data" {
  type        = list(string)
  description = "Custom commands to append to the launch configuration initialization script."
  default     = []
}

variable "redirect_http_to_https" {
  type        = bool
  description = "If true, requests to the AccessTier on port 80 will be redirected to port 443"
  default     = true
}

variable "iam_instance_profile" {
  type        = string
  description = "The name attribute of the IAM instance profile to associate with launched instances."
  default     = null
}

variable "tags" {
  type        = map(any)
  description = "Add tags to each resource"
  default     = null
}

variable "security_group_tags" {
  type        = map
  description = "Additional tags to the security_group"
  default     = null
}

variable "autoscaling_group_tags" {
  type        = map
  description = "Additional tags to the autoscaling_group"
  default     = null
}

variable "lb_tags" {
  type        = map
  description = "Additional tags to the lb"
  default     = null
}

variable "target_group_tags" {
  type        = map
  description = "Additional tags to each target_group"
  default     = null
}

variable "host_tags" {
  type        = map(any)
  description = "Additional tags to assign to this AccessTier"
  default     = { "type" : "access_tier" }
}

variable "groups_by_userinfo" {
  type        = bool
  description = "Derive groups information from userinfo endpoint"
  default     = false
}

variable "name_prefix" {
  type        = string
  description = "String to be added in front of all AWS object names"
  default     = "banyan"
}

variable "rate_limiting" {
  type = object({
    enabled              = bool
    max_credits          = number
    interval             = string
    credits_per_interval = number
    enable_by_key        = bool
    key_lifetime         = string
  })
  description = "Rate limiting configuration for access events"
  default = {
    enabled              = true
    max_credits          = 5000
    interval             = "1m"
    credits_per_interval = 5
    enable_by_key        = true
    key_lifetime         = "9m"
  }
}

variable "max_instance_lifetime" {
  type        = number
  default     = null
  description = "The maximum amount of time, in seconds, that an instance can be in service, values must be either equal to 0 or between 604800 and 31536000 seconds"
}

variable "http_endpoint_imds_v2" {
  type        = string
  description = "value for http_endpoint to enable imds v2 for ec2 instance"
  default     = "enabled"
}

variable "http_tokens_imds_v2" {
  type        = string
  description = "value for http_tokens to enable imds v2 for ec2 instance"
  default     = "required"
}

variable "http_hop_limit_imds_v2" {
  type        = number
  description = "value for http_put_response_hop_limit to enable imds v2 for ec2 instance"
  default     = 1
}

variable "datadog_api_key" {
    type = string
    description = "API key for DataDog"
    default = null
}

variable "sticky_sessions" {
    type = bool
    description = "Enable session stickiness for apps that require it"
    default = false
}