variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "application_insights_name" {
  type    = string
  default = "appi-apim"
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_application_insights" "app_insights" {
  name                = var.application_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "web"
  tags                = length(var.tags) > 0 ? var.tags : null

  internet_ingestion_enabled = true
  internet_query_enabled     = true
  retention_in_days          = 90
}

output "app_insights_connection_string" {
  value = azurerm_application_insights.app_insights.connection_string
}

output "app_insights_name" {
  value = azurerm_application_insights.app_insights.name
}

output "app_insights_id" {
  value = azurerm_application_insights.app_insights.id
}

output "app_insights_instrumentation_key" {
  value = azurerm_application_insights.app_insights.instrumentation_key
}