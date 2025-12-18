#--------------------------------------------------------------
# API Management Module
# Equivalent to apim.bicep
#--------------------------------------------------------------

variable "name" {
  type        = string
  description = "Name of the API Management service"
}

variable "location" {
  type        = string
  description = "Azure region for the resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "publisher_email" {
  type        = string
  description = "Publisher email for API Management"
}

variable "publisher_name" {
  type        = string
  description = "Publisher name for API Management"
}

variable "sku_name" {
  type        = string
  description = "SKU name for API Management"
  default     = "Developer"
}

variable "sku_capacity" {
  type        = number
  description = "SKU capacity for API Management"
  default     = 1
}

variable "virtual_network_type" {
  type        = string
  description = "Virtual network type (External, Internal, None)"
  default     = "External"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for API Management"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for Premium SKU"
  default     = []
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for private endpoint (StandardV2)"
  default     = ""
}

variable "private_endpoint_name" {
  type        = string
  description = "Name of the private endpoint"
  default     = ""
}

variable "private_endpoint_nic_name" {
  type        = string
  description = "Name of the private endpoint network interface"
  default     = ""
}

variable "virtual_network_id" {
  type        = string
  description = "ID of the virtual network for DNS zone linking"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network for DNS zone linking"
}

variable "networking_resource_group_name" {
  type        = string
  description = "Resource group containing the virtual network"
}

variable "key_vault_id" {
  type        = string
  description = "ID of the Key Vault"
  default     = null
}

variable "key_vault_name" {
  type        = string
  description = "Name of the Key Vault"
  default     = ""
}

variable "key_vault_resource_group_name" {
  type        = string
  description = "Resource group of the Key Vault"
  default     = ""
}

variable "application_insights_id" {
  type        = string
  description = "ID of the Application Insights resource"
  default     = ""
}

variable "application_insights_connection_string" {
  type        = string
  description = "Connection string for Application Insights"
  default     = ""
  sensitive   = true
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace"
  default     = ""
}

variable "deploy_sample" {
  type        = bool
  description = "Whether to deploy sample APIs"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the resource"
  default     = {}
}

locals {
  has_application_insights = var.application_insights_id != "" && var.application_insights_connection_string != ""
  apim_private_dns_zone    = "${var.name}.azure-api.net"
  is_standard_v2           = var.sku_name == "StandardV2"
}

# Private DNS Zone for APIM
resource "azurerm_private_dns_zone" "apim" {
  name                = local.apim_private_dns_zone
  resource_group_name = var.networking_resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "apim" {
  name                  = var.virtual_network_name
  resource_group_name   = var.networking_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.apim.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

# API Management Service
resource "azurerm_api_management" "this" {
  name                 = var.name
  location             = var.location
  resource_group_name  = var.resource_group_name
  publisher_name       = var.publisher_name
  publisher_email      = var.publisher_email
  sku_name             = "${var.sku_name}_${var.sku_capacity}"
  tags                 = var.tags
  zones                = var.sku_name == "Premium" && length(var.availability_zones) > 0 ? var.availability_zones : null

  virtual_network_type = local.is_standard_v2 ? "None" : var.virtual_network_type

  dynamic "virtual_network_configuration" {
    for_each = !local.is_standard_v2 && var.virtual_network_type != "None" ? [1] : []
    content {
      subnet_id = var.subnet_id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Security settings
  min_api_version = "2021-08-01"

  public_network_access_enabled = !local.is_standard_v2

  protocols {
    enable_http2 = true
  }

  security {
    enable_backend_ssl30  = false
    enable_backend_tls10  = false
    enable_backend_tls11  = false
    enable_frontend_ssl30 = false
    enable_frontend_tls10 = false
    enable_frontend_tls11 = false
  }

  depends_on = [
    azurerm_private_dns_zone.apim
  ]
}

# Private Endpoint for StandardV2 SKU
resource "azurerm_private_endpoint" "apim" {
  count               = local.is_standard_v2 && var.private_endpoint_subnet_id != "" ? 1 : 0
  name                = var.private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  custom_network_interface_name = var.private_endpoint_nic_name

  private_service_connection {
    name                           = var.private_endpoint_name
    private_connection_resource_id = azurerm_api_management.this.id
    subresource_names              = ["Gateway"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.apim.id]
  }
}

# DNS A Records for APIM
resource "azurerm_private_dns_a_record" "gateway" {
  name                = var.name
  zone_name           = azurerm_private_dns_zone.apim.name
  resource_group_name = var.networking_resource_group_name
  ttl                 = 36000
  records = local.is_standard_v2 && length(azurerm_private_endpoint.apim) > 0 ? [
    azurerm_private_endpoint.apim[0].private_service_connection[0].private_ip_address
  ] : [
    azurerm_api_management.this.private_ip_addresses[0]
  ]

  depends_on = [
    azurerm_api_management.this,
    azurerm_private_endpoint.apim
  ]
}

resource "azurerm_private_dns_a_record" "developer" {
  name                = "${var.name}.developer"
  zone_name           = azurerm_private_dns_zone.apim.name
  resource_group_name = var.networking_resource_group_name
  ttl                 = 36000
  records = local.is_standard_v2 && length(azurerm_private_endpoint.apim) > 0 ? [
    azurerm_private_endpoint.apim[0].private_service_connection[0].private_ip_address
  ] : [
    azurerm_api_management.this.private_ip_addresses[0]
  ]

  depends_on = [
    azurerm_api_management.this,
    azurerm_private_endpoint.apim
  ]
}

# Key Vault Access for APIM
resource "azurerm_role_assignment" "kv_secrets_user" {
  count                = var.key_vault_id != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_api_management.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "kv_certificates_user" {
  count                = var.key_vault_id != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = azurerm_api_management.this.identity[0].principal_id
}

# Application Insights Logger
resource "azurerm_api_management_logger" "app_insights" {
  count               = local.has_application_insights ? 1 : 0
  name                = element(split("/", var.application_insights_id), length(split("/", var.application_insights_id)) - 1)
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  resource_id         = var.application_insights_id

  application_insights {
    connection_string = var.application_insights_connection_string
  }
}

# Application Insights Diagnostic
resource "azurerm_api_management_diagnostic" "app_insights" {
  count                    = local.has_application_insights ? 1 : 0
  identifier               = "applicationinsights"
  api_management_name      = azurerm_api_management.this.name
  resource_group_name      = var.resource_group_name
  api_management_logger_id = azurerm_api_management_logger.app_insights[0].id

  always_log_errors         = true
  log_client_ip             = true
  http_correlation_protocol = "Legacy"
  verbosity                 = "information"
  sampling_percentage       = 100

  frontend_request {
    body_bytes = 0
  }

  frontend_response {
    body_bytes = 0
  }

  backend_request {
    body_bytes = 0
  }

  backend_response {
    body_bytes = 0
  }
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "apim" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_api_management.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

# APIM Groups
resource "azurerm_api_management_group" "administrators" {
  name                = "administrators"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "Administrators"
  description         = "Administrators is a built-in group containing the admin email account provided at the time of service creation."
  type                = "system"
}

resource "azurerm_api_management_group" "developers" {
  name                = "developers"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "Developers"
  description         = "Developers is a built-in group. Its membership is managed by the system."
  type                = "system"
}

resource "azurerm_api_management_group" "guests" {
  name                = "guests"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "Guests"
  description         = "Guests is a built-in group. Its membership is managed by the system."
  type                = "system"
}

# Products
resource "azurerm_api_management_product" "starter" {
  count                 = var.deploy_sample ? 1 : 0
  product_id            = "Starter"
  api_management_name   = azurerm_api_management.this.name
  resource_group_name   = var.resource_group_name
  display_name          = "Starter"
  description           = "Subscribers will be able to run 5 calls/minute up to a maximum of 100 calls/week."
  subscription_required = true
  approval_required     = false
  subscriptions_limit   = 1
  published             = true
}

resource "azurerm_api_management_product" "unlimited" {
  count                 = var.deploy_sample ? 1 : 0
  product_id            = "Unlimited"
  api_management_name   = azurerm_api_management.this.name
  resource_group_name   = var.resource_group_name
  display_name          = "Unlimited"
  description           = "Subscribers have completely unlimited access to the API. Administrator approval is required."
  subscription_required = true
  approval_required     = true
  subscriptions_limit   = 1
  published             = true
}

output "id" {
  description = "The ID of the API Management service"
  value       = azurerm_api_management.this.id
}

output "name" {
  description = "The name of the API Management service"
  value       = azurerm_api_management.this.name
}

output "gateway_url" {
  description = "The gateway URL of the API Management service"
  value       = azurerm_api_management.this.gateway_url
}

output "developer_portal_url" {
  description = "The developer portal URL"
  value       = azurerm_api_management.this.developer_portal_url
}

output "management_api_url" {
  description = "The management API URL"
  value       = azurerm_api_management.this.management_api_url
}

output "principal_id" {
  description = "The principal ID of the system-assigned managed identity"
  value       = azurerm_api_management.this.identity[0].principal_id
}

output "private_ip_addresses" {
  description = "Private IP addresses of the API Management service"
  value       = azurerm_api_management.this.private_ip_addresses
}
