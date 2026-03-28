variable "vnet_name" {
  type = string
}

variable "networking_resource_group_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.networking_resource_group_name
}

resource "azurerm_private_dns_zone" "dns_zone" {
  name                = var.domain
  resource_group_name = var.networking_resource_group_name
  tags                = length(var.tags) > 0 ? var.tags : null
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = var.vnet_name
  resource_group_name   = var.networking_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = length(var.tags) > 0 ? var.tags : null
}

output "dns_zone_name" {
  value = azurerm_private_dns_zone.dns_zone.name
}

output "dns_zone_id" {
  value = azurerm_private_dns_zone.dns_zone.id
}

output "vnet_link_id" {
  value = azurerm_private_dns_zone_virtual_network_link.vnet_link.id
}