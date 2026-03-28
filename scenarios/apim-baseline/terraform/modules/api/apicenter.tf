data "azurerm_client_config" "current" {}

variable "resource_group_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "api_center_name" {
  type = string
}

variable "apim_name" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  has_apim = var.apim_name != ""
  apim_id  = "${var.resource_group_id}/providers/Microsoft.ApiManagement/service/${var.apim_name}"
  api_management_service_reader_role_id = "71522526-b88f-4d52-b57f-d31fc3546d0d"
}

resource "azapi_resource" "api_center_service" {
  type      = "Microsoft.ApiCenter/services@2024-03-01"
  name      = var.api_center_name
  parent_id = var.resource_group_id
  location  = var.location
  tags      = var.tags

  body = {
    identity = {
      type = "SystemAssigned"
    }
    sku = {
      name = "Free"
    }
  }

  response_export_values = ["id", "name", "location", "identity.principalId"]
}

resource "azapi_resource" "role_assignment" {
  count     = local.has_apim ? 1 : 0
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("url", "${local.apim_id}|${azapi_resource.api_center_service.id}|${local.api_management_service_reader_role_id}")
  parent_id = local.apim_id

  body = {
    properties = {
      roleDefinitionId = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.api_management_service_reader_role_id}"
      principalId      = azapi_resource.api_center_service.output.identity.principalId
      principalType    = "ServicePrincipal"
    }
  }
}

resource "azapi_resource" "api_center_workspace" {
  type      = "Microsoft.ApiCenter/services/workspaces@2024-03-01"
  name      = "default"
  parent_id = azapi_resource.api_center_service.id

  body = {
    properties = {
      title       = "Default workspace"
      description = "Default workspace"
    }
  }

  depends_on = [
    azapi_resource.role_assignment,
  ]
}

resource "azapi_resource" "api_workspace_environment" {
  count     = local.has_apim ? 1 : 0
  type      = "Microsoft.ApiCenter/services/workspaces/environments@2024-06-01-preview"
  name      = "Production"
  parent_id = azapi_resource.api_center_workspace.id

  body = {
    properties = {
      description = "Production"
      kind        = "production"
      onboarding = {
        developerPortalUri = [
          "https://${var.apim_name}.developer.azure-api.net",
        ]
        instructions = "No instructions provided."
      }
      server = {
        managementPortalUri = [
          "https://${var.apim_name}.azure-api.net",
        ]
        type = "azure-api-management"
      }
      title = "Production API Management Environment"
    }
  }
}

resource "azapi_resource" "api_source" {
  count     = local.has_apim ? 1 : 0
  type      = "Microsoft.ApiCenter/services/workspaces/apiSources@2024-06-01-preview"
  name      = var.apim_name
  parent_id = azapi_resource.api_center_workspace.id

  body = {
    properties = {
      azureApiManagementSource = {
        msiResourceId = "${data.azurerm_client_config.current.tenant_id}/${azapi_resource.api_center_service.output.identity.principalId}/systemAssigned"
        resourceId    = local.apim_id
      }
      importSpecification = "always"
      targetEnvironmentId = "/workspaces/${azapi_resource.api_center_workspace.name}/environments/Production"
      targetLifecycleStage = "production"
    }
  }

  depends_on = [
    azapi_resource.api_workspace_environment,
    azapi_resource.role_assignment,
  ]
}

output "id" {
  value = azapi_resource.api_center_service.id
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "name" {
  value = azapi_resource.api_center_service.name
}

output "location" {
  value = var.location
}


