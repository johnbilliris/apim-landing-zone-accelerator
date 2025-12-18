#--------------------------------------------------------------
# Private Endpoint Module
#--------------------------------------------------------------

variable "name" {
  type        = string
  description = "Name of the Private Endpoint"
}

variable "location" {
  type        = string
  description = "Azure region for the resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet for the private endpoint"
}

variable "private_connection_resource_id" {
  type        = string
  description = "Resource ID of the service to connect to"
}

variable "subresource_names" {
  type        = list(string)
  description = "Subresource names (group IDs) for the private endpoint"
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "List of Private DNS Zone IDs"
  default     = []
}

variable "custom_network_interface_name" {
  type        = string
  description = "Custom name for the network interface"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the resource"
  default     = {}
}

resource "azurerm_private_endpoint" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.subnet_id
  custom_network_interface_name = var.custom_network_interface_name != "" ? var.custom_network_interface_name : null
  tags                          = var.tags

  private_service_connection {
    name                           = var.name
    private_connection_resource_id = var.private_connection_resource_id
    subresource_names              = var.subresource_names
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }
}

output "id" {
  description = "The ID of the Private Endpoint"
  value       = azurerm_private_endpoint.this.id
}

output "name" {
  description = "The name of the Private Endpoint"
  value       = azurerm_private_endpoint.this.name
}

output "private_ip_address" {
  description = "The private IP address of the Private Endpoint"
  value       = azurerm_private_endpoint.this.private_service_connection[0].private_ip_address
}

output "custom_dns_configs" {
  description = "Custom DNS configurations"
  value       = azurerm_private_endpoint.this.custom_dns_configs
}
