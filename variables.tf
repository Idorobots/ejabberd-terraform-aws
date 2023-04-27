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
  type = list(object({
    internal = number
    external = number
    protocol = string
  }))

  default = [
    {
      internal = 5222
      external = 5222
      protocol = "tcp"
    },
    {
      internal = 5269
      external = 5269
      protocol = "tcp"
    },
    {
      internal = 5443
      external = 5443
      protocol = "tcp"
    }
  ]
}
