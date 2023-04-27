locals {
  # Network
  cidr = "172.31"
  desired_subnets = 3

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
  cidr_block = "${local.cidr}.0.0/16"
}

data "aws_availability_zones" "ecs_vpc_azs" {
  state = "available"
}

resource "aws_subnet" "ecs_vpc_subnets" {
  count = local.desired_subnets

  vpc_id = aws_vpc.ecs_vpc.id
  cidr_block = "${local.cidr}.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.ecs_vpc_azs.names[count.index]
}

# Security Group
resource "aws_security_group" "ecs_security_groups" {
  for_each = var.image.ports
  name = "${each.key}_security_group"
  vpc_id = aws_vpc.ecs_vpc.id

  ingress {
    from_port        = each.value.from
    to_port 	     = each.value.to
    protocol	     = each.value.protocol
    cidr_blocks	     = [aws_vpc.ecs_vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

# ECS Task definition
data "aws_iam_role" "ecs_task_role" {
  name = var.task.roleName
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = var.task.executionRoleName
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family = "${var.task.name}-task-definition"
  requires_compatibilities = [local.capacity_provider]

  task_role_arn = data.aws_iam_role.ecs_task_role.arn
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn

  cpu = local.cpu
  memory = local.mem
  network_mode = "awsvpc"

  container_definitions = jsonencode([{
    name = "${var.task.name}"
    image = "${var.image.url}:${var.image.tag}"
    essential = true
    portMappings = [ for k, v in var.image.ports : {
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
    security_groups = [ for k, v in aws_security_group.ecs_security_groups : v.id ]
    subnets = [ for k, v in aws_subnet.ecs_vpc_subnets : v.id ]
  }
}
