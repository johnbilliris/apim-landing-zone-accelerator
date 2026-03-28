variable "ase_name" {
  type = string
}

variable "ase_resource_group_name" {
  type = string
}

variable "private_dns_zone_name" {
  type = string
}

variable "virtual_network_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "internal_inbound_ip" {
  type = string
}

resource "azurerm_private_dns_zone" "private_zone" {
  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "vnetLink"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_zone.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "web_record" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.private_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  records             = [var.internal_inbound_ip]
}

resource "azurerm_private_dns_a_record" "scm_record" {
  name                = "*.scm"
  zone_name           = azurerm_private_dns_zone.private_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  records             = [var.internal_inbound_ip]
}

resource "azurerm_private_dns_a_record" "at_record" {
  name                = "@"
  zone_name           = azurerm_private_dns_zone.private_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  records             = [var.internal_inbound_ip]
}