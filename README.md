Banyan AWS Access Tier Module
=============================

Creates an autoscaling Access Tier for use with [Banyan Security].

This module creates an AWS auto-scaling group (ASG) and a network load balancer (NLB) for a Banyan Access Tier. Only the NLB is exposed to the public internet. The Access Tier and your applications live in private subnets with no ingress from the internet.

## Usage

```hcl
module "aws_accesstier" {
  source                = "./modules/banyan-accesstier-aws"
  region                = "us-east-1"
  vpc_id                = "vpc-0e73afd7c24062f0a"
  public_subnet_ids     = ["subnet-09ef9206ca406ffe7", "subnet-0bcb18d59e3ff3cc7"]
  private_subnet_ids    = ["subnet-00e393f22c3f09e16", "subnet-0dfce8195de704b65"]
  cluster_name          = "my-banyan-shield"
  site_name             = "my-banyan-site"
  site_domain_names     = ["*.banyan.mycompany.com"]
  ssh_key_name          = "my-ssh-key"
  refresh_token         = "eyJhbGciOiJSUzI1NiIsIm..."
}
```

**NOTE:** The default value for `management_cidr` leaves SSH open to the world on port 2222. You should probably use the CIDR of your VPC, or a bastion host, instead.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| region | Region in which to create Access Tier | `string` | n/a | yes |
| cluster\_name | Name of an existing Shield cluster to register this Access Tier with | `string` | n/a | yes |
| site\_name | Name to use when registering this Access Tier with the console | `string` | n/a | yes |
| private\_subnet\_ids | IDs of the subnets where the Access Tier should create instances | `list(string)` | n/a | yes |
| public\_subnet\_ids | IDs of the subnets where the load balancer should create endpoints | `list(string)` | n/a | yes |
| refresh\_token | API token generated from the Banyan console | `string` | n/a | yes |
| site\_domain\_names | List of aliases or CNAMEs that will direct traffic to this Access Tier | `list(string)` | n/a | yes |
| ami\_id | ID of a custom AMI to use when creating Access Tier instances (leave blank to use default) | `string` | `""` | no |
| api\_server | URL to the Banyan API server | `string` | `"https://net.banyanops.com/api/v1"` | no |
| cross\_zone\_enabled | Allow load balancer to distribute traffic to other zones | `bool` | `true` | no |
| default\_ami\_name | If no AMI ID is supplied, use the most recent AMI from this project | `string` | `"amzn2-ami-hvm-2.0.*-x86_64-ebs"` | no |
| healthcheck\_cidrs | CIDR blocks to allow health check connections from (recommended to use the VPC CIDR range) | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| instance\_type | EC2 instance type to use when creating Access Tier instances | `string` | `"t3.large"` | no |
| management\_cidrs | CIDR blocks to allow SSH connections from | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| min\_instances | Minimum number of Access Tier instances to keep alive | `number` | `2` | no |
| package\_name | Override to use a specific version of netagent (e.g. `banyan-netagent-1.5.0`) | `string` | `"banyan-netagent"` | no |
| ssh\_key\_name | Name of an SSH key stored in AWS to allow management access | `string` | `""` | no |
| vpc\_id | ID of the VPC in which to create the Access Tier | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| nlb\_dns\_name | DNS name of the load balancer (example: `banyan-nlb-b335ff082d3b27ff.elb.us-east-1.amazonaws.com`) |
| nlb\_zone\_id | Zone ID of the load balancer (example: `Z26RNL4JYFTOTI`) |

## Authors

Module created and managed by [Todd Radel](https://github.com/tradel).

## License 

Licensed under Apache 2. See [LICENSE](LICENSE) for details.

[banyan-security]: https://banyansecurity.io