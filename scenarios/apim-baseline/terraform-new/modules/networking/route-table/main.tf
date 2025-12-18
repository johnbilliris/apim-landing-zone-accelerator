#--------------------------------------------------------------
# Route Table Module
#--------------------------------------------------------------

variable "name" {
  type        = string
  description = "Name of the Route Table"
}

variable "location" {
  type        = string
  description = "Azure region for the resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  description = "List of routes"
  default     = []
}

variable "disable_bgp_route_propagation" {
  type        = bool
  description = "Whether to disable BGP route propagation"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the resource"
  default     = {}
}

resource "azurerm_route_table" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = var.disable_bgp_route_propagation
  tags                          = var.tags

  dynamic "route" {
    for_each = var.routes
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }
}

output "id" {
  description = "The ID of the Route Table"
  value       = azurerm_route_table.this.id
}

output "name" {
  description = "The name of the Route Table"
  value       = azurerm_route_table.this.name
}
