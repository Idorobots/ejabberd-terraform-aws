variable "cluster" {
  type = object({
    name = string
  })
  default = {
    name = "ejabberd-cluster"
  }
}

variable "service" {
  type = object({
    name = string
    ecsExec = bool
  })
  default = {
    name = "ejabberd-service"
    ecsExec = true
  }
}

variable task {
  type = object({
    name = string
    roleName = string
    executionRoleName = string
  })

  default = {
    name = "ejabberd"
    roleName = "ecsTaskRole"
    executionRoleName = "ecsTaskExecutionRole"
  }
}

variable "image" {
  type = object({
    url = string
    tag = string
    ports = map(object({
      from = number
      to = number
      protocol = string
    }))
  })

  default = {
    url = "ghcr.io/processone/ecs"
    tag = "latest"
    ports = {
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
}
