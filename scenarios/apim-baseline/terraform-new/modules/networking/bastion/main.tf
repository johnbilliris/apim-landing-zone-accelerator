#--------------------------------------------------------------
# Azure Bastion Module
#--------------------------------------------------------------

variable "name" {
  type        = string
  description = "Name of the Azure Bastion host"
}

variable "location" {
  type        = string
  description = "Azure region for the resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "public_ip_name" {
  type        = string
  description = "Name of the public IP for Bastion"
}

variable "virtual_network_id" {
  type        = string
  description = "ID of the Virtual Network"
}

variable "subnet_id" {
  type        = string
  description = "ID of the AzureBastionSubnet"
}

variable "sku" {
  type        = string
  description = "SKU of the Bastion host"
  default     = "Standard"
}

variable "scale_units" {
  type        = number
  description = "Number of scale units"
  default     = 2
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

resource "azurerm_public_ip" "bastion" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  scale_units         = var.scale_units
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  copy_paste_enabled     = true
  ip_connect_enabled     = false
  shareable_link_enabled = false
  kerberos_enabled       = false
  tunneling_enabled      = false
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "bastion" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_bastion_host.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }
}

output "id" {
  description = "The ID of the Azure Bastion host"
  value       = azurerm_bastion_host.this.id
}

output "name" {
  description = "The name of the Azure Bastion host"
  value       = azurerm_bastion_host.this.name
}

output "public_ip_address" {
  description = "The public IP address of the Azure Bastion"
  value       = azurerm_public_ip.bastion.ip_address
}
