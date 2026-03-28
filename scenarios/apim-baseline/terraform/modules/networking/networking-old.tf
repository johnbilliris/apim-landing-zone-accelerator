variable "vnet_id" {
  type = string
}

variable "subnet_ids" {
  type    = map(string)
  default = {}
}

locals {
  legacy_networking = {
    vnet_id    = var.vnet_id
    subnet_ids = var.subnet_ids
  }
}

output "legacy" {
  value = local.legacy_networking
}

output "vnet_id" {
  value = var.vnet_id
}