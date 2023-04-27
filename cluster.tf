locals {
  capacity_provider = "FARGATE"
  desired_tasks = 1
  max_percent = 200
  min_healthy_percent = 0 # No autoscaling
}

# VPC & subnets
resource "aws_vpc" "ecs_vpc" {
  cidr_block = "172.31.0.0/16"
}

data "aws_subnets" "ecs_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.ecs_vpc.id]
  }
}

# Security Group
resource "aws_security_group" "ecs_security_group" {
  for_each = var.image_ports
  name = "${each.key}_security_group"
  vpc_id = aws_vpc.ecs_vpc.id

  ingress {
    from_port        = each.value.from
    to_port 	     = each.value.to
    protocol	     = each.value.protocol
    cidr_blocks	     = [aws_vpc.ecs_vpc.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.ecs_vpc.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# ECS Cluster & Service
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name
}
