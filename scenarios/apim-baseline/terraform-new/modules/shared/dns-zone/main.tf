#--------------------------------------------------------------
# Private DNS Zone Module
#--------------------------------------------------------------

variable "name" {
  type        = string
  description = "Name of the Private DNS Zone"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "virtual_network_id" {
  type        = string
  description = "ID of the Virtual Network to link"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the Virtual Network for the link"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the resource"
  default     = {}
}

resource "azurerm_private_dns_zone" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = var.virtual_network_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

output "id" {
  description = "The ID of the Private DNS Zone"
  value       = azurerm_private_dns_zone.this.id
}

output "name" {
  description = "The name of the Private DNS Zone"
  value       = azurerm_private_dns_zone.this.name
}
