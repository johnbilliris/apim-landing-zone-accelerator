variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "hub_vnet_id" {
  type = string
}

variable "hub_subnet_ids" {
  type    = map(string)
  default = {}
}

locals {
  hub_topology = {
    location            = var.location
    resource_group_name = var.resource_group_name
    vnet_id             = var.hub_vnet_id
    subnet_ids          = var.hub_subnet_ids
  }
}

output "topology" {
  value = local.hub_topology
}

output "vnet_id" {
  value = var.hub_vnet_id
}