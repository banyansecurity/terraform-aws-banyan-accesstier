Banyan AWS Access Tier Module
=============================

Creates an autoscaling Access Tier for use with [Banyan Security][banyan-security].

This module creates an AWS auto-scaling group (ASG) and a network load balancer (NLB) for a Banyan Access Tier. Only the NLB is exposed to the public internet. The Access Tier and your applications live in private subnets with no ingress from the internet.

## Usage

```hcl
provider "aws" {
  region = "us-east-1"
}

module "aws_accesstier" {
  source                 = "banyansecurity/banyan-accesstier/aws"
  vpc_id                 = "vpc-0e73afd7c24062f0a"
  public_subnet_ids      = ["subnet-09ef9206ca406ffe7", "subnet-0bcb18d59e3ff3cc7"]
  private_subnet_ids     = ["subnet-00e393f22c3f09e16", "subnet-0dfce8195de704b65"]
  cluster_name           = "my-banyan-shield"
  site_name              = "my-banyan-site"
  site_domain_names      = ["*.banyan.mycompany.com"]
  ssh_key_name           = "my-ssh-key"
  refresh_token          = "eyJhbGciOiJSUzI1NiIsIm..."
  redirect_http_to_https = true
}
```

## DataDog metrics integration

We now support sending real-time connection metrics to DataDog. Each instance of the Access Tier will send the following metrics:

| Name | Description |
| :--- | :---------- |
| `banyan.connections` | Total number of incoming connections |
| `banyan.receive_rate` | Received bytes per second |
| `banyan.transmit_rate` | Transmitted bytes per second |
| `banyan.decision_time` | Time required to make authorization decisions, in seconds |
| `banyan.response_time` | Total time required to send response to the user, in seconds |
| `banyan.unauthorized_attemps` | Number of connections rejected due to missing client certificates or policy decisions |

The metrics are tagged with `hostname`, `port`, `service`, and `site_name` so you can filter metrics for a particular Access Tier, host, or service.

Support for other protocols (e.g. statsd, prometheus) and monitoring systems will be added in the future.

To enable DataDog integration, paste your [DataDog API Key][] into the paramter `BanyanDDAPIKey` and re-run the stack. We will automatically install the DataDog agent on your Access Tier, connect it to DataDog, and begin sending metrics to it.

[DataDog API Key]: https://docs.datadoghq.com/account_management/api-app-keys/#add-an-api-key-or-client-token


## Notes

The default value for `management_cidr` leaves SSH open to the world on port 2222. You should probably use the CIDR of your VPC, or a bastion host, instead.

It's probably also a good idea to leave the `refresh_token` out of your code and pass it as a variable instead, so you don't accidentally commit your Banyan API token to your version control system:

```hcl
variable "refresh_token" {
  type = string
}

module "aws_accesstier" {
  source                 = "banyansecurity/banyan-accesstier/aws"
  refresh_token          = var.refresh_token
  ...
}
```

```bash
export TF_VAR_refresh_token="eyJhbGciOiJSUzI1NiIsIm..."
terraform plan
```




## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | ID of a custom AMI to use when creating Access Tier instances (leave blank to use default) | `string` | `""` | no |
| <a name="input_api_server"></a> [api\_server](#input\_api\_server) | URL to the Banyan API server | `string` | `"https://net.banyanops.com/api/v1"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of an existing Shield cluster to register this Access Tier with | `string` | n/a | yes |
| <a name="input_command_center_cidrs"></a> [command\_center\_cidrs](#input\_command\_center\_cidrs) | CIDR blocks to allow Command Center connections to | `list(string)` | `[ "0.0.0.0/0" ]` | no |
| <a name="input_cross_zone_enabled"></a> [cross\_zone\_enabled](#input\_cross\_zone\_enabled) | Allow load balancer to distribute traffic to other zones | `bool` | `true` | no |
| <a name="input_custom_user_data"></a> [custom\_user\_data](#input\_custom\_user\_data) | Custom commands to append to the launch configuration initialization script. | `list(string)` | `[]` | no |
| <a name="input_default_ami_name"></a> [default\_ami\_name](#input\_default\_ami\_name) | If no AMI ID is supplied, use the most recent AMI from this project | `string` | `"amzn2-ami-hvm-2.0.*-x86_64-ebs"` | no |
| <a name="input_groups_by_userinfo"></a> [groups\_by\_userinfo](#input\_groups\_by\_userinfo) | Derive groups information from userinfo endpoint | `bool` | `false` | no |
| <a name="input_healthcheck_cidrs"></a> [healthcheck\_cidrs](#input\_healthcheck\_cidrs) | CIDR blocks to allow health check connections from (recommended to use the VPC CIDR range) | `list(string)` | `[ "0.0.0.0/0" ]` | no |
| <a name="input_host_tags"></a> [host\_tags](#input\_host\_tags) | Additional tags to assign to this AccessTier | `map(any)` | `{ "type": "access_tier" }` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | The name attribute of the IAM instance profile to associate with launched instances. | `string` | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type to use when creating Access Tier instances | `string` | `"t3.large"` | no |
| <a name="input_managed_internal_cidrs"></a> [managed\_internal\_cidrs](#input\_managed\_internal\_cidrs) | CIDR blocks to allow managed internal services connections to | `list(string)` | `[ "0.0.0.0/0" ]` | no |
| <a name="input_management_cidrs"></a> [management\_cidrs](#input\_management\_cidrs) | CIDR blocks to allow SSH connections from | `list(string)` | `[ "0.0.0.0/0" ]` | no |
| <a name="input_min_instances"></a> [min\_instances](#input\_min\_instances) | Minimum number of Access Tier instances to keep alive | `number` | `2` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | String to be added in front of all AWS object names | `string` | `"banyan"` | no |
| <a name="input_package_name"></a> [package\_name](#input\_package\_name) | Override to use a specific version of netagent (e.g. `banyan-netagent-1.5.0`) | `string` | `"banyan-netagent"` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | IDs of the subnets where the Access Tier should create instances | `list(string)` | n/a | yes |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | IDs of the subnets where the load balancer should create endpoints | `list(string)` | n/a | yes |
| <a name="input_rate_limiting"></a> [rate\_limiting](#input\_rate\_limiting) | Rate limiting configuration for access events | `object` | n/a | no |
| <a name="input_redirect_http_to_https"></a> [redirect\_http\_to\_https](#input\_redirect\_http\_to\_https) | If true, requests to the AccessTier on port 80 will be redirected to port 443 | `bool` | `false` | no |
| <a name="input_refresh_token"></a> [refresh\_token](#input\_refresh\_token) | API token generated from the Banyan console | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region in which to create Access Tier | `string` | n/a | yes |
| <a name="input_shield_cidrs"></a> [shield\_cidrs](#input\_shield\_cidrs) | CIDR blocks to allow Shield (Cluster Coordinator) connections to | `list(string)` | `[ "0.0.0.0/0" ]` | no |
| <a name="input_shield_port"></a> [shield\_port](#input\_shield\_port) | TCP port number to allow Shield (Cluster Coordinator) connections to | `number` | `0` | no |
| <a name="input_site_domain_names"></a> [site\_domain\_names](#input\_site\_domain\_names) | List of aliases or CNAMEs that will direct traffic to this Access Tier | `list(string)` | n/a | yes |
| <a name="input_site_name"></a> [site\_name](#input\_site\_name) | Name to use when registering this Access Tier with the console | `string` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of an SSH key stored in AWS to allow management access | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Add tags to each resource | `map(any)` | `null` | no |
| <a name="input_trustprovider_cidrs"></a> [trustprovider\_cidrs](#input\_trustprovider\_cidrs) | CIDR blocks to allow TrustProvider connections to | `list(string)` | `[ "0.0.0.0/0" ]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC in which to create the Access Tier | `string` | n/a | yes |
| <a name="input_http_endpoint_imds_v2"></a> [http\_endpoint\_imds\_v2](#input\_http\_endpoint\_imds\_v2) | Value for http_endpoint to enable imds v2 for ec2 instance | `string` | `"enabled"` | no |
| <a name="input_http_tokens_imds_v2"></a> [http\_tokens\_imds\_v2](#input\_http\_tokens\_imds\_v2) | Value for http_tokens to enable imds v2 for ec2 instance | `string` | `"required"` | no |
| <a name="input_http_hop_limit_imds_v2"></a> [http\_hop\_limit\_imds\_v2](#input\_http\_hop\_limit\_imds\_v2) | Value for http_put_response_hop_limit to enable imds v2 for ec2 instance | `number` | `1` | no |
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | DataDog API key to enable sending connection metrics into DataDog | `string` | `null` | no |
| <a name="input_sticky_sessions"></a> [datadog\_sticky\_sessions](#input\_sticky\_sessions) | Whether to force all connections from a source IP through the same Access Tier instance | `bool` | `false` | no |


The `rate_limiting` object has the following structure:

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="rl_enabled"></a> [enabled](#rl_enabled) | Whether to limit the number of access events sent by the Access Tier | `bool` | `true` | yes |
| <a name="rl_max_credits"></a> [max_credits](#rl_max_credits) | Maximum number of event credits the Access Tier may hold | `number` | `5000` | yes |
| <a name="rl_interval"></a> [interval](#rl_interval) | How often the Access Tier "earns" more credits, formatted as a golang duration string (examples: "30s" or "1m")  | `string` | `1m` | yes |
| <a name="rl_credits_per_interval"></a> [credits\_per\_interval](#rl_credits_per_interval) | How many credits the Access Tier earns in each interval | `number` | `5` | yes |
| <a name="rl_enable_by_key"></a> [enable\_by\_key](#rl_enable_by_key) | Whether multiple requests from a single user should also be rate limited  | `bool` | `true` | yes |
| <a name="rl_key_lifetime"></a> [key\_lifetime](#rl_key_lifetime) | How long a particular combination of user/IP/service is remembered for rate limiting  | `string` | `9m` | yes |

## Outputs

| Name | Description |
|------|-------------|
| nlb\_dns\_name | DNS name of the load balancer (example: `banyan-nlb-b335ff082d3b27ff.elb.us-east-1.amazonaws.com`) |
| nlb\_zone\_id | Zone ID of the load balancer (example: `Z26RNL4JYFTOTI`) |
| security\_group\_id | The ID of the security group attached to the access tier instances, which can be added as an inbound rule on other backend groups (example: `sg-1234abcd`) |

## Authors

Module created and managed by [Todd Radel](https://github.com/tradel).

## License

Licensed under Apache 2. See [LICENSE](LICENSE) for details.

[banyan-security]: https://banyansecurity.io
