variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "hub" {
  type = object({
    vnet_id    = string
    subnet_ids = map(string)
  })
}

variable "spoke" {
  type = object({
    vnet_id    = string
    subnet_ids = map(string)
  })
}

locals {
  deployment = {
    location    = var.location
    environment = var.environment
    hub         = var.hub
    spoke       = var.spoke
  }
}

output "deployment" {
  value = local.deployment
}