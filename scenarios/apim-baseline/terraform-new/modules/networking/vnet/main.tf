#--------------------------------------------------------------
# Virtual Network Module
#--------------------------------------------------------------

variable "name" {
  type        = string
  description = "Name of the Virtual Network"
}

variable "location" {
  type        = string
  description = "Azure region for the resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "address_space" {
  type        = list(string)
  description = "Address space for the Virtual Network"
}

variable "subnets" {
  type = list(object({
    name                              = string
    address_prefix                    = string
    delegations                       = optional(list(string), [])
    network_security_group_name       = optional(string)
    route_table_name                  = optional(string)
    service_endpoints                 = optional(list(string), [])
    private_endpoint_network_policies = optional(string, "Disabled")
  }))
  description = "List of subnet configurations"
  default     = []
}

variable "nsg_ids" {
  type        = map(string)
  description = "Map of NSG names to their resource IDs"
  default     = {}
}

variable "route_table_ids" {
  type        = map(string)
  description = "Map of Route Table names to their resource IDs"
  default     = {}
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace for diagnostics"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the resource"
  default     = {}
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                              = each.value.name
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = [each.value.address_prefix]
  service_endpoints                 = length(each.value.service_endpoints) > 0 ? each.value.service_endpoints : null
  private_endpoint_network_policies = each.value.private_endpoint_network_policies

  dynamic "delegation" {
    for_each = each.value.delegations
    content {
      name = replace(delegation.value, "/", ".")
      service_delegation {
        name = delegation.value
      }
    }
  }
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if subnet.network_security_group_name != null && subnet.network_security_group_name != ""
  }

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = lookup(var.nsg_ids, each.value.network_security_group_name, null)
}

# Associate Route Tables with subnets
resource "azurerm_subnet_route_table_association" "this" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if subnet.route_table_name != null && subnet.route_table_name != ""
  }

  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = lookup(var.route_table_ids, each.value.route_table_name, null)
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "this" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_virtual_network.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

output "id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "The name of the Virtual Network"
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet names to their resource IDs"
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = var.resource_group_name
}
