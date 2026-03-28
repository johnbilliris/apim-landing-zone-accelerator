variable "resource_group_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "use_existing_virtual_network" {
  type    = bool
  default = false
}

variable "use_existing_virtual_network_subnets" {
  type    = bool
  default = false
}

variable "virtual_network_name" {
  type = string
}

variable "vnet_address_prefixes" {
  type = list(string)
}

variable "subnets" {
  type    = list(any)
  default = []
}

variable "diagnostic_settings" {
  type    = list(any)
  default = []
}

variable "deploy_dns" {
  type    = bool
  default = false
}

locals {
  key_vault_private_dns_zone_name    = "privatelink.vaultcore.azure.net"
  monitor_private_dns_zone_name      = "privatelink.monitor.azure.com"
  event_hub_private_dns_zone_name    = "privatelink.servicebus.windows.net"
  sql_db_private_dns_zone_name       = "privatelink.database.azure.com"
  storage_blob_private_dns_zone_name = "privatelink.blob.core.windows.net"
  storage_file_private_dns_zone_name = "privatelink.file.core.windows.net"
  storage_table_private_dns_zone_name = "privatelink.table.core.windows.net"
  storage_queue_private_dns_zone_name = "privatelink.queue.core.windows.net"
  event_grid_private_dns_zone_name   = "privatelink.eventgrid.azure.net"
  service_bus_private_dns_zone_name  = "privatelink.servicebus.windows.net"

  private_dns_zone_names = [
    local.key_vault_private_dns_zone_name,
    local.monitor_private_dns_zone_name,
    local.event_hub_private_dns_zone_name,
    local.sql_db_private_dns_zone_name,
    local.storage_blob_private_dns_zone_name,
    local.storage_file_private_dns_zone_name,
    local.storage_table_private_dns_zone_name,
    local.storage_queue_private_dns_zone_name,
    local.event_grid_private_dns_zone_name,
  ]

  subnet_bodies = [
    for item in(var.use_existing_virtual_network_subnets ? [] : var.subnets) : {
      name = item.name
      properties = {
        addressPrefix = item.addressPrefix
        networkSecurityGroup = try(item.networkSecurityGroupName, "") == "" ? null : {
          id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/networkSecurityGroups/${item.networkSecurityGroupName}"
        }
        privateEndpointNetworkPolicies = try(item.privateEndpointNetworkPolicies, null)
        privateLinkServiceNetworkPolicies = try(item.privateLinkServiceNetworkPolicies, null)
        serviceEndpoints = try(item.serviceEndpoints, null)
        routeTable = try(item.routeTableName, "") == "" ? null : {
          id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/routeTables/${item.routeTableName}"
        }
        delegations = try(item.delegations, null)
      }
    }
  ]
}

data "azurerm_client_config" "current" {}

data "azurerm_virtual_network" "existing" {
  count               = var.use_existing_virtual_network ? 1 : 0
  name                = var.virtual_network_name
  resource_group_name = var.resource_group_name
}

resource "azapi_resource" "virtual_network_new" {
  count     = var.use_existing_virtual_network ? 0 : 1
  type      = "Microsoft.Network/virtualNetworks@2025-01-01"
  name      = var.virtual_network_name
  parent_id = var.resource_group_id
  location  = var.location
  tags      = var.tags

  body = {
    properties = {
      privateEndpointVNetPolicies = "Disabled"
      addressSpace = {
        addressPrefixes = var.vnet_address_prefixes
      }
      subnets = local.subnet_bodies
    }
  }
}

resource "azapi_resource" "virtual_network_diagnostic_settings" {
  for_each = var.use_existing_virtual_network ? {} : {
    for idx, setting in var.diagnostic_settings : idx => setting
  }

  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  name      = "${try(each.value.namePrefix, "diag-")}${var.virtual_network_name}-${try(each.value.destinationSuffix, "law")}" 
  parent_id = azapi_resource.virtual_network_new[0].id

  body = {
    properties = {
      workspaceId = try(each.value.workspaceResourceId, null)
      metrics = [
        for group in try(each.value.metricCategories, [{ category = "AllMetrics" }]) : {
          category  = group.category
          enabled   = try(group.enabled, true)
          timeGrain = null
        }
      ]
      logs = [
        for group in try(each.value.logCategoriesAndGroups, [{ categoryGroup = "allLogs" }]) : {
          categoryGroup = try(group.categoryGroup, null)
          category      = try(group.category, null)
          enabled       = try(group.enabled, true)
        }
      ]
    }
  }
}

output "id" {
  value = var.use_existing_virtual_network ? data.azurerm_virtual_network.existing[0].id : azapi_resource.virtual_network_new[0].id
}

output "name" {
  value = var.virtual_network_name
}

output "location" {
  value = var.location
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "key_vault_private_dns_zone_name" {
  value = local.key_vault_private_dns_zone_name
}

output "monitor_private_dns_zone_name" {
  value = local.monitor_private_dns_zone_name
}

output "event_hub_private_dns_zone_name" {
  value = local.event_hub_private_dns_zone_name
}

output "sql_db_private_dns_zone_name" {
  value = local.sql_db_private_dns_zone_name
}

output "storage_blob_private_dns_zone_name" {
  value = local.storage_blob_private_dns_zone_name
}

output "storage_file_private_dns_zone_name" {
  value = local.storage_file_private_dns_zone_name
}

output "storage_table_private_dns_zone_name" {
  value = local.storage_table_private_dns_zone_name
}

output "storage_queue_private_dns_zone_name" {
  value = local.storage_queue_private_dns_zone_name
}

output "event_grid_private_dns_zone_name" {
  value = local.event_grid_private_dns_zone_name
}

output "service_bus_private_dns_zone_name" {
  value = local.service_bus_private_dns_zone_name
}

output "deployed_subnets" {
  value = [
    for subnet in var.subnets : {
      name       = subnet.name
      resourceId = "${var.use_existing_virtual_network ? data.azurerm_virtual_network.existing[0].id : azapi_resource.virtual_network_new[0].id}/subnets/${subnet.name}"
    }
  ]
}

output "deployed_dns_zones" {
  value = concat(
    [
      {
        name       = local.service_bus_private_dns_zone_name
        resourceId = var.deploy_dns ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/privateDnsZones/${local.service_bus_private_dns_zone_name}" : null
      }
    ],
    [
      for name in local.private_dns_zone_names : {
        name       = name
        resourceId = var.deploy_dns ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/privateDnsZones/${name}" : null
      }
    ]
  )
}