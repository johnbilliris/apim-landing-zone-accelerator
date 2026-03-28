variable "private_endpoint_name" {
  type = string
}

variable "group_id" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "networking_resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "service_resource_id" {
  type = string
}

variable "create_dns_zone" {
  type    = bool
  default = true
}

variable "domain" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "dns_zone_new" {
  count = var.create_dns_zone ? 1 : 0

  source = "./dnszone"

  vnet_name                      = var.vnet_name
  networking_resource_group_name = var.networking_resource_group_name
  domain                         = var.domain
  tags                           = var.tags
}

data "azurerm_private_dns_zone" "existing" {
  count               = var.create_dns_zone ? 0 : 1
  name                = var.domain
  resource_group_name = var.networking_resource_group_name
}

locals {
  dns_zone_name = var.create_dns_zone ? module.dns_zone_new[0].dns_zone_name : data.azurerm_private_dns_zone.existing[0].name
  dns_zone_id   = var.create_dns_zone ? module.dns_zone_new[0].dns_zone_id : data.azurerm_private_dns_zone.existing[0].id
}

resource "azurerm_private_endpoint" "private_endpoint" {
  name                = var.private_endpoint_name
  location            = var.location
  resource_group_name = var.networking_resource_group_name
  subnet_id           = var.subnet_id
  custom_network_interface_name = "${var.private_endpoint_name}-nic"
  tags                = length(var.tags) > 0 ? var.tags : null

  private_service_connection {
    name                           = var.private_endpoint_name
    private_connection_resource_id = var.service_resource_id
    subresource_names              = [var.group_id]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [local.dns_zone_id]
  }
}

output "private_endpoint_id" {
  value = azurerm_private_endpoint.private_endpoint.id
}

output "private_endpoint_name" {
  value = azurerm_private_endpoint.private_endpoint.name
}

output "dns_zone_group_id" {
  value = azurerm_private_endpoint.private_endpoint.private_dns_zone_group[0].id
}

output "location" {
  value = var.location
}