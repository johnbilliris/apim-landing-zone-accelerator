variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "app_name" {
  type = string
}

variable "app_service_plan_name" {
  type = string
}

variable "app_service_environment_name" {
  type    = string
  default = ""
}

variable "always_on" {
  type    = bool
  default = true
}

variable "php_version" {
  type    = string
  default = "5.6"
}

variable "net_framework_version" {
  type    = string
  default = "v8.0"
}

variable "repo_url" {
  type    = string
  default = ""
}

variable "branch" {
  type    = string
  default = "master"
}

variable "application_insights_connection_string" {
  type    = string
  default = ""
}

variable "ip_security_restrictions" {
  type    = list(any)
  default = []
}

variable "app_settings" {
  type    = list(any)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

data "azurerm_service_plan" "app_service_plan" {
  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
}

locals {
  base_app_settings = {
    VNET_ROUTE_ALL = var.app_service_environment_name == "" ? "0" : "1"
  }

  insights_app_settings = var.application_insights_connection_string == "" ? {} : {
    APPLICATIONINSIGHTS_CONNECTION_STRING              = var.application_insights_connection_string
    APPINSIGHTS_PROFILERFEATURE_VERSION                = "1.0.0"
    APPINSIGHTS_SNAPSHOTFEATURE_VERSION                = "1.0.0"
    ApplicationInsightsAgent_EXTENSION_VERSION         = "~2"
    DiagnosticServices_EXTENSION_VERSION               = "~3"
    InstrumentationEngine_EXTENSION_VERSION            = "disabled"
    SnapshotDebugger_EXTENSION_VERSION                 = "disabled"
    XDT_MicrosoftApplicationInsights_BaseExtensions    = "disabled"
    XDT_MicrosoftApplicationInsights_Java              = "1"
    XDT_MicrosoftApplicationInsights_Mode              = "recommended"
    XDT_MicrosoftApplicationInsights_NodeJS            = "1"
    XDT_MicrosoftApplicationInsights_PreemptSdk        = "disabled"
  }

  custom_app_settings = {
    for s in var.app_settings : s.name => s.value if try(s.name, "") != ""
  }

  merged_app_settings = merge(local.custom_app_settings, local.base_app_settings, local.insights_app_settings)
}

resource "azurerm_windows_web_app" "site" {
  name                = var.app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = data.azurerm_service_plan.app_service_plan.id
  https_only          = true
  client_affinity_enabled = false
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on              = var.always_on
    minimum_tls_version    = "1.2"
    ftps_state             = "Disabled"
    remote_debugging_enabled = false
    http2_enabled          = true
    app_command_line       = null

    dynamic "ip_restriction" {
      for_each = var.ip_security_restrictions
      content {
        ip_address = try(ip_restriction.value.ipAddress, null)
        action     = try(ip_restriction.value.action, "Allow")
        priority   = try(ip_restriction.value.priority, null)
        name       = try(ip_restriction.value.name, null)
      }
    }
  }

  app_settings = local.merged_app_settings
}

resource "azurerm_app_service_source_control" "source_control" {
  count = var.repo_url == "" ? 0 : 1

  app_id                 = azurerm_windows_web_app.site.id
  repo_url               = var.repo_url
  branch                 = var.branch != "" ? var.branch : "main"
  use_manual_integration = true
}

output "id" {
  value = azurerm_windows_web_app.site.id
}

output "name" {
  value = azurerm_windows_web_app.site.name
}

output "managed_identity_principal_id" {
  value = azurerm_windows_web_app.site.identity[0].principal_id
}