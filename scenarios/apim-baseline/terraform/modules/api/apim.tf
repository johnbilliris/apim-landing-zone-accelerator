variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name" {
  type = string
}

variable "publisher_name" {
  type    = string
  default = "APIM Platform Team"
}

variable "publisher_email" {
  type    = string
  default = "apim-admin@example.com"
}

variable "sku_name" {
  type    = string
  default = "Developer_1"
}

variable "subnet_id" {
  type    = string
  default = null
}

variable "virtual_network_type" {
  type    = string
  default = "None"
}

variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  use_vnet = var.subnet_id != null && trim(var.subnet_id) != "" && lower(var.virtual_network_type) != "none"
}

resource "azurerm_api_management" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name
  tags                = var.tags

  virtual_network_type = local.use_vnet ? var.virtual_network_type : "None"

  dynamic "virtual_network_configuration" {
    for_each = local.use_vnet ? [1] : []
    content {
      subnet_id = var.subnet_id
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

output "id" {
  value = azurerm_api_management.this.id
}

output "name" {
  value = azurerm_api_management.this.name
}

output "gateway_url" {
  value = azurerm_api_management.this.gateway_url
}

output "developer_portal_url" {
  value = azurerm_api_management.this.developer_portal_url
}

output "identity_principal_id" {
  value = try(azurerm_api_management.this.identity[0].principal_id, null)
}