variable "resource_group_name" {
  type = string
}

variable "api_management_name" {
  type = string
}

variable "api_name" {
  type    = string
  default = "colors-api"
}

variable "display_name" {
  type    = string
  default = "Colors API"
}

variable "path" {
  type    = string
  default = "colors"
}

variable "service_url" {
  type = string
}

resource "azurerm_api_management_api" "colors" {
  name                = var.api_name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  revision            = "1"
  display_name        = var.display_name
  path                = var.path
  protocols           = ["https"]
  service_url         = var.service_url
}

resource "azurerm_api_management_api_operation" "list_colors" {
  operation_id        = "list-colors"
  api_name            = azurerm_api_management_api.colors.name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  display_name        = "List colors"
  method              = "GET"
  url_template        = "/"
  description         = "Returns the list of colors."

  response {
    status_code = 200
    description = "Successful response"
  }
}

resource "azurerm_api_management_api_policy" "colors" {
  api_name            = azurerm_api_management_api.colors.name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML
}

output "api_id" {
  value = azurerm_api_management_api.colors.id
}

output "api_name" {
  value = azurerm_api_management_api.colors.name
}