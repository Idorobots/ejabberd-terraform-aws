
resource "time_sleep" "wait_for_ip_assignment" {
  depends_on = [aws_ecs_service.ecs_service]

  create_duration = "10s"
}

data "aws_network_interfaces" "ecs_service_interfaces" {
  depends_on = [time_sleep.wait_for_ip_assignment]

  filter {
    name   = "group-id"
    values = [aws_security_group.ecs_security_group.id]
  }
}

data "aws_network_interface" "ecs_service_interface" {
  id = join(",", data.aws_network_interfaces.ecs_service_interfaces.ids)
}

output "public_ip" {
  value = "${data.aws_network_interface.ecs_service_interface.association[0].public_ip}"
}

output "admin_url" {
  value = "https://${data.aws_network_interface.ecs_service_interface.association[0].public_ip}:${var.image.ports.https.from}/admin"
}
