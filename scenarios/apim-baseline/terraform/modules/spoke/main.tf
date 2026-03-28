variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "spoke_vnet_id" {
  type = string
}

variable "spoke_subnet_ids" {
  type    = map(string)
  default = {}
}

locals {
  spoke_topology = {
    location            = var.location
    resource_group_name = var.resource_group_name
    vnet_id             = var.spoke_vnet_id
    subnet_ids          = var.spoke_subnet_ids
  }
}

output "topology" {
  value = local.spoke_topology
}

output "vnet_id" {
  value = var.spoke_vnet_id
}