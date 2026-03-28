data "azurerm_client_config" "current" {}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "key_vault_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "secrets" {
  type    = list(any)
  default = []
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "diagnostic_settings" {
  type    = list(any)
  default = []
}

variable "virtual_network_rules" {
  type    = list(any)
  default = []
}

variable "private_endpoint_subnet_id" {
  type    = string
  default = ""
}

variable "private_dns_zone_resource_id" {
  type    = string
  default = ""
}

variable "key_vault_private_endpoint_name" {
  type    = string
  default = ""
}

variable "key_vault_private_endpoint_network_interface_name" {
  type    = string
  default = ""
}

locals {
  has_public_network_access = ((var.private_endpoint_subnet_id == "" || var.private_dns_zone_resource_id == "") && length(var.virtual_network_rules) == 0)
}

resource "azurerm_key_vault" "key_vault" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  tags                       = var.tags
  public_network_access_enabled = local.has_public_network_access

  soft_delete_retention_days = 90
  purge_protection_enabled   = false
  enable_rbac_authorization  = true

  dynamic "network_acls" {
    for_each = local.has_public_network_access ? [] : [1]
    content {
      default_action = "Deny"
      bypass         = "AzureServices"
      ip_rules       = []
      virtual_network_subnet_ids = [
        for v in var.virtual_network_rules : try(v.id, null)
      ]
    }
  }
}

resource "azurerm_key_vault_secret" "secrets" {
  for_each = {
    for s in var.secrets : try(s.name, "") => s if try(s.name, "") != ""
  }

  name         = each.value.name
  value        = each.value.value
  key_vault_id = azurerm_key_vault.key_vault.id
  content_type = try(each.value.contentType, null)
}

resource "azurerm_private_endpoint" "key_vault" {
  count = (var.private_endpoint_subnet_id != "" && var.private_dns_zone_resource_id != "") ? 1 : 0

  name                = var.key_vault_private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  custom_network_interface_name = var.key_vault_private_endpoint_network_interface_name
  tags                = var.tags

  private_service_connection {
    name                           = var.key_vault_private_endpoint_name
    private_connection_resource_id = azurerm_key_vault.key_vault.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_resource_id]
  }
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  for_each = {
    for idx, setting in var.diagnostic_settings : idx => setting
  }

  name                       = "${try(each.value.namePrefix, "diag-")}${var.key_vault_name}-${try(each.value.destinationSuffix, "law")}" 
  target_resource_id         = azurerm_key_vault.key_vault.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = try(each.value.logCategoriesAndGroups, [])
    content {
      category_group = try(enabled_log.value.categoryGroup, null)
      category       = try(enabled_log.value.category, null)
    }
  }

  dynamic "metric" {
    for_each = try(each.value.metricCategories, [])
    content {
      category = try(metric.value.category, "AllMetrics")
    }
  }
}

output "id" {
  value = azurerm_key_vault.key_vault.id
}

output "resource_group_name" {
  value = azurerm_key_vault.key_vault.resource_group_name
}

output "name" {
  value = azurerm_key_vault.key_vault.name
}

output "vault_uri" {
  value = azurerm_key_vault.key_vault.vault_uri
}

output "location" {
  value = azurerm_key_vault.key_vault.location
}