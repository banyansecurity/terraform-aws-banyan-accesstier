locals {
  tags = merge(var.tags, {
    Provider = "BanyanOps"
  })

  asg_tags = merge(local.tags, {
    Name = "${var.site_name}-BanyanHost"
  })
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "sg" {
  name        = "${var.name_prefix}-accesstier-sg-1"
  description = "Elastic Access Tier ingress traffic"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.redirect_http_to_https ? [true] : []
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Redirect to 443"
    }
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Web traffic"
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow for web traffic"
  }

  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow for service tunnel traffic"
  }

  ingress {
    from_port   = 9998
    to_port     = 9998
    protocol    = "tcp"
    cidr_blocks = var.healthcheck_cidrs
    description = "Healthcheck"
  }

  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = var.management_cidrs
    description = "Management"
  }

  egress {
    from_port   = var.shield_port  # shield_port defaults to 0
    to_port     = var.shield_port != 0 ? var.shield_port : 65535
    protocol    = "tcp"
    cidr_blocks = var.shield_cidrs
    description = "Shield (Cluster Coordinator)"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat(var.command_center_cidrs, var.trustprovider_cidrs)
    description = "Command Center and TrustProvider"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.managed_internal_cidrs
    description = "Managed internal services"
  }

  tags = merge(local.tags, var.security_group_tags)
}

resource "aws_autoscaling_group" "asg" {
  name                      = "${var.name_prefix}-accesstier-asg"
  launch_configuration      = aws_launch_configuration.conf.name
  max_size                  = 10
  min_size                  = var.min_instances
  desired_capacity          = var.min_instances
  vpc_zone_identifier       = var.private_subnet_ids
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns         = compact([join("", aws_lb_target_group.target80.*.arn), aws_lb_target_group.target443.arn, aws_lb_target_group.target8443.arn, aws_lb_target_group.target51820.arn])
  max_instance_lifetime     = var.max_instance_lifetime

  dynamic "tag" {
    # do another merge for application specific tags if need-be
    for_each = merge(local.asg_tags, var.autoscaling_group_tags)

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_launch_configuration" "conf" {
  name_prefix     = "${var.name_prefix}-accesstier-conf-"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.ssh_key_name
  security_groups = [aws_security_group.sg.id]
  ebs_optimized   = true

  iam_instance_profile = var.iam_instance_profile

  ephemeral_block_device {
    device_name  = "/dev/sdc"
    virtual_name = "ephemeral0"
  }

  metadata_options {
    http_endpoint               = var.http_endpoint_imds_v2
    http_tokens                 = var.http_tokens_imds_v2
    http_put_response_hop_limit = var.http_hop_limit_imds_v2
  }


  lifecycle {
    create_before_destroy = true
  }

  user_data = join("", concat([
    "#!/bin/bash -ex\n",
    # increase file handle limits
    "echo '* soft nofile 100000' >> /etc/security/limits.d/banyan.conf\n",
    "echo '* hard nofile 100000' >> /etc/security/limits.d/banyan.conf\n",
    "echo 'fs.file-max = 100000' >> /etc/sysctl.d/90-banyan.conf\n",
    "sysctl -w fs.file-max=100000\n",
    # increase conntrack hashtable limits
    "echo 'options nf_conntrack hashsize=65536' >> /etc/modprobe.d/banyan.conf\n",
    "modprobe nf_conntrack\n",
    "echo '65536' > /proc/sys/net/netfilter/nf_conntrack_buckets\n",
    "echo '262144' > /proc/sys/net/netfilter/nf_conntrack_max\n",
    # install dogstatsd (if requested)
    var.datadog_api_key != null ? "curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh | DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=${var.datadog_api_key} DD_SITE=datadoghq.com bash -v\n" : "",
    # install prerequisites and Banyan netagent
    "curl https://www.banyanops.com/onramp/deb-repo/banyan.key | apt-key add -\n",
    "apt-add-repository \"deb https://www.banyanops.com/onramp/deb-repo xenial main\"\n",
    "apt install -y ${var.package_name} \n",
    # configure and start netagent
    "cd /opt/banyan-packages\n",
    "BANYAN_ACCESS_TIER=true ",
    "BANYAN_REDIRECT_TO_HTTPS=${var.redirect_http_to_https} ",
    "BANYAN_SITE_NAME=${var.site_name} ",
    "BANYAN_SITE_ADDRESS=${aws_alb.nlb.dns_name} ",
    "BANYAN_SITE_DOMAIN_NAMES=", join(",", var.site_domain_names), " ",
    "BANYAN_SITE_AUTOSCALE=true ",
    "BANYAN_API=${var.api_server} ",
    "BANYAN_HOST_TAGS=", join(",", [for k, v in var.host_tags : format("%s=%s", k, v)]), " ",
    "BANYAN_ACCESS_EVENT_CREDITS_LIMITING=${var.rate_limiting.enabled} ",
    "BANYAN_ACCESS_EVENT_CREDITS_MAX=${var.rate_limiting.max_credits} ",
    "BANYAN_ACCESS_EVENT_CREDITS_INTERVAL=${var.rate_limiting.interval} ",
    "BANYAN_ACCESS_EVENT_CREDITS_PER_INTERVAL=${var.rate_limiting.credits_per_interval} ",
    "BANYAN_ACCESS_EVENT_KEY_LIMITING=${var.rate_limiting.enable_by_key} ",
    "BANYAN_ACCESS_EVENT_KEY_EXPIRATION=${var.rate_limiting.key_lifetime} ",
    "BANYAN_GROUPS_BY_USERINFO=${var.groups_by_userinfo} ",
    var.datadog_api_key != null ? "BANYAN_STATSD=true BANYAN_STATSD_ADDRESS=127.0.0.1:8125 " : "",
    "./install ${var.refresh_token} ${var.cluster_name} \n",
    "echo 'Port 2222' >> /etc/ssh/sshd_config && /bin/systemctl restart sshd.service\n",
  ], var.custom_user_data))
}

resource "aws_alb" "nlb" {
  name                             = "${var.name_prefix}-nlb"
  load_balancer_type               = "network"
  internal                         = false
  subnets                          = var.public_subnet_ids
  enable_cross_zone_load_balancing = var.cross_zone_enabled

  tags = merge(local.tags, var.lb_tags)
}

resource "aws_lb_target_group" "target443" {
  name     = "${var.name_prefix}-tg-443"
  vpc_id   = var.vpc_id
  port     = 443
  protocol = "TCP"
  stickiness {
      enabled = var.sticky_sessions
      type = "source_ip"
  }
  health_check {
    port                = 9998
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.tags, var.target_group_tags)
}

resource "aws_lb_listener" "listener443" {
  load_balancer_arn = aws_alb.nlb.arn
  port              = 443
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target443.arn
  }
}

resource "aws_lb_target_group" "target80" {
  count = var.redirect_http_to_https ? 1 : 0

  name     = "${var.name_prefix}-tg-80"
  vpc_id   = var.vpc_id
  port     = 80
  protocol = "TCP"
  stickiness {
      enabled = var.sticky_sessions
      type = "source_ip"
  }
  health_check {
    port                = 9998
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.tags, var.target_group_tags)
}

resource "aws_lb_listener" "listener80" {
  count = var.redirect_http_to_https ? 1 : 0

  load_balancer_arn = aws_alb.nlb.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target80[0].arn
  }
}

resource "aws_lb_target_group" "target8443" {
  name     = "${var.name_prefix}-tg-8443"
  vpc_id   = var.vpc_id
  port     = 8443
  protocol = "TCP"
  stickiness {
      enabled = var.sticky_sessions
      type = "source_ip"
  }
  health_check {
    port                = 9998
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.tags, var.target_group_tags)
}

resource "aws_lb_listener" "listener8443" {
  load_balancer_arn = aws_alb.nlb.arn
  port              = 8443
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target8443.arn
  }
}

resource "aws_lb_target_group" "target51820" {
  name     = "${var.name_prefix}-tg-51820"
  vpc_id   = var.vpc_id
  port     = 51820
  protocol = "UDP"
  stickiness {
      enabled = var.sticky_sessions
      type = "source_ip"
  }
  health_check {
    port                = 9998
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.tags, var.target_group_tags)
}

resource "aws_lb_listener" "listener51820" {
  load_balancer_arn = aws_alb.nlb.arn
  port              = 51820
  protocol          = "UDP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target51820.arn
  }
}

resource "aws_autoscaling_policy" "cpu_policy" {
  name                   = "${var.name_prefix}-cpu-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80
  }
}
