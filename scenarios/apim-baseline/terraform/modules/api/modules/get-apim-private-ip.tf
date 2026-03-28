variable "apim_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

data "azurerm_api_management" "apim" {
  name                = var.apim_name
  resource_group_name = var.resource_group_name
}

output "private_ip_address" {
  value = try(data.azurerm_api_management.apim.private_ip_addresses[0], null)
}