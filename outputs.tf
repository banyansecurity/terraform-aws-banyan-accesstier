output "nlb_dns_name" {
    value = aws_alb.nlb.dns_name
    description = "DNS name of the load balancer (example: `banyan-nlb-b335ff082d3b27ff.elb.us-east-1.amazonaws.com`)"
}

output "nlb_zone_id" {
    value = aws_alb.nlb.zone_id
    description = "Zone ID of the load balancer (example: `Z26RNL4JYFTOTI`)"
}
