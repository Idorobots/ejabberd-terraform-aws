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

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_provider" {
  cluster_name = var.cluster_name

  capacity_providers = [local.capacity_provider]

  default_capacity_provider_strategy {
    base = 1
    weight = 100
    capacity_provider = local.capacity_provider
  }
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
