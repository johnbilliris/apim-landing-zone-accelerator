data "azurerm_client_config" "current" {}

variable "apim_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "logger_name" {
  type = string
}

variable "api_names" {
  type    = list(string)
  default = []
}

locals {
  apim_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ApiManagement/service/${var.apim_name}"
  logger_id = "${local.apim_id}/loggers/${var.logger_name}"
  diagnostics_properties = {
    loggerId                = local.logger_id
    alwaysLog               = "allErrors"
    httpCorrelationProtocol = "Legacy"
    verbosity               = "information"
    logClientIp             = true
    sampling = {
      percentage   = 100
      samplingType = "fixed"
    }
    metrics = true
    frontend = {
      request = {
        body = { bytes = 0 }
      }
      response = {
        body = { bytes = 0 }
      }
    }
    backend = {
      request = {
        body = { bytes = 0 }
      }
      response = {
        body = { bytes = 0 }
      }
    }
  }
}

resource "azapi_resource" "service_diagnostic" {
  type      = "Microsoft.ApiManagement/service/diagnostics@2022-08-01"
  name      = "applicationinsights"
  parent_id = local.apim_id

  body = {
    properties = local.diagnostics_properties
  }
}

resource "azapi_resource" "api_diagnostics" {
  for_each = toset(var.api_names)

  type      = "Microsoft.ApiManagement/service/apis/diagnostics@2022-08-01"
  name      = "applicationinsights"
  parent_id = "${local.apim_id}/apis/${each.value}"

  body = {
    properties = local.diagnostics_properties
  }
}