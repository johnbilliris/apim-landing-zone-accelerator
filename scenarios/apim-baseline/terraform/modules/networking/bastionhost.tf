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

variable "host_name" {
  type = string
}

variable "public_ip_name" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "Standard"
}

variable "virtual_network_id" {
  type = string
}

variable "workspace_resource_id" {
  type = string
}

variable "diagnostic_settings" {
  type    = list(any)
  default = []
}

data "azurerm_virtual_network" "vnet" {
  name                = split("/", var.virtual_network_id)[8]
  resource_group_name = split("/", var.virtual_network_id)[4]
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
  name                = var.host_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku_name
  scale_units         = 2

  copy_paste_enabled      = true
  file_copy_enabled       = false
  ip_connect_enabled      = false
  shareable_link_enabled  = false
  tunneling_enabled       = false
  kerberos_enabled        = false
  session_recording_enabled = false

  ip_configuration {
    name                 = "configuration"
    subnet_id            = "${var.virtual_network_id}/subnets/AzureBastionSubnet"
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "bastion" {
  for_each = {
    for idx, setting in var.diagnostic_settings : idx => setting
  }

  name                       = "${try(each.value.namePrefix, "diag-")}${azurerm_public_ip.bastion.name}-${try(each.value.destinationSuffix, "law")}" 
  target_resource_id         = azurerm_bastion_host.this.id
  log_analytics_workspace_id = var.workspace_resource_id

  dynamic "enabled_log" {
    for_each = try(each.value.logCategoriesAndGroups, [{ categoryGroup = "allLogs" }])
    content {
      category_group = try(enabled_log.value.categoryGroup, null)
      category       = try(enabled_log.value.category, null)
    }
  }
}

output "id" {
  value = azurerm_bastion_host.this.id
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "name" {
  value = azurerm_bastion_host.this.name
}

output "location" {
  value = azurerm_bastion_host.this.location
}