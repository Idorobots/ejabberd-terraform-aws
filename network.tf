locals {
  # Network
  cidr = "172.31"
  desired_subnets = 3
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

resource "aws_internet_gateway" "ecs_gw" {
  vpc_id = aws_vpc.ecs_vpc.id
}

resource "aws_default_route_table" "example" {
  default_route_table_id = aws_vpc.ecs_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_gw.id	
  }
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
