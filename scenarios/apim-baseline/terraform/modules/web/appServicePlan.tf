data "azurerm_client_config" "current" {}

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

variable "app_service_plan_name" {
  type = string
}

variable "app_service_environment_name" {
  type = string
}

variable "sku" {
  type    = string
  default = "IsolatedV2"
}

variable "sku_code" {
  type    = string
  default = "I1v2"
}

variable "app_service_plan_capacity" {
  type = number
}

variable "zone_redundant" {
  type    = bool
  default = false
}

locals {
  ase_id = var.app_service_environment_name != "" ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/hostingEnvironments/${var.app_service_environment_name}" : null
}

resource "azurerm_service_plan" "hosting_plan" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  sku_name            = var.sku_code
  worker_count        = var.app_service_plan_capacity
  app_service_environment_id = local.ase_id
  zone_balancing_enabled = var.zone_redundant
  tags                = var.tags
}

output "id" {
  value = azurerm_service_plan.hosting_plan.id
}

output "name" {
  value = azurerm_service_plan.hosting_plan.name
}

output "location" {
  value = azurerm_service_plan.hosting_plan.location
}

output "resource_group_name" {
  value = azurerm_service_plan.hosting_plan.resource_group_name
}