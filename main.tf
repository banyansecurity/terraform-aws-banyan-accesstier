provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

data aws_ami "default_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.default_ami_name]
  }
}

resource aws_security_group "sg" {
  name        = "banyan-accesstier-sg"
  description = "Elastic Access Tier ingress traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9998
    to_port     = 9998
    protocol    = "tcp"
    cidr_blocks = var.healthcheck_cidrs
  }

  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = var.management_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Provider = "BanyanOps"
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "banyan-accesstier-asg"
  launch_configuration      = aws_launch_configuration.conf.name
  max_size                  = 10
  min_size                  = var.min_instances
  desired_capacity          = var.min_instances
  vpc_zone_identifier       = var.private_subnet_ids
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.target443.arn, aws_lb_target_group.target8443.arn]

  tag {
    key                 = "Name"
    value               = "${var.site_name}-BanyanHost"
    propagate_at_launch = true
  }

  tag {
    key                 = "Provider"
    value               = "BanyanOps"
    propagate_at_launch = true
  }
}

resource aws_launch_configuration "conf" {
  name            = "banyan-accesstier-conf"
  image_id        = var.ami_id != "" ? var.ami_id : data.aws_ami.default_ami.id
  instance_type   = var.instance_type
  key_name        = var.ssh_key_name
  security_groups = [aws_security_group.sg.id]
  ebs_optimized   = true

  ephemeral_block_device {
    device_name  = "/dev/sdc"
    virtual_name = "ephemeral0"
  }

  user_data = join("", concat([
    "#!/bin/bash -ex\n",
    "yum update -y\n",
    "yum install -y jq tar gzip curl sed\n",
    "rpm --import https://www.banyanops.com/onramp/repo/RPM-GPG-KEY-banyan\n",
    "yum-config-manager --add-repo https://www.banyanops.com/onramp/repo\n",
    "yum install -y ${var.package_name} \n",
    "cd /opt/banyan-packages\n",
    "while [ -f /var/run/yum.pid ]; do sleep 1; done\n",
    "BANYAN_ACCESS_TIER=true ",
    "BANYAN_SITE_NAME=${var.site_name} ",
    "BANYAN_SITE_ADDRESS=${aws_alb.nlb.dns_name} ",
    "BANYAN_SITE_DOMAIN_NAMES=", join(",", var.site_domain_names), " ",
    "BANYAN_SITE_AUTOSCALE=true ",
    "BANYAN_API=${var.api_server} ",
    "BANYAN_HOST_TAGS= ",
    "./install ${var.refresh_token} ${var.cluster_name} \n",
    "echo 'Port 2222' >> /etc/ssh/sshd_config && /bin/systemctl restart sshd.service\n",
  ], var.custom_user_data))
}

resource aws_alb "nlb" {
  name                             = "banyan-nlb"
  load_balancer_type               = "network"
  internal                         = false
  subnets                          = var.public_subnet_ids
  enable_cross_zone_load_balancing = var.cross_zone_enabled

  tags = {
    Provider = "BanyanOps"
  }
}

resource aws_lb_target_group "target443" {
  name     = "banyan-tg-443"
  vpc_id   = var.vpc_id
  port     = 443
  protocol = "TCP"
  health_check {
    port                = 9998
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource aws_lb_listener "listener443" {
  load_balancer_arn = aws_alb.nlb.arn
  port              = 443
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target443.arn
  }
}

resource aws_lb_target_group "target8443" {
  name     = "banyan-tg-8443"
  vpc_id   = var.vpc_id
  port     = 8443
  protocol = "TCP"
  health_check {
    port                = 9998
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource aws_lb_listener "listener8443" {
  load_balancer_arn = aws_alb.nlb.arn
  port              = 8443
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target8443.arn
  }
}

resource aws_autoscaling_policy "cpu_policy" {
  name                   = "banyan-cpu-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80
  }
}

