#--------------------------------------------------------------
# Application Gateway Module
# Equivalent to appgw.bicep
#--------------------------------------------------------------

variable "name" {
  type        = string
  description = "Name of the Application Gateway"
}

variable "location" {
  type        = string
  description = "Azure region for the resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet for Application Gateway"
}

variable "public_ip_id" {
  type        = string
  description = "ID of the public IP for Application Gateway"
}

variable "waf_policy_name" {
  type        = string
  description = "Name of the WAF policy"
}

variable "key_vault_id" {
  type        = string
  description = "ID of the Key Vault"
  default     = null
}

variable "backend_fqdn" {
  type        = string
  description = "FQDN of the backend (APIM)"
}

variable "probe_url" {
  type        = string
  description = "URL path for health probe"
  default     = "/status-0123456789abcdef"
}

variable "capacity" {
  type        = number
  description = "Capacity of the Application Gateway"
  default     = 2
}

variable "zones" {
  type        = list(string)
  description = "Availability zones"
  default     = ["1", "2", "3"]
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the resource"
  default     = {}
}

# User Assigned Identity for Key Vault access
resource "azurerm_user_assigned_identity" "appgw" {
  name                = "AppGatewayManagedIdentity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Key Vault role assignments
resource "azurerm_role_assignment" "appgw_kv_certs" {
  count                = var.key_vault_id != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = azurerm_user_assigned_identity.appgw.principal_id
}

resource "azurerm_role_assignment" "appgw_kv_secrets" {
  count                = var.key_vault_id != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.appgw.principal_id
}

# WAF Policy
resource "azurerm_web_application_firewall_policy" "this" {
  name                = var.waf_policy_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    max_request_body_size_in_kb = 2000
    file_upload_limit_in_mb     = 100
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  custom_rules {
    name      = "AllowedAppServers"
    priority  = 1
    rule_type = "MatchRule"
    action    = "Allow"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }
      operator           = "IPMatch"
      negation_condition = false
      match_values = [
        "10.134.248.0/24",
        "10.134.246.0/24",
        "10.134.245.0/24"
      ]
    }
  }
}

# Application Gateway
resource "azurerm_application_gateway" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = var.zones
  tags                = var.tags

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = var.capacity
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw.id]
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = var.public_ip_id
  }

  backend_address_pool {
    name  = "apim-backend-pool"
    fqdns = [var.backend_fqdn]
  }

  backend_http_settings {
    name                                = "apim-http-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 180
    probe_name                          = "apim-health-probe"
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = "apim-http-listener"
    frontend_ip_configuration_name = "appGwPublicFrontendIp"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "apim-routing-rule"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "apim-http-listener"
    backend_address_pool_name  = "apim-backend-pool"
    backend_http_settings_name = "apim-http-settings"
  }

  probe {
    name                                      = "apim-health-probe"
    protocol                                  = "Https"
    path                                      = var.probe_url
    interval                                  = 30
    timeout                                   = 120
    unhealthy_threshold                       = 8
    pick_host_name_from_backend_http_settings = true
    match {
      status_code = ["200-399"]
    }
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.this.id

  depends_on = [
    azurerm_role_assignment.appgw_kv_certs,
    azurerm_role_assignment.appgw_kv_secrets
  ]
}

output "id" {
  description = "The ID of the Application Gateway"
  value       = azurerm_application_gateway.this.id
}

output "name" {
  description = "The name of the Application Gateway"
  value       = azurerm_application_gateway.this.name
}

output "identity_principal_id" {
  description = "The principal ID of the managed identity"
  value       = azurerm_user_assigned_identity.appgw.principal_id
}
