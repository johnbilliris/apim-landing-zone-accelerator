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

variable "ase_name" {
  type = string
}

variable "dedicated_host_count" {
  type    = number
  default = 0
}

variable "zone_redundant" {
  type    = bool
  default = false
}

variable "internal_load_balancing_mode" {
  type    = string
  default = "Web, Publishing"
}

variable "allow_new_private_endpoint_connections" {
  type    = bool
  default = false
}

variable "ftp_enabled" {
  type    = bool
  default = false
}

variable "inbound_ip_address_override" {
  type    = string
  default = ""
}

variable "remote_debug_enabled" {
  type    = bool
  default = false
}

variable "subnet_id" {
  type = string
}

variable "create_private_dns" {
  type    = bool
  default = true
}

variable "private_dns_resource_group_name" {
  type    = string
  default = ""
}

variable "virtual_network_id" {
  type    = string
  default = ""
}

variable "log_analytics_workspace_id" {
  type    = string
  default = ""
}

locals {
  resolved_virtual_network_id = var.virtual_network_id != "" ? var.virtual_network_id : regex("^(.*)/subnets/[^/]+$", var.subnet_id)[0]
  proceed_with_private_dns = var.create_private_dns && var.internal_load_balancing_mode != "None"
}

resource "azapi_resource" "asev3" {
  type      = "Microsoft.Web/hostingEnvironments@2025-03-01"
  name      = var.ase_name
  parent_id = var.resource_group_id
  location  = var.location
  tags      = var.tags

  body = {
    kind = "ASEv3"
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      clusterSettings = [
        {
          name  = "DisableTls1.0"
          value = "1"
        }
      ]
      dedicatedHostCount         = var.dedicated_host_count
      zoneRedundant              = var.zone_redundant
      internalLoadBalancingMode  = var.internal_load_balancing_mode
      virtualNetwork = {
        id = var.subnet_id
      }
    }
  }

  response_export_values = ["id", "name", "location", "properties.dnsSuffix"]
}

resource "azapi_resource" "ase_config" {
  type      = "Microsoft.Web/hostingEnvironments/configurations@2024-11-01"
  name      = "networking"
  parent_id = azapi_resource.asev3.id

  body = {
    properties = {
      allowNewPrivateEndpointConnections = var.allow_new_private_endpoint_connections
      ftpEnabled                         = var.ftp_enabled
      inboundIpAddressOverride           = var.inbound_ip_address_override
      remoteDebugEnabled                 = var.remote_debug_enabled
    }
  }

  response_export_values = ["properties.internalInboundIpAddresses"]
}

resource "azurerm_monitor_diagnostic_setting" "ase" {
  count = var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "${var.ase_name}-diagnosticSettings"
  target_resource_id         = azapi_resource.asev3.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }
}

module "private_dns_zone" {
  count = local.proceed_with_private_dns ? 1 : 0

  source = "./appServiceEnvironmentPrivateDNSZone"

  ase_name                 = azapi_resource.asev3.name
  ase_resource_group_name  = var.resource_group_name
  private_dns_zone_name    = azapi_resource.asev3.output.properties.dnsSuffix
  virtual_network_id       = local.resolved_virtual_network_id
  internal_inbound_ip      = try(azapi_resource.ase_config.output.properties.internalInboundIpAddresses[0], null)
  resource_group_name      = var.private_dns_resource_group_name != "" ? var.private_dns_resource_group_name : var.resource_group_name
}

output "name" {
  value = azapi_resource.asev3.name
}

output "id" {
  value = azapi_resource.asev3.id
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "location" {
  value = var.location
}

output "private_dns_zone_name" {
  value = azapi_resource.asev3.output.properties.dnsSuffix
}

output "internal_inbound_ip_address" {
  value = try(azapi_resource.ase_config.output.properties.internalInboundIpAddresses[0], null)
}