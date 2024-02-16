variable "networks" {
  description = "A map of virtual machines to be deployed into the subscription"
  type = map(object({

    nsgname = string
    rgname  = string
    # direction = string
    inbound = optional(list(object({
      rule_name = string
      priority  = string
      #  direction           = optional(string,"Inbound")
      access              = string
      protocol            = string
      source_port         = optional(list(string))
      source_port1        = string
      destination_port    = list(string)
      source_address      = list(string)
      destination_address = list(string)
      # resource_group_name = string
    })), [])

    outbound = optional(list(object({
      rule_name = string
      priority  = string
      #  direction           = optional(string,"Outbound")
      access              = string
      protocol            = string
      source_port         = optional(list(string))
      source_port1        = string
      destination_port    = list(string)
      source_address      = list(string)
      destination_address = list(string)
      # resource_group_name = string

    })), [])








  }))
  default = {}
  # type    = any
}



