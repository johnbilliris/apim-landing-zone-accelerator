#--------------------------------------------------------------
# Key Vault Module
#--------------------------------------------------------------

variable "name" {
  type        = string
  description = "Name of the Key Vault"
}

variable "location" {
  type        = string
  description = "Azure region for the resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "sku_name" {
  type        = string
  description = "SKU of the Key Vault"
  default     = "premium"
}

variable "virtual_network_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for network rules"
  default     = []
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for private endpoint"
  default     = ""
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS Zone ID for private endpoint"
  default     = ""
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace for diagnostics"
  default     = ""
}

variable "secrets" {
  type = list(object({
    name         = string
    value        = string
    content_type = optional(string)
  }))
  description = "List of secrets to create in the Key Vault"
  default     = []
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the resource"
  default     = {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = var.sku_name
  tags                        = var.tags

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  enable_rbac_authorization       = true
  purge_protection_enabled        = false
  soft_delete_retention_days      = 90

  public_network_access_enabled = length(var.virtual_network_subnet_ids) == 0 && var.private_endpoint_subnet_id == ""

  dynamic "network_acls" {
    for_each = length(var.virtual_network_subnet_ids) > 0 || var.private_endpoint_subnet_id != "" ? [1] : []
    content {
      default_action             = "Deny"
      bypass                     = "AzureServices"
      virtual_network_subnet_ids = var.virtual_network_subnet_ids
    }
  }
}

# Create secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each     = { for secret in var.secrets : secret.name => secret }
  name         = each.value.name
  value        = each.value.value
  key_vault_id = azurerm_key_vault.this.id
  content_type = each.value.content_type
}

# Private endpoint
resource "azurerm_private_endpoint" "kv" {
  count               = var.private_endpoint_subnet_id != "" && var.private_dns_zone_id != "" ? 1 : 0
  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "pe-${var.name}"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "kv" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

output "id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}

output "tenant_id" {
  description = "The tenant ID of the Key Vault"
  value       = azurerm_key_vault.this.tenant_id
}
