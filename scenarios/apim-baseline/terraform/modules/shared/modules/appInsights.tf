variable "application_insights" {
  type = list(object({
    name              = string
    resourceGroupName = string
    subscriptionId    = string
  }))
  default = []
}

locals {
  has_application_insights = length(var.application_insights) > 0
}

data "azurerm_application_insights" "existing" {
  count               = local.has_application_insights ? 1 : 0
  name                = var.application_insights[0].name
  resource_group_name = var.application_insights[0].resourceGroupName
}

output "id" {
  value = local.has_application_insights ? data.azurerm_application_insights.existing[0].id : ""
}

output "connection_string" {
  value = local.has_application_insights ? data.azurerm_application_insights.existing[0].connection_string : ""
}