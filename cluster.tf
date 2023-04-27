locals {
  # Cluster
  capacity_provider = "FARGATE"

  # Service
  desired_tasks = 1
  max_percent = 200
  min_healthy_percent = 0 # No autoscaling

  # Task
  cpu = "256"
  mem = "512"
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

# ECS Task definition
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family = "${var.service_name}-task-definition"
  requires_compatibilities = [local.capacity_provider]

  cpu = local.cpu
  memory = local.mem
  network_mode = "awsvpc"

  container_definitions = jsonencode([{
    name = "${var.service_name}-container"
    image = "${var.image.url}:${var.image.tag}"
    essential = true
    portMappings = [ for k, v in var.image_ports : {
      containerPort = v.to
      hostPort = v.from
    }]
  }])
}

# ECS Cluster & Service
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name
}

resource "aws_ecs_service" "ecs_service" {
  name = var.service_name
  cluster = aws_ecs_cluster.ecs_cluster.arn
  launch_type = local.capacity_provider

  deployment_maximum_percent = local.max_percent
  deployment_minimum_healthy_percent = local.min_healthy_percent
  desired_count = local.desired_tasks

  task_definition = aws_ecs_task_definition.ecs_task_definition.arn

  network_configuration {
    assign_public_ip = true
    security_groups = [ for k, v in aws_security_group.ecs_security_group : v.id ]
    subnets = data.aws_subnets.ecs_vpc_subnets[*].id
  }
}
