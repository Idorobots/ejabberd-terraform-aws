variable "image" {
  type = object({
    url = string
    tag = string
  })

  default = {
    url = "ghcr.io/processone/ecs"
    tag = "latest"
  }
}
variable "image_ports" {
  type = map(object({
    from = number
    to = number
    protocol = string
  }))

  default = {
    xmpp_c2c = {
      from = 5222
      to = 5222
      protocol = "tcp"
    }

    xmpp_s2s = {
      from = 5269
      to = 5269
      protocol = "tcp"
    }

    https = {
      from = 5443
      to = 5443
      protocol = "tcp"
    }
  }
}

variable "cluster_name" {
  type = string
  default = "ejabberd-cluster"
}

variable "service_name" {
  type = string
  default = "ejabberd-service"
}
