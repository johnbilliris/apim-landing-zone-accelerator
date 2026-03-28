data "azurerm_client_config" "current" {}

variable "apim_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "product_name" {
  type = string
}

variable "api_name" {
  type    = string
  default = "colors-api"
}

locals {
  apim_id    = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ApiManagement/service/${var.apim_name}"
  product_id = "${local.apim_id}/products/${var.product_name}"
}

resource "azapi_resource" "product_api" {
  type      = "Microsoft.ApiManagement/service/products/apis@2024-06-01-preview"
  name      = var.api_name
  parent_id = local.product_id
}