variable "region" {
  type        = string
  description = "Region in which to create Access Tier"
}

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

variable "ami_id" {
  type        = string
  description = "ID of a custom AMI to use when creating Access Tier instances (leave blank to use default)"
  default     = ""
}

variable "default_ami_name" {
  type        = string
  description = "If no AMI ID is supplied, use the most recent AMI from this project"
  default     = "amzn2-ami-hvm-2.0.*-x86_64-ebs"
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
