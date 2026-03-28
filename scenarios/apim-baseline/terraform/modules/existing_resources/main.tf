data "azurerm_client_config" "current" {}

locals {
  log_analytics_workspaces = [
    {
      name                = "NDA-COR-AWG-SENTINEL-PROD"
      resourceGroupName   = "nda-cor-arg-sentinel-prod"
      subscriptionId      = data.azurerm_client_config.current.subscription_id
      type                = "sentinel"
      diagnosticSettingsEnabled = true
      diagnosticSetting = {
        namePrefix = "diag-"
        logCategoriesAndGroups = [
          {
            categoryGroup = "allLogs"
          }
        ]
      }
    },
    {
      name                = "LA-AE-MGMT-01"
      resourceGroupName   = "rg-ae-mgmt-oms-01"
      subscriptionId      = data.azurerm_client_config.current.subscription_id
      type                = "law"
      diagnosticSettingsEnabled = true
      diagnosticSetting = {
        namePrefix = "diag-"
        metricCategories = [
          {
            category = "AllMetrics"
          }
        ]
      }
    }
  ]

  application_insights = [
    {
      name              = "appi-ae-mgmt-01"
      resourceGroupName = "rg-ae-mgmt-oms-01"
      subscriptionId    = data.azurerm_client_config.current.subscription_id
    }
  ]
}

output "log_analytics_workspaces" {
  value = local.log_analytics_workspaces
}

output "application_insights" {
  value = local.application_insights
}